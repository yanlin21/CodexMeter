import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    init() {
        refreshStatus()
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshStatus()
        } catch {
            refreshStatus()
            errorMessage = "Unable to update Launch at Login"
        }
    }

    private func refreshStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
