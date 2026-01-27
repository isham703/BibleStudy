import SwiftUI

// MARK: - Live Captions Panel
// Compact overlay + expandable scrollable panel for live sermon captions.
// Ephemeral — captions are NOT persisted. Shows real-time on-device
// speech recognition output during recording only.
//
// Two modes:
// - Compact: 1-2 lines of latest text with activity dot, chevron to expand
// - Expanded: Scrollable panel (max 120pt) showing finalized + volatile segments
//             with Bible references highlighted and tappable

struct LiveCaptionsPanel: View {
    let isExpanded: Bool
    let captionText: String
    let segments: [LiveCaptionSegment]
    let isSpeechDetected: Bool
    let onToggle: () -> Void
    var onReferenceTapped: ((ParsedReference) -> Void)? = nil
    var onFullScreen: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dotOpacity: Double = 0.3
    @State private var dotScale: CGFloat = 0.85
    @State private var isNearBottom: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible
            headerRow

            // Expanded content — scrollable transcript
            if isExpanded {
                expandedContent
                    .frame(maxHeight: 120)
                    .opacity(isExpanded ? 1 : 0)
                    .animation(Theme.Animation.fade, value: isExpanded)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(panelBackground)
        .animation(Theme.Animation.settle, value: isExpanded)
        .onChange(of: isSpeechDetected) { _, detected in
            animateSpeechDot(detected: detected)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live Captions")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Toggle area (dot + label + trust messaging + preview)
            Button(action: onToggle) {
                HStack(spacing: Theme.Spacing.sm) {
                    // Activity dot
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(dotOpacity)
                        .scaleEffect(dotScale)

                    // LIVE label
                    Text("LIVE")
                        .font(Typography.Editorial.label)
                        .tracking(Typography.Editorial.labelTracking)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.red)

                    // Trust messaging
                    Text("(not saved)")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))

                    Spacer()

                    // Caption preview (compact mode only)
                    if !isExpanded {
                        captionPreview
                    }
                }
            }
            .buttonStyle(.plain)

            // Full-screen button (expanded mode only)
            if isExpanded, onFullScreen != nil {
                Button {
                    onFullScreen?()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Full screen captions")
            }

            // Expand/collapse chevron
            Button(action: onToggle) {
                Image(systemName: "chevron.up")
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(Theme.Animation.settle, value: isExpanded)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Caption Preview (Compact Mode)

    private var captionPreview: some View {
        Group {
            if let latestText = displayText, !latestText.isEmpty {
                Text(latestText)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
                    .truncationMode(.head)
                    .animation(Theme.Animation.fade, value: latestText)
                    .contentTransition(.interpolate)
            } else {
                Text("Listening...")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Finalized segments with reference highlighting
                    ForEach(segments) { segment in
                        HighlightedCaptionText(
                            text: segment.text,
                            font: Typography.Command.body,
                            baseColor: Color("AppTextPrimary"),
                            onReferenceTapped: onReferenceTapped
                        )
                        .id(segment.id)
                    }

                    // Current volatile text (no highlighting — text is still changing)
                    if !captionText.isEmpty {
                        Text(captionText)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .animation(Theme.Animation.fade, value: captionText)
                            .contentTransition(.interpolate)
                            .id("volatile")
                    }

                    // Empty state
                    if segments.isEmpty && captionText.isEmpty {
                        Text("Listening...")
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .onChange(of: segments.count) { _, _ in
                guard isNearBottom else { return }
                withAnimation(Theme.Animation.settle) {
                    if let lastId = segments.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: captionText) { _, _ in
                guard isNearBottom else { return }
                withAnimation(Theme.Animation.settle) {
                    proxy.scrollTo("volatile", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Background

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .fill(Color("AppSurface"))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        Color("AppAccentAction").opacity(Theme.Opacity.divider),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
    }

    // MARK: - Helpers

    /// Display text: prefer volatile (latest), fall back to last segment
    private var displayText: String? {
        if !captionText.isEmpty {
            return captionText
        }
        return segments.last?.text
    }

    /// Animate the speech activity dot with asymmetric timing
    private func animateSpeechDot(detected: Bool) {
        if reduceMotion {
            dotOpacity = detected ? 1.0 : 0.3
            dotScale = 1.0
            return
        }

        if detected {
            withAnimation(Theme.Animation.speechDotOn) {
                dotOpacity = 1.0
                dotScale = 1.0
            }
        } else {
            withAnimation(Theme.Animation.speechDotOff) {
                dotOpacity = 0.3
                dotScale = 0.85
            }
        }
    }
}

// MARK: - Preview

#Preview("Live Captions - Compact") {
    VStack {
        Spacer()
        LiveCaptionsPanel(
            isExpanded: false,
            captionText: "...no condemnation for those who are in Christ Jesus",
            segments: [],
            isSpeechDetected: true,
            onToggle: {}
        )
        .padding(.horizontal, Theme.Spacing.lg)
        Spacer()
    }
    .background(Color.appBackground)
}

#Preview("Live Captions - Expanded") {
    VStack {
        Spacer()
        LiveCaptionsPanel(
            isExpanded: true,
            captionText: "that there is therefore now no condemnation",
            segments: [
                LiveCaptionSegment(
                    id: UUID(),
                    text: "And so we see in Romans 8:1,",
                    timestamp: 0,
                    isFinal: true
                ),
                LiveCaptionSegment(
                    id: UUID(),
                    text: "the apostle Paul makes this extraordinary declaration.",
                    timestamp: 5,
                    isFinal: true
                ),
            ],
            isSpeechDetected: true,
            onToggle: {},
            onReferenceTapped: { ref in print("Tapped: \(ref.displayText)") },
            onFullScreen: {}
        )
        .padding(.horizontal, Theme.Spacing.lg)
        Spacer()
    }
    .background(Color.appBackground)
}
