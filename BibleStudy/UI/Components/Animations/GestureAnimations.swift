import SwiftUI

// MARK: - Gesture Animations
// Interactive gesture-driven animations for the illuminated manuscript theme
// Includes: interactive glow, verse ripple, swipe navigation, pull indicators

// MARK: - Interactive Glow Modifier
// Press response with luminous fade effect

struct InteractiveGlowModifier: ViewModifier {
    let color: Color
    let intensity: Double

    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(color.opacity(isPressed ? intensity : 0))
                    .allowsHitTesting(false)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.luminous, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    /// Add interactive glow on press
    func interactiveGlow(
        color: Color = Color.divineGold,
        intensity: Double = 0.15
    ) -> some View {
        modifier(InteractiveGlowModifier(color: color, intensity: intensity))
    }
}

// MARK: - Verse Ripple Effect
// Long-press expanding ring from touch point

struct VerseRippleModifier: ViewModifier {
    let color: Color
    let onRippleComplete: (() -> Void)?

    @State private var ripplePosition: CGPoint = .zero
    @State private var showRipple = false
    @State private var rippleScale: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Circle()
                        .fill(color.opacity(AppTheme.Opacity.medium))
                        .frame(width: 60, height: 60)
                        .scaleEffect(rippleScale)
                        .opacity(showRipple ? 0 : AppTheme.Opacity.strong)
                        .position(ripplePosition)
                        .allowsHitTesting(false)
                }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.3)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onEnded { value in
                        switch value {
                        case .second(true, let drag):
                            if let location = drag?.location {
                                triggerRipple(at: location)
                            }
                        default:
                            break
                        }
                    }
            )
    }

    private func triggerRipple(at location: CGPoint) {
        guard !AppTheme.Animation.isReduceMotionEnabled else {
            onRippleComplete?()
            return
        }

        ripplePosition = location
        showRipple = true
        rippleScale = 0

        withAnimation(AppTheme.Animation.luminous) {
            rippleScale = 3
        }

        withAnimation(AppTheme.Animation.luminous.delay(0.1)) {
            showRipple = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            rippleScale = 0
            onRippleComplete?()
        }
    }
}

extension View {
    /// Add verse ripple effect on long press
    func verseRipple(
        color: Color = Color.divineGold,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        modifier(VerseRippleModifier(color: color, onRippleComplete: onComplete))
    }
}

// MARK: - Swipe Navigation Modifier
// Physics-based chapter navigation with rubber-band edges

struct SwipeNavigationModifier: ViewModifier {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let canSwipeLeft: Bool
    let canSwipeRight: Bool

    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    private let threshold: CGFloat = 100
    private let rubberBandFactor: CGFloat = 0.3

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let translation = value.translation.width

                        // Apply rubber-band effect at edges
                        if translation > 0 && !canSwipeRight {
                            offset = translation * rubberBandFactor
                        } else if translation < 0 && !canSwipeLeft {
                            offset = translation * rubberBandFactor
                        } else {
                            offset = translation
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        let translation = value.translation.width

                        if translation > threshold && canSwipeRight {
                            // Swipe right - go to previous
                            HapticService.shared.navigationThreshold()
                            withAnimation(AppTheme.Animation.pageTurn) {
                                offset = 0
                            }
                            onSwipeRight()
                        } else if translation < -threshold && canSwipeLeft {
                            // Swipe left - go to next
                            HapticService.shared.navigationThreshold()
                            withAnimation(AppTheme.Animation.pageTurn) {
                                offset = 0
                            }
                            onSwipeLeft()
                        } else {
                            // Snap back
                            withAnimation(AppTheme.Animation.sacredSpring) {
                                offset = 0
                            }
                        }
                    }
            )
    }
}

extension View {
    /// Add swipe navigation with rubber-band edges
    func swipeNavigation(
        onSwipeLeft: @escaping () -> Void,
        onSwipeRight: @escaping () -> Void,
        canSwipeLeft: Bool = true,
        canSwipeRight: Bool = true
    ) -> some View {
        modifier(SwipeNavigationModifier(
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight,
            canSwipeLeft: canSwipeLeft,
            canSwipeRight: canSwipeRight
        ))
    }
}

// MARK: - Pull Indicator
// Spring arrow showing navigation threshold

struct PullIndicator: View {
    enum Direction {
        case left, right, up, down

        var rotation: Angle {
            switch self {
            case .left: return .degrees(180)
            case .right: return .degrees(0)
            case .up: return .degrees(-90)
            case .down: return .degrees(90)
            }
        }
    }

    let direction: Direction
    let progress: CGFloat // 0 to 1
    let color: Color

    init(
        direction: Direction,
        progress: CGFloat,
        color: Color = Color.divineGold
    ) {
        self.direction = direction
        self.progress = min(max(progress, 0), 1)
        self.color = color
    }

