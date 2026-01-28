import SwiftUI
import AVKit

// MARK: - Sermon Recording Phase
// Atrium-style: Clean, spacious recording interface with waveform visualization

struct SermonRecordingPhase: View {
    @Bindable var flowState: SermonFlowState
    @Environment(AppState.self) private var appState
    @State private var pulsePhase: CGFloat = 0
    @State private var isAwakened = false
    @State private var showFullScreenCaptions = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()

                // Header with recording indicator
                headerSection
                    .padding(.bottom, Theme.Spacing.xxl)

                // Waveform visualizer card with live captions overlay
                ZStack(alignment: .bottom) {
                    waveformSection

                    if flowState.isLiveCaptionsEnabled && flowState.isLiveCaptionsAvailable {
                        LiveCaptionsPanel(
                            isExpanded: flowState.showLiveCaptionsExpanded,
                            captionText: flowState.liveCaptionText,
                            segments: flowState.liveCaptionSegments,
                            isSpeechDetected: flowState.isSpeechDetected,
                            onToggle: { flowState.showLiveCaptionsExpanded.toggle() },
                            onReferenceTapped: { ref in
                                flowState.captionReferenceState.selectedReference =
                                    CaptionReferenceState.DetectedReference(
                                        id: UUID(),
                                        parsed: ref,
                                        canonicalId: ReferenceParser.canonicalId(for: ref),
                                        detectedAt: Date()
                                    )
                            },
                            onFullScreen: {
                                showFullScreenCaptions = true
                            },
                            source: flowState.liveCaptionSource,
                            isCloudReconnectAvailable: flowState.isCloudReconnectAvailable,
                            onSwitchToCloud: {
                                if #available(iOS 26, *) {
                                    Task {
                                        await flowState.switchToCloudCaptions()
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.bottom, Theme.Spacing.xs)
                        .transition(.asymmetric(
                            insertion: .offset(y: 12).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .animation(Theme.Animation.settle, value: flowState.isLiveCaptionsAvailable)

                // Reference chip overlay
                if let selected = flowState.captionReferenceState.selectedReference {
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
                    .transition(.asymmetric(
                        insertion: .offset(y: 8).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(Theme.Animation.settle, value: flowState.captionReferenceState.selectedReference?.id)
                }

                // Timer display
                timerSection
                    .padding(.top, Theme.Spacing.xxl)

                Spacer()

                // Control buttons
                controlsSection
                    .padding(.bottom, Theme.Spacing.lg)

                // Input picker (iOS 26+) — secondary action below controls
                if #available(iOS 26, *) {
                    InputPickerButton()
                        .frame(height: 44)
                        .opacity(isAwakened ? 1 : 0)
                        .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
                        .padding(.bottom, Theme.Spacing.xxl)
                } else {
                    Spacer()
                        .frame(height: Theme.Spacing.xxl)
                }
            }
        }
        .onAppear {
            startPulseAnimation()
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
        .fullScreenCover(isPresented: $showFullScreenCaptions) {
            FullScreenCaptionsView(flowState: flowState)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            // Soft top glow
            RadialGradient(
                colors: [
                    Color("AppAccentAction").opacity(Theme.Opacity.subtle / 3),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.2),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Recording pulse glow when active
            if flowState.isRecording && !flowState.isPaused {
                RadialGradient(
                    colors: [
                        Color.red.opacity(Double(0.08 * pulsePhase)),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.35),
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Recording indicator circle
            ZStack {
                // Outer pulse ring (when recording)
                if flowState.isRecording && !flowState.isPaused {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(1 + pulsePhase * 0.15)
                        .opacity(Double(1 - pulsePhase * 0.5))
                }

                // Main circle
                Circle()
                    .fill(Color("AppSurface"))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(
                                flowState.isPaused ? Color("AppDivider") : Color.red.opacity(0.5),
                                lineWidth: 2
                            )
                    )

                // Inner recording dot
                Circle()
                    .fill(flowState.isPaused ? Color("TertiaryText") : Color.red)
                    .frame(width: 24, height: 24)
                    .shadow(color: flowState.isPaused ? .clear : .red.opacity(0.5), radius: 8)
            }
            .opacity(isAwakened ? 1 : 0)
            .scaleEffect(isAwakened ? 1 : 0.9)
            .animation(Theme.Animation.settle.delay(0.1), value: isAwakened)

            // Status label
            Text(flowState.isPaused ? "PAUSED" : "RECORDING")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(flowState.isPaused ? Color("TertiaryText") : Color.red)
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
        }
    }

    // MARK: - Waveform Section

    private var waveformSection: some View {
        SermonWaveformView(
            audioLevels: flowState.audioLevels,
            currentLevel: flowState.currentAudioLevel,
            isActive: flowState.isRecording && !flowState.isPaused
        )
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Duration timer
            Text(flowState.formattedDuration)
                .font(.system(size: 56, weight: .light, design: .default))
                .monospacedDigit()
                .foregroundStyle(Color("AppTextPrimary"))
                .contentTransition(.numericText())

            // Subtitle with conditional countdown
            if !flowState.meetsMinimumDuration && !flowState.isPaused {
                Text("Minimum recording: \(flowState.formattedRemainingTime) remaining")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("FeedbackWarning"))
            } else {
                Text(flowState.isPaused ? "Tap play to continue" : "Recording sermon...")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            // Pause/Resume button
            Button {
                HapticService.shared.lightTap()
                if flowState.isPaused {
                    flowState.resumeRecording()
                } else {
                    flowState.pauseRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color("AppSurface"))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                        )

                    Image(systemName: flowState.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
            .buttonStyle(SermonRecordingButtonStyle())
            .accessibilityLabel(flowState.isPaused ? "Resume recording" : "Pause recording")

            // Stop button (primary)
            Button {
                HapticService.shared.mediumTap()
                Task {
                    await flowState.stopRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: flowState.canStopRecording
                                    ? [
                                        Color("AppAccentAction"),
                                        Color("AppAccentAction").opacity(0.85)
                                    ]
                                    : [
                                        Color("AppSurface"),
                                        Color("AppSurface").opacity(0.85)
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: flowState.canStopRecording
                                ? Color("AppAccentAction").opacity(0.3)
                                : Color.clear,
                            radius: 12,
                            y: 4
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    flowState.canStopRecording
                                        ? Color.clear
                                        : Color("AppDivider"),
                                    lineWidth: Theme.Stroke.hairline
                                )
                        )

                    // Stop square icon
                    RoundedRectangle(cornerRadius: 4)
                        .fill(flowState.canStopRecording ? Color.white : Color("TertiaryText"))
                        .frame(width: 24, height: 24)
                }
            }
            .disabled(!flowState.canStopRecording)
            .buttonStyle(SermonRecordingButtonStyle())
            .accessibilityLabel("Stop recording")
            .accessibilityHint(flowState.canStopRecording ? "Double tap to finish and save" : "Record at least 30 seconds to enable")

            // Cancel button
            Button {
                HapticService.shared.lightTap()
                flowState.cancelRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color("AppSurface"))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color("FeedbackError").opacity(0.3), lineWidth: Theme.Stroke.hairline)
                        )

                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color("FeedbackError"))
                }
            }
            .buttonStyle(SermonRecordingButtonStyle())
            .accessibilityLabel("Cancel recording")
            .accessibilityHint("Double tap to discard recording and start over")
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isAwakened)
    }

    // MARK: - Animation

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }
    }

    // MARK: - Navigation

    private func navigateToPassage(_ location: BibleLocation, forReferenceId: UUID) {
        // Save location to app state
        appState.saveLocation(location)

        // Dismiss chip
        flowState.captionReferenceState.dismissChip(forReferenceId: forReferenceId)

        // Post navigation notification (picked up by MainTabView to switch tabs)
        NotificationCenter.default.post(
            name: .deepLinkNavigationRequested,
            object: nil,
            userInfo: ["location": location]
        )
    }
}

