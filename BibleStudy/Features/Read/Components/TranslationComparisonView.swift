import SwiftUI

// MARK: - Translation Comparison View
// Shows selected verses in multiple translations for comparison

struct TranslationComparisonView: View {
    let verseRange: VerseRange
    @Environment(BibleService.self) private var bibleService
    @State private var comparisonVerses: [String: [Verse]] = [:]  // translationId -> verses
    @State private var selectedTranslations: [String] = []
    @State private var isLoading = false
    @State private var showTranslationPicker = false

    // Default translations to show
    private let defaultTranslationCount = 3

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                if isLoading && comparisonVerses.isEmpty {
                    loadingView
                } else if comparisonVerses.isEmpty {
                    emptyState
                } else {
                    // Reference header
                    HStack {
                        Text(verseRange.reference)
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                        Spacer()
                        Button {
                            showTranslationPicker = true
                        } label: {
                            HStack(spacing: AppTheme.Spacing.xxs) {
                                Image(systemName: "plus.circle")
                                Text("Add")
                            }
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.accentBlue)
                        }
                    }

                    // Translation cards
                    ForEach(selectedTranslations, id: \.self) { translationId in
                        if let verses = comparisonVerses[translationId] {
                            TranslationCard(
                                translationId: translationId,
                                verses: verses,
                                isCurrent: translationId == bibleService.currentTranslationId,
                                onRemove: selectedTranslations.count > 1 ? {
                                    removeTranslation(translationId)
                                } : nil
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showTranslationPicker) {
            TranslationSelectionSheet(
                availableTranslations: bibleService.availableTranslations,
                selectedTranslations: selectedTranslations
            ) { translationId in
                addTranslation(translationId)
            }
        }
        .task {
            await loadInitialTranslations()
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
            Text("Loading translations...")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.xxxl + AppTheme.Spacing.md)
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "doc.on.doc")
                .font(Typography.UI.largeTitle)
                .foregroundStyle(Color.tertiaryText)

            Text("Compare Translations")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            Text("See how different Bible translations render this passage.")
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await loadInitialTranslations()
                }
            } label: {
                Text("Load Translations")
                    .font(Typography.UI.bodyBold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadInitialTranslations() async {
        guard selectedTranslations.isEmpty else { return }

        isLoading = true

        // Start with current translation and up to 2 others
        var translations = [bibleService.currentTranslationId]
        for translation in bibleService.availableTranslations {
            if translations.count >= defaultTranslationCount { break }
            if !translations.contains(translation.id) {
                translations.append(translation.id)
            }
        }

        selectedTranslations = translations
        await loadVerses(for: translations)

        isLoading = false
    }

    private func loadVerses(for translationIds: [String]) async {
        for translationId in translationIds {
            guard comparisonVerses[translationId] == nil else { continue }

            do {
                let verses = try await bibleService.getVerses(range: verseRange, translationId: translationId)
                comparisonVerses[translationId] = verses
            } catch {
                print("Failed to load verses for \(translationId): \(error)")
            }
        }
    }

    private func addTranslation(_ translationId: String) {
        guard !selectedTranslations.contains(translationId) else { return }

        selectedTranslations.append(translationId)

        Task {
            await loadVerses(for: [translationId])
        }
    }

    private func removeTranslation(_ translationId: String) {
        selectedTranslations.removeAll { $0 == translationId }
        comparisonVerses.removeValue(forKey: translationId)
    }
}

// MARK: - Translation Card

struct TranslationCard: View {
    let translationId: String
    let verses: [Verse]
    let isCurrent: Bool
    var onRemove: (() -> Void)?

    private var translation: Translation? {
        Translation.find(byId: translationId)
    }

    private var verseText: String {
        verses.map { $0.text }.joined(separator: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(translation?.abbreviation ?? translationId.uppercased())
                            .font(Typography.UI.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primaryText)

                        if isCurrent {
                            Text("Current")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.accentGold)
                                .padding(.horizontal, AppTheme.Spacing.xs)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                                )
                        }
                    }

                    if let translation = translation {
                        Text(translation.name)
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }

                Spacer()

                if let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
            }

            // Verse text
            Text(verseText)
                .font(Typography.Scripture.body(size: 16))
                .foregroundStyle(Color.primaryText)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(isCurrent ? Color.accentGold.opacity(AppTheme.Opacity.medium) : Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Translation Selection Sheet

struct TranslationSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let availableTranslations: [Translation]
    let selectedTranslations: [String]
    let onSelect: (String) -> Void

    private var unselectedTranslations: [Translation] {
        availableTranslations.filter { !selectedTranslations.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                if unselectedTranslations.isEmpty {
                    Text("All available translations are already shown.")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.secondaryText)
                } else {
                    ForEach(unselectedTranslations) { translation in
                        Button {
                            onSelect(translation.id)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(translation.name)
                                    .font(Typography.UI.body)
                                    .foregroundStyle(Color.primaryText)

                                Text(translation.abbreviation)
                                    .font(Typography.UI.caption1)
                                    .foregroundStyle(Color.secondaryText)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TranslationComparisonView(verseRange: .genesis1_1)
        .environment(BibleService.shared)
}
