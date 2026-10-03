import Foundation
import OSLog

struct CodexService: Sendable {
    private let locator = CodexExecutableLocator()
    private let logger = Logger(subsystem: "com.codexmeter.app", category: "CodexService")

    func fetchSnapshot() async throws -> CodexUsageSnapshot {
        try await Task.detached(priority: .userInitiated) {
            try fetchSnapshotSynchronously()
        }.value
    }

    private func fetchSnapshotSynchronously() throws -> CodexUsageSnapshot {
        guard let executable = locator.locate() else { throw ServiceError.cliNotFound }
        let client = JSONRPCClient(executableURL: executable)
        defer { client.stop() }

        do {
            try client.start()
            _ = try client.request(
                method: "initialize",
                params: [
                    "clientInfo": [
                        "name": "codex_meter",
                        "title": "CodexMeter",
                        "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    ],
                    "capabilities": [
                        "experimentalApi": true,
                        "requestAttestation": false
                    ]
                ],
                timeout: 10
            )
            try client.sendNotification(method: "initialized")

            let accountResult: [String: Any]?
            do {
                accountResult = try client.request(
                    method: "account/read",
                    params: ["refreshToken": false],
                    timeout: 15
                )
            } catch {
                logger.debug("Account read failed; rate-limit data may still be available: \(error.localizedDescription, privacy: .private)")
                accountResult = nil
            }

            let limitsResult: [String: Any]
            do {
                limitsResult = try client.request(
                    method: "account/rateLimits/read",
                    params: ["excludeResetCreditDetails": true],
                    timeout: 20
                )
            } catch {
                if Self.accountObject(from: accountResult) == nil,
                   error.localizedDescription.localizedCaseInsensitiveContains("auth") {
                    throw ServiceError.notSignedIn
                }
                throw error
            }

            return try Self.makeSnapshot(account: accountResult, limits: limitsResult)
        } catch let error as ServiceError {
            throw error
        } catch let error as JSONRPCClient.ClientError {
            switch error {
            case .couldNotStart: throw ServiceError.serverStartFailed
            case .timedOut: throw ServiceError.timedOut
            case .processExited: throw ServiceError.processExited
            case .rpc(_, let message) where message.localizedCaseInsensitiveContains("login") || message.localizedCaseInsensitiveContains("auth"):
                throw ServiceError.notSignedIn
            case .invalidResponse: throw ServiceError.schemaChanged
            default: throw ServiceError.unableToRead
            }
        } catch {
            logger.error("Usage refresh failed: \(error.localizedDescription, privacy: .private)")
            throw ServiceError.unableToRead
        }
    }

    private static func makeSnapshot(
        account: [String: Any]?,
        limits: [String: Any]
    ) throws -> CodexUsageSnapshot {
        let snapshots = rateLimitSnapshots(from: limits)
        guard !snapshots.isEmpty else { throw ServiceError.schemaChanged }

        let rawPlan = (accountObject(from: account)?["planType"] as? String)
            ?? snapshots.compactMap { $0["planType"] as? String }.first
        let windows = snapshots.flatMap { snapshot -> [[String: Any]] in
            [snapshot["primary"], snapshot["secondary"]].compactMap { $0 as? [String: Any] }
        }

        var fiveHour: UsageWindow?
        var weekly: UsageWindow?
        for rawWindow in windows {
            guard let window = parseWindow(rawWindow) else { continue }
            switch classify(window) {
            case .fiveHour:
                if fiveHour == nil { fiveHour = window }
            case .weekly:
                if weekly == nil { weekly = window }
            case .unknown:
                continue
            }
        }

        let credits = snapshots.compactMap(parseCredits).first
        return CodexUsageSnapshot(
            planName: UsageFormatting.planDisplayName(rawPlan),
            fiveHour: fiveHour,
            weekly: weekly,
            credits: credits,
            updatedAt: Date()
        )
    }

    private static func accountObject(from result: [String: Any]?) -> [String: Any]? {
        result?["account"] as? [String: Any]
    }

    private static func rateLimitSnapshots(from limits: [String: Any]) -> [[String: Any]] {
        if let byID = limits["rateLimitsByLimitId"] as? [String: Any] {
            if let codex = byID["codex"] as? [String: Any] { return [codex] }
            let values = byID.values.compactMap { $0 as? [String: Any] }
            if !values.isEmpty { return values }
        }
        if let legacy = limits["rateLimits"] as? [String: Any] { return [legacy] }
        return []
    }

    private static func parseWindow(_ value: [String: Any]) -> UsageWindow? {
        guard let used = double(value["usedPercent"]) else { return nil }
        let duration = integer(value["windowDurationMins"] ?? value["durationMinutes"])
        let resetSeconds = double(value["resetsAt"] ?? value["resetAt"])
        return UsageWindow(
            usedPercent: used,
            resetAt: resetSeconds.map(Date.init(timeIntervalSince1970:)),
            durationMinutes: duration
        )
    }

    private static func parseCredits(_ snapshot: [String: Any]) -> CreditInfo? {
        guard let raw = snapshot["credits"] as? [String: Any] else { return nil }
        let hasCredits = (raw["hasCredits"] as? Bool) ?? false
        let unlimited = (raw["unlimited"] as? Bool) ?? false
        let balance = double(raw["balance"])
        guard hasCredits || unlimited || (balance ?? 0) > 0 else { return nil }
        return CreditInfo(balance: balance, currency: "USD", isUnlimited: unlimited)
    }

    private enum WindowKind { case fiveHour, weekly, unknown }

    private static func classify(_ window: UsageWindow) -> WindowKind {
        if let duration = window.durationMinutes {
            if abs(duration - 300) <= 180 { return .fiveHour }
            if abs(duration - 10_080) <= 2_880 { return .weekly }
            if duration < 1_440 { return .fiveHour }
            if duration >= 1_440 { return .weekly }
        }
        if let resetAt = window.resetAt {
            let interval = resetAt.timeIntervalSinceNow
            if interval <= 8 * 60 * 60 { return .fiveHour }
            if interval <= 9 * 24 * 60 * 60 { return .weekly }
        }
        return .unknown
    }

    private static func double(_ value: Any?) -> Double? {
        if let double = value as? Double { return double }
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String { return Double(string) }
        return nil
    }

    private static func integer(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    enum ServiceError: LocalizedError {
        case cliNotFound
        case notSignedIn
        case serverStartFailed
        case timedOut
        case processExited
        case schemaChanged
        case unableToRead

        var errorDescription: String? {
            switch self {
            case .cliNotFound: "Codex CLI not found"
            case .notSignedIn: "Codex is not signed in"
            case .serverStartFailed: "Unable to start Codex"
            case .timedOut: "Codex did not respond in time"
            case .processExited: "Codex stopped unexpectedly"
            case .schemaChanged, .unableToRead: "Unable to read Codex usage"
            }
        }
    }
}
