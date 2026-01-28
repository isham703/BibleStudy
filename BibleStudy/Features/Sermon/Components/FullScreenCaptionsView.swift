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
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isNearBottom: Bool = true
    @State private var dotOpacity: Double = 0.3
    @State private var dotScale: CGFloat = 0.85

    /// Cached finalized text - only rebuilt when segments change (not on every volatile update)
    @State private var cachedFinalizedText: String = ""

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

            // Reference chip overlay (same as SermonRecordingPhase)
            if let selected = flowState.captionReferenceState.selectedReference {
                VStack {
                    Spacer()
                    CaptionReferenceChip(
                        reference: selected,
                        onGoToPassage: { location in
                            navigateToPassage(location, forReferenceId: selected.id)
                        },
                        onDismiss: {
                            flowState.captionReferenceState.dismissChip(forReferenceId: selected.id)
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
                .transition(.asymmetric(
                    insertion: .offset(y: 8).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(Theme.Animation.settle, value: flowState.captionReferenceState.selectedReference?.id)
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
        let finalText = cachedFinalizedText
        let volatile = flowState.liveCaptionText
        let hasFinalizedContent = !finalText.isEmpty

        return ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Combined finalized + volatile text as continuous flowing prose
                    if hasFinalizedContent || !volatile.isEmpty {
                        HighlightedCaptionText(
                            text: finalText,
                            font: Typography.Scripture.prompt,
                            baseColor: Color("AppTextPrimary"),
                            // Only enable taps when we have finalized content
                            onReferenceTapped: hasFinalizedContent ? { ref in
                                flowState.captionReferenceState.selectedReference =
                                    CaptionReferenceState.DetectedReference(
                                        id: UUID(),
                                        parsed: ref,
                                        canonicalId: ReferenceParser.canonicalId(for: ref),
                                        detectedAt: Date()
                                    )
                            } : nil,
                            volatileSuffix: volatile.isEmpty ? nil : volatile,
                            volatileColor: Color("AppTextSecondary")
                        )
                        .lineSpacing(Typography.Scripture.promptLineSpacing)
                        .animation(Theme.Animation.fade, value: volatile)
                        .contentTransition(.interpolate)
                    }

                    // Empty state
                    if flowState.liveCaptionSegments.isEmpty && volatile.isEmpty {
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

                    // Scroll anchor at bottom
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, Theme.Spacing.xl)
            }
            .onChange(of: flowState.liveCaptionSegments.count) { _, _ in
                // Rebuild cached finalized text only when segment count changes
                let rendered = CaptionScriptureFormatter.renderSegments(flowState.liveCaptionSegments)
                cachedFinalizedText = rendered.map(\.displayText).joined(separator: " ")

                guard isNearBottom else { return }
                withAnimation(Theme.Animation.settle) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: volatile) { _, _ in
                guard isNearBottom else { return }
                withAnimation(Theme.Animation.settle) {
                    proxy.scrollTo("bottom", anchor: .bottom)
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

    // MARK: - Navigation

    private func navigateToPassage(_ location: BibleLocation, forReferenceId: UUID) {
        // Save location to app state
        appState.saveLocation(location)

        // Dismiss chip first
        flowState.captionReferenceState.dismissChip(forReferenceId: forReferenceId)

        // Dismiss fullscreen view
        dismiss()

        // Post navigation notification (picked up by MainTabView to switch tabs)
        NotificationCenter.default.post(
            name: .deepLinkNavigationRequested,
            object: nil,
            userInfo: ["location": location]
        )
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
