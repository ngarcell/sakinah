import SwiftUI

struct DailyDuaCard: View {
    let dua: DuaData
    let duaLanguage: DuaLanguage
    @State private var showFullDua = false

    var body: some View {
        SakinahCard {
            VStack(alignment: .leading, spacing: SakinahSpacing.base) {
                Text("TODAY'S DU'A")
                    .font(SakinahFont.captionBold)
                    .tracking(0.4)
                    .foregroundStyle(SakinahColor.textSecondary)

                if showsArabic {
                    Text(dua.arabic)
                        .font(SakinahFont.arabic)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if showsTransliteration {
                    Text(dua.transliteration)
                        .font(SakinahFont.bodySmall)
                        .italic()
                        .foregroundStyle(SakinahColor.textSecondary)
                        .lineLimit(2)
                }

                if showsTranslation {
                    Text(dua.translation)
                        .font(SakinahFont.bodySmall)
                        .foregroundStyle(SakinahColor.textSecondary)
                        .lineSpacing(4)
                        .lineLimit(3)
                }

                Button {
                    HapticEngine.shared.fire(.select)
                    showFullDua = true
                } label: {
                    HStack(spacing: SakinahSpacing.xs) {
                        Text("Read in full")
                        Image(systemName: "arrow.right")
                    }
                    .font(SakinahFont.captionBold)
                    .foregroundStyle(SakinahColor.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, SakinahSpacing.base)
        .sheet(isPresented: $showFullDua) {
            DailyDuaSheet(dua: dua)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var showsArabic: Bool {
        duaLanguage == .arabicEnglish || duaLanguage == .arabicTransliteration || duaLanguage == .all
    }

    private var showsTransliteration: Bool {
        duaLanguage == .arabicTransliteration || duaLanguage == .all
    }

    private var showsTranslation: Bool {
        duaLanguage == .arabicEnglish || duaLanguage == .all
    }
}

struct DailyDuaSheet: View {
    let dua: DuaData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SakinahSpacing.xl) {
                    Text(dua.arabic)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(SakinahColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .lineSpacing(10)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(dua.transliteration)
                        .font(SakinahFont.body)
                        .italic()
                        .foregroundStyle(SakinahColor.textSecondary)
                        .lineSpacing(5)

                    Text(dua.translation)
                        .font(SakinahFont.body)
                        .foregroundStyle(SakinahColor.textPrimary)
                        .lineSpacing(5)

                    Text(dua.source)
                        .font(SakinahFont.caption)
                        .foregroundStyle(SakinahColor.textTertiary)

                    ShareLink(item: "\(dua.arabic)\n\n\(dua.translation)\n\n\(dua.source)") {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(SakinahFont.headline)
                    }
                    .foregroundStyle(SakinahColor.primary)
                }
                .padding(SakinahSpacing.base)
            }
            .background(SakinahColor.background)
            .navigationTitle("Today's Du'a")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
