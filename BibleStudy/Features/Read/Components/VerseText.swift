import SwiftUI

// MARK: - Selection Position Preference Key
// Used to track the Y position of selected verses for dynamic toolbar positioning

struct SelectionPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        // Keep the first (topmost) selected verse position
        if let next = nextValue() {
            if let current = value {
                value = min(current, next)
            } else {
                value = next
            }
        }
    }
}

// MARK: - Selection Bounds Preference Key
// Used to track the full bounds of selected verses for floating context menu positioning
// Reports CGRect in global coordinate space for precise menu placement

struct SelectionBoundsPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        // Union all selected verse bounds to encompass the full selection
        if let next = nextValue() {
            if let current = value {
                value = current.union(next)
            } else {
                value = next
            }
        }
    }
}

// MARK: - Visible Verse Preference Key
// Tracks the topmost visible verse number for progress indication

struct VisibleVersePreferenceKey: PreferenceKey {
    static var defaultValue: Int? = nil

    static func reduce(value: inout Int?, nextValue: () -> Int?) {
        // Keep the smallest (topmost) verse number
        if let next = nextValue() {
            if let current = value {
                value = min(current, next)
            } else {
                value = next
            }
        }
    }
}

// MARK: - Verse Text
// Displays a single verse with selection support

struct VerseText: View {
    let verse: Verse
    let isSelected: Bool
    let fontSize: ScriptureFontSize
    let lineSpacing: CGFloat
    let onTap: () -> Void
    let onLongPress: () -> Void
    // Double-tap for instant insight access (optional, defaults to nil)
    var onDoubleTap: (() -> Void)?
    // Optional accessibility action callbacks
    var onCopy: (() -> Void)?
    var onHighlight: (() -> Void)?
    var onStudy: (() -> Void)?
    // Audio playback state
    var isPlayingAudio: Bool = false
    // Preserved highlight state (fading gold highlight after insight sheet dismiss)
    var preservedHighlightOpacity: Double = 0
    // Persistent highlight color (user-created highlight from database)
    // When set, displays background color matching user's chosen highlight color
    var highlightColor: HighlightColor? = nil

    // MARK: - Enhanced Selection Feedback State
    @State private var isPressed = false
    @State private var showShimmer = false
    @State private var shimmerPhase: CGFloat = -0.3  // Start position for shimmer wave
    @State private var scaleOvershoot = false
    @State private var showPressGlow = false

    // Scale verse number width with Dynamic Type
    @ScaledMetric(relativeTo: .caption) private var verseNumberWidth: CGFloat = 24

    // MARK: - Animation Constants
    private let pressScale: CGFloat = 0.96
    private let overshootScale: CGFloat = 1.02
    private let normalScale: CGFloat = 1.0

    /// Background color based on state priority system
    ///
    /// Priority order (highest to lowest):
    /// 1. Selection - Interactive UI state (indigo background with border)
    /// 2. Audio playback - Current verse being read aloud (indigo glow)
    /// 3. Preserved highlight - Fading context after insight dismiss (temporary indigo fade)
    /// 4. Saved highlight - User's persistent annotation (colored background)
    /// 5. Clear - Default state (no background)
    ///
    /// Rationale: Temporary interactive states take precedence over persistent user data
    /// to provide immediate visual feedback. Persistent highlights remain visible when
    /// no interactive state is active, ensuring they're always accessible during reading.
    private var backgroundColor: Color {
        // Priority 1: Selection state (temporary interactive UI)
        if isSelected {
            return Color.selectedBackground
        }
        // Priority 2: Audio playback state (temporary dynamic activity)
        else if isPlayingAudio {
            return Color.Semantic.accent.opacity(AppTheme.Opacity.light)
        }
        // Priority 3: Preserved highlight (temporary fading context)
        else if preservedHighlightOpacity > 0 {
            // Fading indigo highlight for context preservation after insight sheet dismiss
            return Color.scholarIndigoSubtle.opacity(preservedHighlightOpacity)
        }
        // Priority 4: Saved highlight (persistent user annotation)
        // This is the key fix - highlights now display when no temporary state is active
        else if let highlightColor = highlightColor {
            return highlightColor.color  // Uses asset catalog color with proper light/dark mode support
        }
        // Priority 5: Default (no background)
        else {
            return Color.clear
        }
    }

