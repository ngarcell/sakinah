import SwiftUI

struct PlantDetailSheet: View {
    let dimension: GardenDimension
    let level: Double
    let weeklyLevels: [Double] // last 4 weeks
    var onGoToToday: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: SakinahSpacing.lg) {
            // Handle
            Capsule()
                .fill(SakinahColor.divider)
                .frame(width: 36, height: 4)
                .padding(.top, SakinahSpacing.sm)

            // Header
            VStack(spacing: SakinahSpacing.sm) {
                Image(systemName: dimension.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(SakinahColor.primary)
                Text(dimension.label)
                    .font(SakinahFont.title3)
                    .foregroundStyle(SakinahColor.textPrimary)
            }

            // Level description
            Text(levelDescription)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SakinahSpacing.lg)

            // Mini trend
            VStack(spacing: SakinahSpacing.sm) {
                Text("Last 4 weeks")
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.textSecondary)

                HStack(spacing: SakinahSpacing.md) {
                    ForEach(0..<4, id: \.self) { i in
                        let val = i < weeklyLevels.count ? weeklyLevels[i] : 0
                        let isGood = val >= 3
                        Circle()
                            .fill(isGood ? SakinahColor.primary : Color.clear)
                            .stroke(isGood ? SakinahColor.primary : SakinahColor.textTertiary, lineWidth: 2)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(SakinahSpacing.base)
            .background(SakinahColor.backgroundSecondary)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))

            // Suggestion if level is low
            if level <= 2 {
                VStack(spacing: SakinahSpacing.sm) {
                    Text(suggestion)
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .multilineTextAlignment(.center)

                    if let onGoToToday {
                        SakinahButton(title: "Go to Today's Prompt", icon: "arrow.right", variant: .secondary, isFullWidth: false) {
                            onGoToToday()
                        }
                    }
                }
                .padding(SakinahSpacing.base)
                .background(SakinahColor.accentLight)
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            }

            Spacer()
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    private var levelDescription: String {
        let name = dimension.label.lowercased()
        switch Int(level.rounded()) {
        case 1: return "Your \(name) needs more care right now."
        case 2: return "Your \(name) is starting to recover."
        case 3: return "Your \(name) is steady."
        case 4: return "Your \(name) is strong."
        case 5: return "Your \(name) is flourishing."
        default: return "Your \(name) is on its way"
        }
    }

    private var suggestion: String {
        switch dimension {
        case .communication: return "Try answering today's prompt together"
        case .qualityTime: return "Plan a moment of quality time this week"
        case .spiritualConnection: return "Read today's du'a together"
        case .emotionalSafety: return "Check in on how your partner is feeling"
        case .growth: return "Reflect on something new you could learn together"
        }
    }
}
