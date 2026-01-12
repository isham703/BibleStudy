import SwiftUI

// MARK: - Sacred Transitions
// Custom view transitions inspired by illuminated manuscript aesthetics
// Includes: unfurl, illuminate, manuscript, ascend

// MARK: - Transition Types

enum SacredTransitionStyle {
    case unfurl        // Scroll-like vertical reveal
    case illuminate    // Light bloom from center
    case manuscript    // Page turn with golden edge
    case ascend        // Rise with particle trail
    case fade          // Simple elegant fade
    case scale         // Scale with fade
}

// MARK: - Unfurl Transition
// Scroll-like vertical reveal animation

struct UnfurlTransition: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(y: isActive ? 1 : 0, anchor: .top)
            .opacity(isActive ? 1 : 0)
            .animation(Theme.Animation.settle, value: isActive)
    }
}

// MARK: - Illuminate Transition
// Light bloom from center

struct IlluminateTransition: ViewModifier {
    let isActive: Bool

    @State private var glowOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        ZStack {
            // Glow effect
            if !reduceMotion {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("AccentBronze").opacity(Theme.Opacity.disabled),
                                Color("AccentBronze").opacity(Theme.Opacity.subtle),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .scaleEffect(isActive ? 2 : 0)
                    .opacity(glowOpacity)
                    .allowsHitTesting(false)
            }

            content
                .scaleEffect(isActive ? 1 : 0.8)
                .opacity(isActive ? 1 : 0)
        }
        .animation(Theme.Animation.slowFade, value: isActive)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                // Flash glow then fade
                withAnimation(Theme.Animation.fade) {
                    glowOpacity = 1
                }
                withAnimation(Theme.Animation.slowFade.delay(0.2)) {
                    glowOpacity = 0
                }
            }
        }
    }
}

// MARK: - Manuscript Transition
// Page-like reveal with golden edge hint

struct ManuscriptTransition: ViewModifier {
    let isActive: Bool
    let direction: Edge

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isActive ? 0 : (direction == .leading ? -90 : 90)),
                axis: (x: 0, y: 1, z: 0),
                anchor: direction == .leading ? .trailing : .leading,
                perspective: 0.3
            )
            .opacity(isActive ? 1 : 0)
            .overlay(
                // Golden edge highlight
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AccentBronze").opacity(isActive ? 0 : 0.85),
                                Color.clear
                            ],
                            startPoint: direction == .leading ? .trailing : .leading,
                            endPoint: direction == .leading ? .leading : .trailing
                        )
                    )
                    .allowsHitTesting(false)
            )
            .animation(Theme.Animation.fade, value: isActive)
    }
}

// MARK: - Ascend Transition
// Rise with subtle trail effect

struct AscendTransition: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: isActive ? 0 : 30)
            .opacity(isActive ? 1 : 0)
            .blur(radius: isActive ? 0 : 2)
            .animation(Theme.Animation.slowFade, value: isActive)
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply unfurl transition (scroll-like reveal)
    func unfurlTransition(isActive: Bool) -> some View {
        modifier(UnfurlTransition(isActive: isActive))
    }

    /// Apply illuminate transition (light bloom)
    func illuminateTransition(isActive: Bool) -> some View {
        modifier(IlluminateTransition(isActive: isActive))
    }

    /// Apply manuscript transition (page turn)
    func manuscriptTransition(isActive: Bool, from direction: Edge = .trailing) -> some View {
        modifier(ManuscriptTransition(isActive: isActive, direction: direction))
    }

    /// Apply ascend transition (rise up)
    func ascendTransition(isActive: Bool) -> some View {
        modifier(AscendTransition(isActive: isActive))
    }

    /// Apply sacred transition by style
    func sacredTransition(
        _ style: SacredTransitionStyle,
        isActive: Bool,
        direction: Edge = .trailing
    ) -> some View {
        Group {
            switch style {
            case .unfurl:
                self.unfurlTransition(isActive: isActive)
            case .illuminate:
                self.illuminateTransition(isActive: isActive)
            case .manuscript:
                self.manuscriptTransition(isActive: isActive, from: direction)
            case .ascend:
                self.ascendTransition(isActive: isActive)
            case .fade:
                self.opacity(isActive ? 1 : 0)
                    .animation(Theme.Animation.slowFade, value: isActive)
            case .scale:
                self.scaleEffect(isActive ? 1 : 0.9)
                    .opacity(isActive ? 1 : 0)
                    .animation(Theme.Animation.settle, value: isActive)
            }
        }
    }
}

