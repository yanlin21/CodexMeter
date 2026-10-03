import Foundation

enum AppGroupStore {
    // Xcode expands this value from the shared CODEX_METER_APP_GROUP build setting.
    // Keeping it in Info.plist lets forks select their own Team without editing Swift.
    static var identifier: String {
        Bundle.main.object(forInfoDictionaryKey: "CodexMeterAppGroupIdentifier") as? String
            ?? "codexmeter.shared"
    }
    private static let fileName = "usage-snapshot.json"

    static func load() -> CodexUsageSnapshot? {
        guard let url = snapshotURL(), let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try? decoder.decode(CodexUsageSnapshot.self, from: data)
    }

    static func save(_ snapshot: CodexUsageSnapshot) throws {
        guard let url = snapshotURL(createDirectory: true) else {
            throw StoreError.containerUnavailable
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        try encoder.encode(snapshot).write(to: url, options: [.atomic])
    }

    private static func snapshotURL(createDirectory: Bool = false) -> URL? {
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) {
            return container.appendingPathComponent(fileName)
        }

        // Keeps unsigned command-line/debug runs useful. A signed Widget requires the App Group.
        guard let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }
        let fallback = applicationSupport.appendingPathComponent("CodexMeter", isDirectory: true)
        if createDirectory {
            try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        }
        return fallback.appendingPathComponent(fileName)
    }

    enum StoreError: LocalizedError {
        case containerUnavailable

        var errorDescription: String? {
            "The shared App Group container is unavailable."
        }
    }
}
