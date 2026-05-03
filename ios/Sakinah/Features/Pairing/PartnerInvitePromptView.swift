import SwiftUI
import SwiftData
import UIKit

struct PartnerInvitePromptView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var isPreparingInvite = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                        hero
                        detailCard
                        inviteCard
                    }
                    .padding(SakinahSpacing.base)
                }
            }
            .navigationTitle("Invite Your Spouse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not now") {
                        appState.showPartnerInvitePrompt = false
                        dismiss()
                    }
                    .foregroundStyle(SakinahColor.primary)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareURL {
                    PartnerInviteShareSheet(
                        items: [
                            "I set up our private space in Sakinah. Join me here:",
                            shareURL
                        ]
                    )
                }
            }
            .alert("Invite Unavailable", isPresented: errorBinding) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.md) {
            Text("Bring your spouse into the same space when you're ready.")
                .font(SakinahFont.title1)
                .foregroundStyle(SakinahColor.textPrimary)

            Text("Sakinah keeps your daily prompt history, shared journal, letters, goals, and reflections together in one private place.")
                .font(SakinahFont.body)
                .foregroundStyle(SakinahColor.textSecondary)
        }
        .padding(.top, SakinahSpacing.sm)
    }

    private var detailCard: some View {
        SakinahCard(elevated: true) {
            VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                row(icon: "bubble.left.and.bubble.right.fill", title: "Daily prompts stay in sync")
                row(icon: "book.closed.fill", title: "Shared journal and letters feel personal, not cluttered")
                row(icon: "checklist", title: "Goals, memories, and reflections live in one calm timeline")
            }
        }
    }

    private var inviteCard: some View {
        SakinahCard {
            VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                Text("Shared access")
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)

                Text("Create a private invitation link and send it through Messages, WhatsApp, or wherever you already talk.")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)

                if let shareURL {
                    Text(shareURL.absoluteString)
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)
                        .textSelection(.enabled)

                    HStack(spacing: SakinahSpacing.sm) {
                        SakinahButton(title: "Share Link", icon: "square.and.arrow.up", isFullWidth: false) {
                            showShareSheet = true
                        }

                        SakinahButton(title: "Copy", icon: "doc.on.doc", variant: .secondary, isFullWidth: false) {
                            UIPasteboard.general.url = shareURL
                            HapticEngine.shared.fire(.success)
                        }
                    }
                } else {
                    SakinahButton(
                        title: isPreparingInvite ? "Preparing..." : "Create Invite Link",
                        icon: "link",
                        isFullWidth: false
                    ) {
                        createInvite()
                    }
                    .disabled(isPreparingInvite)
                }
            }
        }
    }

    private func row(icon: String, title: String) -> some View {
        HStack(spacing: SakinahSpacing.md) {
            ZStack {
                Circle()
                    .fill(SakinahColor.primaryLight)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SakinahColor.primary)
            }

            Text(title)
                .font(SakinahFont.bodySmall)
                .foregroundStyle(SakinahColor.textPrimary)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { newValue in
                if !newValue {
                    errorMessage = nil
                }
            }
        )
    }

    private func createInvite() {
        guard !isPreparingInvite else { return }
        isPreparingInvite = true

        Task {
            defer { isPreparingInvite = false }

            do {
                let url = try await CloudKitService.shared.createShareURL(
                    appState: appState,
                    context: modelContext
                )
                shareURL = url
                appState.markInviteCreated()
                HapticEngine.shared.fire(.success)
            } catch {
                errorMessage = "Sakinah couldn’t create the invitation link right now. Make sure iCloud is available and try again."
            }
        }
    }
}

private struct PartnerInviteShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
