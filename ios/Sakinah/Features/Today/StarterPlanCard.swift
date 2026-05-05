import SwiftUI

struct StarterPlanCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @ViewBuilder
    var body: some View {
        if let plan = appState.currentStarterPlan {
            SakinahCard(elevated: true) {
                VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                            SakinahBadge(
                                text: "Your first week",
                                color: SakinahColor.accent,
                                tintedBackground: SakinahColor.accentLight
                            )

                            Text(plan.headline)
                                .font(SakinahFont.title3)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button {
                            dismissCard()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(SakinahColor.textTertiary)
                                .frame(width: 28, height: 28)
                                .background(SakinahColor.backgroundSecondary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(plan.reason)
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .lineSpacing(3)

                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text("This week")
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .textCase(.uppercase)
                        Text(plan.firstWeekAction)
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textPrimary)
                    }

                    Text(plan.recommendedPackOrLesson)
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.accent)
                }
            }
            .padding(.horizontal, SakinahSpacing.base)
        }
    }

    private func dismissCard() {
        appState.currentUser?.dismissStarterPlan()
        try? modelContext.save()
    }
}
