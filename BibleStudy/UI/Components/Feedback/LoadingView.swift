import SwiftUI
import Combine

// MARK: - Loading View
// Displays a loading indicator with optional message

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color("AppAccentAction"))

            Text(message)
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.opacity(Theme.Opacity.textPrimary))
    }
}

// MARK: - Inline Loading
struct InlineLoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    var message: String = "Loading..."

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Color("AppAccentAction"))

            Text(message)
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding()
    }
}

// MARK: - Skeleton Loading
struct SkeletonView: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.input)
            .fill(Color("AppTextSecondary"))
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Theme.Animation.slowFade
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.6
                }
            }
    }
}

// MARK: - AI Loading View
struct AILoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    var message: String = "Generating explanation..."

    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // AI Icon with animation
            Image(systemName: "sparkles")
                .font(Typography.Command.title1)
                .foregroundStyle(Color("AppAccentAction"))
                .symbolEffect(.pulse)

            Text(message + String(repeating: ".", count: dotCount))
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(minWidth: 200)
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Data Loading Progress View
/// Shows progress during first-launch data loading
struct DataLoadingProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    let phase: DataLoadingPhase

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // App icon placeholder
            Image(systemName: "book.closed.fill")
                .font(Typography.Command.largeTitle)
                .foregroundStyle(Color("AppAccentAction"))
                .symbolEffect(.pulse.byLayer, isActive: phase.isLoading)

            // Title
            Text("Bible Study")
                .font(Typography.Command.title2)
                .foregroundStyle(Color("AppTextPrimary"))

            // Progress section
            progressContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    @ViewBuilder
    private var progressContent: some View {
        switch phase {
        case .idle:
            EmptyView()

        case let .loading(description, progress):
            VStack(spacing: Theme.Spacing.md) {
                ProgressView(value: progress)
                    .tint(Color("AppAccentAction"))
                    .frame(width: 200)

                Text(description)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))

                if progress > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(Typography.Command.caption.monospacedDigit())
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
            .padding(.top, Theme.Spacing.lg)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.Command.title2)
                .foregroundStyle(Color("FeedbackSuccess"))
                .transition(.scale.combined(with: .opacity))

        case let .failed(error):
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.Command.title2)
                    .foregroundStyle(Color("FeedbackWarning"))

                Text("Failed to load data")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text(error)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - First Launch Overlay
/// Full-screen overlay for first launch data loading
struct FirstLaunchOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    let phase: DataLoadingPhase
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            DataLoadingProgressView(phase: phase)

            if case .failed = phase {
                VStack {
                    Spacer()

                    Button(action: onRetry) {
                        Text("Retry")
                            .font(Typography.Command.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Color("AppAccentAction"))
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
    }
}

// MARK: - Streaming Content View
/// Displays progressive AI response with skeleton loading and phased reveals
/// Implements the "ink-bleed" animation effect from classical design
struct StreamingContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    /// The content to display (nil = loading)
    let content: StreamingContent?

    /// Loading state
    let isLoading: Bool

    /// Progress stage for user feedback
    let progressStage: StreamingProgressStage

    // MARK: - Animation State
    @State private var showSummary = false
    @State private var showKeyPoints = false
    @State private var visibleKeyPointCount = 0
    @State private var showSources = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Progress indicator
            progressIndicator

            if isLoading {
                // Skeleton loading state
                skeletonContent
            } else if let content = content {
                // Actual content with phased reveal
                actualContent(content)
            }
        }
        .onChange(of: content) { _, newContent in
            if newContent != nil {
                startRevealAnimation()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color("AccentBronze"))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("FeedbackSuccess"))
            }

            Text(progressStage.message)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .animation(Theme.Animation.settle, value: progressStage)
    }

    // MARK: - Skeleton Content

    private var skeletonContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Summary skeleton
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                GoldShimmerLine(width: .infinity)
                GoldShimmerLine(width: 280)
                GoldShimmerLine(width: 220)
            }

            // Key points label skeleton
            GoldShimmerLine(width: 100)
                .padding(.top, Theme.Spacing.sm)

            // Key points skeletons
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: Theme.Spacing.sm) {
                        Circle()
                            .fill(Color("AppTextSecondary").opacity(Theme.Opacity.focusStroke))
                            .frame(width: 6, height: 6)
                        GoldShimmerLine(width: .random(in: 180...280))
                    }
                }
            }
        }
    }

    // MARK: - Actual Content

    @ViewBuilder
    private func actualContent(_ content: StreamingContent) -> some View {
        // Summary with ink-bleed animation
        Text(content.summary)
            .font(Typography.Command.body)
            .foregroundStyle(Color("AppTextPrimary"))
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showSummary ? 1 : 0)
            .blur(radius: showSummary ? 0 : 8)
            .offset(y: showSummary ? 0 : 4)

        // Key points section
        if !content.keyPoints.isEmpty {
            Text("Key Points")
                .font(Typography.Command.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.top, Theme.Spacing.sm)
                .opacity(showKeyPoints ? 1 : 0)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(Array(content.keyPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Circle()
                            .fill(Color("AccentBronze"))
                            .frame(width: 6, height: 6)
                            .padding(.top, Theme.Spacing.sm - 2)

                        Text(point)
                            .font(Typography.Command.subheadline)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .opacity(index < visibleKeyPointCount ? 1 : 0)
                    .blur(radius: index < visibleKeyPointCount ? 0 : 4)
                    .offset(y: index < visibleKeyPointCount ? 0 : 4)
                }
            }
        }

        // Sources
        if !content.sources.isEmpty {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "checkmark.shield")
                    .font(Typography.Command.meta)
                Text("Sources: \(content.sources.joined(separator: ", "))")
                    .font(Typography.Command.meta)
            }
            .foregroundStyle(Color("TertiaryText"))
            .opacity(showSources ? 1 : 0)
            .padding(.top, Theme.Spacing.sm)
        }
    }

    // MARK: - Animation

    private func startRevealAnimation() {
        // Summary appears first
        withAnimation(Theme.Animation.settle) {
            showSummary = true
        }

        // Key points label after delay
        withAnimation(Theme.Animation.settle.delay(0.3)) {
            showKeyPoints = true
        }

        // Key points stagger in
        if let content = content {
            for index in 0..<content.keyPoints.count {
                let delay = 0.5 + Double(index) * 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(Theme.Animation.settle) {
                        visibleKeyPointCount = index + 1
                    }
                }
            }

            // Sources appear last
            let sourcesDelay = 0.5 + Double(content.keyPoints.count) * 0.15 + 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + sourcesDelay) {
                withAnimation(Theme.Animation.settle) {
                    showSources = true
                }
            }
        }
    }
}

