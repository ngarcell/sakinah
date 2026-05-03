import SwiftUI
import SwiftData

struct LoveLettersView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LoveLetter.deliveryDate, order: .reverse) private var allLetters: [LoveLetter]
    @State private var showCompose = false
    @State private var selectedLetter: LoveLetter? = nil
    @State private var envelopeRevealed = false

    var body: some View {
        ZStack {
            SakinahColor.background.ignoresSafeArea()

            if filteredLetters.isEmpty {
                SakinahEmptyState(
                    icon: "envelope.fill",
                    title: "Love letters",
                    message: "Write a letter now and let it arrive later, whether for an anniversary, a birthday, or an ordinary day that matters.",
                    actionTitle: "Write a Letter",
                    action: { showCompose = true }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: SakinahSpacing.md) {
                        ForEach(filteredLetters) { letter in
                            letterCard(letter)
                        }
                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, SakinahSpacing.base)
                    .padding(.top, SakinahSpacing.md)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Love Letters")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    HapticEngine.shared.fire(.tap)
                    showCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(SakinahColor.primary)
                }
            }
        }
        .fullScreenCover(isPresented: $showCompose) {
            ComposeLetterView()
        }
        .sheet(item: $selectedLetter) { letter in
            LetterReadView(letter: letter)
                .presentationDetents([.large])
        }
    }

    private var filteredLetters: [LoveLetter] {
        let uid = appState.currentUser?.id ?? ""
        let cid = appState.currentCouple?.id ?? ""
        return allLetters.filter { letter in
            letter.coupleID == cid && (
                letter.senderID == uid ||
                (letter.senderID != uid && letter.isDelivered)
            )
        }
    }

    private func letterCard(_ letter: LoveLetter) -> some View {
        let isSent = letter.senderID == appState.currentUser?.id
        let isReceived = !isSent && letter.isDelivered
        return Button {
            if isReceived || isSent {
                selectedLetter = letter
            }
        } label: {
            VStack(alignment: .leading, spacing: SakinahSpacing.sm) {
                HStack {
                    Image(systemName: letter.isDelivered ? "envelope.open.fill" : "envelope.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(isReceived ? SakinahColor.accent : SakinahColor.primary)
                    if isReceived {
                        Text("From \(letter.senderName)")
                            .font(SakinahFont.headline)
                            .foregroundStyle(SakinahColor.accent)
                    } else {
                        Text(letter.title.isEmpty ? "Letter" : letter.title)
                            .font(SakinahFont.headline)
                            .foregroundStyle(SakinahColor.textPrimary)
                    }
                    Spacer()
                }

                if !letter.isDelivered {
                    Text("Delivers on \(DateFormatting.gregorian(letter.deliveryDate, style: .medium))")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                } else {
                    Text("Delivered \(DateFormatting.timeAgo(letter.deliveryDate))")
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textTertiary)
                }
            }
            .padding(SakinahSpacing.base)
            .background(
                isReceived ? SakinahColor.primaryLight.opacity(0.5) :
                !letter.isDelivered ? SakinahColor.accentLight.opacity(0.5) :
                SakinahColor.surface
            )
            .clipShape(.rect(cornerRadius: SakinahRadius.medium))
            .sakinahShadow(.subtle)
        }
    }
}

struct ComposeLetterView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var deliveryDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    @State private var showSealAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                SakinahColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: SakinahSpacing.lg) {
                        Text("Write a Love Letter")
                            .font(SakinahFont.title2)
                            .foregroundStyle(SakinahColor.textPrimary)

                        Text("To: \(appState.partnerName)")
                            .font(SakinahFont.headline)
                            .foregroundStyle(SakinahColor.accent)

