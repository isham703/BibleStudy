import SwiftUI

// MARK: - Animated Ask Input Bar
// Expandable input bar that morphs between collapsed and expanded states
// Adapted from CustomBottomBar reference with BibleStudy theming

struct AnimatedAskInputBar<LeadingAction: View, TrailingAction: View, MainAction: View>: View {
    var highlightWhenEmpty: Bool = true
    var hint: String
    var tint: Color = Color("AccentBronze")  // Same in both modes
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    @ViewBuilder var leadingAction: () -> LeadingAction
    @ViewBuilder var trailingAction: () -> TrailingAction
    @ViewBuilder var mainAction: () -> MainAction
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - View State

    @State private var isHighlighting: Bool = false
    private let slideOffset: CGFloat = 20

    private var respectsReducedMotion: Bool {
        reduceMotion
    }

    var body: some View {
        let mainLayout = isFocused
            ? AnyLayout(ZStackLayout(alignment: .bottomTrailing))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: Theme.Spacing.sm))
        let shape = RoundedRectangle(cornerRadius: isFocused ? Theme.Radius.card : Theme.Radius.button)

        ZStack {
            mainLayout {
                let subLayout = isFocused
                    ? AnyLayout(VStackLayout(alignment: .trailing, spacing: Theme.Spacing.lg))
                    : AnyLayout(ZStackLayout(alignment: .trailing))

                subLayout {
                    // Text Field
                    TextField(hint, text: $text, axis: .vertical)
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(isFocused ? 5 : 1)
                        .focused(_isFocused)
                        .mask {
                            Rectangle()
                                .padding(.trailing, isFocused ? 0 : 48)
                        }

                    // Trailing & Leading Action View
                    HStack(spacing: Theme.Spacing.sm) {
                        // Leading Actions
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(subviews: leadingAction()) { subview in
                                subview
                                    .frame(width: 32, height: 32)
                                    .contentShape(.rect)
                            }
                        }
                        .compositingGroup()
                        .allowsHitTesting(isFocused)
                        .blur(radius: isFocused ? 0 : 4)
                        .opacity(isFocused ? 1 : 0)

                        Spacer(minLength: 0)

                        // Trailing Action (single button)
                        trailingAction()
                            .frame(width: 32, height: 32)
                            .contentShape(.rect)
                    }
                }
                .frame(height: isFocused ? nil : 44)
                .padding(.leading, Theme.Spacing.md)
                .padding(.trailing, isFocused ? Theme.Spacing.md : Theme.Spacing.sm)
                .padding(.bottom, isFocused ? Theme.Spacing.sm : 0)
                .padding(.top, isFocused ? Theme.Spacing.lg : 0)
                .background {
                    ZStack {
                        highlightingBackgroundView

                        shape
                            .fill(.bar)
                            .shadow(
                                color: Color("AccentBronze").opacity(Theme.Opacity.subtle),
                                radius: 4,
                                x: 0,
                                y: 4
                            )
                            .shadow(
                                color: .black.opacity(Theme.Opacity.subtle),
                                radius: 16,
                                x: 0,
                                y: -4
                            )
                    }
                }

                // Main Action Button (slides off when focused)
                mainAction()
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    .clipShape(.circle)
                    .background {
                        Circle()
                            .fill(.bar)
                            .shadow(
                                color: Color("AccentBronze").opacity(Theme.Opacity.subtle),
                                radius: 4,
                                x: 0,
                                y: 4
                            )
                            .shadow(
                                color: .black.opacity(Theme.Opacity.subtle),
                                radius: 16,
                                x: 0,
                                y: -4
                            )
                    }
                    .visualEffect { [isFocused] content, proxy in
                        content
                            .offset(x: isFocused ? (proxy.size.width + slideOffset) : 0)
                    }
            }
        }
        .geometryGroup()
        .animation(
            respectsReducedMotion ? .none : Theme.Animation.fade,
            value: isFocused
        )
    }

    // MARK: - Highlighting Background

    @ViewBuilder
    private var highlightingBackgroundView: some View {
        let highlightShape = RoundedRectangle(cornerRadius: isFocused ? Theme.Radius.card : Theme.Radius.button)

        if !isFocused && text.isEmpty && highlightWhenEmpty && !respectsReducedMotion {
            highlightShape
                .stroke(
                    tint.gradient,
                    style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .mask {
                    let clearColors: [Color] = Array(repeating: .clear, count: 3)

                    highlightShape
                        .fill(AngularGradient(
                            colors: clearColors + [Color.white] + clearColors,
                            center: .center,
                            angle: .init(degrees: isHighlighting ? 360 : 0)
                        ))
                }
                .padding(-8)
                .blur(radius: 8)
                .onAppear {
                    withAnimation(Theme.Animation.fade) {
                        isHighlighting = true
                    }
                }
                .onDisappear {
                    isHighlighting = false
                }
                .transition(.blurReplace)
        }
    }

}

