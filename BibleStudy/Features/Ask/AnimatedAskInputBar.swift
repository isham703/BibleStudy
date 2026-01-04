import SwiftUI

// MARK: - Animated Ask Input Bar
// Expandable input bar that morphs between collapsed and expanded states
// Adapted from CustomBottomBar reference with BibleStudy theming

struct AnimatedAskInputBar<LeadingAction: View, TrailingAction: View, MainAction: View>: View {
    var highlightWhenEmpty: Bool = true
    var hint: String
    var tint: Color = Color.divineGold
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    @ViewBuilder var leadingAction: () -> LeadingAction
    @ViewBuilder var trailingAction: () -> TrailingAction
    @ViewBuilder var mainAction: () -> MainAction

    // MARK: - View State

    @State private var isHighlighting: Bool = false
    private let slideOffset: CGFloat = AppTheme.InputBar.slideOffset

    private var respectsReducedMotion: Bool {
        AppTheme.Animation.isReduceMotionEnabled
    }

    var body: some View {
        let mainLayout = isFocused
            ? AnyLayout(ZStackLayout(alignment: .bottomTrailing))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: AppTheme.Spacing.sm))
        let shape = RoundedRectangle(cornerRadius: isFocused ? AppTheme.InputBar.cornerRadiusFocused : AppTheme.InputBar.cornerRadius)

        ZStack {
            mainLayout {
                let subLayout = isFocused
                    ? AnyLayout(VStackLayout(alignment: .trailing, spacing: AppTheme.Spacing.lg))
                    : AnyLayout(ZStackLayout(alignment: .trailing))

                subLayout {
                    // Text Field
                    TextField(hint, text: $text, axis: .vertical)
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(isFocused ? 5 : 1)
                        .focused(_isFocused)
                        .mask {
                            Rectangle()
                                .padding(.trailing, isFocused ? 0 : AppTheme.InputBar.textFieldMaskPadding)
                        }

                    // Trailing & Leading Action View
                    HStack(spacing: AppTheme.Spacing.sm) {
                        // Leading Actions
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(subviews: leadingAction()) { subview in
                                subview
                                    .frame(width: AppTheme.InputBar.buttonSize, height: AppTheme.InputBar.buttonSize)
                                    .contentShape(.rect)
                            }
                        }
                        .compositingGroup()
                        .allowsHitTesting(isFocused)
                        .blur(radius: isFocused ? 0 : AppTheme.Blur.light)
                        .opacity(isFocused ? 1 : 0)

                        Spacer(minLength: 0)

                        // Trailing Action (single button)
                        trailingAction()
                            .frame(width: AppTheme.InputBar.buttonSize, height: AppTheme.InputBar.buttonSize)
                            .contentShape(.rect)
                    }
                }
                .frame(height: isFocused ? nil : AppTheme.InputBar.height)
                .padding(.leading, AppTheme.Spacing.md)
                .padding(.trailing, isFocused ? AppTheme.Spacing.md : AppTheme.Spacing.sm)
                .padding(.bottom, isFocused ? AppTheme.Spacing.sm : 0)
                .padding(.top, isFocused ? AppTheme.Spacing.lg : 0)
                .background {
                    ZStack {
                        highlightingBackgroundView

                        shape
                            .fill(.bar)
                            .shadow(
                                color: Color.divineGold.opacity(AppTheme.Opacity.subtle),
                                radius: AppTheme.Blur.light,
                                x: 0,
                                y: AppTheme.Blur.light
                            )
                            .shadow(
                                color: .black.opacity(AppTheme.Opacity.subtle),
                                radius: AppTheme.Blur.intense,
                                x: 0,
                                y: -AppTheme.Blur.light
                            )
                    }
                }

                // Main Action Button (slides off when focused)
                mainAction()
                    .frame(width: AppTheme.InputBar.mainButtonSize, height: AppTheme.InputBar.mainButtonSize)
                    .clipShape(.circle)
                    .background {
                        Circle()
                            .fill(.bar)
                            .shadow(
                                color: Color.divineGold.opacity(AppTheme.Opacity.subtle),
                                radius: AppTheme.Blur.light,
                                x: 0,
                                y: AppTheme.Blur.light
                            )
                            .shadow(
                                color: .black.opacity(AppTheme.Opacity.subtle),
                                radius: AppTheme.Blur.intense,
                                x: 0,
                                y: -AppTheme.Blur.light
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
            respectsReducedMotion ? .none : AppTheme.Animation.keyboardSync,
            value: isFocused
        )
    }

    // MARK: - Highlighting Background

    @ViewBuilder
    private var highlightingBackgroundView: some View {
        let highlightShape = RoundedRectangle(cornerRadius: isFocused ? AppTheme.InputBar.cornerRadiusFocused : AppTheme.InputBar.cornerRadius)

        if !isFocused && text.isEmpty && highlightWhenEmpty && !respectsReducedMotion {
            highlightShape
                .stroke(
                    tint.gradient,
                    style: .init(lineWidth: AppTheme.Border.thick, lineCap: .round, lineJoin: .round)
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
                .padding(-AppTheme.Blur.glow)
                .blur(radius: AppTheme.Blur.glow)
                .onAppear {
                    withAnimation(AppTheme.Animation.shimmerContinuous) {
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
            .blur(radius: status ? 0 : AppTheme.Blur.heavy)
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

    private let fillColor = Color.gray.opacity(AppTheme.Opacity.light)

    private var respectsReducedMotion: Bool {
        AppTheme.Animation.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Anchor chip (shown when verse is anchored)
            if let anchor = anchorRange {
                anchorChip(for: anchor)
                    .transition(
                        respectsReducedMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.9)).animation(AppTheme.Animation.sacredSpring),
                                removal: .opacity.combined(with: .scale(scale: 0.9)).animation(AppTheme.Animation.quick)
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
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.sm)
        .animation(respectsReducedMotion ? .none : AppTheme.Animation.keyboardSync, value: anchorRange != nil)
    }

    // MARK: - Anchor Chip

    @ViewBuilder
    private func anchorChip(for anchor: VerseRange) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Bookmark icon
            Image(systemName: "bookmark.fill")
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.divineGold)

            // Reference text
            Text(anchor.shortReference)
                .font(Typography.UI.caption1.weight(.medium))
                .foregroundStyle(Color.primaryText)

            // Tap to change indicator
            Button {
                HapticService.shared.lightTap()
                onVersePicker()
            } label: {
                Image(systemName: "chevron.down")
                    .font(Typography.UI.iconXxxs)
                    .foregroundStyle(Color.tertiaryText)
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
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.tertiaryText)
            }
            .accessibilityLabel("Clear anchor")
            .accessibilityHint("Removes the verse anchor and returns to general mode")
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background {
            Capsule()
                .fill(.bar)
                .shadow(
                    color: Color.divineGold.opacity(AppTheme.Opacity.subtle),
                    radius: AppTheme.Blur.light,
                    x: 0,
                    y: 2
                )
                .shadow(
                    color: .black.opacity(AppTheme.Opacity.subtle),
                    radius: AppTheme.Blur.medium,
                    x: 0,
                    y: 4
                )
        }
        .overlay {
            Capsule()
                .strokeBorder(Color.divineGold.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
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
                .foregroundStyle(Color.divineGold)
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
                .foregroundStyle(Color.primaryText)
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
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.divineGold.gradient, in: .circle)
                    .blurFade(isFocused.wrappedValue)

                // Mic (shown when not focused)
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.primaryText)
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
                        .tint(Color.divineGold)
                } else {
                    Image(systemName: "sparkles")
                        .font(Typography.UI.body)
                        .foregroundStyle(
                            text.isEmpty
                                ? Color.tertiaryText
                                : Color.divineGold
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
            .background(Color.appBackground)
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
            .background(Color.appBackground)
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
            .background(Color.appBackground)
        }
    }
    return PreviewWrapper()
}
