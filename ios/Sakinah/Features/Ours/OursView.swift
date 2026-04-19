import SwiftUI
import SwiftData

struct OursView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

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
        VStack(spacing: SakinahSpacing.xs) {
            Text("Ours 🔒")
                .font(SakinahFont.title1)
                .foregroundStyle(SakinahColor.textPrimary)
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                Text("Your private space, encrypted end-to-end")
                    .font(SakinahFont.caption)
            }
            .foregroundStyle(SakinahColor.textTertiary)
        }
    }

    private var gridCards: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: SakinahSpacing.md), GridItem(.flexible(), spacing: SakinahSpacing.md)], spacing: SakinahSpacing.md) {
            NavigationLink {
                SharedJournalView()
            } label: {
                oursCard(icon: "book.fill", title: "Shared Journal", subtitle: "Write together")
            }
            NavigationLink {
                LoveLettersView()
            } label: {
                oursCard(icon: "envelope.fill", title: "Love Letters", subtitle: "Send future surprises")
            }
            NavigationLink {
                SharedGoalsView()
            } label: {
                oursCard(icon: "target", title: "Shared Goals", subtitle: "Track progress")
            }
            NavigationLink {
                WishlistsView()
            } label: {
                oursCard(icon: "gift.fill", title: "Wishlists", subtitle: "Hint, hint... 😉")
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    private func oursCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: SakinahSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(SakinahColor.primary)
            Text(title)
                .font(SakinahFont.headline)
                .foregroundStyle(SakinahColor.textPrimary)
            Text(subtitle)
                .font(SakinahFont.caption)
                .foregroundStyle(SakinahColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SakinahSpacing.xl)
        .background(SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.large))
        .sakinahShadow(.subtle)
    }
}
