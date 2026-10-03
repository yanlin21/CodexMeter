import SwiftUI

@main
struct CodexMeterApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: store)
        } label: {
            Text(store.menuBarTitle)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("CodexMeter", id: "dashboard") {
            DashboardView(store: store)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
