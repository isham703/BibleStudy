import SwiftUI

// MARK: - Segment Content View
// Displays the content of a single story segment

struct SegmentContentView: View {
    let segment: StorySegment
    let onVerseAnchorTap: ((VerseRange) -> Void)?
    var existingReflection: String?
    var onSaveReflection: ((String) -> Void)?

    @State private var showReflection = false
    @State private var reflectionText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Segment header
                segmentHeader

                // Location badge
                if let location = segment.location {
                    LocationBadge(location: location)
                }

                // Main narrative content
                narrativeContent

                // Key term highlight
                if let keyTerm = segment.keyTerm {
                    KeyTermCard(keyTerm: keyTerm)
                }

                // Verse anchor button
                if let verseAnchor = segment.verseAnchor {
                    VerseAnchorButton(
                        verseRange: verseAnchor,
                        onTap: { onVerseAnchorTap?(verseAnchor) }
                    )
                }

                // Reflection question
                if let question = segment.reflectionQuestion {
                    ReflectionCard(
                        question: question,
                        isExpanded: $showReflection,
                        reflectionText: $reflectionText,
                        onSave: {
                            onSaveReflection?(reflectionText)
                        }
                    )
                }

                Spacer(minLength: AppTheme.Spacing.xxxl)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .onAppear {
            reflectionText = existingReflection ?? ""
        }
    }

    // MARK: - Segment Header
    private var segmentHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Timeline label
            if let label = segment.timelineLabel {
                Text(label)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.accentGold)
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Title with mood indicator
            HStack(spacing: AppTheme.Spacing.sm) {
                if let mood = segment.mood {
                    Image(systemName: mood.icon)
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color(mood.accentColorName))
                }

                Text(segment.title)
                    .font(Typography.Scripture.title)
                    .foregroundStyle(Color.primaryText)
            }
        }
    }

    // MARK: - Narrative Content
    private var narrativeContent: some View {
        Text(segment.content)
            .font(Typography.Scripture.body(size: 18))
            .foregroundStyle(Color.primaryText)
            .lineSpacing(8)
            .textSelection(.enabled)
    }
}

// MARK: - Location Badge
struct LocationBadge: View {
    let location: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "mappin.circle.fill")
                .font(Typography.UI.caption1)
            Text(location)
                .font(Typography.UI.caption1)
        }
        .foregroundStyle(Color.secondaryText)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(Color.surfaceBackground)
        )
    }
}

// MARK: - Key Term Card
struct KeyTermCard: View {
    let keyTerm: KeyTermHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "character.book.closed")
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.accentGold)
                Text("Key Term")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.secondaryText)
            }

            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(keyTerm.term)
                        .font(Typography.Display.headline)
                        .foregroundStyle(Color.primaryText)

                    if let original = keyTerm.originalWord {
                        Text(original)
                            .font(Typography.Language.transliteration)
                            .foregroundStyle(Color.accentGold)
                    }
                }

                Spacer()

                Text(keyTerm.briefMeaning)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.accentGold.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Verse Anchor Button
struct VerseAnchorButton: View {
    let verseRange: VerseRange
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "book.closed.fill")
                    .font(Typography.UI.subheadline)

                Text("Read Scripture: \(verseRange.shortReference)")
                    .font(Typography.UI.subheadline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.caption1)
            }
            .foregroundStyle(Color.accentGold)
            .padding(AppTheme.Spacing.md)
            .background(Color.accentGold.opacity(AppTheme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reflection Card
struct ReflectionCard: View {
    let question: String
    @Binding var isExpanded: Bool
    @Binding var reflectionText: String
    let onSave: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(AppTheme.Animation.standard) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.accentRose)

                    Text("Reflection")
                        .font(Typography.UI.caption1Bold)
                        .foregroundStyle(Color.secondaryText)

                    if !reflectionText.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.highlightGreen)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(question)
                    .font(Typography.UI.warmBody)
                    .foregroundStyle(Color.primaryText)
                    .italic()
                    .padding(.top, AppTheme.Spacing.xs)

                // Reflection text input
                TextField("Write your reflection...", text: $reflectionText, axis: .vertical)
                    .font(Typography.UI.body)
                    .lineLimit(3...8)
                    .textFieldStyle(.plain)
                    .padding(AppTheme.Spacing.sm)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    .focused($isFocused)

                // Save button
                if !reflectionText.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            isFocused = false
                            onSave()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "checkmark")
                                    .font(Typography.UI.caption1)
                                Text("Save")
                                    .font(Typography.UI.caption1Bold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(Color.accentRose)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.accentRose.opacity(AppTheme.Opacity.faint))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
}

// MARK: - Preview
#Preview {
    SegmentContentView(
        segment: StorySegment(
            storyId: UUID(),
            order: 1,
            title: "In the Beginning",
            content: "Before time itself began, before the first ray of light pierced the void, there was God. The universe lay formless and empty, a vast expanse of darkness hovering over the deep waters. The Spirit of God moved across this primordial canvas, pregnant with possibility.\n\nThen God spoke. His voice, the first sound to ever echo through existence, called forth light itself: \"Let there be light.\" And there was light—brilliant, pure, and good. God separated this new radiance from the darkness, calling one Day and the other Night. Thus ended the first day, with evening and morning marking the rhythm that would govern all of creation.",
            verseAnchor: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 5),
            timelineLabel: "Day 1",
            location: "The Formless Void",
            mood: .peaceful,
            reflectionQuestion: "What does it mean that God's first creative act was to bring light into darkness?",
            keyTerm: KeyTermHighlight(
                term: "light",
                originalWord: "אוֹר (or)",
                briefMeaning: "Physical light, but also symbolizing God's presence and truth"
            )
        ),
        onVerseAnchorTap: nil
    )
    .background(Color.appBackground)
}
