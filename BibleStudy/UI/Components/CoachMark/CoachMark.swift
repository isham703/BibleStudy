import SwiftUI

// MARK: - Illuminated Coach Mark
// First-time guidance with illuminated manuscript aesthetics
// Feels like a wise scribe pointing to the page

struct CoachMark: View {
    let type: CoachMarkType
    let targetFrame: CGRect?
    let onBegin: () -> Void
    let onLater: () -> Void

    // MARK: - Animation State

    @State private var isVisible = false
    @State private var borderProgress: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var sparkleRotation: Double = 0
    @State private var targetPulseScale: CGFloat = 1.0
    @State private var targetGlowOpacity: Double = 0.1
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Layout Constants

    private let cardCornerRadius: CGFloat = 12
    private let cardMaxWidth: CGFloat = 300
    private let arrowSize: CGSize = CGSize(width: 16, height: 10)

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        Colors.Surface.surface(for: ThemeMode.current(from: colorScheme))
            .opacity(Theme.Opacity.nearOpaque + 0.03)
    }

    private var textColor: Color {
        Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme))
    }

    var body: some View {
        ZStack {
            // Backdrop (dismisses on tap)
            Color.black.opacity(Theme.Opacity.medium)
                .ignoresSafeArea()
                .onTapGesture {
                    onLater()
                }

            // Target highlight (pulsing gold ring)
            if let targetFrame = targetFrame {
                targetHighlight(frame: targetFrame)
            }

            // Coach mark card
            coachMarkCard
                .scaleEffect(isVisible ? 1.0 : 0.85)
                .opacity(isVisible ? 1.0 : 0)
        }
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Coach Mark Card

    private var coachMarkCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                // Sparkle icon
                Image(systemName: type.icon)
                    .font(Typography.Icon.sm.weight(.semibold))
                    .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                    .rotationEffect(.degrees(sparkleRotation))

                // Title
                Text(type.title)
                    .font(Typography.Scripture.heading)
                    .tracking(2.5)
                    .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
            }
            .opacity(textOpacity)

            // Message
            Text(type.message)
                .font(Typography.Scripture.body)
                .foregroundStyle(textColor)
                .lineSpacing(Typography.Scripture.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(textOpacity)

            // Buttons
            HStack(spacing: Theme.Spacing.md) {
                Spacer()

                // Later button
                Button(action: onLater) {
                    Text("Later")
                        .font(Typography.Command.cta)
                        .foregroundStyle(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.plain)
                .opacity(textOpacity)

                // Begin button
                Button(action: onBegin) {
                    Text("Begin")
                        .font(Typography.Command.cta)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.button)
                                .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)))
                        )
                }
                .buttonStyle(.plain)
                .opacity(textOpacity)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: cardMaxWidth)
        .background(cardBackground)
        .overlay(goldBorderOverlay)
        .shadow(
            color: .black.opacity(Theme.Opacity.light),
            radius: 32,
            x: 0,
            y: 12
        )
        .shadow(
            color: Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle),
            radius: 20,
            x: 0,
            y: 0
        )
        .padding(.horizontal, Theme.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.title). \(type.message)")
        .accessibilityHint("Double tap to begin, or swipe right for later")
        .accessibilityAction(named: "Begin") { onBegin() }
        .accessibilityAction(named: "Dismiss for later") { onLater() }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .fill(backgroundColor)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .fill(.ultraThinMaterial)
            )
    }

    // MARK: - Gold Border Overlay

    private var goldBorderOverlay: some View {
        ZStack {
            // Outer border
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.control)
                .opacity(borderProgress)

            // Inner border (double-border manuscript effect)
            RoundedRectangle(cornerRadius: cardCornerRadius - 2)
                .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.heavy), lineWidth: Theme.Stroke.hairline)
                .padding(2)
                .opacity(borderProgress * 0.6)
        }
    }

    // MARK: - Target Highlight

    private func targetHighlight(frame: CGRect) -> some View {
        let expandedFrame = frame.insetBy(dx: -8, dy: -8)

        return ZStack {
            // Pulsing gold glow
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(targetGlowOpacity))
                .frame(width: expandedFrame.width, height: expandedFrame.height)

            // Gold ring
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.control)
                .frame(width: expandedFrame.width, height: expandedFrame.height)
                .scaleEffect(targetPulseScale)
        }
        .position(x: expandedFrame.midX, y: expandedFrame.midY)
    }

    // MARK: - Animation

    private func animateEntrance() {
        // Card scales in
        withAnimation(Theme.Animation.settle.delay(0.15)) {
            isVisible = true
        }

        // Border draws in
        withAnimation(Theme.Animation.slowFade.delay(0.4)) {
            borderProgress = 1.0
        }

        // Text fades in
        withAnimation(Theme.Animation.settle.delay(0.5)) {
            textOpacity = 1.0
        }

        // Sparkle rotation
        withAnimation(Theme.Animation.slowFade.delay(0.6)) {
            sparkleRotation = 360
        }

        // Target pulse animation
        if targetFrame != nil {
            withAnimation(Theme.Animation.fade.delay(0.6)) {
                targetPulseScale = 1.02
                targetGlowOpacity = 0.2
            }
        }

        // Haptic on appear
        HapticService.shared.lightTap()
    }
}

// MARK: - Coach Mark Overlay Modifier

struct CoachMarkOverlayModifier: ViewModifier {
    @State private var coachMarkManager = CoachMarkManager.shared
    var targetFrame: CGRect?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let coachMark = coachMarkManager.currentCoachMark {
                    CoachMark(
                        type: coachMark,
                        targetFrame: targetFrame,
                        onBegin: {
                            coachMarkManager.beginFromCoachMark()
                        },
                        onLater: {
                            coachMarkManager.dismissForLater()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .animation(Theme.Animation.settle, value: coachMarkManager.currentCoachMark)
            .environment(\.coachMarkManager, coachMarkManager)
    }
}

extension View {
    /// Adds a coach mark overlay that displays tutorial hints
    func coachMarkOverlay(targetFrame: CGRect? = nil) -> some View {
        self.modifier(CoachMarkOverlayModifier(targetFrame: targetFrame))
    }
}

// MARK: - Preview

#Preview("Highlight Tutorial") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack {
            Text("Sample verse text here")
                .padding()
        }
    }
    .overlay {
        CoachMark(
            type: .highlightTutorial,
            targetFrame: CGRect(x: 50, y: 200, width: 300, height: 60),
            onBegin: { print("Begin tapped") },
            onLater: { print("Later tapped") }
        )
    }
}

#Preview("Multi-Select Tutorial") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
    }
    .overlay {
        CoachMark(
            type: .multiSelectTutorial,
            targetFrame: nil,
            onBegin: { print("Begin tapped") },
            onLater: { print("Later tapped") }
        )
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.surfaceInk.ignoresSafeArea()
    }
    .overlay {
        CoachMark(
            type: .categoryTutorial,
            targetFrame: nil,
            onBegin: { print("Begin tapped") },
            onLater: { print("Later tapped") }
        )
    }
    .preferredColorScheme(.dark)
}
