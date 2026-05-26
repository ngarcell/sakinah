import SwiftUI
import SwiftData

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
                            HStack {
                                Text("YOUR 30-DAY PLAN")
                                    .font(SakinahFont.captionBold)
                                    .tracking(0.4)
                                    .foregroundStyle(SakinahColor.textSecondary)
                                Spacer()
                                Text(planDayText)
                                    .font(SakinahFont.captionBold)
                                    .foregroundStyle(SakinahColor.accent)
                            }

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

                    ProgressView(value: planProgress)
                        .tint(SakinahColor.primary)
                        .background(SakinahColor.divider)

                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text("Today")
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

    private var planDay: Int {
        guard let createdAt = appState.currentUser?.starterPlanCreatedAt else { return 1 }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: createdAt),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        return min(max(days + 1, 1), 30)
    }

    private var planDayText: String {
        "Day \(planDay) of 30"
    }

    private var planProgress: Double {
        Double(planDay) / 30.0
    }

    private func dismissCard() {
        appState.currentUser?.dismissStarterPlan()
        try? modelContext.save()
    }
}
