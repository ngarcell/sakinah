import SwiftUI
import SwiftData
import StoreKit

struct QuickCheckInCard: View {
    @Bindable var vm: TodayViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview

    private let moods: [Mood] = [.great, .good, .okay, .low, .tough]

    var body: some View {
        SakinahCard {
            if appState.hasPremiumAccess {
                premiumContent
            } else {
                lockedContent
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
        .animation(SakinahAnimation.gentle, value: vm.showCheckInNote)
        .animation(SakinahAnimation.gentle, value: vm.partnerMood)
    }

    private var premiumContent: some View {
        VStack(spacing: SakinahSpacing.base) {
            HStack {
                Text("HOW ARE YOU FEELING?")
                    .font(SakinahFont.captionBold)
                    .tracking(0.4)
                    .foregroundStyle(SakinahColor.textSecondary)
                Spacer()
                if vm.hasCheckedInToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SakinahColor.success)
                        .font(.system(size: 16))
                    }
            }

            if vm.hasCheckedInToday && !vm.isUpdatingCheckIn, let selectedMood = vm.selectedMood {
                HStack(spacing: SakinahSpacing.sm) {
                    Text(selectedMood.emoji)
                        .font(.system(size: 22))
                    Text("Checked in as \(selectedMood.label)")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textPrimary)
                    Spacer()
                    Button("Undo") {
                        vm.toggleUpdateCheckIn()
                    }
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.primary)
                }
                .padding(SakinahSpacing.md)
                .background(SakinahColor.backgroundSecondary)
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            } else {
                HStack(spacing: 0) {
                    ForEach(moods, id: \.self) { mood in
                        moodButton(mood)
                    }
                }
            }

            if let partnerMood = vm.partnerMood {
                partnerBanner(mood: partnerMood)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if vm.hasCheckedInToday && !vm.isUpdatingCheckIn {
                Button {
                    vm.toggleUpdateCheckIn()
                } label: {
                    Text("Change")
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.primary)
                }
                .pressScale()
            }
        }
    }

    private var lockedContent: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.base) {
            HStack {
                Text("HOW ARE YOU FEELING?")
                    .font(SakinahFont.captionBold)
                    .tracking(0.4)
                    .foregroundStyle(SakinahColor.textSecondary)
                Spacer()
                if let selectedMood = vm.selectedMood {
                    Text(selectedMood.emoji)
                        .font(.system(size: 24))
                }
            }

            if let selectedMood = vm.selectedMood {
                Text("Your last check-in was \(selectedMood.label.lowercased()).")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
            } else {
                Text("Check-ins are still visible here. Upgrade to keep recording how the day feels for you.")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
            }

            if let partnerMood = vm.partnerMood {
                partnerBanner(mood: partnerMood)
            }

            UpgradePromptView(
                icon: "heart.circle.fill",
                headline: "Keep daily check-ins active",
                message: "Return to your mood history, notes, and shared rhythm with an active plan.",
                ctaTitle: "See plans"
            ) {
                appState.presentPaywall(for: .dailyHabit)
            }
        }
    }

    private func moodButton(_ mood: Mood) -> some View {
        let isSelected = vm.selectedMood == mood
        return Button {
            vm.selectMood(mood, context: modelContext)
            Task {
                await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
            }
        } label: {
            VStack(spacing: SakinahSpacing.xs) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(isSelected ? SakinahColor.primaryLight : SakinahColor.backgroundSecondary)
                    .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                Text(mood.label)
                    .font(SakinahFont.caption)
                    .foregroundStyle(isSelected ? SakinahColor.textPrimary : SakinahColor.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .opacity(isSelected ? 1 : (vm.selectedMood == nil ? 0.8 : 0.6))
            .scaleEffect(isSelected ? 1.15 : 1.0)
        }
        .pressScale()
        .animation(SakinahAnimation.bounce, value: isSelected)
    }

    private func partnerBanner(mood: Mood) -> some View {
        HStack(spacing: SakinahSpacing.sm) {
            Text(mood.emoji)
                .font(.system(size: 18))
            Text("\(vm.partnerName) is feeling \(mood.label.lowercased())")
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textSecondary)
            Spacer()
        }
        .padding(SakinahSpacing.md)
        .background(SakinahColor.backgroundSecondary)
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
    }
}