                        // Title
                        TextField("Add a title (optional)", text: $title)
                            .font(SakinahFont.body)
                            .padding(SakinahSpacing.md)
                            .background(SakinahColor.backgroundSecondary)
                            .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                        // Lined paper text editor
                        ZStack(alignment: .topLeading) {
                            // Lines
                            GeometryReader { geo in
                                let lineCount = Int(geo.size.height / 28)
                                Path { path in
                                    for i in 1...max(1, lineCount) {
                                        let y = CGFloat(i) * 28
                                        path.move(to: CGPoint(x: 0, y: y))
                                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                                    }
                                }
                                .stroke(SakinahColor.divider, lineWidth: 0.5)
                            }

                            if content.isEmpty {
                                Text("Dear \(appState.partnerName)...")
                                    .font(SakinahFont.body)
                                    .foregroundStyle(SakinahColor.textTertiary)
                                    .padding(.horizontal, SakinahSpacing.md)
                                    .padding(.top, SakinahSpacing.md)
                            }
                            TextEditor(text: $content)
                                .font(SakinahFont.body)
                                .foregroundStyle(SakinahColor.textPrimary)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, SakinahSpacing.sm)
                                .padding(.vertical, SakinahSpacing.sm)
                                .lineSpacing(10)
                        }
                        .frame(minHeight: 280)
                        .background(SakinahColor.backgroundSecondary)
                        .clipShape(.rect(cornerRadius: SakinahRadius.medium))

                        DatePicker("Deliver on", selection: $deliveryDate, in: Calendar.current.date(byAdding: .day, value: 1, to: Date())!..., displayedComponents: .date)
                            .font(SakinahFont.body)
                            .tint(SakinahColor.primary)

                        SakinahButton(title: "Seal & Schedule") {
                            sealLetter()
                        }
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
                    }
                    .padding(SakinahSpacing.base)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SakinahColor.primary)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
        }
    }

    private func sealLetter() {
        let letter = LoveLetter(
            coupleID: appState.currentCouple?.id ?? "",
            senderID: appState.currentUser?.id ?? "",
            senderName: appState.userName,
            recipientName: appState.partnerName,
            title: title,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            deliveryDate: deliveryDate
        )
        modelContext.insert(letter)
        try? modelContext.save()
        HapticEngine.shared.fire(.success)
        scheduleDeliveryNotification(letter)
        Task {
            await CloudKitService.shared.syncIfPossible(appState: appState, context: modelContext)
        }
        dismiss()
    }

    private func scheduleDeliveryNotification(_ letter: LoveLetter) {
        let content = UNMutableNotificationContent()
        content.title = "A letter is ready"
        content.body = "A love letter from \(letter.senderName) has arrived."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: letter.deliveryDate),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "letter.\(letter.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

struct LetterReadView: View {
    let letter: LoveLetter
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        VStack(spacing: SakinahSpacing.lg) {
            Capsule()
                .fill(SakinahColor.divider)
                .frame(width: 36, height: 4)
                .padding(.top, SakinahSpacing.sm)

            Image(systemName: "envelope.open.fill")
                .font(.system(size: 40))
                .foregroundStyle(SakinahColor.accent)
                .scaleEffect(appeared ? 1 : 0.5)

            if !letter.title.isEmpty {
                Text(letter.title)
                    .font(SakinahFont.title2)
                    .foregroundStyle(SakinahColor.textPrimary)
            }

            Text("From \(letter.senderName)")
                .font(SakinahFont.caption)
                .foregroundStyle(SakinahColor.textTertiary)

            ScrollView {
                Text(letter.content)
                    .font(SakinahFont.body)
                    .foregroundStyle(SakinahColor.textPrimary)
                    .lineSpacing(6)
                    .opacity(appeared ? 1 : 0)
            }

            Text(DateFormatting.gregorian(letter.createdAt))
                .font(SakinahFont.caption)
                .foregroundStyle(SakinahColor.textTertiary)
        }
        .padding(SakinahSpacing.base)
        .onAppear {
            withAnimation(SakinahAnimation.gentle.delay(0.2)) {
                appeared = true
            }
        }
    }
}

import UserNotifications
