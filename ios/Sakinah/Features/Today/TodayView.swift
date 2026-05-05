import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var vm = TodayViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            SakinahColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .background(
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [SakinahColor.background, SakinahColor.background.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 20)
                        }
                    )
                    .zIndex(1)

                OfflineBanner()

                ScrollView {
                    VStack(spacing: SakinahSpacing.xl) {
                        if appState.pairingStatus != .paired {
                            inviteBanner
                        }

                        if appState.shouldShowStarterPlanCard {
                            StarterPlanCard()
                        }

                        DailyPromptCard(vm: vm)

                        if let dua = vm.todaysDua {
                            DailyDuaCard(
                                dua: dua,
                                duaLanguage: appState.currentUser?.duaLanguagePreference ?? .all
                            )
                        }

                        QuickCheckInCard(vm: vm)

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, SakinahSpacing.md)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    vm.loadContent(appState: appState)
                    vm.loadExistingData(context: modelContext)
                }
            }
        }
        .onAppear {
            vm.loadContent(appState: appState)
            vm.loadExistingData(context: modelContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Theme.greeting), \(firstName)")
                        .font(SakinahFont.title2)
                        .foregroundStyle(SakinahColor.textPrimary)

                    Text(dateString)
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textSecondary)
                }

                Spacer()

                // Partner avatar
                partnerAvatar
            }

            // Progress badges
            HStack(spacing: SakinahSpacing.sm) {
                if vm.currentStreak > 0 {
                    StreakBadge(count: vm.currentStreak, label: "day streak")
                }
                if let relationshipDurationDays = appState.relationshipDurationDays, relationshipDurationDays > 0 {
                    StreakBadge(count: relationshipDurationDays, label: "days together", icon: "heart.fill")
                }
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
        .padding(.top, SakinahSpacing.sm)
        .padding(.bottom, SakinahSpacing.md)
        .background(SakinahColor.background)
    }

    private var firstName: String {
        let name = appState.currentUser?.name ?? "You"
        return name.components(separatedBy: " ").first ?? name
    }

    private var dateString: String {
        let gregorian = Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if appState.currentCouple?.useHijriCalendar == true {
            let hijri = DateFormatting.hijri(Date())
            return "\(gregorian) \u{00B7} \(hijri)"
        }
        return gregorian
    }

    private var partnerAvatar: some View {
        let partnerName = appState.partnerName
        let initials = String(partnerName.prefix(1)).uppercased()

        return ZStack {
            Circle()
                .fill(SakinahColor.primaryLight)
                .frame(width: 36, height: 36)
            Text(initials)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SakinahColor.primary)
        }
        .overlay(alignment: .bottomTrailing) {
            if vm.partnerMood != nil {
                Circle()
                    .fill(SakinahColor.success)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(SakinahColor.background, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var inviteBanner: some View {
        Button {
            appState.showPartnerInvitePrompt = true
        } label: {
            HStack(alignment: .top, spacing: SakinahSpacing.md) {
                ZStack {
                    Circle()
                        .fill(SakinahColor.accentLight)
                        .frame(width: 38, height: 38)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SakinahColor.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite your spouse into this space")
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)
                    Text("Send one private link so prompts, journal entries, goals, and reflections stay in sync.")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SakinahColor.textTertiary)
            }
            .padding(SakinahSpacing.base)
            .background(SakinahColor.surface)
            .clipShape(.rect(cornerRadius: SakinahRadius.large))
            .sakinahShadow(.subtle)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, SakinahSpacing.base)
    }
}
