import SwiftUI
import StoreKit

struct SakinahPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PlanOption = .annual
    @State private var isPurchasing = false
    @State private var showCelebration = false

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
            case .monthly: return "Flexible"
            case .annual: return "Best Value — Save 58%"
            case .lifetime: return "Pay once, forever"
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
                VStack(spacing: SakinahSpacing.xl) {
                    // Title
                    Text("Unlock Sakinah Premium ✨")
                        .font(SakinahFont.title1)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, SakinahSpacing.xl)

                    // Garden illustration
                    gardenIllustration

                    // Benefits
                    benefitsList

                    // Plan selection
                    VStack(spacing: SakinahSpacing.md) {
                        ForEach(PlanOption.allCases, id: \.self) { plan in
                            planCard(plan)
                        }
                    }
                    .padding(.horizontal, SakinahSpacing.base)

                    // Purchase button
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

                    // Footer links
                    HStack(spacing: SakinahSpacing.lg) {
                        Button("Restore Purchases") {
                            Task { await SubscriptionService.shared.restorePurchases() }
                        }
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)

                        Text("Terms • Privacy")
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
    }

    private var gardenIllustration: some View {
        ZStack {
            SakinahColor.primaryLight
            // Simplified garden at full bloom
            Canvas { context, size in
                let groundY = size.height * 0.7
                let groundRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
                context.fill(Rectangle().path(in: groundRect), with: .color(SakinahColor.primaryLight))

                // Draw 5 simplified blooming plants
                let spacing = size.width / 6
                for i in 0..<5 {
                    let x = spacing * CGFloat(i + 1)
                    GardenPlantRenderer.drawPlant(
                        in: context,
                        dimension: GardenDimension.allCases[i],
                        level: 5,
                        at: CGPoint(x: x, y: 0),
                        groundY: groundY,
                        time: 0,
                        swayPhase: 1.0,
                        breezeActive: false
                    )
                }
            }
        }
        .frame(height: 160)
        .clipShape(.rect(cornerRadius: SakinahRadius.large))
        .padding(.horizontal, SakinahSpacing.base)
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.md) {
            benefitRow("Deeper conversations with themed prompt packs")
            benefitRow("Relationship trend insights over time")
            benefitRow("Scheduled love letters & shared goals")
            benefitRow("Early access to new features")
        }
        .padding(.horizontal, SakinahSpacing.xl)
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: SakinahSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(SakinahColor.accent)
                .font(.system(size: 20))
            Text(text)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textPrimary)
        }
    }

    private func planCard(_ plan: PlanOption) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            HapticEngine.shared.fire(.select)
            withAnimation(SakinahAnimation.bounce) {
                selectedPlan = plan
            }
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
                    .stroke(isSelected ? SakinahColor.accent : SakinahColor.divider, lineWidth: isSelected ? 3 : 1)
            )
            .if(isSelected) { view in
                view.glow(color: SakinahColor.accent, radius: 12, opacity: 0.2)
            }
            .overlay(alignment: .topTrailing) {
                if plan == .annual {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SakinahColor.accent)
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
                Text("Welcome to Premium ✨")
                    .font(SakinahFont.title1)
                    .foregroundStyle(.white)
            }
        }
    }

    private func purchase() {
        isPurchasing = true
        Task { @MainActor in
            defer { isPurchasing = false }
            guard let product = SubscriptionService.shared.availableProducts.first(where: { $0.id == selectedPlan.productID }) else {
                return
            }
            do {
                if let _ = try await SubscriptionService.shared.purchase(product) {
                    HapticEngine.shared.fire(.celebration)
                    withAnimation { showCelebration = true }
                    try? await Task.sleep(for: .seconds(2))
                    dismiss()
                }
            } catch {
                // StoreKit handles its own error UI; dismiss loading state silently
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
