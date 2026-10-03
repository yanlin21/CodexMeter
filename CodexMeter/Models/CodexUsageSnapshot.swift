import Foundation

struct CodexUsageSnapshot: Codable, Equatable, Sendable {
    var planName: String?
    var fiveHour: UsageWindow?
    var weekly: UsageWindow?
    var credits: CreditInfo?
    var updatedAt: Date

    var preferredWindow: UsageWindow? {
        weekly ?? fiveHour
    }

    static let placeholder = CodexUsageSnapshot(
        planName: "ChatGPT Pro",
        fiveHour: UsageWindow(
            usedPercent: 18,
            remainingPercent: 82,
            resetAt: Date().addingTimeInterval(2 * 60 * 60),
            durationMinutes: 300
        ),
        weekly: UsageWindow(
            usedPercent: 36,
            remainingPercent: 64,
            resetAt: Date().addingTimeInterval(4 * 24 * 60 * 60),
            durationMinutes: 10_080
        ),
        credits: nil,
        updatedAt: Date()
    )
}

struct UsageWindow: Codable, Equatable, Sendable, Identifiable {
    var usedPercent: Double
    var remainingPercent: Double
    var resetAt: Date?
    var durationMinutes: Int?

    var id: String {
        "\(durationMinutes ?? -1)-\(resetAt?.timeIntervalSince1970 ?? 0)"
    }

    init(
        usedPercent: Double,
        remainingPercent: Double? = nil,
        resetAt: Date?,
        durationMinutes: Int?
    ) {
        let clampedUsed = min(100, max(0, usedPercent))
        self.usedPercent = clampedUsed
        self.remainingPercent = min(100, max(0, remainingPercent ?? (100 - clampedUsed)))
        self.resetAt = resetAt
        self.durationMinutes = durationMinutes
    }
}

struct CreditInfo: Codable, Equatable, Sendable {
    var balance: Double?
    var currency: String?
    var isUnlimited: Bool

    init(balance: Double?, currency: String?, isUnlimited: Bool = false) {
        self.balance = balance
        self.currency = currency
        self.isUnlimited = isUnlimited
    }
}

