import SwiftUI
import StoreKit

struct SakinahPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanOption = .annual
    @State private var isPurchasing = false
    @State private var showCelebration = false
    @State private var appeared = false

    enum PlanOption: String, CaseIterable {
        case monthly, annual, lifetime

        var productID: String {
            switch self {
            case .monthly: return SubscriptionService.monthlyID
            case .annual: return SubscriptionService.annualID
            case .lifetime: return SubscriptionService.lifetimeID
            }
        }

        var title: String {
            switch self {
            case .monthly: return "Monthly"
            case .annual: return "Annual"
            case .lifetime: return "Lifetime"
            }
        }

        var price: String {
            switch self {
            case .monthly: return "$9.99/mo"
            case .annual: return "$49.99/yr"
            case .lifetime: return "$129.99"
            }
        }

        var subtitle: String {
            switch self {
            case .monthly: return "Flexible, cancel anytime"
            case .annual: return "Save 58% \u{2014} $4.17/mo"
            case .lifetime: return "Pay once, yours forever"
            }
        }

        var buttonTitle: String {
            switch self {
            case .monthly: return "Subscribe"
            case .annual: return "Start 7-Day Free Trial"
            case .lifetime: return "Purchase"
            }
        }

        var buttonSubtitle: String? {
            switch self {
            case .annual: return "Then $49.99/year. Cancel anytime."
            default: return nil
            }
        }
    }

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: SakinahSpacing.xxl) {
                    // Close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(SakinahColor.textTertiary)
                        }
                    }
                    .padding(.horizontal, SakinahSpacing.base)
                    .padding(.top, SakinahSpacing.sm)

                    // Hero
                    VStack(spacing: SakinahSpacing.md) {
                        Text("Grow deeper,\ntogether")
                            .font(SakinahFont.display)
                            .foregroundStyle(SakinahColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        Text("Premium unlocks the tools that turn\ndaily check-ins into lasting growth.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .opacity(appeared ? 1 : 0)
                    }

                    // Garden illustration
                    gardenIllustration
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.95)

                    // Outcomes, not features
                    outcomesList
                        .opacity(appeared ? 1 : 0)

                    // Plan cards
                    VStack(spacing: SakinahSpacing.md) {
                        ForEach(PlanOption.allCases, id: \.self) { plan in
                            planCard(plan)
                        }
                    }
                    .padding(.horizontal, SakinahSpacing.base)

                    // Purchase CTA
                    VStack(spacing: SakinahSpacing.xs) {
                        SakinahButton(title: selectedPlan.buttonTitle, isLoading: isPurchasing) {
                            purchase()
                        }
                        .padding(.horizontal, SakinahSpacing.base)

                        if let subtitle = selectedPlan.buttonSubtitle {
                            Text(subtitle)
                                .font(SakinahFont.caption)
                                .foregroundStyle(SakinahColor.textTertiary)
                        }
                    }

                    // Footer
                    HStack(spacing: SakinahSpacing.lg) {
                        Button("Restore Purchases") {
                            Task { await SubscriptionService.shared.restorePurchases() }
                        }
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)

                        Link("Terms", destination: URL(string: "https://socialreporthq.com/sakinah/terms")!)
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.textTertiary)

                        Link("Privacy", destination: URL(string: "https://socialreporthq.com/sakinah/privacy")!)
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.textTertiary)
                    }
                    .padding(.bottom, SakinahSpacing.xl)
                }
            }
            .scrollIndicators(.hidden)

            if showCelebration {
                celebrationOverlay
                    .transition(.opacity)
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.15)) {
                appeared = true
            }
        }
    }

    // MARK: - Outcomes (not features)

    private var outcomesList: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.lg) {
            outcomeRow(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Conversations that matter",
                detail: "100+ themed prompts that go beyond surface-level"
            )
            outcomeRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "See your growth over time",
                detail: "Track how your relationship evolves week by week"
            )
            outcomeRow(
                icon: "envelope.fill",
                title: "Surprise each other",
                detail: "Write love letters now, deliver them when it matters"
            )
            outcomeRow(
                icon: "target",
                title: "Build together",
                detail: "Shared goals, wishlists, and a private journal"
            )
        }
        .padding(.horizontal, SakinahSpacing.xl)
    }

    private func outcomeRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: SakinahSpacing.md) {
            ZStack {
                Circle()
                    .fill(SakinahColor.primaryLight)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SakinahColor.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)
                Text(detail)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    private var gardenIllustration: some View {
        ZStack {
            SakinahColor.primaryLight
            Canvas { context, size in
                let groundY = size.height * 0.7
                let groundRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
                context.fill(Rectangle().path(in: groundRect), with: .color(SakinahColor.primaryLight))
                let spacing = size.width / 6
                for i in 0..<5 {
                    let x = spacing * CGFloat(i + 1)
                    GardenPlantRenderer.drawPlant(
                        in: context, dimension: GardenDimension.allCases[i],
                        level: 5, at: CGPoint(x: x, y: 0),
                        groundY: groundY, time: 0, swayPhase: 1.0, breezeActive: false
                    )
                }
            }
        }
        .frame(height: 140)
        .clipShape(.rect(cornerRadius: SakinahRadius.large))
        .padding(.horizontal, SakinahSpacing.base)
    }

    private func planCard(_ plan: PlanOption) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            HapticEngine.shared.fire(.select)
            withAnimation(SakinahAnimation.bounce) { selectedPlan = plan }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                    Text(plan.subtitle)
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
                Spacer()
                Text(plan.price)
                    .font(SakinahFont.title3)
                    .foregroundStyle(SakinahColor.textPrimary)
            }
            .padding(SakinahSpacing.base)
            .background(isSelected ? SakinahColor.accentLight : SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(isSelected ? SakinahColor.accent : SakinahColor.divider, lineWidth: isSelected ? 2.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if plan == .annual {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [SakinahColor.accent, SakinahColor.accentWarm],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(.capsule)
                        .offset(x: -8, y: -10)
                }
            }
        }
        .pressScale()
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: SakinahSpacing.lg) {
                ParticleSystem(isActive: true, color: SakinahColor.accent, particleCount: 20)
                    .frame(width: 200, height: 200)
                Text("Welcome to Premium \u{2728}")
                    .font(SakinahFont.title1)
                    .foregroundStyle(.white)
                Text("Your garden is ready to bloom.")
                    .font(SakinahFont.body)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private func purchase() {
        isPurchasing = true
        Task { @MainActor in
            defer { isPurchasing = false }
            do {
                if try await SubscriptionService.shared.purchase(productID: selectedPlan.productID) {
                    HapticEngine.shared.fire(.celebration)
                    withAnimation { showCelebration = true }
                    try? await Task.sleep(for: .seconds(2))
                    dismiss()
                }
            } catch {
                // StoreKit handles its own error UI
            }
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
}