// MARK: - AnyTransition Extensions

extension AnyTransition {
    /// Unfurl from top like unrolling a scroll
    static var unfurl: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0, anchor: .top).combined(with: .opacity),
            removal: .scale(scale: 0, anchor: .bottom).combined(with: .opacity)
        )
    }

    /// Illuminate with golden glow
    static var illuminate: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }

    /// Page turn from right
    static var manuscriptFromRight: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Page turn from left
    static var manuscriptFromLeft: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    /// Ascend from below
    static var ascend: AnyTransition {
        .asymmetric(
            insertion: .offset(y: 30).combined(with: .opacity),
            removal: .offset(y: -30).combined(with: .opacity)
        )
    }

    /// Reverent fade (slower, more dignified)
    static var reverentFade: AnyTransition {
        .opacity.animation(Theme.Animation.slowFade)
    }
}

// MARK: - Navigation Transition Container
// Handles chapter-to-chapter navigation with appropriate transitions

struct NavigationTransitionContainer<Content: View>: View {
    let navigationDirection: NavigationDirection
    let content: () -> Content

    @State private var isVisible = false

    enum NavigationDirection {
        case forward, backward, none
    }

    init(
        direction: NavigationDirection = .none,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.navigationDirection = direction
        self.content = content
    }

    var body: some View {
        content()
            .manuscriptTransition(
                isActive: isVisible,
                from: navigationDirection == .forward ? .trailing : .leading
            )
            .onAppear {
                isVisible = true
            }
    }
}

// MARK: - Celebration Transition
// Special transition for achievements and milestones

struct CelebrationTransitionModifier: ViewModifier {
    let isActive: Bool
    let onComplete: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1 : 0.5)
            .opacity(isActive ? 1 : 0)
            .animation(Theme.Animation.settle, value: isActive)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    HapticService.shared.goldenBurst()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete?()
                    }
                }
            }
    }
}

extension View {
    /// Apply celebration transition with particle burst
    func celebrationTransition(
        isActive: Bool,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        modifier(CelebrationTransitionModifier(isActive: isActive, onComplete: onComplete))
    }
}

// MARK: - Preview

#Preview("Unfurl Transition") {
    struct PreviewContainer: View {
        @State private var isActive = false

        var body: some View {
            VStack {
                Button("Toggle") {
                    isActive.toggle()
                }

                Text("Scroll-like reveal")
                    .font(Typography.Scripture.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .unfurlTransition(isActive: isActive)
            }
            .padding()
        }
    }

    return PreviewContainer()
}

#Preview("Illuminate Transition") {
    struct PreviewContainer: View {
        @State private var isActive = false

        var body: some View {
            VStack {
                Button("Toggle") {
                    isActive.toggle()
                }

                Text("Light bloom effect")
                    .font(Typography.Scripture.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .illuminateTransition(isActive: isActive)
            }
            .padding()
        }
    }

    return PreviewContainer()
}

#Preview("Manuscript Transition") {
    struct PreviewContainer: View {
        @State private var isActive = false

        var body: some View {
            VStack {
                Button("Toggle") {
                    isActive.toggle()
                }

                Text("Page turn effect")
                    .font(Typography.Scripture.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .manuscriptTransition(isActive: isActive)
            }
            .padding()
        }
    }

    return PreviewContainer()
}

#Preview("Celebration Transition") {
    struct PreviewContainer: View {
        @State private var showCelebration = false

        var body: some View {
            VStack {
                Button("Celebrate!") {
                    showCelebration = true
                }

                if showCelebration {
                    VStack {
                        Image(systemName: "star.fill")
                            .font(Typography.Icon.display)
                            .foregroundStyle(Color("AccentBronze"))

                        Text("Achievement!")
                            .font(Typography.Scripture.heading)
                    }
                    .celebrationTransition(isActive: showCelebration) {
                        showCelebration = false
                    }
                }
            }
            .padding()
        }
    }

    return PreviewContainer()
}
