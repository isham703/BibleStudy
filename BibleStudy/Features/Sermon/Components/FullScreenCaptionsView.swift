import SwiftUI

// MARK: - Full Screen Captions View
// Dedicated accessibility-first view with minimal chrome for reading
// live captions during sermon recording. Uses large serif typography
// for comfortable reading at a distance.
//
// Presented via .fullScreenCover from SermonRecordingPhase.
// Reads from the same SermonFlowState — no state duplication.
// Screen stays awake via .persistentSystemOverlays(.hidden).

struct FullScreenCaptionsView: View {
    @Bindable var flowState: SermonFlowState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isNearBottom: Bool = true
    @State private var dotOpacity: Double = 0.3
    @State private var dotScale: CGFloat = 0.85

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Minimal header
                header
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                Divider()
                    .foregroundStyle(Color("AppDivider"))

                // Caption content
                captionScrollView
                    .padding(.horizontal, Theme.Spacing.xl)

                // Timer bar at bottom
                timerBar
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.md)
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBarHidden()
        .onChange(of: flowState.isSpeechDetected) { _, detected in
            animateSpeechDot(detected: detected)
        }
        .onChange(of: flowState.isRecording) { _, isRecording in
            // Auto-dismiss if recording stops
            if !isRecording {
                dismiss()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
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

            Text("(not saved)")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Close full screen captions")
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Caption Scroll View

    private var captionScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Finalized segments — large serif text with reference highlighting
                    ForEach(flowState.liveCaptionSegments) { segment in
                        HighlightedCaptionText(
                            text: segment.text,
                            font: Typography.Scripture.prompt,
                            baseColor: Color("AppTextPrimary"),
                            onReferenceTapped: { ref in
                                flowState.captionReferenceState.selectedReference =
                                    CaptionReferenceState.DetectedReference(
                                        id: UUID(),
                                        parsed: ref,
                                        canonicalId: ReferenceParser.canonicalId(for: ref),
                                        detectedAt: Date()
                                    )
                            }
                        )
                        .lineSpacing(Typography.Scripture.promptLineSpacing)
                        .id(segment.id)
                    }

                    // Current volatile text — slightly dimmer
                    if !flowState.liveCaptionText.isEmpty {
                        Text(flowState.liveCaptionText)
                            .font(Typography.Scripture.prompt)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineSpacing(Typography.Scripture.promptLineSpacing)
                            .animation(Theme.Animation.fade, value: flowState.liveCaptionText)
                            .contentTransition(.interpolate)
                            .id("volatile")
                    }

                    // Empty state
                    if flowState.liveCaptionSegments.isEmpty && flowState.liveCaptionText.isEmpty {
                        VStack(spacing: Theme.Spacing.md) {
                            Spacer().frame(height: 60)

                            Image(systemName: "waveform")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(Color("TertiaryText"))

                            Text("Listening...")
                                .font(Typography.Scripture.prompt)
                                .foregroundStyle(Color("TertiaryText"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, Theme.Spacing.xl)
            }
            .onChange(of: flowState.liveCaptionSegments.count) { _, _ in
                guard isNearBottom else { return }
                withAnimation(Theme.Animation.settle) {
                    if let lastId = flowState.liveCaptionSegments.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: flowState.liveCaptionText) { _, _ in
                guard isNearBottom else { return }
                withAnimation(Theme.Animation.settle) {
                    proxy.scrollTo("volatile", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Timer Bar

    private var timerBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Recording duration
            Text(flowState.formattedDuration)
                .font(.system(size: 20, weight: .light).monospacedDigit())
                .foregroundStyle(Color("AppTextPrimary"))
                .contentTransition(.numericText())

            Spacer()

            // Status
            HStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(flowState.isPaused ? Color("TertiaryText") : Color.red)
                    .frame(width: 8, height: 8)

                Text(flowState.isPaused ? "Paused" : "Recording")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Speech Dot Animation

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

#Preview("Full Screen Captions") {
    FullScreenCaptionsView(flowState: {
        let state = SermonFlowState()
        state.isRecording = true
        state.liveCaptionSegments = [
            LiveCaptionSegment(
                id: UUID(),
                text: "And so we see in Romans 8:1, that there is therefore now no condemnation for those who are in Christ Jesus.",
                timestamp: 0,
                isFinal: true
            ),
            LiveCaptionSegment(
                id: UUID(),
                text: "For the law of the Spirit of life has set you free in Christ Jesus from the law of sin and death.",
                timestamp: 8,
                isFinal: true
            ),
        ]
        state.liveCaptionText = "For God has done what the law, weakened by the flesh..."
        return state
    }())
    .preferredColorScheme(.dark)
}
