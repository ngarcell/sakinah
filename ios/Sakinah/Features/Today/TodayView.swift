import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var vm = TodayViewModel()
    @AppStorage("todayInviteBannerDismissedDay") private var dismissedInviteBannerDay = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SakinahColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    OfflineBanner()

                    ScrollView {
                        VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                            Text(dateLine)
                                .font(SakinahFont.bodySmall)
                                .foregroundStyle(SakinahColor.textSecondary)
                                .padding(.horizontal, SakinahSpacing.base)

                            if shouldShowInviteBanner {
                                inviteBanner
                            }

                            DailyPromptCard(vm: vm)

                            if let dua = vm.todaysDua {
                                DailyDuaCard(
                                    dua: dua,
                                    duaLanguage: appState.currentUser?.duaLanguagePreference ?? .all
                                )
                            }

                            QuickCheckInCard(vm: vm)

                            if appState.shouldShowStarterPlanCard {
                                StarterPlanCard()
                            }

                            Spacer().frame(height: 32)
                        }
                        .padding(.top, SakinahSpacing.md)
                        .padding(.bottom, SakinahSpacing.jumbo)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        vm.loadContent(appState: appState)
                        vm.loadExistingData(context: modelContext)
                    }
                }
            }
        }
        .onAppear {
            vm.loadContent(appState: appState)
            vm.loadExistingData(context: modelContext)
        }
    }

    private var dateLine: String {
        let gregorian = Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        if appState.currentCouple?.useHijriCalendar == true {
            return "\(gregorian) | \(DateFormatting.hijri(Date()))"
        }
        return gregorian
    }

    private var todayKey: String {
        ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
    }

    private var shouldShowInviteBanner: Bool {
        appState.pairingStatus != .paired && dismissedInviteBannerDay != todayKey
    }

    private var inviteBanner: some View {
        SakinahCard(accent: true) {
            HStack(alignment: .top, spacing: SakinahSpacing.md) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(SakinahColor.accent)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
                    Text("Invite \(appState.partnerName) to Sakinah")
                        .font(SakinahFont.headline)
                        .foregroundStyle(SakinahColor.textPrimary)

                    Text("Share your space and answers together.")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)

                    Button {
                        HapticEngine.shared.fire(.tap)
                        appState.showPartnerInvitePrompt = true
                    } label: {
                        HStack(spacing: SakinahSpacing.xs) {
                            Text("Send Invite")
                            Image(systemName: "arrow.right")
                        }
                        .font(SakinahFont.captionBold)
                        .foregroundStyle(SakinahColor.primary)
                    }
                    .padding(.top, SakinahSpacing.xs)
                }

                Spacer()

                Button {
                    dismissedInviteBannerDay = todayKey
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SakinahColor.textTertiary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
    }
}
