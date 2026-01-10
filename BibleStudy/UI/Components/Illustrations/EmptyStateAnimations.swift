import SwiftUI

// MARK: - Empty State Animations
// Lines & connections themed animations for each empty state type

// MARK: - No Highlights Animation
// Dots connected by golden lines, highlight shapes forming

struct NoHighlightsAnimation: View {
    @State private var highlightOpacity: Double = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Network of connected dots
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "a", x: 0.2, y: 0.3, size: 8, state: .idle),
                    NetworkNode(id: "b", x: 0.4, y: 0.5, size: 10, state: .pulsing),
                    NetworkNode(id: "c", x: 0.6, y: 0.3, size: 8, state: .idle),
                    NetworkNode(id: "d", x: 0.8, y: 0.5, size: 8, state: .idle),
                    NetworkNode(id: "e", x: 0.5, y: 0.7, size: 10, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "a", to: "b", isActive: true),
                    NetworkConnection(from: "b", to: "c", isActive: true),
                    NetworkConnection(from: "c", to: "d", dashed: true),
                    NetworkConnection(from: "b", to: "e", dashed: true),
                ]
            )

            // Forming highlight shape
            HighlightShapeIndicator()
                .opacity(highlightOpacity)
                .offset(x: 20, y: -10)
        }
        .onAppear {
            guard !respectsReducedMotion else {
                highlightOpacity = 0.5
                return
            }
            withAnimation(Theme.Animation.slowFade.repeatForever(autoreverses: true)) {
                highlightOpacity = 0.6
            }
        }
    }
}

private struct HighlightShapeIndicator: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.input)
            .fill(Color.decorativeGold.opacity(Theme.Opacity.medium))
            .frame(width: 60, height: 20)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy), lineWidth: Theme.Stroke.hairline)
            )
    }
}

// MARK: - No Notes Animation
// Flowing pen-stroke lines connecting thought nodes

struct NoNotesAnimation: View {
    var body: some View {
        ZStack {
            // Thought nodes
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "thought1", x: 0.25, y: 0.35, size: 12, state: .pulsing),
                    NetworkNode(id: "thought2", x: 0.75, y: 0.35, size: 10, state: .idle),
                    NetworkNode(id: "thought3", x: 0.5, y: 0.65, size: 10, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "thought1", to: "thought2", isFlowing: true, flowSpeed: 3, curved: true, curvature: 0.2),
                    NetworkConnection(from: "thought1", to: "thought3", curved: true, curvature: -0.15, dashed: true),
                    NetworkConnection(from: "thought2", to: "thought3", dashed: true),
                ]
            )

            // Pen stroke indicator
            PenStrokeLines()
                .offset(y: 15)
        }
    }
}

private struct PenStrokeLines: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var lineProgress: CGFloat = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: CGPoint(x: size.width * 0.3, y: size.height * 0.7))
                p.addQuadCurve(
                    to: CGPoint(x: size.width * 0.7, y: size.height * 0.75),
                    control: CGPoint(x: size.width * 0.5, y: size.height * 0.6)
                )
            }

            let progress = respectsReducedMotion ? 1.0 : lineProgress
            let trimmed = path.trimmedPath(from: 0, to: progress)

            context.stroke(
                trimmed,
                with: .color(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled)),
                style: StrokeStyle(lineWidth: Theme.Stroke.control, lineCap: .round)
            )
        }
        .onAppear {
            guard !respectsReducedMotion else { return }
            withAnimation(Theme.Animation.slowFade.repeatForever(autoreverses: true)) {
                lineProgress = 1
            }
        }
    }
}

// MARK: - No Cross References Animation
// Network graph with nodes pulsing, seeking connections

struct NoCrossRefsAnimation: View {
    var body: some View {
        NetworkGraph(
            nodes: [
                NetworkNode(id: "source", x: 0.5, y: 0.3, size: 14, state: .pulsing),
                NetworkNode(id: "ref1", x: 0.2, y: 0.6, size: 8, state: .idle),
                NetworkNode(id: "ref2", x: 0.5, y: 0.7, size: 8, state: .idle),
                NetworkNode(id: "ref3", x: 0.8, y: 0.6, size: 8, state: .idle),
            ],
            connections: [
                NetworkConnection(from: "source", to: "ref1", isActive: false, dashed: true),
                NetworkConnection(from: "source", to: "ref2", isActive: false, dashed: true),
                NetworkConnection(from: "source", to: "ref3", isActive: false, dashed: true),
            ],
            staggerDelay: 0.15
        )
    }
}

// MARK: - No Topics Animation
// Search node with radiating connection lines

struct NoTopicsAnimation: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Radiating search pattern
            NetworkGraph.star(rayCount: 6, centerActive: true)

            // Search indicator in center
            Image(systemName: "magnifyingglass")
                .font(Typography.Command.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
        }
    }
}

// MARK: - No Plans Animation
// Timeline nodes connecting in sequence