    /// Current scale based on press state and overshoot animation
    private var currentScale: CGFloat {
        if isPressed {
            return pressScale
        } else if scaleOvershoot {
            return overshootScale
        } else {
            return normalScale
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
            // Verse Number (scales with Dynamic Type)
            Text("\(verse.verse)")
                .font(Typography.Scripture.verseNumber)
                .foregroundStyle(Color.verseNumber)
                .frame(minWidth: verseNumberWidth, alignment: .trailing)

            // Verse Text
            Text(verse.text)
                .font(Typography.Scripture.bodyWithSize(fontSize))
                .foregroundStyle(Color.primaryText)
                .lineSpacing(lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(backgroundColor)
        )
        // MARK: - Press Glow Effect (gold inner glow on press)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(Color.divineGold.opacity(showPressGlow ? AppTheme.Opacity.subtle : 0))
                .animation(AppTheme.Animation.quick, value: showPressGlow)
        )
        // MARK: - Gold Shimmer Wave Effect (on tap release)
        .overlay(
            GeometryReader { _ in
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color.divineGold.opacity(AppTheme.Opacity.medium + 0.05), location: 0.4),
                        .init(color: Color.illuminatedGold.opacity(AppTheme.Opacity.heavy), location: 0.5),
                        .init(color: Color.divineGold.opacity(AppTheme.Opacity.medium + 0.05), location: 0.6),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: UnitPoint(x: shimmerPhase - 0.3, y: 0),
                    endPoint: UnitPoint(x: shimmerPhase + 0.3, y: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                .opacity(showShimmer ? 1 : 0)
                .allowsHitTesting(false)
            }
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: SelectionPositionPreferenceKey.self,
                        value: isSelected ? geometry.frame(in: .global).midY : nil
                    )
                    .preference(
                        key: SelectionBoundsPreferenceKey.self,
                        value: isSelected ? geometry.frame(in: .global) : nil
                    )
            }
        )
        .contentShape(Rectangle())
        // MARK: - Double-Tap Gesture (higher priority for instant insights)
        .onTapGesture(count: 2) {
            if let doubleTapAction = onDoubleTap {
                triggerSelectionFeedback()
                HapticService.shared.mediumTap()
                doubleTapAction()
            }
        }
        // MARK: - Single-Tap Gesture (select verse)
        .onTapGesture(count: 1) {
            triggerSelectionFeedback()
            onTap()
        }
        .onLongPressGesture(minimumDuration: AppTheme.Gesture.longPressDuration) {
            onLongPress()
        } onPressingChanged: { pressing in
            handlePressStateChange(pressing)
        }
        .scaleEffect(currentScale)
        .animation(AppTheme.Animation.spring, value: currentScale)
        .animation(AppTheme.Animation.quick, value: isSelected)
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(buildAccessibilityLabel())
        .accessibilityHint(buildAccessibilityHint())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityCustomContent("Verse Number", "\(verse.verse)")
        .accessibilityAction(named: "Select") {
            onTap()
        }
        .accessibilityAction(named: "Start Range Selection") {
            onLongPress()
        }
        .modifier(ConditionalAccessibilityActions(
            onCopy: onCopy,
            onHighlight: onHighlight,
            onStudy: onStudy
        ))
    }

    // MARK: - Accessibility Helpers

    /// Builds comprehensive accessibility label including verse number, text, and highlight state
    private func buildAccessibilityLabel() -> String {
        var label = "Verse \(verse.verse). \(verse.text)"

        // Add highlight information if verse is highlighted
        if let color = highlightColor {
            label += ". Highlighted with \(color.accessibilityName)"
        }

        return label
    }

    /// Builds context-appropriate accessibility hint based on current state
    private func buildAccessibilityHint() -> String {
        if isSelected {
            return "Selected. Double tap to deselect."
        } else if highlightColor != nil {
            return "This verse is highlighted. Double tap to select. Double tap and hold to start range selection."
        } else {
            return "Double tap to select. Double tap and hold to start range selection."
        }
    }

    // MARK: - Enhanced Selection Feedback Methods

    /// Handles press state changes with glow effect
    private func handlePressStateChange(_ pressing: Bool) {
        if pressing {
            // Press down: show glow and scale down
            withAnimation(AppTheme.Animation.quick) {
                isPressed = true
                showPressGlow = true
            }
        } else {
            // Release: trigger overshoot animation sequence
            withAnimation(AppTheme.Animation.celebrationBounce) {
                isPressed = false
                scaleOvershoot = true
                showPressGlow = false
            }

            // Settle back to normal scale
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(AppTheme.Animation.spring) {
                    scaleOvershoot = false
                }
            }
        }
    }

    /// Triggers the gold shimmer wave effect on tap
    /// A diagonal gradient sweeps across the verse like gold leaf catching light
    private func triggerSelectionFeedback() {
        // Reset shimmer to starting position
        shimmerPhase = -0.3
        showShimmer = true

        // Animate shimmer wave sweeping diagonally across the verse
        withAnimation(AppTheme.Animation.slow) {
            shimmerPhase = 1.3
        }

        // Hide shimmer after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showShimmer = false
            shimmerPhase = -0.3
        }

        // Haptic feedback (light tap for selection)
        HapticService.shared.lightTap()
    }
}

