import SwiftUI

// MARK: - Sermon Processing Phase
// Shows processing progress with step checklist

struct SermonProcessingPhase: View {
    @Bindable var flowState: SermonFlowState
    @State private var pulsePhase: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        // swiftlint:disable:next hardcoded_stack_spacing
        VStack(spacing: 40) {  // Large hero spacing for processing state
            Spacer()

            // Illuminated initial
            illuminatedInitial

            // Progress bar
            progressBar

            // Status text
            statusText

            // Step checklist
            stepChecklist

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Illuminated Initial

    private var illuminatedInitial: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentBronze.opacity(Theme.Opacity.medium),
                            Color.accentBronze.opacity(Theme.Opacity.subtle),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(1 + pulsePhase * 0.1)

            // Background circle
            Circle()
                .fill(Color.surfaceRaised)
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(Color.accentBronze.opacity(Theme.Opacity.heavy), lineWidth: Theme.Stroke.control)
                )

            // Animated "S" initial
            Text("S")
                .font(Typography.Scripture.display)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: Theme.Spacing.xs)
                    .fill(Color.surfaceRaised)

                // Fill with shimmer
                RoundedRectangle(cornerRadius: Theme.Spacing.xs)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * flowState.processingProgress)
                    .overlay(
                        // Shimmer effect
                        LinearGradient(
                            colors: [.clear, .white.opacity(Theme.Opacity.medium), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 100)
                        .offset(x: shimmerOffset)
                        .mask(
                            RoundedRectangle(cornerRadius: Theme.Spacing.xs)
                        )
                    )
                    // swiftlint:disable:next hardcoded_animation_spring
                    .animation(Theme.Animation.settle, value: flowState.processingProgress)
            }
        }
        .frame(height: Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Status Text

    private var statusText: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if case .processing(let step) = flowState.phase {
                Text(step.displayName)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textPrimary)

                Text("\(Int(flowState.processingProgress * 100))%")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.accentBronze)
            }
        }
    }

    // MARK: - Step Checklist

    private var stepChecklist: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ProcessingStepRow(
                title: "Upload audio",
                isComplete: isStepComplete(.uploading(progress: 1)),
                isActive: isStepActive(.uploading(progress: 0))
            )

            ProcessingStepRow(
                title: "Transcribe sermon",
                isComplete: isStepComplete(.transcribing(progress: 1, chunk: 1, total: 1)),
                isActive: isStepActive(.transcribing(progress: 0, chunk: 1, total: 1))
            )

            ProcessingStepRow(
                title: "Review content",
                isComplete: isStepComplete(.moderating),
                isActive: isStepActive(.moderating)
            )

            ProcessingStepRow(
                title: "Generate study guide",
                isComplete: isStepComplete(.analyzing),
                isActive: isStepActive(.analyzing)
            )

            ProcessingStepRow(
                title: "Save & sync",
                isComplete: isStepComplete(.saving),
                isActive: isStepActive(.saving)
            )
        }
        .padding(Theme.Spacing.xxl)
        .background(Color.surfaceRaised.opacity(Theme.Opacity.heavy))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.accentBronze.opacity(Theme.Opacity.lightMedium), lineWidth: Theme.Stroke.hairline)
        )
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
        // swiftlint:disable:next hardcoded_animation_ease
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulsePhase = 1
        }

        // Shimmer animation
        // swiftlint:disable:next hardcoded_animation_linear
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 400
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
        HStack(spacing: Theme.Spacing.lg) {
            // Status icon
            ZStack {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(Color.green)
                } else if isActive {
                    Circle()
                        .stroke(Color.accentBronze, lineWidth: Theme.Stroke.control)
                        .frame(width: Theme.Spacing.xl, height: Theme.Spacing.xl)
                        .overlay(
                            Circle()
                                .fill(Color.accentBronze)
                                .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                                .scaleEffect(1 + pulsePhase * 0.5)
                        )
                        .onAppear {
                            // swiftlint:disable:next hardcoded_animation_ease
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                pulsePhase = 1
                            }
                        }
                } else {
                    Circle()
                        .stroke(Color.textSecondary.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                        .frame(width: Theme.Spacing.xl, height: Theme.Spacing.xl)
                }
            }
            .frame(width: Theme.Spacing.xxl)

            // Title
            Text(title)
                .font(Typography.Scripture.body)
                .foregroundStyle(
                    isActive ? Color.textPrimary :
                    isComplete ? Color.textPrimary.opacity(Theme.Opacity.overlay) :
                    Color.textSecondary.opacity(Theme.Opacity.heavy)
                )

            Spacer()
        }
    }
}

#Preview {
    SermonProcessingPhase(flowState: {
        let state = SermonFlowState()
        state.phase = .processing(.transcribing(progress: 0.6, chunk: 2, total: 4))
        state.processingProgress = 0.45
        return state
    }())
    .preferredColorScheme(.dark)
}
