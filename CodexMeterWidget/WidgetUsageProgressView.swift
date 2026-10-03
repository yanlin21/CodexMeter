import SwiftUI

struct WidgetUsageProgressView: View {
    let title: String
    let window: UsageWindow

    private var statusColor: Color {
        switch window.remainingPercent {
        case ..<20: return .red
        case 20...40: return .orange
        default: return .accentColor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption.weight(.semibold))
                Spacer()
                Text(UsageFormatting.percent(window.remainingPercent))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(statusColor)
            }
            ProgressView(value: window.remainingPercent, total: 100)
                .progressViewStyle(.linear)
                .tint(statusColor)
            if let reset = UsageFormatting.resetDescription(window.resetAt) {
                Text("Reset \(reset)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

