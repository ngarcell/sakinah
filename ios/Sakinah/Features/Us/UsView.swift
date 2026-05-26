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
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                        relationshipSummary

                        WellnessGardenView(
                            gardenState: vm.gardenState,
                            onPlantTapped: { dimension in
                                vm.selectedPlant = dimension
                                showPlantDetail = true
                            }
                        )
                        .padding(.horizontal, SakinahSpacing.base)

                        weeklyReflectionSection

                        let coupleMemories = memories.filter { $0.coupleID == (appState.currentCouple?.id ?? "") }
                        MilestonesView(
                            milestones: vm.milestones,
                            memories: coupleMemories,
                            coupleID: appState.currentCouple?.id ?? ""
                        )

                        Spacer().frame(height: 32)
                    }
                    .padding(.top, SakinahSpacing.md)
                    .padding(.bottom, SakinahSpacing.jumbo)
                }
                .scrollIndicators(.hidden)
            }
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var relationshipSummary: some View {
        Group {
            if let days = appState.relationshipDurationDays, days > 0 {
                HStack(spacing: SakinahSpacing.sm) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(SakinahColor.rose)
                    Text("\(days) days together")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                }
                .padding(.horizontal, SakinahSpacing.base)
            }
        }
    }

    @ViewBuilder
    private var weeklyReflectionSection: some View {
        if appState.hasPremiumAccess && vm.showReflection {
            WeeklyReflectionCard {
                withAnimation(SakinahAnimation.gentle) {
                    vm.showReflection = false
                    vm.gardenState = appState.currentCouple?.gardenState ?? GardenState()
                }
            }
        } else {
            weeklyReflectionPreview
        }
    }

    private var weeklyReflectionPreview: some View {
        Button {
            if appState.hasPremiumAccess {
                vm.showReflection = true
            } else {
                appState.presentPaywall(for: .weeklyReflection)
            }
        } label: {
            SakinahCard {
                VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                    HStack {
                        VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                            Text("WEEKLY REFLECTION")
                                .font(SakinahFont.captionBold)
                                .tracking(0.4)
                                .foregroundStyle(SakinahColor.textSecondary)
                            Text("Available every Sunday")
                                .font(SakinahFont.caption)
                                .foregroundStyle(SakinahColor.textTertiary)
                        }

                        Spacer()

                        if !appState.hasPremiumAccess {
                            SakinahBadge(
                                text: "Premium",
                                icon: "lock.fill",
                                color: .white,
                                tintedBackground: SakinahColor.accent
                            )
                        }
                    }

                    Text("How connected did you feel to \(appState.partnerName) this week?")
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundStyle(SakinahColor.textPrimary)
                        .lineSpacing(4)

                    Label(
                        appState.hasPremiumAccess ? "Begin Reflection" : "Unlock Reflection",
                        systemImage: appState.hasPremiumAccess ? "arrow.right" : "lock.fill"
                    )
                    .font(SakinahFont.headline)
                    .foregroundStyle(SakinahColor.primary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, SakinahSpacing.base)
    }
}
