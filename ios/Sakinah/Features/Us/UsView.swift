import SwiftUI
import SwiftData

struct UsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var vm = UsViewModel()
    @State private var showPlantDetail = false
    @Query private var memories: [Memory]

    init() {
        // Fetch memories ordered by date descending
        _memories = Query(sort: \Memory.date, order: .reverse)
    }

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: SakinahSpacing.xl) {
                    header

                    // Wellness Garden — hero visual
                    WellnessGardenView(
                        gardenState: vm.gardenState,
                        onPlantTapped: { dim in
                            vm.selectedPlant = dim
                            showPlantDetail = true
                        }
                    )
                    .padding(.horizontal, SakinahSpacing.base)

                    // Weekly Reflection (conditional)
                    if vm.showReflection {
                        WeeklyReflectionCard {
                            withAnimation(SakinahAnimation.gentle) {
                                vm.showReflection = false
                                // Reload garden state
                                vm.gardenState = appState.currentCouple?.gardenState ?? GardenState()
                            }
                        }
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
        VStack(spacing: SakinahSpacing.xs) {
            Text("Us")
                .font(SakinahFont.title1)
                .foregroundStyle(SakinahColor.textPrimary)

            HStack(spacing: 4) {
                Text("\(vm.daysTogether)")
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.accent)
                Text("days growing together")
                    .font(SakinahFont.bodySmall)
                    .foregroundStyle(SakinahColor.textSecondary)
            }
        }
    }
}
