import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: UsageStore
    @StateObject private var launchAtLogin = LaunchAtLoginController()
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                header

                if let snapshot = store.snapshot {
                    usageContent(snapshot)
                } else if store.isLoading {
                    loadingContent
                } else {
                    emptyContent
                }

                if let error = store.errorMessage {
                    errorContent(error)
                }
            }
            .padding(16)

            Divider()
            actions
                .padding(10)
        }
        .frame(width: 320)
        .task { store.start() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Codex")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            PlanBadge(planName: store.snapshot?.planName)
        }
    }

    @ViewBuilder
    private func usageContent(_ snapshot: CodexUsageSnapshot) -> some View {
        VStack(spacing: 10) {
            if let window = snapshot.fiveHour {
                card { UsageProgressView(title: "5 Hours", window: window) }
            }
            if let window = snapshot.weekly {
                card { UsageProgressView(title: "Weekly", window: window) }
            }
            if let credits = snapshot.credits {
                card {
                    HStack {
                        Label("Credits", systemImage: "creditcard")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text(UsageFormatting.credits(credits))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                }
            }
        }

        HStack {
            Text("Updated \(UsageFormatting.updatedDescription(snapshot.updatedAt))")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
            if store.isLoading {
                ProgressView().controlSize(.mini)
            }
        }
    }

    private var loadingContent: some View {
        HStack(spacing: 10) {
            ProgressView().controlSize(.small)
            Text("Reading Codex usage…")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 74)
    }

    private var emptyContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No usage data")
                .font(.system(size: 12, weight: .medium))
        }
        .frame(maxWidth: .infinity, minHeight: 74)
    }

    private func errorContent(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.system(size: 11, weight: .medium))
                if store.snapshot != nil {
                    Text("Showing the last successful update.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var actions: some View {
        VStack(spacing: 2) {
            actionButton("Refresh Now", systemImage: "arrow.clockwise") {
                Task { await store.refresh() }
            }
            .disabled(store.isLoading)

            actionButton("Open CodexMeter", systemImage: "macwindow") {
                openWindow(id: "dashboard")
                NSApp.activate(ignoringOtherApps: true)
            }

            Toggle(isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            )) {
                Label("Launch at Login", systemImage: "power")
            }
            .toggleStyle(.checkbox)
            .font(.system(size: 12))
            .padding(.horizontal, 6)
            .padding(.vertical, 5)

            if let message = launchAtLogin.errorMessage {
                Text(message)
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 7)
            }

            Divider().padding(.vertical, 3)
            actionButton("Quit CodexMeter", systemImage: "xmark.circle") {
                NSApp.terminate(nil)
            }
        }
    }

    private func actionButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(11)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