struct NoPlansAnimation: View {
    var body: some View {
        ZStack {
            // Timeline network
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "day1", x: 0.15, y: 0.5, size: 10, state: .pulsing),
                    NetworkNode(id: "day2", x: 0.35, y: 0.5, size: 10, state: .idle),
                    NetworkNode(id: "day3", x: 0.55, y: 0.5, size: 10, state: .idle),
                    NetworkNode(id: "day4", x: 0.75, y: 0.5, size: 10, state: .idle),
                    NetworkNode(id: "goal", x: 0.9, y: 0.5, size: 12, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "day1", to: "day2", dashed: true),
                    NetworkConnection(from: "day2", to: "day3", dashed: true),
                    NetworkConnection(from: "day3", to: "day4", dashed: true),
                    NetworkConnection(from: "day4", to: "goal", dashed: true),
                ]
            )

            // Calendar indicator
            CalendarIndicator()
                .offset(y: -35)
        }
    }
}

private struct CalendarIndicator: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.input)
            .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled), lineWidth: Theme.Stroke.hairline)
            .frame(width: 30, height: 26)
            .overlay(
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled))
                        .frame(height: Theme.Stroke.control)
                    Spacer()
                }
            )
    }
}

// MARK: - No Messages Animation
// Neural network pattern with question mark node

struct NoMessagesAnimation: View {
    var body: some View {
        ZStack {
            // Neural network
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "q", x: 0.3, y: 0.4, size: 16, state: .pulsing),
                    NetworkNode(id: "n1", x: 0.55, y: 0.25, size: 8, state: .idle),
                    NetworkNode(id: "n2", x: 0.7, y: 0.45, size: 10, state: .idle),
                    NetworkNode(id: "n3", x: 0.55, y: 0.65, size: 8, state: .idle),
                    NetworkNode(id: "a", x: 0.85, y: 0.45, size: 12, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "q", to: "n1", isFlowing: true, flowSpeed: 2.5),
                    NetworkConnection(from: "q", to: "n2", isFlowing: true, flowSpeed: 3),
                    NetworkConnection(from: "q", to: "n3", isFlowing: true, flowSpeed: 2.8),
                    NetworkConnection(from: "n1", to: "a", dashed: true),
                    NetworkConnection(from: "n2", to: "a", dashed: true),
                    NetworkConnection(from: "n3", to: "a", dashed: true),
                ]
            )

            // Question mark in source node
            Text("?")
                .font(Typography.Command.meta)
                .fontWeight(.bold)
                .foregroundStyle(Color.white)
                .offset(x: -35, y: -10)
        }
    }
}

// MARK: - All Caught Up Animation
// Connected nodes forming checkmark, lines completing

struct AllCaughtUpAnimation: View {
    @State private var showCheckmark = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Success network
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "a", x: 0.2, y: 0.5, size: 10, state: .success),
                    NetworkNode(id: "b", x: 0.4, y: 0.7, size: 12, state: .success),
                    NetworkNode(id: "c", x: 0.75, y: 0.3, size: 10, state: .success),
                ],
                connections: [
                    NetworkConnection(from: "a", to: "b", color: .success, isActive: true),
                    NetworkConnection(from: "b", to: "c", color: .success, isActive: true),
                ]
            )

            // Animated checkmark overlay
            if showCheckmark {
                AnimatedCheckmark(color: .success, size: 50)
                    .offset(y: -5)
            }
        }
        .onAppear {
            let delay = respectsReducedMotion ? 0 : 0.8
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                showCheckmark = true
            }
        }
    }
}

// MARK: - No Verses to Memorize Animation
// Memory pathway lines, waiting for content

struct NoVersesToMemorizeAnimation: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Memory pathways (brain-like pattern)
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "core", x: 0.5, y: 0.45, size: 14, state: .pulsing),
                    NetworkNode(id: "m1", x: 0.25, y: 0.3, size: 8, state: .idle),
                    NetworkNode(id: "m2", x: 0.75, y: 0.3, size: 8, state: .idle),
                    NetworkNode(id: "m3", x: 0.2, y: 0.6, size: 8, state: .idle),
                    NetworkNode(id: "m4", x: 0.8, y: 0.6, size: 8, state: .idle),
                    NetworkNode(id: "m5", x: 0.5, y: 0.75, size: 8, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "core", to: "m1", dashed: true),
                    NetworkConnection(from: "core", to: "m2", dashed: true),
                    NetworkConnection(from: "core", to: "m3", dashed: true),
                    NetworkConnection(from: "core", to: "m4", dashed: true),
                    NetworkConnection(from: "core", to: "m5", dashed: true),
                    NetworkConnection(from: "m1", to: "m3", curved: true, curvature: 0.3, dashed: true),
                    NetworkConnection(from: "m2", to: "m4", curved: true, curvature: -0.3, dashed: true),
                ]
            )

            // Brain/memory indicator
            Image(systemName: "brain.head.profile")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy))
                .offset(x: 0, y: -5)
        }
    }
}

