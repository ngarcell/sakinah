import SwiftUI
import SwiftData
import StoreKit

struct DailyPromptCard: View {
    @Bindable var vm: TodayViewModel
    @Environment(AppState.self) private var appState
    @State private var showPartnerAnswer = false

    var body: some View {
        Group {
            switch vm.promptState {
            case .unanswered:
                unansweredState
            case .revealed:
                answeredState
            }
        }
        .overlay {
            ParticleSystem(isActive: vm.particlesActive, color: SakinahColor.accent)
                .allowsHitTesting(false)
        }
        .sheet(isPresented: $showPartnerAnswer) {
            PartnerAnswerSheet(name: vm.partnerName, answer: vm.partnerResponse)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var unansweredState: some View {
        Group {
            if appState.hasPremiumAccess {
                NavigationLink {
                    DailyPromptAnswerView(vm: vm)
                } label: {
                    VStack(alignment: .leading, spacing: SakinahSpacing.lg) {
                        Text("TODAY'S REFLECTION")
                            .font(SakinahFont.captionBold)
                            .tracking(0.4)
                            .foregroundStyle(.white.opacity(0.82))

                        Text("\"\(vm.promptText)\"")
                            .font(.system(size: 19, weight: .regular, design: .serif))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            Label("Write your answer", systemImage: "square.and.pencil")
                                .font(SakinahFont.headline)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .padding(.top, SakinahSpacing.xs)

                        HStack(spacing: SakinahSpacing.sm) {
                            statusDot(isActive: false)
                            Text("Not yet")
                                .font(SakinahFont.caption)
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }
                    .padding(SakinahSpacing.base)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: SakinahColor.heroGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                    .sakinahShadow(.medium)
                }
                .buttonStyle(.plain)
            } else {
                UpgradePromptView(
                    icon: "moon.stars.fill",
                    headline: "Keep the daily ritual open",
                    message: "Your earlier answers stay here. Upgrade to answer new prompts and keep your shared rhythm moving.",
                    ctaTitle: "See plans"
                ) {
                    appState.presentPaywall(for: .dailyHabit)
                }
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    private var answeredState: some View {
        SakinahCard {
            VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                HStack(alignment: .center) {
                    HStack(spacing: SakinahSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SakinahColor.success)
                        Text("TODAY'S REFLECTION")
                            .font(SakinahFont.captionBold)
                            .tracking(0.4)
                            .foregroundStyle(SakinahColor.textSecondary)
                    }

                    Spacer()

                    NavigationLink("Edit") {
                        DailyPromptAnswerView(vm: vm)
                    }
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.primary)
                }

                Text("\"\(vm.userResponse)\"")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .foregroundStyle(SakinahColor.textPrimary)
                    .lineSpacing(4)
                    .lineLimit(2)

                HStack {
                    Text("Read more")
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.primary)

                    Spacer()

                    if !vm.partnerResponse.isEmpty {
                        Button {
                            showPartnerAnswer = true
                        } label: {
                            HStack(spacing: SakinahSpacing.xs) {
                                Text("\(vm.partnerName)'s answer")
                                Image(systemName: "chevron.right")
                            }
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.rose)
                        }
                    }
                }
            }
        }
        .overlay {
            if vm.revealFlash {
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .fill(SakinahColor.accent.opacity(0.12))
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    private func statusDot(isActive: Bool) -> some View {
        Circle()
            .strokeBorder(.white.opacity(0.75), lineWidth: 1.5)
            .background(Circle().fill(isActive ? .white : .clear))
            .frame(width: 9, height: 9)
    }
}

struct DailyPromptAnswerView: View {
    @Bindable var vm: TodayViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
            VStack(alignment: .leading, spacing: SakinahSpacing.md) {
                Text("\"\(vm.promptText)\"")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(SakinahColor.textPrimary)
                    .lineSpacing(5)

                HStack {
                    Rectangle()
                        .fill(SakinahColor.divider)
                        .frame(height: 1)
                    Image(systemName: "sparkle")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(SakinahColor.accent)
                    Rectangle()
                        .fill(SakinahColor.divider)
                        .frame(height: 1)
                }
            }

            ZStack(alignment: .topLeading) {
                if draft.isEmpty {
                    Text("Write your answer here...")
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textTertiary)
                        .padding(.horizontal, SakinahSpacing.md)
                        .padding(.vertical, SakinahSpacing.md)
                }

                TextEditor(text: $draft)
                    .font(SakinahFont.body)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(SakinahSpacing.sm)
                    .onChange(of: draft) { _, newValue in
                        if newValue.count > vm.maxResponseLength {
                            draft = String(newValue.prefix(vm.maxResponseLength))
                        }
                    }
            }
            .frame(maxHeight: .infinity)
            .background(SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .stroke(SakinahColor.border, lineWidth: 1)
            )

            if draft.count > 400 {
                Text("\(draft.count)/\(vm.maxResponseLength)")
                    .font(SakinahFont.caption)
                    .foregroundStyle(draft.count >= vm.maxResponseLength ? SakinahColor.error : SakinahColor.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(SakinahSpacing.base)
        .background(SakinahColor.background.ignoresSafeArea())
        .navigationTitle("Today's Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
            ToolbarItem(placement: .keyboard) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            draft = vm.userResponse
        }
    }

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.count <= vm.maxResponseLength
    }

    private func save() {
        guard appState.hasPremiumAccess, canSave else { return }
        vm.userResponse = draft
        vm.submitResponse(context: modelContext)
        ReviewService.shared.onPromptRevealed(requestReview: { requestReview() })
        Task {
            await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
        }
        dismiss()
    }
}

struct PartnerAnswerSheet: View {
    let name: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.lg) {
            Capsule()
                .fill(SakinahColor.divider)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, SakinahSpacing.sm)

            Text("\(name)'s answer")
                .font(SakinahFont.title2)
                .foregroundStyle(SakinahColor.textPrimary)

            Text(answer)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(SakinahColor.textPrimary)
                .lineSpacing(6)

            Spacer()
        }
        .padding(SakinahSpacing.base)
        .background(SakinahColor.background)
    }
}
