import SwiftUI

struct OnboardingContextScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text("Why did you install Sakinah now?")
                            .font(SakinahFont.title1)
                            .foregroundStyle(SakinahColor.textPrimary)
                        Text("Choose the context that will make the first week feel relevant from the start.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("Relationship stage")
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .tracking(0.1)
                            .textCase(.uppercase)

                        HStack(spacing: SakinahSpacing.sm) {
                            ForEach(RelationshipStage.allCases, id: \.self) { stage in
                                stageChip(stage)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("Primary focus")
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .tracking(0.1)
                            .textCase(.uppercase)

                        VStack(spacing: SakinahSpacing.sm) {
                            ForEach(RelationshipFocus.allCases, id: \.self) { focus in
                                focusCard(focus)
                            }
                        }
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            VStack(spacing: SakinahSpacing.sm) {
                SakinahButton(title: "Continue") {
                    vm.advance(to: .setup, context: modelContext)
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
            SakinahBadge(text: "Step 2 of 5", color: SakinahColor.accent, tintedBackground: SakinahColor.accentLight)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.top, SakinahSpacing.base)
        .padding(.horizontal, SakinahSpacing.base)
    }

    private func stageChip(_ stage: RelationshipStage) -> some View {
        let selected = vm.relationshipStage == stage

        return Button {
            HapticEngine.shared.fire(.select)
            vm.relationshipStage = stage
        } label: {
            Text(stage.label)
                .font(SakinahFont.captionBold)
                .foregroundStyle(selected ? .white : SakinahColor.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SakinahSpacing.md)
                .background(selected ? SakinahColor.primary : SakinahColor.backgroundSecondary)
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
        }
        .pressScale()
    }

    private func focusCard(_ focus: RelationshipFocus) -> some View {
        let selected = vm.relationshipFocus == focus

        return Button {
            HapticEngine.shared.fire(.select)
            vm.relationshipFocus = focus
        } label: {
            HStack(alignment: .top, spacing: SakinahSpacing.md) {
                Circle()
                    .fill(selected ? SakinahColor.accent : SakinahColor.primaryLight)
                    .frame(width: 12, height: 12)
                    .padding(.top, 6)

                Text(focus.label)
                    .font(SakinahFont.body)
                    .foregroundStyle(SakinahColor.textPrimary)

                Spacer()
            }
            .padding(SakinahSpacing.base)
            .background(selected ? SakinahColor.accentLight.opacity(0.7) : SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(selected ? SakinahColor.accent.opacity(0.4) : SakinahColor.divider.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
