import SwiftUI
import SwiftData

struct QuickCheckInCard: View {
    @Bindable var vm: TodayViewModel
    @Environment(\.modelContext) private var modelContext

    private let moods: [Mood] = [.great, .good, .okay, .low, .tough]

    var body: some View {
        SakinahCard {
            VStack(spacing: SakinahSpacing.base) {
                Text("How are you today?")
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)

                // Mood options
                HStack(spacing: 0) {
                    ForEach(moods, id: \.self) { mood in
                        moodButton(mood)
                    }
                }

                // Optional note field
                if vm.showCheckInNote {
                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("Anything you'd like to share?")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)

                        TextField("Write a note (optional)...", text: $vm.checkInNote, axis: .vertical)
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textPrimary)
                            .padding(SakinahSpacing.md)
                            .background(SakinahColor.backgroundSecondary)
                            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                            .lineLimit(3...5)
                            .onSubmit {
                                vm.saveCheckIn(context: modelContext)
                            }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Partner mood
                if let partnerMood = vm.partnerMood {
                    partnerBanner(mood: partnerMood)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Update button if already checked in
                if vm.hasCheckedInToday && !vm.isUpdatingCheckIn {
                    Button {
                        vm.toggleUpdateCheckIn()
                    } label: {
                        Text("Update")
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
            Text("\(vm.partnerName) is feeling \(mood.label.lowercased()) today")
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textSecondary)
            Spacer()
            if vm.partnerNote != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SakinahColor.textTertiary)
            }
        }
        .padding(SakinahSpacing.md)
        .background(SakinahColor.backgroundSecondary)
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
    }
}