// MARK: - No Search Results Animation
// Magnifying glass with scattered disconnected nodes

struct NoSearchResultsAnimation: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchPulse = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Scattered disconnected nodes
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "s1", x: 0.2, y: 0.3, size: 6, state: .idle),
                    NetworkNode(id: "s2", x: 0.75, y: 0.25, size: 6, state: .idle),
                    NetworkNode(id: "s3", x: 0.15, y: 0.7, size: 6, state: .idle),
                    NetworkNode(id: "s4", x: 0.85, y: 0.65, size: 6, state: .idle),
                    NetworkNode(id: "s5", x: 0.5, y: 0.8, size: 6, state: .idle),
                ],
                connections: [] // No connections - results not found
            )

            // Pulsing search icon in center
            Image(systemName: "magnifyingglass")
                .font(Typography.Command.title2)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy))
                .scaleEffect(searchPulse ? 1.1 : 1.0)
                .opacity(searchPulse ? 0.6 : 1.0)
        }
        .onAppear {
            guard !respectsReducedMotion else { return }
            withAnimation(Theme.Animation.slowFade.repeatForever(autoreverses: true)) {
                searchPulse = true
            }
        }
    }
}

// MARK: - No Bookmarks Animation
// Bookmark shape with fading connection trails

struct NoBookmarksAnimation: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Faint connection trails
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "center", x: 0.5, y: 0.45, size: 14, state: .pulsing),
                    NetworkNode(id: "b1", x: 0.25, y: 0.3, size: 6, state: .idle),
                    NetworkNode(id: "b2", x: 0.75, y: 0.3, size: 6, state: .idle),
                    NetworkNode(id: "b3", x: 0.3, y: 0.7, size: 6, state: .idle),
                    NetworkNode(id: "b4", x: 0.7, y: 0.7, size: 6, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "center", to: "b1", dashed: true),
                    NetworkConnection(from: "center", to: "b2", dashed: true),
                    NetworkConnection(from: "center", to: "b3", dashed: true),
                    NetworkConnection(from: "center", to: "b4", dashed: true),
                ]
            )

            // Bookmark indicator in center
            Image(systemName: "bookmark")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy))
        }
    }
}

// MARK: - No History Animation
// Timeline with fading past nodes

struct NoHistoryAnimation: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Timeline nodes fading into past
            NetworkGraph(
                nodes: [
                    NetworkNode(id: "now", x: 0.85, y: 0.5, size: 12, state: .pulsing),
                    NetworkNode(id: "h1", x: 0.65, y: 0.5, size: 10, state: .idle),
                    NetworkNode(id: "h2", x: 0.45, y: 0.5, size: 8, state: .idle),
                    NetworkNode(id: "h3", x: 0.25, y: 0.5, size: 6, state: .idle),
                    NetworkNode(id: "h4", x: 0.1, y: 0.5, size: 4, state: .idle),
                ],
                connections: [
                    NetworkConnection(from: "now", to: "h1", dashed: true),
                    NetworkConnection(from: "h1", to: "h2", dashed: true),
                    NetworkConnection(from: "h2", to: "h3", dashed: true),
                    NetworkConnection(from: "h3", to: "h4", dashed: true),
                ]
            )

            // Clock indicator
            Image(systemName: "clock.arrow.circlepath")
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.disabled))
                .offset(y: -35)
        }
    }
}

// MARK: - Preview
#Preview("Empty State Animations") {
    ScrollView {
        VStack(spacing: Theme.Spacing.xxl) {
            Group {
                Text("No Highlights").font(Typography.Command.headline)
                NoHighlightsAnimation()
                    .frame(height: 120)

                Text("No Notes").font(Typography.Command.headline)
                NoNotesAnimation()
                    .frame(height: 120)

                Text("No Cross References").font(Typography.Command.headline)
                NoCrossRefsAnimation()
                    .frame(height: 120)
            }

            Group {
                Text("No Topics").font(Typography.Command.headline)
                NoTopicsAnimation()
                    .frame(height: 120)

                Text("No Plans").font(Typography.Command.headline)
                NoPlansAnimation()
                    .frame(height: 100)

                Text("No Messages").font(Typography.Command.headline)
                NoMessagesAnimation()
                    .frame(height: 120)
            }

            Group {
                Text("All Caught Up").font(Typography.Command.headline)
                AllCaughtUpAnimation()
                    .frame(height: 120)

                Text("No Verses to Memorize").font(Typography.Command.headline)
                NoVersesToMemorizeAnimation()
                    .frame(height: 140)

                Text("No Search Results").font(Typography.Command.headline)
                NoSearchResultsAnimation()
                    .frame(height: 120)

                Text("No Bookmarks").font(Typography.Command.headline)
                NoBookmarksAnimation()
                    .frame(height: 120)

                Text("No History").font(Typography.Command.headline)
                NoHistoryAnimation()
                    .frame(height: 100)
            }
        }
        .padding()
    }
    .background(Color.appBackground)
}
