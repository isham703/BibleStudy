import SwiftUI
import Combine

// MARK: - Loading View
// Displays a loading indicator with optional message

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(AppTheme.Scale.enlarged)
                .tint(Color.accentGold)

            Text(message)
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.opacity(AppTheme.Opacity.high))
    }
}

// MARK: - Inline Loading
struct InlineLoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
                .tint(Color.accentGold)

            Text(message)
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .padding()
    }
}

// MARK: - Skeleton Loading
struct SkeletonView: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
            .fill(Color.secondaryText)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    AppTheme.Animation.slow
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.6
                }
            }
    }
}

// MARK: - AI Loading View
struct AILoadingView: View {
    var message: String = "Generating explanation..."

    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // AI Icon with animation
            Image(systemName: "sparkles")
                .font(Typography.UI.title1)
                .foregroundStyle(Color.accentGold)
                .symbolEffect(.pulse)

            Text(message + String(repeating: ".", count: dotCount))
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
                .frame(minWidth: 200)
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(Color.surfaceBackground)
        )
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Data Loading Progress View
/// Shows progress during first-launch data loading
struct DataLoadingProgressView: View {
    let phase: DataLoadingPhase

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // App icon placeholder
            Image(systemName: "book.closed.fill")
                .font(Typography.UI.largeTitle)
                .foregroundStyle(Color.accentGold)
                .symbolEffect(.pulse.byLayer, isActive: phase.isLoading)

            // Title
            Text("Bible Study")
                .font(Typography.UI.title2)
                .foregroundStyle(Color.primaryText)

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
            VStack(spacing: AppTheme.Spacing.md) {
                ProgressView(value: progress)
                    .tint(Color.accentGold)
                    .frame(width: 200)

                Text(description)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)

                if progress > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(Typography.UI.caption1.monospacedDigit())
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .padding(.top, AppTheme.Spacing.lg)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.UI.title2)
                .foregroundStyle(Color.success)
                .transition(.scale.combined(with: .opacity))

        case let .failed(error):
            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.UI.title2)
                    .foregroundStyle(Color.warning)

                Text("Failed to load data")
                    .font(Typography.UI.warmSubheadline)
                    .foregroundStyle(Color.primaryText)

                Text(error)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - First Launch Overlay
/// Full-screen overlay for first launch data loading
struct FirstLaunchOverlay: View {
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
                            .font(Typography.UI.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(Color.accentGold)
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, AppTheme.Spacing.xxxl)
                }
            }
        }
    }
}

// MARK: - Streaming Content View
/// Displays progressive AI response with skeleton loading and phased reveals
/// Implements the "ink-bleed" animation effect from illuminated manuscript design
struct StreamingContentView: View {
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
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
        HStack(spacing: AppTheme.Spacing.sm) {
            if isLoading {
                ProgressView()
                    .scaleEffect(AppTheme.Scale.reduced)
                    .tint(Color.divineGold)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(Typography.UI.iconSm)
                    .foregroundStyle(Color.success)
            }

            Text(progressStage.message)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
        }
        .animation(AppTheme.Animation.standard, value: progressStage)
    }

    // MARK: - Skeleton Content

    private var skeletonContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Summary skeleton
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                GoldShimmerLine(width: .infinity)
                GoldShimmerLine(width: 280)
                GoldShimmerLine(width: 220)
            }

            // Key points label skeleton
            GoldShimmerLine(width: 100)
                .padding(.top, AppTheme.Spacing.sm)

            // Key points skeletons
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(Color.secondaryText.opacity(AppTheme.Opacity.medium))
                            .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
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
            .font(Typography.UI.body)
            .foregroundStyle(Color.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(showSummary ? 1 : 0)
            .blur(radius: showSummary ? 0 : 8)
            .offset(y: showSummary ? 0 : 4)

        // Key points section
        if !content.keyPoints.isEmpty {
            Text("Key Points")
                .font(Typography.UI.caption1Bold)
                .foregroundStyle(Color.secondaryText)
                .padding(.top, AppTheme.Spacing.sm)
                .opacity(showKeyPoints ? 1 : 0)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(content.keyPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(Color.divineGold)
                            .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
                            .padding(.top, AppTheme.Spacing.sm - 2)

                        Text(point)
                            .font(Typography.UI.subheadline)
                            .foregroundStyle(Color.primaryText)
                    }
                    .opacity(index < visibleKeyPointCount ? 1 : 0)
                    .blur(radius: index < visibleKeyPointCount ? 0 : 4)
                    .offset(y: index < visibleKeyPointCount ? 0 : 4)
                }
            }
        }

        // Sources
        if !content.sources.isEmpty {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "checkmark.shield")
                    .font(Typography.UI.caption2)
                Text("Sources: \(content.sources.joined(separator: ", "))")
                    .font(Typography.UI.caption2)
            }
            .foregroundStyle(Color.tertiaryText)
            .opacity(showSources ? 1 : 0)
            .padding(.top, AppTheme.Spacing.sm)
        }
    }

    // MARK: - Animation

    private func startRevealAnimation() {
        // Summary appears first
        withAnimation(AppTheme.Animation.sacredSpring) {
            showSummary = true
        }

        // Key points label after delay
        withAnimation(AppTheme.Animation.standard.delay(0.3)) {
            showKeyPoints = true
        }

        // Key points stagger in
        if let content = content {
            for index in 0..<content.keyPoints.count {
                let delay = 0.5 + Double(index) * 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(AppTheme.Animation.spring) {
                        visibleKeyPointCount = index + 1
                    }
                }
            }

            // Sources appear last
            let sourcesDelay = 0.5 + Double(content.keyPoints.count) * 0.15 + 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + sourcesDelay) {
                withAnimation(AppTheme.Animation.standard) {
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

// MARK: - Gold Shimmer Line

private struct GoldShimmerLine: View {
    let width: CGFloat

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
            .fill(
                LinearGradient(
                    colors: [
                        Color.secondaryText.opacity(AppTheme.Opacity.lightMedium),
                        Color.goldLeafShimmer.opacity(AppTheme.Opacity.disabled),
                        Color.secondaryText.opacity(AppTheme.Opacity.lightMedium)
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
                withAnimation(AppTheme.Animation.shimmer) {
                    shimmerOffset = 300
                }
            }
    }
}

// MARK: - Preview
#Preview("Loading Views") {
    VStack(spacing: AppTheme.Spacing.xxxl) {
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
