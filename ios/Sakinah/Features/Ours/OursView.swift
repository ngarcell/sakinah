import SwiftUI
import SwiftData
import UIKit

struct OursView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var journalEntries: [JournalEntry]
    @Query(sort: \LoveLetter.deliveryDate, order: .reverse) private var letters: [LoveLetter]
    @Query(sort: \SharedGoal.createdAt, order: .reverse) private var goals: [SharedGoal]
    @Query(sort: \WishItem.createdAt, order: .reverse) private var wishes: [WishItem]
    @Query(sort: \Memory.date, order: .reverse) private var memories: [Memory]

    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                        Text("Private between you and \(appState.partnerName).")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                            .padding(.horizontal, SakinahSpacing.base)

                        if appState.hasLapsedAccess {
                            lapsedBanner
                        }

                        featureGrid
                        sharingNotice
                        memoriesSection
                        Spacer().frame(height: 32)
                    }
                    .padding(.top, SakinahSpacing.md)
                    .padding(.bottom, SakinahSpacing.jumbo)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var lapsedBanner: some View {
        UpgradePromptView(
            icon: "lock.shield.fill",
            headline: "Your shared space is still here",
            message: "Keep reading what you already saved, or unlock new writing, goals, wishes, and memories with an active plan."
        ) {
            appState.presentPaywall(for: .sharedSpace)
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    private var featureGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: SakinahSpacing.md),
                GridItem(.flexible(), spacing: SakinahSpacing.md)
            ],
            spacing: SakinahSpacing.md
        ) {
            featureCard(
                icon: "book.closed",
                title: "Shared Journal",
                subtitle: "\(filteredJournalEntries.count) entries",
                destination: SharedJournalView()
            )

            featureCard(
                icon: "envelope",
                title: "Love Letters",
                subtitle: unreadLetters > 0 ? "\(unreadLetters) unread" : "\(filteredLetters.count) letters",
                showUnreadDot: unreadLetters > 0,
                destination: LoveLettersView()
            )

            featureCard(
                icon: "target",
                title: "Shared Goals",
                subtitle: "\(activeGoals.count) active",
                destination: SharedGoalsView()
            )

            featureCard(
                icon: "gift",
                title: "Wishlists",
                subtitle: "\(filteredWishes.count) items",
                destination: WishlistsView()
            )
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    private func featureCard<Destination: View>(
        icon: String,
        title: String,
        subtitle: String,
        showUnreadDot: Bool = false,
        destination: Destination
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(SakinahColor.primary)
                    Spacer()
                    if showUnreadDot {
                        Circle()
                            .fill(SakinahColor.rose)
                            .frame(width: 9, height: 9)
                    }
                }

                VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                    Text(title)
                        .font(SakinahFont.title3)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
            }
            .padding(SakinahSpacing.base)
            .frame(maxWidth: .infinity, minHeight: 144, alignment: .leading)
            .background(SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(SakinahColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var sharingNotice: some View {
        HStack(alignment: .top, spacing: SakinahSpacing.sm) {
            Image(systemName: "lock.shield")
                .font(.system(size: 13))
            Text("Shared privately with \(appState.partnerName) via iCloud. Only you two can see this.")
                .font(SakinahFont.caption)
        }
        .foregroundStyle(SakinahColor.textTertiary)
        .padding(.horizontal, SakinahSpacing.base)
    }

    private var memoriesSection: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.md) {
            HStack {
                Text("MEMORIES")
                    .font(SakinahFont.captionBold)
                    .tracking(0.4)
                    .foregroundStyle(SakinahColor.textSecondary)
                Spacer()
                Text("\(filteredMemories.count)")
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
            }
            .padding(.horizontal, SakinahSpacing.base)

            if filteredMemories.isEmpty {
                SakinahCard {
                    Text("Recent memories will appear here after you add them from Us.")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
                .padding(.horizontal, SakinahSpacing.base)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: SakinahSpacing.sm), count: 3),
                    spacing: SakinahSpacing.sm
                ) {
                    ForEach(filteredMemories.prefix(9)) { memory in
                        memoryTile(memory)
                    }
                }
                .padding(.horizontal, SakinahSpacing.base)
            }
        }
    }

    private func memoryTile(_ memory: Memory) -> some View {
        ZStack {
            if let photoData = memory.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                SakinahColor.surfaceWarm
                Text(memory.caption)
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .lineLimit(4)
                    .padding(SakinahSpacing.sm)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: SakinahRadius.small))
    }

    private var coupleID: String {
        appState.currentCouple?.id ?? ""
    }

    private var currentUserID: String {
        appState.currentUser?.id ?? ""
    }

    private var filteredJournalEntries: [JournalEntry] {
        journalEntries.filter { $0.coupleID == coupleID && ($0.userID == currentUserID || $0.isShared) }
    }

    private var filteredLetters: [LoveLetter] {
        letters.filter { letter in
            letter.coupleID == coupleID && (
                letter.senderID == currentUserID ||
                (letter.senderID != currentUserID && letter.isDelivered)
            )
        }
    }

    private var unreadLetters: Int {
        filteredLetters.filter { $0.senderID != currentUserID && !$0.isRead }.count
    }

    private var activeGoals: [SharedGoal] {
        goals.filter { $0.coupleID == coupleID && !$0.isCompleted }
    }

    private var filteredWishes: [WishItem] {
        wishes.filter { $0.coupleID == coupleID }
    }

    private var filteredMemories: [Memory] {
        memories.filter { $0.coupleID == coupleID }
    }
}
