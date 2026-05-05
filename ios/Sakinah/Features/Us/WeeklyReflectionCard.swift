import SwiftUI
import SwiftData

struct WeeklyReflectionCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var currentQuestion: Int = 0
    @State private var scores: [Int] = [0, 0, 0, 0, 0]
    @State private var shareWithPartner: Bool = false
    @State private var showCelebration: Bool = false
    @State private var isCompleted: Bool = false

    private let dimensions = GardenDimension.allCases

    var onComplete: (() -> Void)? = nil

    var body: some View {
        if !isCompleted {
            SakinahCard(elevated: true) {
                VStack(spacing: SakinahSpacing.base) {
                    // Accent left border overlay
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(SakinahColor.accent)
                            .frame(width: 4)
                            .clipShape(.rect(cornerRadii: .init(topLeading: SakinahRadius.large, bottomLeading: SakinahRadius.large)))
                        Spacer()
                    }
                    .frame(height: 0)

                    // Header
                    VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                        HStack {
                            Text("Weekly Reflection")
                                .font(SakinahFont.title3)
                                .foregroundStyle(SakinahColor.textPrimary)
                            Spacer()
                        }
                        Text("Take a quiet moment to reflect on your week together.")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                    }

                    // Privacy toggle
                    HStack {
                        Text("Share with \(appState.partnerName)")
                            .font(SakinahFont.bodySmall)
                            .foregroundStyle(SakinahColor.textSecondary)
                        Spacer()
                        Toggle("", isOn: $shareWithPartner)
                            .labelsHidden()
                            .tint(SakinahColor.primary)
                    }
                    .padding(SakinahSpacing.md)
                    .background(SakinahColor.backgroundSecondary)
                    .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                    Divider()

                    // Question
                    questionView

                    // Progress dots
                    HStack(spacing: SakinahSpacing.sm) {
                        ForEach(0..<5, id: \.self) { i in
                            Circle()
                                .fill(scores[i] > 0 ? SakinahColor.primary : SakinahColor.backgroundSecondary)
                                .frame(width: 8, height: 8)
                                .animation(SakinahAnimation.spring, value: scores[i])
                        }
                    }

                    // Next / Submit
                    if currentQuestion < 4 {
                        SakinahButton(title: "Next") {
                            withAnimation(SakinahAnimation.gentle) {
                                currentQuestion += 1
                            }
                        }
                        .disabled(scores[currentQuestion] == 0)
                        .opacity(scores[currentQuestion] == 0 ? 0.55 : 1)
                    } else {
                        SakinahButton(title: "Submit Reflection") {
                            submitReflection()
                        }
                        .disabled(scores[currentQuestion] == 0)
                        .opacity(scores[currentQuestion] == 0 ? 0.55 : 1)
                    }
                }
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(SakinahColor.accent)
                    .frame(width: 4)
                    .clipShape(.rect(cornerRadii: .init(topLeading: SakinahRadius.medium, bottomLeading: SakinahRadius.medium)))
            }
            .padding(.horizontal, SakinahSpacing.base)
            .overlay {
                if showCelebration {
                    celebrationOverlay
                        .transition(.opacity)
                }
            }
        }
    }

    private var questionView: some View {
        VStack(spacing: SakinahSpacing.lg) {
            let dim = dimensions[currentQuestion]
            Text(dim.reflectionQuestion)
                .font(SakinahFont.headline)
                .foregroundStyle(SakinahColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SakinahSpacing.sm)
                .id(currentQuestion) // Force re-render on question change

            // 5-point scale
            HStack(spacing: SakinahSpacing.sm) {
                ForEach(1...5, id: \.self) { score in
                    let isSelected = scores[currentQuestion] == score
                    Button {
                        HapticEngine.shared.fire(.select)
                        withAnimation(SakinahAnimation.bounce) {
                            scores[currentQuestion] = score
                        }
                    } label: {
                        Text("\(score)")
                            .font(SakinahFont.headline)
                            .foregroundStyle(isSelected ? .white : SakinahColor.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(isSelected ? SakinahColor.primary : SakinahColor.backgroundSecondary)
                            .clipShape(Circle())
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                    }
                    .pressScale()
                    .animation(SakinahAnimation.bounce, value: isSelected)
                }
            }

            // Labels
            HStack {
                Text("Not at all")
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
                Spacer()
                Text("Absolutely")
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
    }

    private var celebrationOverlay: some View {
        VStack(spacing: SakinahSpacing.base) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 34))
                .foregroundStyle(SakinahColor.accent)
            Text("A beautiful week together")
                .font(SakinahFont.title3)
                .foregroundStyle(SakinahColor.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SakinahColor.surface.opacity(0.95))
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
    }

    private func submitReflection() {
        guard appState.hasPremiumAccess else {
            appState.presentPaywall(for: .weeklyReflection)
            return
        }
        HapticEngine.shared.fire(.success)

        let reflection = WeeklyReflection(
            coupleID: appState.currentCouple?.id ?? "",
            userID: appState.currentUser?.id ?? "",
            weekStartDate: startOfWeek(),
            communicationScore: scores[0],
            qualityTimeScore: scores[1],
            spiritualConnectionScore: scores[2],
            emotionalSafetyScore: scores[3],
            growthScore: scores[4],
            isSharedWithPartner: shareWithPartner
        )
        modelContext.insert(reflection)

        // Update garden state
        if let couple = appState.currentCouple {
            var garden = couple.gardenState
            garden.applyReflectionScores(reflection.scores)
            couple.gardenState = garden
            couple.touch()
        }

        try? modelContext.save()
        Task {
            await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
        }

        // Celebration if all scores ≥ 4
        if scores.allSatisfy({ $0 >= 4 }) {
            HapticEngine.shared.fire(.celebration)
            withAnimation {
                showCelebration = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withAnimation {
                    showCelebration = false
                    isCompleted = true
                }
                onComplete?()
            }
        } else {
            withAnimation(SakinahAnimation.gentle) {
                isCompleted = true
            }
            onComplete?()
        }
    }

    private func startOfWeek() -> Date {
        let cal = Calendar.current
        return cal.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date()).date ?? Date()
    }
}
