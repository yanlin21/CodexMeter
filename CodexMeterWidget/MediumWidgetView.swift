import SwiftUI

struct MediumWidgetView: View {
    let snapshot: CodexUsageSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Codex")
                    .font(.headline)
                Spacer()
                if let badge = UsageFormatting.planBadge(snapshot?.planName) {
                    Text(badge)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }

            if let snapshot {
                if let fiveHour = snapshot.fiveHour {
                    WidgetUsageProgressView(title: "5 Hours", window: fiveHour)
                }
                if let weekly = snapshot.weekly {
                    WidgetUsageProgressView(title: "Weekly", window: weekly)
                }
                if snapshot.fiveHour == nil && snapshot.weekly == nil {
                    Text("No quota data available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                HStack(spacing: 8) {
                    if let credits = snapshot.credits {
                        Text("Credits \(UsageFormatting.credits(credits))")
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("Updated \(UsageFormatting.updatedDescription(snapshot.updatedAt))")
                        .lineLimit(1)
                }
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            } else {
                Spacer()
                Label("Open CodexMeter to refresh", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}