// MARK: - Blur Fade Extension

extension View {
    @ViewBuilder
    func blurFade(_ status: Bool) -> some View {
        self
            .compositingGroup()
            .blur(radius: status ? 0 : 16)
            .opacity(status ? 1 : 0)
    }
}

// MARK: - Ask Animated Input Bar
// Pre-configured animated input bar for the Ask chat with all action buttons

struct AskAnimatedInputBar: View {
    @Binding var text: String
    var isLoading: Bool = false
    var isFocused: FocusState<Bool>.Binding
    var anchorRange: VerseRange?
    let onSend: () -> Void
    let onVersePicker: () -> Void
    let onSearch: () -> Void
    var onClearAnchor: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let fillColor = Color.gray.opacity(Theme.Opacity.selectionBackground)

    private var respectsReducedMotion: Bool {
        reduceMotion
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Anchor chip (shown when verse is anchored)
            if let anchor = anchorRange {
                anchorChip(for: anchor)
                    .transition(
                        respectsReducedMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.9)).animation(Theme.Animation.settle),
                                removal: .opacity.combined(with: .scale(scale: 0.9)).animation(Theme.Animation.fade)
                            )
                    )
            }

            // Main input bar
            AnimatedAskInputBar(
                hint: anchorRange != nil ? "Ask about this passage..." : "Ask a question...",
                text: $text,
                isFocused: isFocused
            ) {
                // Leading Actions (verse, search, attach)
                leadingActionButtons
            } trailingAction: {
                // Morphing mic ↔ checkmark
                trailingActionButton
            } mainAction: {
                // Golden send button
                sendButton
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
        .animation(respectsReducedMotion ? .none : Theme.Animation.fade, value: anchorRange != nil)
    }

    // MARK: - Anchor Chip

    @ViewBuilder
    private func anchorChip(for anchor: VerseRange) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            // Bookmark icon
            Image(systemName: "bookmark.fill")
                .font(Typography.Command.meta)
                .foregroundStyle(Color("AccentBronze"))

            // Reference text
            Text(anchor.shortReference)
                .font(Typography.Command.caption.weight(.medium))
                .foregroundStyle(Color("AppTextPrimary"))

            // Tap to change indicator
            Button {
                HapticService.shared.lightTap()
                onVersePicker()
            } label: {
                Image(systemName: "chevron.down")
                    .font(Typography.Icon.xxxs)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .accessibilityLabel("Change passage")
            .accessibilityHint("Opens verse picker to change anchored passage")

            Spacer()

            // Clear button
            Button {
                HapticService.shared.lightTap()
                onClearAnchor?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .accessibilityLabel("Clear anchor")
            .accessibilityHint("Removes the verse anchor and returns to general mode")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            Capsule()
                .fill(.bar)
                .shadow(
                    color: Color("AccentBronze").opacity(Theme.Opacity.subtle),
                    radius: 4,
                    x: 0,
                    y: 2
                )
                .shadow(
                    color: .black.opacity(Theme.Opacity.subtle),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .overlay {
            Capsule()
                .strokeBorder(Color("AccentBronze").opacity(Theme.Opacity.textSecondary), lineWidth: Theme.Stroke.hairline)
        }
    }

    // MARK: - Leading Action Buttons

    @ViewBuilder
    private var leadingActionButtons: some View {
        // Verse picker button
        Button {
            HapticService.shared.lightTap()
            onVersePicker()
        } label: {
            Image(systemName: "book.closed")
                .fontWeight(.medium)
                .foregroundStyle(Color("AccentBronze"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(fillColor, in: .circle)
        }
        .accessibilityLabel("Select verse")
        .accessibilityHint("Opens verse picker to anchor your question to a passage")

        // Search button
        Button {
            HapticService.shared.lightTap()
            onSearch()
        } label: {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color("AppTextPrimary"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(fillColor, in: .circle)
        }
        .accessibilityLabel("Search Bible")
        .accessibilityHint("Quick search in the Bible")
    }

    // MARK: - Trailing Action Button

    private var trailingActionButton: some View {
        Button {
            if isFocused.wrappedValue {
                // Keyboard opened - dismiss it
                HapticService.shared.lightTap()
                isFocused.wrappedValue = false
            } else {
                // Mic action (future)
                HapticService.shared.lightTap()
                print("Mic action - voice input future feature")
            }
        } label: {
            ZStack {
                // Checkmark (shown when focused)
                Image(systemName: "checkmark")
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("AccentBronze").gradient, in: .circle)
                    .blurFade(isFocused.wrappedValue)

                // Mic (shown when not focused)
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(fillColor, in: .circle)
                    .blurFade(!isFocused.wrappedValue)
            }
        }
        .accessibilityLabel(isFocused.wrappedValue ? "Done" : "Voice input")
        .accessibilityHint(isFocused.wrappedValue ? "Dismisses keyboard" : "Use voice to ask a question")
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            guard !text.isEmpty && !isLoading else { return }
            HapticService.shared.divineReveal()
            onSend()
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color("AccentBronze"))
                } else {
                    Image(systemName: "sparkles")
                        .font(Typography.Command.body)
                        .foregroundStyle(
                            text.isEmpty
                                ? Color("TertiaryText")
                                : Color("AccentBronze")
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .disabled(text.isEmpty || isLoading)
        .accessibilityLabel("Send")
        .accessibilityHint(text.isEmpty ? "Type a question first" : "Sends your question to the AI")
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()
                AskAnimatedInputBar(
                    text: $text,
                    isFocused: $isFocused,
                    onSend: {},
                    onVersePicker: {},
                    onSearch: {},
                    onClearAnchor: {}
                )
            }
            .background(Color("AppBackground"))
        }
    }
    return PreviewWrapper()
}

#Preview("Expanded") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()
                AskAnimatedInputBar(
                    text: $text,
                    isFocused: $isFocused,
                    onSend: {},
                    onVersePicker: {},
                    onSearch: {},
                    onClearAnchor: {}
                )
            }
            .background(Color("AppBackground"))
            .onAppear {
                isFocused = true
            }
        }
    }
    return PreviewWrapper()
}

#Preview("With Anchor") {
    struct PreviewWrapper: View {
        @State private var text = ""
        @State private var anchor: VerseRange? = VerseRange.john3_16
        @FocusState private var isFocused: Bool

        var body: some View {
            VStack {
                Spacer()
                AskAnimatedInputBar(
                    text: $text,
                    isFocused: $isFocused,
                    anchorRange: anchor,
                    onSend: {},
                    onVersePicker: {},
                    onSearch: {},
                    onClearAnchor: { anchor = nil }
                )
            }
            .background(Color("AppBackground"))
        }
    }
    return PreviewWrapper()
}
