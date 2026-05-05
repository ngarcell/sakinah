import SwiftUI

struct OnboardingClarifyScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text("Help us shape the first week")
                            .font(SakinahFont.title1)
                            .foregroundStyle(SakinahColor.textPrimary)
                        Text("Two quick choices will make your first prompt and next steps feel more specific.")
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
                SakinahButton(title: "Build my first week") {
                    vm.advance(to: .firstValue, context: modelContext)
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

    private var header: some View {
        HStack {
            Button {
                vm.goBack(context: modelContext)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SakinahColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(SakinahColor.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            SakinahBadge(text: "Step 4 of 5", color: SakinahColor.accent, tintedBackground: SakinahColor.accentLight)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, SakinahSpacing.base)
        .padding(.horizontal, SakinahSpacing.base)
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
