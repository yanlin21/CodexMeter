import SwiftUI

struct PlanBadge: View {
    let planName: String?

    var body: some View {
        if let badge = UsageFormatting.planBadge(planName) {
            Text(badge)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
                .accessibilityLabel(planName ?? badge)
        }
    }
}

