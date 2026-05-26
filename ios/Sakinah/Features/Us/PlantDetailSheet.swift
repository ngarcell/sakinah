import SwiftUI

struct PlantDetailSheet: View {
    let dimension: GardenDimension
    let level: Double
    let weeklyLevels: [Double]
    var onGoToToday: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: SakinahSpacing.xl) {
                plantIllustration

                VStack(spacing: SakinahSpacing.sm) {
                    Text(dimension.label)
                        .font(SakinahFont.title1)
                        .foregroundStyle(SakinahColor.textPrimary)

                    Text(levelTitle)
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.accent)
                }

                Text(levelDescription)
                    .font(SakinahFont.body)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                    Text("Progress toward next level")
                        .font(SakinahFont.captionBold)
                        .tracking(0.4)
                        .foregroundStyle(SakinahColor.textSecondary)

                    ProgressView(value: min(max(level / 5.0, 0), 1))
                        .tint(SakinahColor.primary)

                    HStack(spacing: SakinahSpacing.sm) {
                        ForEach(0..<4, id: \.self) { index in
                            let value = index < weeklyLevels.count ? weeklyLevels[index] : 0
                            Circle()
                                .fill(value >= 3 ? SakinahColor.primary : Color.clear)
                                .overlay(
                                    Circle()
                                        .stroke(value >= 3 ? SakinahColor.primary : SakinahColor.border, lineWidth: 1.5)
                                )
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                .padding(SakinahSpacing.base)
                .background(SakinahColor.surface)
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                    Text("Suggested actions")
                        .font(SakinahFont.captionBold)
                        .tracking(0.4)
                        .foregroundStyle(SakinahColor.textSecondary)

                    ForEach(suggestions, id: \.self) { suggestion in
                        Label(suggestion, systemImage: "leaf.fill")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SakinahSpacing.sm) {
                        ForEach(relatedPrompts, id: \.self) { prompt in
                            Text(prompt)
                                .font(SakinahFont.captionBold)
                                .foregroundStyle(SakinahColor.primary)
                                .padding(.horizontal, SakinahSpacing.md)
                                .padding(.vertical, SakinahSpacing.sm)
                                .background(SakinahColor.primaryLight)
                                .clipShape(.capsule)
                        }
                    }
                }
            }
            .padding(SakinahSpacing.base)
        }
        .background(SakinahColor.background)
    }

    private var plantIllustration: some View {
        ZStack {
            Circle()
                .fill(SakinahColor.primaryLight)
                .frame(width: 160, height: 160)
            Image(systemName: dimension.icon)
                .font(.system(size: 58, weight: .regular))
                .foregroundStyle(SakinahColor.primary)
        }
    }

    private var levelTitle: String {
        let levelNumber = min(max(Int(level.rounded()), 1), 5)
        let label: String
        switch levelNumber {
        case 1: label = "Sprouting"
        case 2: label = "Budding"
        case 3: label = "Growing"
        case 4: label = "Blooming"
        default: label = "Flourishing"
        }
        return "\(label) - Level \(levelNumber) of 5"
    }

    private var levelDescription: String {
        let name = dimension.label.lowercased()
        switch Int(level.rounded()) {
        case 1: return "Your \(name) needs more care right now."
        case 2: return "Your \(name) is starting to recover."
        case 3: return "Your \(name) is steady."
        case 4: return "Your \(name) is strong."
        case 5: return "Your \(name) is flourishing."
        default: return "Your \(name) is on its way."
        }
    }

    private var suggestions: [String] {
        switch dimension {
        case .communication:
            return ["Answer today's reflection", "Ask one follow-up question", "Name what you heard before replying"]
        case .qualityTime:
            return ["Protect ten quiet minutes", "Plan one no-phone meal", "Choose one shared errand"]
        case .spiritualConnection:
            return ["Read today's du'a together", "Pray for one specific need", "Share one ayah or reminder"]
        case .emotionalSafety:
            return ["Check in gently", "Thank your spouse for one effort", "Delay a hard topic until calm"]
        case .growth:
            return ["Read a lesson chapter", "Try one small practice", "Reflect on what changed this week"]
        }
    }

    private var relatedPrompts: [String] {
        ["Today", "This week", "Together"]
    }
}
