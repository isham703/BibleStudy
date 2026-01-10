import SwiftUI

// MARK: - Segment Content View
// Displays the content of a single story segment

struct SegmentContentView: View {
    let segment: StorySegment
    let onVerseAnchorTap: ((VerseRange) -> Void)?
    var existingReflection: String?
    var onSaveReflection: ((String) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var showReflection = false
    @State private var reflectionText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
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

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            reflectionText = existingReflection ?? ""
        }
    }

    // MARK: - Segment Header
    private var segmentHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Timeline label
            if let label = segment.timelineLabel {
                Text(label)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .textCase(.uppercase)
                    .tracking(1)
            }

            // Title with mood indicator
            HStack(spacing: Theme.Spacing.sm) {
                if let mood = segment.mood {
                    Image(systemName: mood.icon)
                        .font(Typography.Command.subheadline)
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
            .font(Typography.Scripture.body)
            .foregroundStyle(Color.primaryText)
            .lineSpacing(8)
            .textSelection(.enabled)
    }
}

// MARK: - Location Badge
struct LocationBadge: View {
    let location: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "mappin.circle.fill")
                .font(Typography.Command.caption)
            Text(location)
                .font(Typography.Command.caption)
        }
        .foregroundStyle(Color.secondaryText)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(Color.surfaceBackground)
        )
    }
}

// MARK: - Key Term Card
struct KeyTermCard: View {
    let keyTerm: KeyTermHighlight

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "character.book.closed")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                Text("Key Term")
                    .font(Typography.Command.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
            }

            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(keyTerm.term)
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.primaryText)

                    if let original = keyTerm.originalWord {
                        Text(original)
                            .font(.system(size: 15, weight: .regular, design: .serif).italic())
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    }
                }

                Spacer()

                Text(keyTerm.briefMeaning)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
        )
    }
}

// MARK: - Verse Anchor Button
struct VerseAnchorButton: View {
    let verseRange: VerseRange
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "book.closed.fill")
                    .font(Typography.Command.subheadline)

                Text("Read Scripture: \(verseRange.shortReference)")
                    .font(Typography.Command.subheadline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Command.caption)
            }
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .padding(Theme.Spacing.md)
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(Theme.Animation.settle) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color.accentRose)

                    Text("Reflection")
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)

                    if !reflectionText.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.highlightGreen)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(question)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.primaryText)
                    .italic()
                    .padding(.top, Theme.Spacing.xs)

                // Reflection text input
                TextField("Write your reflection...", text: $reflectionText, axis: .vertical)
                    .font(Typography.Command.body)
                    .lineLimit(3...8)
                    .textFieldStyle(.plain)
                    .padding(Theme.Spacing.sm)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    .focused($isFocused)

                // Save button
                if !reflectionText.isEmpty {
                    HStack {
                        Spacer()
                        Button {
                            isFocused = false
                            onSave()
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "checkmark")
                                    .font(Typography.Command.caption)
                                Text("Save")
                                    .font(Typography.Command.caption.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Color.accentRose)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color.accentRose.opacity(Theme.Opacity.faint))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
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
