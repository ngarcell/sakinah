import SwiftUI
import SwiftData

struct OnboardingClarifyScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: .clarify) {
                vm.goBack(context: modelContext)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text("What needs care right now?")
                            .font(SakinahFont.title1)
                            .foregroundStyle(SakinahColor.textPrimary)
                        Text("These choices help Sakinah avoid generic advice and make the first prompt match what is actually hard.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("How urgent does this feel?")
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .tracking(0.1)
                            .textCase(.uppercase)

                        VStack(spacing: SakinahSpacing.sm) {
                            ForEach(RelationshipUrgency.allCases, id: \.self) { urgency in
                                selectionCard(
                                    title: urgency.label,
                                    isSelected: vm.relationshipUrgency == urgency
                                ) {
                                    vm.relationshipUrgency = urgency
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("What has been the harder part lately?")
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .tracking(0.1)
                            .textCase(.uppercase)

                        VStack(spacing: SakinahSpacing.sm) {
                            ForEach(RelationshipFriction.allCases, id: \.self) { friction in
                                selectionCard(
                                    title: friction.label,
                                    isSelected: vm.relationshipFriction == friction
                                ) {
                                    vm.relationshipFriction = friction
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            VStack(spacing: SakinahSpacing.sm) {
                SakinahButton(title: "Continue") {
                    vm.advance(to: .momentum, context: modelContext)
                }

                Button("Back") {
                    vm.goBack(context: modelContext)
                }
                .font(SakinahFont.captionBold)
                .foregroundStyle(SakinahColor.primary)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
        }
    }

    private func selectionCard(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.shared.fire(.select)
            action()
        } label: {
            HStack(spacing: SakinahSpacing.md) {
                Circle()
                    .fill(isSelected ? SakinahColor.accent : SakinahColor.primaryLight)
                    .frame(width: 12, height: 12)

                Text(title)
                    .font(SakinahFont.body)
                    .foregroundStyle(SakinahColor.textPrimary)

                Spacer()
            }
            .padding(SakinahSpacing.base)
            .background(isSelected ? SakinahColor.accentLight.opacity(0.7) : SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(isSelected ? SakinahColor.accent.opacity(0.4) : SakinahColor.divider.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