// MARK: - Streaming Content Model

struct StreamingContent: Equatable {
    let summary: String
    let keyPoints: [String]
    let sources: [String]
}

// MARK: - Progress Stage

enum StreamingProgressStage: Equatable {
    case analyzing
    case generating
    case formatting
    case complete

    var message: String {
        switch self {
        case .analyzing: return "Analyzing context..."
        case .generating: return "Generating insight..."
        case .formatting: return "Formatting response..."
        case .complete: return "Complete"
        }
    }
}

// MARK: - Loading Dots View
/// Elegant animated loading indicator with three dots
/// Uses refined bronze accent and ceremonial timing

struct LoadingDotsView: View {
    @State private var animatingDot = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color("AccentBronze"))
                    .frame(width: 8, height: 8)
                    .opacity(animatingDot == index ? 1.0 : 0.3)
                    .scaleEffect(animatingDot == index ? 1.2 : 1.0)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(Theme.Animation.fade) {
                animatingDot = (animatingDot + 1) % 3
            }
        }
    }
}

// MARK: - Gold Shimmer Line

private struct GoldShimmerLine: View {
    let width: CGFloat

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.xs)
            .fill(
                LinearGradient(
                    colors: [
                        Color("AppTextSecondary").opacity(Theme.Opacity.selectionBackground),
                        Color("AccentBronze").opacity(Theme.Opacity.disabled),
                        Color("AppTextSecondary").opacity(Theme.Opacity.selectionBackground)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width == .infinity ? nil : width, height: 14)
            .frame(maxWidth: width == .infinity ? .infinity : nil, alignment: .leading)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            )
            .onAppear {
                withAnimation(Theme.Animation.fade) {
                    shimmerOffset = 300
                }
            }
    }
}

// MARK: - Preview
#Preview("Loading Views") {
    VStack(spacing: Theme.Spacing.xxl) {
        LoadingView()
            .frame(height: 200)

        InlineLoadingView()

        HStack {
            SkeletonView()
                .frame(width: 100, height: 20)
            SkeletonView()
                .frame(width: 150, height: 20)
        }

        AILoadingView()
    }
    .padding()
    .background(Color.appBackground)
}

#Preview("Data Loading Progress") {
    DataLoadingProgressView(phase: .loading(description: "Loading verses...", progress: 0.45))
}

#Preview("First Launch Overlay") {
    FirstLaunchOverlay(
        phase: .loading(description: "Preparing your Bible...", progress: 0.3)
    ) {
        print("Retry tapped")
    }
}

#Preview("Streaming Content - Loading") {
    StreamingContentView(
        content: nil,
        isLoading: true,
        progressStage: .analyzing
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("Streaming Content - Complete") {
    StreamingContentView(
        content: StreamingContent(
            summary: "This verse establishes the foundational moment of creation where God speaks light into existence. The Hebrew phrase uses the jussive form, expressing a divine command or decree.",
            keyPoints: [
                "Creation of light precedes the sun (verse 14)",
                "Divine speech as the instrument of creation",
                "Pattern of \"God said... and it was so\""
            ],
            sources: ["Biblical Hebrew lexicon", "Genesis commentary"]
        ),
        isLoading: false,
        progressStage: .complete
    )
    .padding()
    .background(Color.appBackground)
}