// MARK: - Conditional Accessibility Actions
// Adds accessibility actions only when callbacks are provided
struct ConditionalAccessibilityActions: ViewModifier {
    let onCopy: (() -> Void)?
    let onHighlight: (() -> Void)?
    let onStudy: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .modifier(CopyActionModifier(action: onCopy))
            .modifier(HighlightActionModifier(action: onHighlight))
            .modifier(StudyActionModifier(action: onStudy))
    }
}

struct CopyActionModifier: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action = action {
            content.accessibilityAction(named: "Copy") { action() }
        } else {
            content
        }
    }
}

struct HighlightActionModifier: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action = action {
            content.accessibilityAction(named: "Highlight") { action() }
        } else {
            content
        }
    }
}

struct StudyActionModifier: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        if let action = action {
            content.accessibilityAction(named: "Study") { action() }
        } else {
            content
        }
    }
}

// MARK: - Verse Block (Multiple Verses)
struct VerseBlock: View {
    let verses: [Verse]
    let selectedVerses: Set<Int>
    let fontSize: ScriptureFontSize
    let lineSpacing: CGFloat
    let onSelectVerse: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(verses) { verse in
                VerseText(
                    verse: verse,
                    isSelected: selectedVerses.contains(verse.verse),
                    fontSize: fontSize,
                    lineSpacing: lineSpacing,
                    onTap: { onSelectVerse(verse.verse) },
                    onLongPress: { onSelectVerse(verse.verse) }
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        VerseText(
            verse: Verse(bookId: 1, chapter: 1, verse: 1, text: "In the beginning God created the heaven and the earth."),
            isSelected: false,
            fontSize: .medium,
            lineSpacing: LineSpacing.normal.value,
            onTap: {},
            onLongPress: {}
        )

        VerseText(
            verse: Verse(bookId: 1, chapter: 1, verse: 2, text: "And the earth was without form, and void; and darkness was upon the face of the deep."),
            isSelected: true,
            fontSize: .medium,
            lineSpacing: LineSpacing.normal.value,
            onTap: {},
            onLongPress: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}

// MARK: - Paragraph Mode View
// Displays verses as continuous prose with superscript verse numbers

struct ParagraphModeView: View {
    let verses: [Verse]
    let selectedVerses: Set<Int>
    let fontSize: ScriptureFontSize
    let lineSpacing: CGFloat
    let onSelectVerse: (Int) -> Void
    /// Closure to retrieve highlight color for a given verse number
    /// Returns nil if verse is not highlighted
    let getHighlightColor: (Int) -> HighlightColor?

    var body: some View {
        // Build attributed text with all verses
        Text(buildAttributedText())
            .font(Typography.Scripture.bodyWithSize(fontSize))
            .foregroundStyle(Color.primaryText)
            .lineSpacing(lineSpacing)
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.md)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(buildAccessibilityLabel())
    }

    private func buildAttributedText() -> AttributedString {
        var result = AttributedString()

        for (index, verse) in verses.enumerated() {
            // Superscript verse number
            var verseNumber = AttributedString("\(verse.verse)")
            verseNumber.font = Typography.UI.caption2
            verseNumber.foregroundColor = Color.verseNumber
            verseNumber.baselineOffset = 4

            result.append(verseNumber)
            result.append(AttributedString(" "))

            // Verse text with background color based on state priority
            var verseText = AttributedString(verse.text)

            // Priority 1: Selection state (interactive UI)
            if selectedVerses.contains(verse.verse) {
                verseText.backgroundColor = Color.selectedBackground
            }
            // Priority 2: Saved highlight (persistent user annotation)
            else if let highlightColor = getHighlightColor(verse.verse) {
                verseText.backgroundColor = highlightColor.color
            }
            // Note: Audio playback and preserved highlights not supported in paragraph mode
            // as it's unclear which word in the flowing text should be highlighted

            result.append(verseText)

            // Add space between verses (except last)
            if index < verses.count - 1 {
                result.append(AttributedString(" "))
            }
        }

        return result
    }

    private func buildAccessibilityLabel() -> String {
        verses.map { "Verse \($0.verse). \($0.text)" }.joined(separator: " ")
    }
}
