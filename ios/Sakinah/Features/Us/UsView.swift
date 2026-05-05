import SwiftUI
import SwiftData

struct UsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var vm = UsViewModel()
    @State private var showPlantDetail = false
    @Query private var memories: [Memory]

    init() {
        _memories = Query(sort: \Memory.date, order: .reverse)
    }

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: SakinahSpacing.xl) {
                    header

                    // Wellness Garden
                    WellnessGardenView(
                        gardenState: vm.gardenState,
                        onPlantTapped: { dim in
                            vm.selectedPlant = dim
                            showPlantDetail = true
                        }
                    )
                    .padding(.horizontal, SakinahSpacing.base)

                    // Garden health hint
                    if vm.gardenState.averageLevel < 2.5 {
                        HStack(spacing: SakinahSpacing.sm) {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(SakinahColor.primary)
                            Text("Daily care and weekly reflection help this garden feel more alive over time.")
                                .font(SakinahFont.caption)
                                .foregroundStyle(SakinahColor.textSecondary)
                        }
                        .padding(SakinahSpacing.md)
                        .background(SakinahColor.primaryLight)
                        .clipShape(.rect(cornerRadius: SakinahRadius.medium))
                        .padding(.horizontal, SakinahSpacing.base)
                    }

                    // Weekly Reflection
                    if vm.showReflection && appState.hasPremiumAccess {
                        WeeklyReflectionCard {
                            withAnimation(SakinahAnimation.gentle) {
                                vm.showReflection = false
                                vm.gardenState = appState.currentCouple?.gardenState ?? GardenState()
                            }
                        }
                    } else if vm.showReflection {
                        UpgradePromptView(
                            icon: "heart.text.square.fill",
                            headline: "Unlock weekly reflections",
                            message: "Keep turning your week together into a clearer picture of what needs care."
                        ) {
                            appState.presentPaywall(for: .weeklyReflection)
                        }
                        .padding(.horizontal, SakinahSpacing.base)
                    }

                    // Milestones & Memories
                    let coupleMemories = memories.filter { $0.coupleID == (appState.currentCouple?.id ?? "") }
                    MilestonesView(
                        milestones: vm.milestones,
                        memories: coupleMemories,
                        coupleID: appState.currentCouple?.id ?? ""
                    )

                    Spacer().frame(height: 100)
                }
                .padding(.top, SakinahSpacing.lg)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            vm.load(appState: appState, context: modelContext)
        }
        .sheet(isPresented: $showPlantDetail) {
            if let dim = vm.selectedPlant {
                PlantDetailSheet(
                    dimension: dim,
                    level: vm.gardenState.level(for: dim),
                    weeklyLevels: vm.weeklyLevels[dim] ?? []
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var header: some View {
        VStack(spacing: SakinahSpacing.sm) {
            Text("Us")
                .font(SakinahFont.title1)
                .foregroundStyle(SakinahColor.textPrimary)

            if let relationshipDurationDays = appState.relationshipDurationDays, relationshipDurationDays > 0 {
                HStack(spacing: 4) {
                    Text("\(relationshipDurationDays)")
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.accent)
                        .contentTransition(.numericText())
                    Text("days together")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
            }
        }
    }
}
