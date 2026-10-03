import Combine
import Foundation
import OSLog
import WidgetKit

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var snapshot: CodexUsageSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: CodexService
    private let logger = Logger(subsystem: "com.codexmeter.app", category: "UsageStore")
    private var refreshTimer: AnyCancellable?
    private var hasStarted = false

    init(service: CodexService = CodexService()) {
        self.service = service
        self.snapshot = AppGroupStore.load()
    }

    var menuBarTitle: String {
        guard let remaining = snapshot?.preferredWindow?.remainingPercent else { return "Codex" }
        return "Codex \(UsageFormatting.percent(remaining))"
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        Task { await refresh() }
        refreshTimer = Timer.publish(every: 5 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let newSnapshot = try await service.fetchSnapshot()
            snapshot = newSnapshot
            do {
                try AppGroupStore.save(newSnapshot)
            } catch {
                logger.error("Could not cache usage: \(error.localizedDescription, privacy: .private)")
            }
            WidgetCenter.shared.reloadTimelines(ofKind: "CodexMeterWidget")
        } catch {
            // Preserve the last successful snapshot so the menu and Widget do not go blank.
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Unable to read Codex usage"
            logger.error("Refresh failed: \(error.localizedDescription, privacy: .private)")
        }
    }
}

