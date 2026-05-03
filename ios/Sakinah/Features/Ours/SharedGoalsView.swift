import SwiftUI
import SwiftData
import StoreKit

struct SharedGoalsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Query(sort: \SharedGoal.createdAt, order: .reverse) private var allGoals: [SharedGoal]
    @State private var showAddGoal = false
    @State private var celebratingGoalID: String? = nil

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            if filteredGoals.isEmpty {
                SakinahEmptyState(
                    icon: "target",
                    title: "Shared goals",
                    message: "Set goals together and track your progress. Whether it's spiritual, financial, or quality time — grow side by side.",
                    actionTitle: "Create a Goal",
                    action: { showAddGoal = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: SakinahSpacing.md) {
                        // Active goals
                        let active = filteredGoals.filter { !$0.isCompleted }
                        if !active.isEmpty {
                            ForEach(active) { goal in
                                goalCard(goal)
                            }
                        }

                        // Completed goals
                        let completed = filteredGoals.filter(\.isCompleted)
                        if !completed.isEmpty {
                            DisclosureGroup {
                                ForEach(completed) { goal in
                                    goalCard(goal)
                                }
                            } label: {
                                Text("Completed (\(completed.count))")
                                    .font(SakinahFont.captionBold)
                                    .foregroundStyle(SakinahColor.textSecondary)
                            }
                            .tint(SakinahColor.textSecondary)
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, SakinahSpacing.base)
                    .padding(.top, SakinahSpacing.md)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Shared Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticEngine.shared.fire(.tap)
                    showAddGoal = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(SakinahColor.primary)
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet()
                .presentationDetents([.medium])
        }
    }

    private var filteredGoals: [SharedGoal] {
        let cid = appState.currentCouple?.id ?? ""
        return allGoals.filter { $0.coupleID == cid }
    }

    private func goalCard(_ goal: SharedGoal) -> some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
            HStack {
                Text(goal.title)
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .strikethrough(goal.isCompleted, color: SakinahColor.textTertiary)
                Spacer()
                if !goal.isCompleted {
                    Button {
                        incrementGoal(goal)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SakinahColor.primary)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(SakinahColor.primary, lineWidth: 2)
                            )
                    }
                    .pressScale()
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SakinahColor.success)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(SakinahColor.primaryLight)
                        .frame(height: 8)
                    Capsule()
                        .fill(goal.isCompleted ? SakinahColor.success : SakinahColor.primary)
                        .frame(width: geo.size.width * goal.progress, height: 8)
                        .animation(SakinahAnimation.spring, value: goal.progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(goal.currentCount)/\(goal.targetCount) — \(Int(goal.progress * 100))%")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
                Spacer()
                Text("Due \(DateFormatting.gregorian(goal.deadline, style: .short))")
                    .font(SakinahFont.caption)
                    .foregroundStyle(SakinahColor.textTertiary)
            }
        }
        .padding(SakinahSpacing.base)
        .background(celebratingGoalID == goal.id ? SakinahColor.accent.opacity(0.1) : SakinahColor.surface)
        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
        .sakinahShadow(.subtle)
        .overlay {
            if celebratingGoalID == goal.id {
                ParticleSystem(isActive: true, color: SakinahColor.accent)
                    .allowsHitTesting(false)
            }
        }
        .animation(SakinahAnimation.gentle, value: celebratingGoalID)
    }

    private func incrementGoal(_ goal: SharedGoal) {
        HapticEngine.shared.fire(.tap)
        goal.currentCount += 1
        goal.touch()
        if goal.currentCount >= goal.targetCount {
            goal.isCompleted = true
            goal.touch()
            HapticEngine.shared.fire(.celebration)
            celebratingGoalID = goal.id
            ReviewService.shared.onGoalCompleted(requestReview: { requestReview() })
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                celebratingGoalID = nil
            }
        }
        try? modelContext.save()
        Task {
            await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
        }
    }
}

struct AddGoalSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var target = 10
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var category: GoalCategory = .other

    var body: some View {
        NavigationStack {
            VStack(spacing: SakinahSpacing.lg) {
                TextField("Goal title", text: $title)
                    .font(SakinahFont.body)
                    .padding(SakinahSpacing.md)
                    .background(SakinahColor.backgroundSecondary)
                    .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                Stepper("Target: \(target)", value: $target, in: 1...100)
                    .font(SakinahFont.body)

                DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    .font(SakinahFont.body)
                    .tint(SakinahColor.primary)

                Picker("Category", selection: $category) {
                    ForEach(GoalCategory.allCases, id: \.self) { cat in
                        Text(cat.label).tag(cat)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                SakinahButton(title: "Create Goal") {
                    save()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }
            .padding(SakinahSpacing.base)
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SakinahColor.primary)
                }
            }
        }
    }

    private func save() {
        let goal = SharedGoal(
            coupleID: appState.currentCouple?.id ?? "",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            targetCount: target,
            category: category,
            deadline: deadline
        )
        modelContext.insert(goal)
        try? modelContext.save()
        HapticEngine.shared.fire(.success)
        Task {
            await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
        }
        dismiss()
    }
}