// MARK: - Button Style

private struct SermonRecordingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Sermon Waveform View

struct SermonWaveformView: View {
    let audioLevels: [Float]
    let currentLevel: Float
    let isActive: Bool

    private let barCount = 50
    private let barWidth: CGFloat = 3
    private let spacing: CGFloat = 3

    // Static gradient to avoid recreating on every draw
    private static let barGradient = Gradient(colors: [
        Color(red: 0.85, green: 0.65, blue: 0.35).opacity(0.9),
        Color(red: 0.75, green: 0.55, blue: 0.25).opacity(0.7)
    ])

    var body: some View {
        // Throttle redraws to 10fps when active (use fully qualified name to avoid conflict)
        SwiftUI.TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            GeometryReader { _ in
                Canvas { context, size in
                    let totalBars = barCount
                    let totalWidth = CGFloat(totalBars) * (barWidth + spacing) - spacing
                    let startX = (size.width - totalWidth) / 2
                    let maxHeight = size.height * 0.7

                    for i in 0..<totalBars {
                        // Get level from array or use current level for recent bars
                        let level: CGFloat
                        if i < audioLevels.count {
                            level = CGFloat(audioLevels[i])
                        } else if i == audioLevels.count && isActive {
                            level = CGFloat(currentLevel)
                        } else {
                            level = 0.05
                        }

                        let height = max(3, level * maxHeight)
                        let x = startX + CGFloat(i) * (barWidth + spacing)
                        let y = (size.height - height) / 2

                        let rect = CGRect(x: x, y: y, width: barWidth, height: height)

                        context.fill(
                            RoundedRectangle(cornerRadius: 1.5).path(in: rect),
                            with: .linearGradient(
                                Self.barGradient,
                                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                                endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                            )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Input Picker Button (iOS 26+)
// Wraps AVInputPickerInteraction to show Apple's built-in audio input
// and mic mode selection UI (Voice Isolation, Bluetooth, etc.)

@available(iOS 26, *)
private struct InputPickerButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "mic.fill")
        config.imagePadding = 6
        config.title = "Audio Input"
        config.baseForegroundColor = UIColor(named: "AppTextSecondary")
        button.configuration = config
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)

        containerView.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        // Attach the input picker interaction
        let interaction = AVInputPickerInteraction()
        button.addInteraction(interaction)

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview

#Preview {
    SermonRecordingPhase(flowState: {
        let state = SermonFlowState()
        state.isRecording = true
        state.audioLevels = (0..<40).map { _ in Float.random(in: 0.1...0.8) }
        return state
    }())
    .preferredColorScheme(.dark)
}
