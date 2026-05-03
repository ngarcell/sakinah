import SwiftUI
import SwiftData

struct DailyPromptCard: View {
    @Bindable var vm: TodayViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @State private var wordAppeared: [Bool] = []
    @State private var userBubbleScale: CGFloat = 0
    @State private var partnerBubbleScale: CGFloat = 0

    var body: some View {
        SakinahCard(elevated: true) {
            VStack(spacing: 0) {
                promptContent
            }
            .padding(.top, SakinahSpacing.sm)
            .padding(.bottom, SakinahSpacing.xs)
        }
        .overlay(alignment: .top) {
            // Warm gradient overlay at top edge
            LinearGradient(
                colors: [vm.promptCategory.badgeColor.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .allowsHitTesting(false)
        }
        .overlay {
            if vm.revealFlash {
                RoundedRectangle(cornerRadius: SakinahRadius.medium)
                    .fill(SakinahColor.accent.opacity(0.1))
            }
        }
        .overlay {
            ParticleSystem(isActive: vm.particlesActive, color: SakinahColor.accent)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, SakinahSpacing.base)
    }

    @ViewBuilder
    private var promptContent: some View {
        switch vm.promptState {
        case .unanswered:
            unansweredState
        case .revealed:
            revealedState
        }
    }

    // MARK: - State 1: Unanswered

    private var unansweredState: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.base) {
            SakinahBadge(
                text: vm.promptCategory.displayLabel,
                color: vm.promptCategory.badgeColor,
                tintedBackground: vm.promptCategory.badgeColor.opacity(0.12)
            )

            // Typewriter prompt text
            HStack {
                Spacer()
                typewriterText
                Spacer()
            }

            // Text editor
            VStack(alignment: .trailing, spacing: SakinahSpacing.xs) {
                ZStack(alignment: .topLeading) {
                    if vm.userResponse.isEmpty {
                        Text("Write the answer you want to bring into your next conversation.")
                            .font(SakinahFont.body)
                            .foregroundStyle(SakinahColor.textTertiary)
                            .padding(.horizontal, SakinahSpacing.md)
                            .padding(.vertical, SakinahSpacing.md)
                    }
                    TextEditor(text: $vm.userResponse)
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, SakinahSpacing.sm)
                        .padding(.vertical, SakinahSpacing.sm)
                        .onChange(of: vm.userResponse) { _, new in
                            if new.count > vm.maxResponseLength {
                                vm.userResponse = String(new.prefix(vm.maxResponseLength))
                            }
                        }
                }
                .frame(minHeight: 100)
                .background(SakinahColor.backgroundSecondary)
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                Text(vm.characterCount)
                    .font(SakinahFont.caption)
                    .foregroundStyle(
                        vm.userResponse.count > vm.maxResponseLength - 50
                        ? SakinahColor.warning
                        : SakinahColor.textTertiary
                    )
            }

            SakinahButton(title: "Save my answer") {
                vm.submitResponse(context: modelContext)
                ReviewService.shared.onPromptRevealed(requestReview: { requestReview() })
                Task {
                    await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
                }
            }
            .disabled(!vm.isResponseValid)
            .opacity(vm.isResponseValid ? 1 : 0.55)
        }
    }

    private var typewriterText: some View {
        let words = vm.promptText.split(separator: " ").map(String.init)
        return VStack {
            WrappingHStack(words: words, wordAppeared: wordAppeared)
                .onAppear {
                    wordAppeared = Array(repeating: false, count: words.count)
                    for i in words.indices {
                        withAnimation(.easeIn(duration: 0.3).delay(Double(i) * 0.08)) {
                            if i < wordAppeared.count {
                                wordAppeared[i] = true
                            }
                        }
                    }
                }
        }
    }

    // MARK: - State 2: Revealed

    private var revealedState: some View {
        VStack(spacing: SakinahSpacing.base) {
            SakinahBadge(
                text: vm.promptCategory.displayLabel,
                color: SakinahColor.accent,
                tintedBackground: SakinahColor.accentLight
            )

            VStack(spacing: SakinahSpacing.xs) {
                Text("Saved for today")
                    .font(SakinahFont.title3)
                    .foregroundStyle(SakinahColor.textPrimary)

                Text(vm.promptText)
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SakinahSpacing.sm)
            }

            // User's bubble (right)
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: SakinahSpacing.xs) {
                    Text(vm.userName)
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.textSecondary)
                    SpeechBubbleView(tailOnRight: true, backgroundColor: SakinahColor.primaryLight) {
                        Text(vm.userResponse)
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .frame(maxWidth: 260)
                .scaleEffect(userBubbleScale)
            }

            if !vm.partnerResponse.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        Text(vm.partnerName)
                            .font(SakinahFont.captionBold)
                            .foregroundStyle(SakinahColor.textSecondary)
                        SpeechBubbleView(tailOnRight: false, backgroundColor: SakinahColor.accentLight) {
                            Text(vm.partnerResponse)
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textPrimary)
                        }
                    }
                    .frame(maxWidth: 260)
                    .scaleEffect(partnerBubbleScale)
                    Spacer()
                }

                reactionBar
            } else {
                HStack(spacing: SakinahSpacing.sm) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(SakinahColor.accent)
                    Text("Bring this into your next conversation together.")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                    Spacer()
                }
                .padding(SakinahSpacing.md)
                .background(SakinahColor.backgroundSecondary)
                .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            }
        }
        .onAppear {
            withAnimation(SakinahAnimation.bounce.delay(0.1)) {
                userBubbleScale = 1
            }
            if !vm.partnerResponse.isEmpty {
                withAnimation(SakinahAnimation.bounce.delay(0.25)) {
                    partnerBubbleScale = 1
                }
            }
        }
    }

    private var reactionBar: some View {
        HStack(spacing: SakinahSpacing.md) {
            ForEach(["❤️", "😂", "🥺", "🤲", "✨"], id: \.self) { emoji in
                let isSelected = vm.selectedReaction == emoji
                Button {
                    vm.selectReaction(emoji)
                } label: {
                    Text(emoji)
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                        .background(isSelected ? SakinahColor.primaryLight : Color.clear)
                        .clipShape(Circle())
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .shadow(color: isSelected ? SakinahColor.primary.opacity(0.3) : .clear, radius: 8)
                }
                .pressScale()
                .animation(SakinahAnimation.bounce, value: isSelected)
            }
        }
        .padding(.top, SakinahSpacing.sm)
    }
}

// MARK: - Wrapping HStack for typewriter text

struct WrappingHStack: View {
    let words: [String]
    let wordAppeared: [Bool]

    var body: some View {
        // Simple approach: use a Text with attributedString approach
        // For typewriter effect, we'll use individual Text views in a flow layout
        FlowLayout(spacing: 4) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(SakinahFont.title3)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .opacity(index < wordAppeared.count && wordAppeared[index] ? 1 : 0)
            }
        }
        .multilineTextAlignment(.center)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}
