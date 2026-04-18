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

                ScrollView {
                    VStack(spacing: SakinahSpacing.xl) {
                        // Daily Prompt Card — hero element
                        DailyPromptCard(vm: vm)

                        // Daily Du'a Card
                        if let dua = vm.todaysDua {
                            DailyDuaCard(
                                dua: dua,
                                duaLanguage: appState.currentUser?.duaLanguagePreference ?? .all
                            )
                        }

                        // Quick Check-In Card
                        QuickCheckInCard(vm: vm)

                        // Bottom breathing room
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top, SakinahSpacing.md)
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            vm.loadContent(appState: appState)
            vm.loadExistingData(context: modelContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: SakinahSpacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Salaam, \(firstName) 🌙")
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
        }
        .padding(.horizontal, SakinahSpacing.base)
        .padding(.top, SakinahSpacing.sm)
        .padding(.bottom, SakinahSpacing.md)
        .background(SakinahColor.background)
    }

    private var firstName: String {
        let name = appState.currentUser?.name ?? "Friend"
        return name.components(separatedBy: " ").first ?? name
    }

    private var dateString: String {
        let gregorian = Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if appState.currentCouple?.useHijriCalendar == true {
            let hijri = DateFormatting.hijri(Date())
            return "\(gregorian) · \(hijri)"
        }
        return gregorian
    }

    private var partnerAvatar: some View {
        let partnerName = appState.currentCouple?.user2Name ?? "P"
        let initials = String(partnerName.prefix(1)).uppercased()

        return ZStack {
            Circle()
                .fill(SakinahColor.primaryLight)
                .frame(width: 32, height: 32)
            Text(initials)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SakinahColor.primary)
        }
        .overlay(alignment: .bottomTrailing) {
            // Green dot if partner checked in today
            if vm.partnerMood != nil {
                Circle()
                    .fill(SakinahColor.success)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(SakinahColor.background, lineWidth: 1.5)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }
}
