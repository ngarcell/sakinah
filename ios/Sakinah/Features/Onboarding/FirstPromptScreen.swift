import SwiftUI

struct FirstPromptScreen: View {
    @Bindable var vm: OnboardingViewModel
    let onComplete: () -> Void
    @State private var appeared = false
    @FocusState private var focused: Bool

    @MainActor
    private var prompt: (id: String, text: String, category: PromptCategory) {
        ContentService.shared.firstPrompt(partnerName: vm.partnerName.isEmpty ? "your spouse" : vm.partnerName)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SakinahColor.background, SakinahColor.accentLight.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        HapticEngine.shared.fire(.tap)
                        vm.advance(to: .coupleSetup)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SakinahColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(SakinahColor.surface)
                            .clipShape(Circle())
                            .sakinahShadow(.subtle)
                    }
                    .pressScale()
                    Spacer()
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.top, SakinahSpacing.sm)

                ScrollView {
                    VStack(spacing: SakinahSpacing.xl) {
                        VStack(spacing: SakinahSpacing.sm) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 34, weight: .regular))
                                .foregroundStyle(SakinahColor.accent)
                                .scaleEffect(appeared ? 1 : 0.85)
                                .opacity(appeared ? 1 : 0)
                            Text("Begin with something real")
                                .font(SakinahFont.title2)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("Write one honest answer now. We’ll save it first, then unlock the full experience.")
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, SakinahSpacing.lg)

                        SakinahCard(elevated: true) {
                            VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                                SakinahBadge(
                                    text: prompt.category.label,
                                    icon: prompt.category.icon,
                                    color: SakinahColor.accent,
                                    tintedBackground: SakinahColor.accentLight
                                )
                                Text(prompt.text)
                                    .font(SakinahFont.title3)
                                    .foregroundStyle(SakinahColor.textPrimary)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)

                                ZStack(alignment: .topLeading) {
                                    if vm.firstResponse.isEmpty {
                                        Text("Write the answer you want to bring into your next conversation.")
                                            .font(SakinahFont.body)
                                            .foregroundStyle(SakinahColor.textTertiary)
                                            .padding(.horizontal, SakinahSpacing.sm)
                                            .padding(.top, SakinahSpacing.sm)
                                    }
                                    TextEditor(text: $vm.firstResponse)
                                        .font(SakinahFont.body)
                                        .foregroundStyle(SakinahColor.textPrimary)
                                        .scrollContentBackground(.hidden)
                                        .frame(minHeight: 120)
                                        .focused($focused)
                                }
                                .padding(SakinahSpacing.sm)
                                .background(SakinahColor.backgroundSecondary)
                                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                            }
                        }
                        .padding(.horizontal, SakinahSpacing.base)
                    }
                    .padding(.bottom, SakinahSpacing.xl)
                }

                VStack(spacing: SakinahSpacing.xs) {
                    SakinahButton(title: "Save my first answer", icon: "checkmark.circle.fill") {
                        HapticEngine.shared.fire(.success)
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(250))
                            onComplete()
                        }
                    }
                    .disabled(vm.firstResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(vm.firstResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)

                    Text("Next: a short handoff, then the hosted plan screen.")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.base)
            }
        }
        .onAppear {
            withAnimation(SakinahAnimation.bounce.delay(0.1)) { appeared = true }
        }
    }
}
