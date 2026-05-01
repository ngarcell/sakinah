import SwiftUI
import SwiftData

struct WishlistsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WishItem.createdAt, order: .reverse) private var allWishes: [WishItem]
    @State private var newWishText = ""
    @State private var showAddField = false
    @State private var expandedWish: String? = nil

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()
            ScrollView {
                HStack(alignment: .top, spacing: SakinahSpacing.md) {
                    // My wishes
                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("My Wishes")
                            .font(SakinahFont.headline)
                            .foregroundStyle(SakinahColor.textPrimary)

                        if myWishes.isEmpty && !showAddField {
                            Text("Start with one little hint.")
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textTertiary)
                                .padding(.vertical, SakinahSpacing.xl)
                        }

                        ForEach(myWishes) { wish in
                            wishRow(wish, editable: true)
                        }

                        if showAddField {
                            HStack {
                                TextField("I wish for...", text: $newWishText)
                                    .font(SakinahFont.bodySmall)
                                    .submitLabel(.done)
                                    .onSubmit { addWish() }
                                Button {
                                    addWish()
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SakinahColor.primary)
                                }
                                .disabled(newWishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            .padding(SakinahSpacing.sm)
                            .background(SakinahColor.backgroundSecondary)
                            .clipShape(.rect(cornerRadius: SakinahRadius.small))
                        }

                        Button {
                            withAnimation(SakinahAnimation.spring) {
                                showAddField = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Add wish")
                                    .font(SakinahFont.captionBold)
                            }
                            .foregroundStyle(SakinahColor.primary)
                        }
                        .pressScale()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(SakinahColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, SakinahSpacing.md)

                    // Partner's wishes
                    VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                        Text("\(appState.partnerName)'s Wishes")
                            .font(SakinahFont.headline)
                            .foregroundStyle(SakinahColor.textPrimary)

                        if partnerWishes.isEmpty {
                            Text("\(appState.partnerName) hasn't dropped a hint yet.")
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textTertiary)
                                .padding(.vertical, SakinahSpacing.xl)
                        }

                        ForEach(partnerWishes) { wish in
                            wishRow(wish, editable: false)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(SakinahSpacing.base)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Wishlists")
        .navigationBarTitleDisplayMode(.large)
    }

    private var myWishes: [WishItem] {
        let uid = appState.currentUser?.id ?? ""
        let cid = appState.currentCouple?.id ?? ""
        return allWishes.filter { $0.coupleID == cid && $0.userID == uid }
    }

    private var partnerWishes: [WishItem] {
        let uid = appState.currentUser?.id ?? ""
        let cid = appState.currentCouple?.id ?? ""
        return allWishes.filter { $0.coupleID == cid && $0.userID != uid }
    }

    private func wishRow(_ wish: WishItem, editable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(wish.text)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textPrimary)
                .lineLimit(expandedWish == wish.id ? nil : 1)
                .onTapGesture {
                    withAnimation(SakinahAnimation.spring) {
                        expandedWish = expandedWish == wish.id ? nil : wish.id
                    }
                }

            if expandedWish == wish.id {
                if let note = wish.note, !note.isEmpty {
                    Text(note)
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
                if let link = wish.link, let url = URL(string: link) {
                    Link(destination: url) {
                        Text(link)
                            .font(SakinahFont.caption)
                            .foregroundStyle(SakinahColor.primary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(SakinahSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SakinahColor.backgroundSecondary.opacity(0.5))
        .clipShape(.rect(cornerRadius: SakinahRadius.small))
        .swipeActions(edge: .trailing) {
            if editable {
                Button(role: .destructive) {
                    modelContext.delete(wish)
                    try? modelContext.save()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func addWish() {
        let trimmed = newWishText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let wish = WishItem(
            coupleID: appState.currentCouple?.id ?? "",
            userID: appState.currentUser?.id ?? "",
            text: trimmed
        )
        modelContext.insert(wish)
        try? modelContext.save()
        HapticEngine.shared.fire(.tap)
        newWishText = ""
        showAddField = false
    }
}
