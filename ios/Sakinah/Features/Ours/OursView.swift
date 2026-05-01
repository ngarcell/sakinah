import SwiftUI
import SwiftData

struct OursView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false

    private var isPremium: Bool { subscriptionService.isPremium }

    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: SakinahSpacing.xl) {
                        header
                        gridCards

                        // Upgrade prompt if not premium
                        if !isPremium {
                            UpgradePromptView(
                                icon: "lock.open.fill",
                                headline: "Keep more than today's prompt",
                                message: "Premium opens your shared journal, letters, goals, and wishlists in one place.",
                                ctaTitle: "Open shared space",
                                onUpgrade: { showPaywall = true }
                            )
                            .padding(.horizontal, SakinahSpacing.base)
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, SakinahSpacing.lg)
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(isPresented: $showPaywall) {
            SakinahPaywallView(entryPoint: .sharedSpace)
        }
    }

    private var header: some View {
        VStack(spacing: SakinahSpacing.sm) {
            Text("Ours")
                .font(SakinahFont.title1)
                .foregroundStyle(SakinahColor.textPrimary)

            HStack(spacing: SakinahSpacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                Text("End-to-end encrypted, just for you two")
                    .font(SakinahFont.caption)
            }
            .foregroundStyle(SakinahColor.textTertiary)
        }
    }

    private var gridCards: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: SakinahSpacing.md),
                GridItem(.flexible(), spacing: SakinahSpacing.md)
            ],
            spacing: SakinahSpacing.md
        ) {
            oursNavCard(
                icon: "book.fill",
                title: "Journal",
                subtitle: "Write together",
                gradient: [SakinahColor.primary, SakinahColor.primary.opacity(0.7)],
                destination: SharedJournalView(),
                requiresPremium: true
            )

            oursNavCard(
                icon: "envelope.fill",
                title: "Letters",
                subtitle: "Send surprises",
                gradient: [SakinahColor.accent, SakinahColor.accentWarm],
                destination: LoveLettersView(),
                requiresPremium: true
            )

            oursNavCard(
                icon: "target",
                title: "Goals",
                subtitle: "Build together",
                gradient: [SakinahColor.success, SakinahColor.success.opacity(0.7)],
                destination: SharedGoalsView(),
                requiresPremium: true
            )

            oursNavCard(
                icon: "gift.fill",
                title: "Wishlists",
                subtitle: "Drop hints",
                gradient: [Color(hex: 0x8B5CF6), Color(hex: 0xA78BFA)],
                destination: WishlistsView(),
                requiresPremium: true
            )
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    @ViewBuilder
    private func oursNavCard<Dest: View>(
        icon: String, title: String, subtitle: String,
        gradient: [Color], destination: Dest, requiresPremium: Bool
    ) -> some View {
        if requiresPremium && !isPremium {
            Button {
                HapticEngine.shared.fire(.tap)
                showPaywall = true
            } label: {
                cardContent(icon: icon, title: title, subtitle: subtitle, gradient: gradient, locked: true)
            }
            .pressScale()
        } else {
            NavigationLink {
                destination
            } label: {
                cardContent(icon: icon, title: title, subtitle: subtitle, gradient: gradient, locked: false)
            }
            .pressScale()
        }
    }

    private func cardContent(icon: String, title: String, subtitle: String, gradient: [Color], locked: Bool) -> some View {
        VStack(spacing: SakinahSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: locked ? "lock.fill" : icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)
                Text(subtitle)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textSecondary)
            }

            if locked {
                Text("Premium")
                    .font(SakinahFont.micro)
                    .foregroundStyle(SakinahColor.accent)
                    .padding(.horizontal, SakinahSpacing.sm)
                    .padding(.vertical, 2)
                    .background(SakinahColor.accentLight)
                    .clipShape(.capsule)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SakinahSpacing.xl)
        .background(SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.large))
        .sakinahShadow(.subtle)
        .opacity(locked ? 0.85 : 1)
    }
}
