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
            VStack(spacing: SakinahSpacing.base) {
                HStack {
                    Text("How are you feeling?")
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                    Spacer()
                    if vm.hasCheckedInToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SakinahColor.success)
                            .font(.system(size: 16))
                    }
                }

                // Mood options
                HStack(spacing: 0) {
                    ForEach(moods, id: \.self) { mood in
                        moodButton(mood)
                    }
                }

                // Optional note
                if vm.showCheckInNote {
                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("Want to add a note?")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)

                        TextField("Share what's on your mind...", text: $vm.checkInNote, axis: .vertical)
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textPrimary)
                            .padding(SakinahSpacing.md)
                            .background(SakinahColor.backgroundSecondary)
                            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                            .lineLimit(3...5)
                            .onSubmit {
                                vm.saveCheckIn(context: modelContext, requestReview: { requestReview() })
                                Task {
                                    await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
                                }
                            }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Partner mood
                if let partnerMood = vm.partnerMood {
                    partnerBanner(mood: partnerMood)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Update button
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
        .padding(.horizontal, SakinahSpacing.base)
        .animation(SakinahAnimation.gentle, value: vm.showCheckInNote)
        .animation(SakinahAnimation.gentle, value: vm.partnerMood)
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
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(SakinahColor.primaryLight)
                            .frame(width: 48, height: 48)
                    }
                    Text(mood.emoji)
                        .font(.system(size: 28))
                }
                .frame(width: 48, height: 48)

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
