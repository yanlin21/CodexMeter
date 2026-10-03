import SwiftUI

struct SmallWidgetView: View {
    let snapshot: CodexUsageSnapshot?

    private var selected: (String, UsageWindow)? {
        if let weekly = snapshot?.weekly { return ("Weekly", weekly) }
        if let fiveHour = snapshot?.fiveHour { return ("5 Hours", fiveHour) }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Codex")
                    .font(.headline)
                Spacer()
                if let badge = UsageFormatting.planBadge(snapshot?.planName) {
                    Text(badge)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let selected {
                Text(selected.0)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(UsageFormatting.percent(selected.1.remainingPercent))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(statusColor(selected.1.remainingPercent))
                if let reset = UsageFormatting.resetDescription(selected.1.resetAt, compact: true) {
                    Text("Reset \(reset)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("Open CodexMeter to refresh")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statusColor(_ remaining: Double) -> Color {
        if remaining < 20 { return .red }
        if remaining <= 40 { return .orange }
        return .accentColor
    }
}

