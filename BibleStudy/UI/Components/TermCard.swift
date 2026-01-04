import SwiftUI

// MARK: - Term Card
// Displays a Hebrew/Greek word with linguistic information
// Phase 3: Enhanced with plain English morphology

struct TermCard: View {
    let token: LanguageTokenDisplay
    var onTap: (() -> Void)?
    var onExplain: (() async -> String)?

    @State private var isExpanded = false
    @State private var showTechnicalDetails = false
    @State private var isLoadingExplanation = false
    @State private var explanation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header Row: Original word + Language badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    // Original word in Hebrew/Greek
                    Text(token.surface)
                        .font(token.language == "hebrew" ?
                              Typography.Language.hebrew :
                              Typography.Language.greek)
                        .foregroundStyle(Color.primaryText)

                    // Transliteration
                    Text(token.transliteration)
                        .font(Typography.Language.transliteration)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                // Language and Part of Speech badges
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
                    LanguageBadge(language: token.language)
                    if !token.partOfSpeech.isEmpty {
                        PartOfSpeechBadge(partOfSpeech: token.partOfSpeech)
                    }
                }
            }

            // Gloss (English meaning) - prominent display
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "equal.circle")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.accentGold)
                Text(token.gloss)
                    .font(Typography.Language.gloss)
                    .foregroundStyle(Color.accentGold)
            }

            // Plain English Morphology - the main feature
            if !token.plainEnglishMorph.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(token.plainEnglishMorph)
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.primaryText)
                }
            }

            // Grammatical Significance - "Why it matters"
            if !token.grammaticalSignificance.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "lightbulb")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.info)
                        Text("Why it matters")
                            .font(Typography.UI.warmSubheadline)
                            .foregroundStyle(Color.info)
                    }
                    Text(token.grammaticalSignificance)
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(AppTheme.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color.info.opacity(AppTheme.Opacity.faint))
                )
            }

            // Lemma and Strong's Number row
            HStack(spacing: AppTheme.Spacing.sm) {
                LemmaChip(lemma: token.lemma)
                if let strongsNum = token.strongsNumber, !strongsNum.isEmpty {
                    StrongsChip(number: strongsNum)
                }
            }

            // Technical details (collapsible)
            if !token.morph.isEmpty {
                Button {
                    withAnimation(AppTheme.Animation.quick) {
                        showTechnicalDetails.toggle()
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: showTechnicalDetails ? "chevron.up" : "chevron.down")
                            .font(Typography.UI.caption2)
                        Text("Technical details")
                            .font(Typography.UI.caption2)
                    }
                    .foregroundStyle(Color.tertiaryText)
                }
                .buttonStyle(.plain)

                if showTechnicalDetails {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Text("Morphology code:")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.tertiaryText)
                            Text(token.morph)
                                .font(Typography.UI.caption2)
                                .fontDesign(.monospaced)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                    .padding(AppTheme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(Color.surfaceBackground)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // AI Explanation (if loaded)
            if let explanation = explanation {
                Divider()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "sparkles")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.accentGold)
                        Text("In Context")
                            .font(Typography.UI.caption1Bold)
                            .foregroundStyle(Color.accentGold)
                    }

                    Text(explanation)
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.secondaryText)
                }
            }

            // Explain button
            if let onExplain = onExplain, explanation == nil {
                Button {
                    Task {
                        isLoadingExplanation = true
                        explanation = await onExplain()
                        isLoadingExplanation = false
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        if isLoadingExplanation {
                            ProgressView()
                                .scaleEffect(AppTheme.Scale.small)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Explain in context")
                    }
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.accentGold)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        Capsule()
                            .stroke(Color.accentGold.opacity(AppTheme.Opacity.heavy), lineWidth: AppTheme.Border.thin)
                    )
                }
                .disabled(isLoadingExplanation)
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Language Badge
struct LanguageBadge: View {
    let language: String

    var displayText: String {
        language == "hebrew" ? "Hebrew" : "Greek"
    }

    var color: Color {
        language == "hebrew" ? Color.accentGold : Color.accentBlue
    }

    var body: some View {
        Text(displayText)
            .font(Typography.UI.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(color.opacity(AppTheme.Opacity.light))
            )
    }
}

// MARK: - Part of Speech Badge
struct PartOfSpeechBadge: View {
    let partOfSpeech: String

    var body: some View {
        Text(partOfSpeech)
            .font(Typography.UI.caption2)
            .foregroundStyle(Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
    }
}

// MARK: - Lemma Chip
struct LemmaChip: View {
    let lemma: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Text("Root:")
                .foregroundStyle(Color.tertiaryText)
            Text(lemma)
                .foregroundStyle(Color.secondaryText)
        }
        .font(Typography.UI.caption2)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Strong's Number Chip
struct StrongsChip: View {
    let number: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: "number")
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)
            Text(number)
                .foregroundStyle(Color.secondaryText)
        }
        .font(Typography.UI.caption2)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(
            Capsule()
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Morphology Chip (kept for backward compatibility)
struct MorphologyChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typography.UI.caption2)
            .foregroundStyle(Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
    }
}

// MARK: - Preview
#Preview("Hebrew Verb - Jussive") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.lg) {
            TermCard(
                token: LanguageTokenDisplay(
                    id: "1",
                    surface: "יְהִי",
                    transliteration: "yehi",
                    lemma: "הָיָה",
                    gloss: "let there be",
                    morph: "V-Qal-Jussive-3ms",
                    language: "hebrew",
                    strongsNumber: "H1961",
                    partOfSpeech: "Verb",
                    plainEnglishMorph: "Command form ('let it be'), third person singular",
                    grammaticalSignificance: "Expresses a divine command—something that should happen. The jussive form shows God's sovereign authority."
                )
            ) {
                print("Tapped")
            } onExplain: {
                return "This jussive form expresses divine decree. God doesn't ask for light to appear—He commands it into existence. The same grammatical form is used throughout Genesis 1 to show God's effortless, sovereign creation."
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}

#Preview("Greek Noun") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.lg) {
            TermCard(
                token: LanguageTokenDisplay(
                    id: "2",
                    surface: "λόγος",
                    transliteration: "logos",
                    lemma: "λόγος",
                    gloss: "word, reason, logic",
                    morph: "N-NSM",
                    language: "greek",
                    strongsNumber: "G3056",
                    partOfSpeech: "Noun",
                    plainEnglishMorph: "Subject of the sentence, masculine singular",
                    grammaticalSignificance: "This is the main subject—the one doing or being something in this clause."
                )
            )
        }
        .padding()
    }
    .background(Color.appBackground)
}

#Preview("Minimal Token") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.lg) {
            TermCard(
                token: LanguageTokenDisplay(
                    id: "3",
                    surface: "אוֹר",
                    transliteration: "'or",
                    lemma: "אוֹר",
                    gloss: "light",
                    morph: "N-ms",
                    language: "hebrew"
                )
            )
        }
        .padding()
    }
    .background(Color.appBackground)
}
