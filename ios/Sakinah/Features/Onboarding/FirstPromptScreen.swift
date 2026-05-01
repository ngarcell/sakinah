import SwiftUI

struct FirstPromptScreen: View {
    @Bindable var vm: OnboardingViewModel
    let onComplete: () -> Void
    @State private var appeared = false
    @State private var celebrating = false
    @FocusState private var focused: Bool

    @MainActor
    private var prompt: (id: String, text: String, category: PromptCategory) {
        ContentService.shared.firstPrompt(partnerName: vm.partnerName.isEmpty ? "your partner" : vm.partnerName)
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
                            Text("✨")
                                .font(.system(size: 44))
                                .scaleEffect(appeared ? 1 : 0.3)
                                .opacity(appeared ? 1 : 0)
                            Text("Start with this")
                                .font(SakinahFont.title2)
                                .foregroundStyle(SakinahColor.accent)
                                .multilineTextAlignment(.center)
                            Text("Answer one question now. The rhythm starts here.")
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
                    SakinahButton(title: "Save our first answer", icon: "checkmark.circle.fill") {
                        HapticEngine.shared.fire(.celebration)
                        withAnimation(SakinahAnimation.bounce) { celebrating = true }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(900))
                            onComplete()
                        }
                    }
                    .disabled(vm.firstResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(vm.firstResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)

                    Text("Next: choose a plan and keep this space going together.")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.base)
            }

            if celebrating {
                ConfettiBurst()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(SakinahAnimation.bounce.delay(0.1)) { appeared = true }
        }
    }
}

struct ConfettiBurst: View {
    @State private var particles: [Particle] = (0..<40).map { _ in Particle() }
    @State private var animate = false

    struct Particle: Identifiable {
        let id = UUID()
        let angle: Double = Double.random(in: 0..<360)
        let distance: CGFloat = CGFloat.random(in: 120...260)
        let size: CGFloat = CGFloat.random(in: 4...9)
        let delay: Double = Double.random(in: 0...0.15)
        let hue: Color = [SakinahColor.accent, SakinahColor.primary, Color(hex: 0xF4C77D)].randomElement()!
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.hue)
                    .frame(width: p.size, height: p.size)
                    .offset(
                        x: animate ? cos(p.angle * .pi / 180) * p.distance : 0,
                        y: animate ? sin(p.angle * .pi / 180) * p.distance : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(.easeOut(duration: 1.1).delay(p.delay), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}
