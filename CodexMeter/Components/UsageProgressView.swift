import SwiftUI

struct UsageProgressView: View {
    let title: String
    let window: UsageWindow
    var compact = false

    private var statusColor: Color {
        switch window.remainingPercent {
        case ..<20: return .red
        case 20...40: return .orange
        default: return .accentColor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: compact ? 12 : 13, weight: .semibold))
                Spacer()
                Text(UsageFormatting.percent(window.remainingPercent))
                    .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusColor)
                    .monospacedDigit()
            }

            ProgressView(value: window.remainingPercent, total: 100)
                .progressViewStyle(.linear)
                .tint(statusColor)
                .accessibilityLabel("\(title) remaining")
                .accessibilityValue(UsageFormatting.percent(window.remainingPercent))

            if let reset = UsageFormatting.resetDescription(window.resetAt) {
                Text("Reset \(reset)")
                    .font(.system(size: compact ? 10 : 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

