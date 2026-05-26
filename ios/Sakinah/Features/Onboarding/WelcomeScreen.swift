import SwiftUI
import SwiftData

struct WelcomeScreen: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var appeared = false
    @State private var taglineVisible = false
    @State private var ctaVisible = false
    #if DEBUG
    @State private var isLoadingDemo = false
    #endif

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            RadialGradient(
                colors: [SakinahColor.accent.opacity(0.1), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingProgressHeader(step: .welcome, showsBack: false)

                Spacer(minLength: 0)

                GeometricPattern()
                    .frame(height: 280)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .animation(.easeOut(duration: 1.8), value: appeared)

                Spacer(minLength: SakinahSpacing.lg)

                VStack(spacing: SakinahSpacing.lg) {
                    HStack(spacing: 2) {
                        Text("sakinah")
                            .font(.system(size: 44, weight: .bold, design: .serif))
                            .foregroundStyle(SakinahColor.textPrimary)
                        Circle()
                            .fill(SakinahColor.accent)
                            .frame(width: 8, height: 8)
                            .offset(y: 12)
                            .glow(color: SakinahColor.accent, radius: 12, opacity: 0.6)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    VStack(spacing: SakinahSpacing.xs) {
                        if vm.hasPendingShareInvitation {
                            SakinahBadge(
                                text: "Shared space waiting",
                                color: SakinahColor.accent,
                                tintedBackground: SakinahColor.accentLight
                            )
                        }

                        Text(vm.hasPendingShareInvitation ? "Your spouse already opened the shared space." : "You're in the right place.")
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .multilineTextAlignment(.center)

                        Text(vm.hasPendingShareInvitation ? "Finish your side, save one honest answer, and step back into the same private space together." : "Sakinah helps Muslim couples build a calmer private ritual around honest prompts, du'a, and everyday care.")
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .opacity(taglineVisible ? 1 : 0)
                    .offset(y: taglineVisible ? 0 : 10)
                }

                Spacer()

                VStack(spacing: SakinahSpacing.md) {
                    SakinahButton(title: vm.hasPendingShareInvitation ? "Continue My Setup" : "Begin") {
                        HapticEngine.shared.fire(.tap)
                        vm.advance(to: .outcome, context: modelContext)
                    }

                    #if DEBUG
                    SakinahButton(
                        title: "Skip - Load Demo",
                        icon: "photo.on.rectangle",
                        variant: .secondary,
                        isLoading: isLoadingDemo
                    ) {
                        isLoadingDemo = true
                        _ = DemoDataSeeder.load(context: modelContext, appState: appState)
                        isLoadingDemo = false
                    }
                    #endif

                    Text("You will save one meaningful answer before continuing.")
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
                .padding(.horizontal, SakinahSpacing.base)
                .padding(.bottom, SakinahSpacing.xl)
                .opacity(ctaVisible ? 1 : 0)
                .offset(y: ctaVisible ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.2)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.6)) {
                taglineVisible = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(1.0)) {
                ctaVisible = true
            }
        }
    }
}
