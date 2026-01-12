import SwiftUI

// MARK: - Sermon Processing Phase
// Atrium-style: Clean, spacious processing screen with step checklist

struct SermonProcessingPhase: View {
    @Bindable var flowState: SermonFlowState
    @State private var pulsePhase: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var isAwakened = false
    @State private var showReassurance = false
    @State private var reassuranceTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()

                // Illuminated initial
                illuminatedInitial
                    .padding(.bottom, Theme.Spacing.xxl)

                // Progress bar
                progressBar
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)

                // Status text
                statusText
                    .padding(.bottom, Theme.Spacing.xxl)

                // Step checklist
                stepChecklist
                    .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }
        }
        .onAppear {
            startAnimations()
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
        .onDisappear {
            reassuranceTask?.cancel()
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

            // Processing pulse glow
            RadialGradient(
                colors: [
                    Color("AppAccentAction").opacity(Double(0.06 * pulsePhase)),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 250
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Illuminated Initial

    private var illuminatedInitial: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(Color("AppAccentAction").opacity(0.2), lineWidth: 2)
                .frame(width: 100, height: 100)
                .scaleEffect(1 + pulsePhase * 0.1)
                .opacity(Double(1 - pulsePhase * 0.3))

            // Main circle
            Circle()
                .fill(Color("AppSurface"))
                .frame(width: 88, height: 88)
                .overlay(
                    Circle()
                        .stroke(Color("AppDivider"), lineWidth: 2)
                )

            // Animated "S" initial
            Text("S")
                .font(.system(size: 40, weight: .light, design: .serif))
                .foregroundStyle(Color("AppAccentAction"))
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.9)
        .animation(Theme.Animation.settle.delay(0.1), value: isAwakened)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                    )

                // Fill with gradient
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppAccentAction"),
                                Color("AppAccentAction").opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * flowState.processingProgress)
                    .overlay(
                        // Shimmer effect
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 80)
                        .offset(x: shimmerOffset)
                        .mask(RoundedRectangle(cornerRadius: 4))
                    )
                    .animation(Theme.Animation.settle, value: flowState.processingProgress)
            }
        }
        .frame(height: 8)
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
    }

    // MARK: - Status Text

    private var statusText: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if case .processing(let step) = flowState.phase {
                Text(step.displayName)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("\(Int(flowState.processingProgress * 100))%")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color("AppAccentAction"))

                // Time estimate (appears after reassurance message)
                if showReassurance {
                    Text(flowState.formattedEstimatedTime)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
        .animation(Theme.Animation.fade, value: showReassurance)
    }

    // MARK: - Step Checklist

    private var stepChecklist: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Step card
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ProcessingStepRow(
                    title: "Uploading",
                    isComplete: isStepComplete(.uploading(progress: 1)),
                    isActive: isStepActive(.uploading(progress: 0))
                )

                ProcessingStepRow(
                    title: "Transcribing",
                    isComplete: isStepComplete(.transcribing(progress: 1, chunk: 1, total: 1)),
                    isActive: isStepActive(.transcribing(progress: 0, chunk: 1, total: 1))
                )

                ProcessingStepRow(
                    title: "Reviewing",
                    isComplete: isStepComplete(.moderating),
                    isActive: isStepActive(.moderating)
                )

                ProcessingStepRow(
                    title: "Preparing guide",
                    isComplete: isStepComplete(.analyzing),
                    isActive: isStepActive(.analyzing)
                )

                ProcessingStepRow(
                    title: "Saving",
                    isComplete: isStepComplete(.saving),
                    isActive: isStepActive(.saving)
                )
            }
            .padding(Theme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )

            // AI transparency indicator
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.xs)

                Text("AI-generated content will be labeled for review")
                    .font(Typography.Command.caption)
            }
            .foregroundStyle(Color("TertiaryText"))
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
    }

    // MARK: - Step State Helpers

    private func isStepComplete(_ targetStep: ProcessingStep) -> Bool {
        guard case .processing(let currentStep) = flowState.phase else {
            return flowState.phase == .viewing
        }
        return currentStep.progress > targetStep.progress
    }

    private func isStepActive(_ targetStep: ProcessingStep) -> Bool {
        guard case .processing(let currentStep) = flowState.phase else { return false }

        // Compare step types
        switch (currentStep, targetStep) {
        case (.uploading, .uploading): return true
        case (.transcribing, .transcribing): return true
        case (.moderating, .moderating): return true
        case (.analyzing, .analyzing): return true
        case (.saving, .saving): return true
        default: return false
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }

        // Shimmer animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 400
        }

        // Show reassurance message after 2 seconds (cancellable)
        reassuranceTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.0))
            guard !Task.isCancelled else { return }
            withAnimation(Theme.Animation.fade) {
                showReassurance = true
            }
        }
    }
}

// MARK: - Processing Step Row

struct ProcessingStepRow: View {
    let title: String
    let isComplete: Bool
    let isActive: Bool

    @State private var pulsePhase: CGFloat = 0

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Status icon
            ZStack {
                if isComplete {
                    Circle()
                        .fill(Color("FeedbackSuccess"))
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                } else if isActive {
                    Circle()
                        .stroke(Color("AppAccentAction"), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    Circle()
                        .fill(Color("AppAccentAction"))
                        .frame(width: 10, height: 10)
                        .scaleEffect(1 + pulsePhase * 0.3)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                pulsePhase = 1
                            }
                        }
                } else {
                    Circle()
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                        .frame(width: 28, height: 28)
                }
            }
            .frame(width: 32)

            // Title
            Text(title)
                .font(Typography.Command.body)
                .foregroundStyle(
                    isActive ? Color("AppTextPrimary") :
                    isComplete ? Color("AppTextSecondary") :
                    Color("TertiaryText")
                )
                .fontWeight(isActive ? .medium : .regular)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    SermonProcessingPhase(flowState: {
        let state = SermonFlowState()
        state.phase = .processing(.analyzing)
        state.processingProgress = 0.75
        return state
    }())
    .preferredColorScheme(.dark)
}
