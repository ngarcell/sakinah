import SwiftUI
import SwiftData

struct CoupleSetupScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressHeader(step: .setup) {
                vm.goBack(context: modelContext)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text("Make this feel like your marriage")
                            .font(SakinahFont.title1)
                            .foregroundStyle(SakinahColor.textPrimary)
                        Text("Only the details that help Sakinah sound like your real shared space. Skip anything that is not useful right now.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                    }

                    SakinahTextField(label: "Your name", placeholder: "e.g. Yusuf", text: $vm.yourName)
                    SakinahTextField(label: "Spouse's name", placeholder: "e.g. Aisha", text: $vm.partnerName)

                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("Relationship date")
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .tracking(0.1)
                            .textCase(.uppercase)

                        Text("Add it if you want Sakinah to reflect your real timeline. Skip it if you would rather not.")
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.textTertiary)

                        Toggle("Use an anniversary or special date", isOn: $vm.hasAnniversary)
                            .tint(SakinahColor.primary)

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
                        Text("Du'a language")
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

            VStack(spacing: SakinahSpacing.sm) {
                SakinahButton(title: "Preview our first week") {
                    vm.advance(to: .planPreview, context: modelContext)
                }
                .disabled(!vm.canContinueFromSetup)
                .opacity(vm.canContinueFromSetup ? 1 : 0.55)

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
