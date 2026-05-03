import SwiftUI

struct OursView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: SakinahSpacing.xl) {
                        header
                        gridCards

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, SakinahSpacing.lg)
                }
                .scrollIndicators(.hidden)
            }
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
                Text("Private to your account and shared through iCloud only with the spouse you invite.")
                    .font(SakinahFont.caption)
            }
            .foregroundStyle(SakinahColor.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, SakinahSpacing.xl)
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
                destination: SharedJournalView()
            )

            oursNavCard(
                icon: "envelope.fill",
                title: "Letters",
                subtitle: "Send surprises",
                gradient: [SakinahColor.accent, SakinahColor.accentWarm],
                destination: LoveLettersView()
            )

            oursNavCard(
                icon: "target",
                title: "Goals",
                subtitle: "Build together",
                gradient: [SakinahColor.success, SakinahColor.success.opacity(0.7)],
                destination: SharedGoalsView()
            )

            oursNavCard(
                icon: "gift.fill",
                title: "Wishlists",
                subtitle: "Keep thoughtful notes",
                gradient: [SakinahColor.accentWarm, SakinahColor.accent],
                destination: WishlistsView()
            )
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    @ViewBuilder
    private func oursNavCard<Dest: View>(
        icon: String, title: String, subtitle: String, gradient: [Color], destination: Dest
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            cardContent(icon: icon, title: title, subtitle: subtitle, gradient: gradient)
        }
        .pressScale()
    }

    private func cardContent(icon: String, title: String, subtitle: String, gradient: [Color]) -> some View {
        VStack(spacing: SakinahSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SakinahSpacing.xl)
        .background(SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.large))
        .sakinahShadow(.subtle)
    }
}
