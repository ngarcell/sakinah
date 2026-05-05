import SwiftUI
import SwiftData

struct SharedJournalView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showCompose = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SakinahColor.background.ignoresSafeArea()

            if filteredEntries.isEmpty {
                SakinahEmptyState(
                    icon: "book.closed",
                    title: "Your shared journal",
                    message: "Keep gratitude, honesty, and ordinary moments in one place that feels like the two of you.",
                    actionTitle: appState.hasPremiumAccess ? "Write Entry" : "Unlock Journal",
                    action: {
                        if appState.hasPremiumAccess {
                            showCompose = true
                        } else {
                            appState.presentPaywall(for: .sharedSpace)
                        }
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: SakinahSpacing.md) {
                        ForEach(filteredEntries) { entry in
                            journalCard(entry)
                        }
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, SakinahSpacing.base)
                    .padding(.top, SakinahSpacing.md)
                }
                .scrollIndicators(.hidden)
            }

            // FAB
            Button {
                HapticEngine.shared.fire(.tap)
                if appState.hasPremiumAccess {
                    showCompose = true
                } else {
                    appState.presentPaywall(for: .sharedSpace)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(colors: [SakinahColor.primary, SakinahColor.primary.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .sakinahShadow(.medium)
            }
            .pressScale()
            .padding(.trailing, SakinahSpacing.lg)
            .padding(.bottom, SakinahSpacing.lg)
        }
        .navigationTitle("Shared Journal")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCompose) {
            ComposeJournalSheet()
                .presentationDetents([.large])
        }
    }

    private var filteredEntries: [JournalEntry] {
        let uid = appState.currentUser?.id ?? ""
        let cid = appState.currentCouple?.id ?? ""
        return entries.filter { $0.coupleID == cid && ($0.userID == uid || $0.isShared) }
    }

    private func journalCard(_ entry: JournalEntry) -> some View {
        let isPartner = entry.userID != appState.currentUser?.id
        return VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isPartner ? SakinahColor.accentLight : SakinahColor.primaryLight)
                        .frame(width: 24, height: 24)
                    Text(String(entry.authorName.prefix(1)).uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isPartner ? SakinahColor.accent : SakinahColor.primary)
                }
                Text(entry.authorName)
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.textSecondary)
                Spacer()
                Text(DateFormatting.timeAgo(entry.createdAt))
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
            }

            Text(entry.content)
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textPrimary)
                .lineLimit(6)

            HStack {
                Image(systemName: entry.isShared ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 11))
                Text(entry.isShared ? "Shared" : "Private")
                    .font(SakinahFont.caption)
            }
            .foregroundStyle(SakinahColor.textTertiary)
        }
        .padding(SakinahSpacing.base)
        .background(isPartner ? SakinahColor.accentLight.opacity(0.3) : SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
        .sakinahShadow(.subtle)
    }
}

struct ComposeJournalSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var isShared = true

    var body: some View {
        NavigationStack {
            Group {
                if appState.hasPremiumAccess {
                    VStack(spacing: SakinahSpacing.lg) {
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("What's on your heart today?")
                                    .font(SakinahFont.body)
                                    .foregroundStyle(SakinahColor.textTertiary)
                                    .padding(.horizontal, SakinahSpacing.md)
                                    .padding(.vertical, SakinahSpacing.md)
                            }
                            TextEditor(text: $content)
                                .font(SakinahFont.body)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, SakinahSpacing.sm)
                                .padding(.vertical, SakinahSpacing.sm)
                        }
                        .frame(minHeight: 200)
                        .background(SakinahColor.backgroundSecondary)
                        .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                        Toggle(isOn: $isShared) {
                            Text("Share with \(appState.partnerName)")
                                .font(SakinahFont.body)
                                .foregroundStyle(SakinahColor.textPrimary)
                        }
                        .tint(SakinahColor.primary)

                        Spacer()

                        SakinahButton(title: "Save") {
                            save()
                        }
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                    }
                } else {
                    UpgradePromptView(
                        icon: "book.closed.fill",
                        headline: "Keep writing in your journal",
                        message: "Your saved entries remain here. Unlock new writing and sharing with an active plan."
                    ) {
                        appState.presentPaywall(for: .sharedSpace)
                        dismiss()
                    }
                }
            }
            .padding(SakinahSpacing.base)
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SakinahColor.primary)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
        }
    }

    private func save() {
        guard appState.hasPremiumAccess else {
            appState.presentPaywall(for: .sharedSpace)
            dismiss()
            return
        }
        let entry = JournalEntry(
            coupleID: appState.currentCouple?.id ?? "",
            userID: appState.currentUser?.id ?? "",
            authorName: appState.userName,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            isShared: isShared
        )
        modelContext.insert(entry)
        try? modelContext.save()
        HapticEngine.shared.fire(.success)

        Task {
            await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
        }
        dismiss()
    }
}