    var body: some View {
        Image(systemName: "chevron.right")
            .font(Typography.UI.iconLg.weight(.medium))
            .foregroundStyle(color.opacity(AppTheme.Opacity.medium + progress * AppTheme.Opacity.overlay))
            .rotationEffect(direction.rotation)
            .scaleEffect(AppTheme.Scale.reduced + progress * 0.4)
            .opacity(progress > 0.1 ? 1 : 0)
            .animation(AppTheme.Animation.quick, value: progress)
    }
}

// MARK: - Gold Shimmer Effect
// Animated shimmer overlay for gold elements

struct GoldShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.illuminatedGold.opacity(AppTheme.Opacity.medium),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: -geometry.size.width * 0.25 + geometry.size.width * 1.5 * phase)
                    .allowsHitTesting(false)
                }
                .mask(content)
            )
            .onAppear {
                guard !AppTheme.Animation.isReduceMotionEnabled else { return }
                withAnimation(AppTheme.Animation.shimmer) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Add gold shimmer effect
    func goldShimmer() -> some View {
        modifier(GoldShimmerModifier())
    }
}

// MARK: - Bounce Scale Effect
// Dignified bounce for selection feedback

struct BounceScaleModifier: ViewModifier {
    let trigger: Bool

    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    guard !AppTheme.Animation.isReduceMotionEnabled else { return }
                    withAnimation(AppTheme.Animation.sacredSpring) {
                        scale = 1.05
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(AppTheme.Animation.sacredSpring) {
                            scale = 1
                        }
                    }
                }
            }
    }
}

extension View {
    /// Add bounce scale effect on trigger
    func bounceScale(trigger: Bool) -> some View {
        modifier(BounceScaleModifier(trigger: trigger))
    }
}

// MARK: - Fade Slide Transition
// Elegant fade with subtle slide

struct FadeSlideModifier: ViewModifier {
    let isVisible: Bool
    let direction: Edge

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(
                x: offsetX,
                y: offsetY
            )
            .animation(AppTheme.Animation.reverent, value: isVisible)
    }

    private var offsetX: CGFloat {
        guard !isVisible else { return 0 }
        switch direction {
        case .leading: return -20
        case .trailing: return 20
        default: return 0
        }
    }

    private var offsetY: CGFloat {
        guard !isVisible else { return 0 }
        switch direction {
        case .top: return -20
        case .bottom: return 20
        default: return 0
        }
    }
}

extension View {
    /// Add fade slide transition
    func fadeSlide(isVisible: Bool, from direction: Edge = .bottom) -> some View {
        modifier(FadeSlideModifier(isVisible: isVisible, direction: direction))
    }
}

// MARK: - Stagger Animation Container
// Staggered reveal for list items

struct StaggeredAnimationContainer<Content: View>: View {
    let itemCount: Int
    let delayPerItem: Double
    let content: (Int, Bool) -> Content

    @State private var animatedItems: Set<Int> = []

    init(
        itemCount: Int,
        delayPerItem: Double = 0.05,
        @ViewBuilder content: @escaping (Int, Bool) -> Content
    ) {
        self.itemCount = itemCount
        self.delayPerItem = delayPerItem
        self.content = content
    }

    var body: some View {
        ForEach(0..<itemCount, id: \.self) { index in
            content(index, animatedItems.contains(index))
                .onAppear {
                    guard !AppTheme.Animation.isReduceMotionEnabled else {
                        _ = animatedItems.insert(index)
                        return
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * delayPerItem) {
                        withAnimation(AppTheme.Animation.unfurl) {
                            _ = animatedItems.insert(index)
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview("Interactive Glow") {
    VStack(spacing: AppTheme.Spacing.xl - 4) {
        Text("Tap and hold")
            .font(Typography.Scripture.body())
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .interactiveGlow()

        Text("Gold accent")
            .font(Typography.Scripture.body())
            .padding()
            .background(Color.monasteryStone)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
            .interactiveGlow(color: Color.divineGold, intensity: 0.25)
    }
    .padding()
}

#Preview("Pull Indicators") {
    HStack(spacing: AppTheme.Spacing.xxxl - 8) {
        VStack(spacing: AppTheme.Spacing.xl - 4) {
            PullIndicator(direction: .left, progress: 0.3)
            PullIndicator(direction: .left, progress: 0.6)
            PullIndicator(direction: .left, progress: 1.0)
        }

        VStack(spacing: AppTheme.Spacing.xl - 4) {
            PullIndicator(direction: .right, progress: 0.3)
            PullIndicator(direction: .right, progress: 0.6)
            PullIndicator(direction: .right, progress: 1.0)
        }
    }
    .padding()
}

#Preview("Gold Shimmer") {
    Text("GENESIS")
        .font(Typography.Illuminated.bookTitle())
        .foregroundStyle(Color.divineGold)
        .goldShimmer()
        .padding()
}
