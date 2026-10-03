import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CodexMeter")
                        .font(.system(size: 28, weight: .bold))
                    Text(store.snapshot?.planName ?? "Local Codex usage")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }

            if let snapshot = store.snapshot {
                VStack(spacing: 12) {
                    if let window = snapshot.fiveHour {
                        dashboardCard { UsageProgressView(title: "5 Hours", window: window) }
                    }
                    if let window = snapshot.weekly {
                        dashboardCard { UsageProgressView(title: "Weekly", window: window) }
                    }
                    if let credits = snapshot.credits {
                        dashboardCard {
                            HStack {
                                Label("Credits", systemImage: "creditcard")
                                Spacer()
                                Text(UsageFormatting.credits(credits))
                                    .font(.title3.weight(.semibold))
                            }
                        }
                    }
                }

                Text("Last updated \(UsageFormatting.updatedDescription(snapshot.updatedAt))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if store.isLoading {
                ProgressView("Reading Codex usage…")
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ContentUnavailableView(
                    "No Usage Data",
                    systemImage: "chart.bar.xaxis",
                    description: Text(store.errorMessage ?? "Refresh to read usage from the installed Codex CLI.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            }

            if let error = store.errorMessage, store.snapshot != nil {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 460, idealWidth: 520, minHeight: 360)
        .task { store.start() }
    }

    private func dashboardCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.separator.opacity(0.35), lineWidth: 0.5)
            }
    }
}

