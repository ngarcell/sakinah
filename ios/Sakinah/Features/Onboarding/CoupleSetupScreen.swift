import SwiftUI

struct CoupleSetupScreen: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text("Tell us about you two")
                            .font(SakinahFont.title1)
                            .foregroundStyle(SakinahColor.textPrimary)
                        Text("A few details help us personalize your journey.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                    }

                    SakinahTextField(label: "Your name", placeholder: "e.g. Yusuf", text: $vm.yourName)
                    SakinahTextField(label: "Partner's name", placeholder: "e.g. Aisha", text: $vm.partnerName)

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("Relationship Stage")
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
                        HStack {
                            Text("Anniversary / Special Date")
                                .font(SakinahFont.captionBold)
                                .foregroundStyle(SakinahColor.textSecondary)
                                .tracking(0.1)
                                .textCase(.uppercase)
                            Spacer()
                            Toggle("", isOn: $vm.hasAnniversary)
                                .labelsHidden()
                                .tint(SakinahColor.primary)
                        }

                        if vm.hasAnniversary {
                            VStack(spacing: SakinahSpacing.sm) {
                                DatePicker("", selection: $vm.anniversaryDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(SakinahColor.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack {
                                    Text("Use Hijri calendar")
                                        .font(SakinahFont.bodySmall)
                                        .foregroundStyle(SakinahColor.textPrimary)
                                    Spacer()
                                    Toggle("", isOn: $vm.useHijri)
                                        .labelsHidden()
                                        .tint(SakinahColor.primary)
                                }
                                if vm.useHijri {
                                    Text(DateFormatting.hijri(vm.anniversaryDate))
                                        .font(SakinahFont.caption)
                                        .foregroundStyle(SakinahColor.accent)
                                }
                            }
                            .padding(SakinahSpacing.base)
                            .background(SakinahColor.backgroundSecondary)
                            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(SakinahAnimation.spring, value: vm.hasAnniversary)
                    .animation(SakinahAnimation.spring, value: vm.useHijri)

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("Du'a language preference")
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .tracking(0.1)
                            .textCase(.uppercase)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: SakinahSpacing.sm) {
                                ForEach(DuaLanguage.allCases, id: \.self) { lang in
                                    langChip(lang)
                                }
                            }
                        }
                        .contentMargins(.horizontal, 0, for: .scrollContent)
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.xl)
            }

            SakinahButton(title: "Continue") {
                vm.advance(to: .firstPrompt)
            }
            .padding(.horizontal, SakinahSpacing.base)
            .padding(.bottom, SakinahSpacing.base)
            .disabled(vm.yourName.isEmpty || vm.partnerName.isEmpty)
            .opacity(vm.yourName.isEmpty || vm.partnerName.isEmpty ? 0.55 : 1)
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            SakinahBadge(text: "Step 4 of 5", color: SakinahColor.accent, tintedBackground: SakinahColor.accentLight)
            Spacer()
        }
        .padding(.top, SakinahSpacing.base)
    }

    private func stageChip(_ stage: RelationshipStage) -> some View {
        let selected = vm.relationshipStage == stage
        return Button {
            HapticEngine.shared.fire(.select)
            vm.relationshipStage = stage
        } label: {
            VStack(spacing: 6) {
                Text(stage.emoji).font(.system(size: 22))
                Text(stage.label)
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(selected ? .white : SakinahColor.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SakinahSpacing.md)
            .background(selected ? SakinahColor.primary : SakinahColor.backgroundSecondary)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(selected ? SakinahColor.primary : Color.clear, lineWidth: 2)
            )
        }
        .pressScale()
        .animation(SakinahAnimation.spring, value: selected)
    }

    private func langChip(_ lang: DuaLanguage) -> some View {
        let selected = vm.duaLanguage == lang
        return Button {
            HapticEngine.shared.fire(.select)
            vm.duaLanguage = lang
        } label: {
            Text(lang.label)
                .font(SakinahFont.captionBold)
                .foregroundStyle(selected ? .white : SakinahColor.textPrimary)
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.vertical, SakinahSpacing.md)
                .background(selected ? SakinahColor.primary : SakinahColor.backgroundSecondary)
                .clipShape(.capsule)
        }
        .pressScale()
        .animation(SakinahAnimation.spring, value: selected)
    }
}
