import SwiftUI

// MARK: - Illuminated Coach Mark
// First-time guidance with illuminated manuscript aesthetics
// Feels like a wise scribe pointing to the page

struct IlluminatedCoachMark: View {
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
        colorScheme == .dark
            ? Color.chapelShadow.opacity(AppTheme.Opacity.nearOpaque + 0.03)
            : Color.freshVellum.opacity(AppTheme.Opacity.nearOpaque + 0.03)
    }

    private var textColor: Color {
        colorScheme == .dark
            ? Color.moonlitParchment
            : Color.monasteryBlack
    }

    var body: some View {
        ZStack {
            // Backdrop (dismisses on tap)
            Color.black.opacity(AppTheme.Opacity.medium)
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack(spacing: AppTheme.Spacing.sm) {
                // Sparkle icon
                Image(systemName: type.icon)
                    .font(Typography.UI.iconSm.weight(.semibold))
                    .foregroundStyle(Color.divineGold)
                    .rotationEffect(.degrees(sparkleRotation))

                // Title
                Text(type.title)
                    .font(Typography.Codex.illuminatedHeader)
                    .tracking(Typography.Codex.headerTracking)
                    .foregroundStyle(Color.divineGold)
            }
            .opacity(textOpacity)

            // Message
            Text(type.message)
                .font(Typography.Codex.body)
                .foregroundStyle(textColor)
                .lineSpacing(Typography.Codex.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(textOpacity)

            // Buttons
            HStack(spacing: AppTheme.Spacing.md) {
                Spacer()

                // Later button
                Button(action: onLater) {
                    Text("Later")
                        .font(Typography.UI.buttonLabel)
                        .foregroundStyle(Color.divineGold)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
                .buttonStyle(.plain)
                .opacity(textOpacity)

                // Begin button
                Button(action: onBegin) {
                    Text("Begin")
                        .font(Typography.UI.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .fill(Color.divineGold)
                        )
                }
                .buttonStyle(.plain)
                .opacity(textOpacity)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: cardMaxWidth)
        .background(cardBackground)
        .overlay(goldBorderOverlay)
        .shadow(
            color: .black.opacity(AppTheme.Opacity.light),
            radius: 32,
            x: 0,
            y: 12
        )
        .shadow(
            color: Color.divineGold.opacity(AppTheme.Opacity.subtle),
            radius: 20,
            x: 0,
            y: 0
        )
        .padding(.horizontal, AppTheme.Spacing.xl)
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
                .stroke(Color.divineGold, lineWidth: AppTheme.Border.regular)
                .opacity(borderProgress)

            // Inner border (double-border manuscript effect)
            RoundedRectangle(cornerRadius: cardCornerRadius - 2)
                .stroke(Color.goldLeafShimmer, lineWidth: AppTheme.Border.hairline)
                .padding(AppTheme.Spacing.xxs)
                .opacity(borderProgress * 0.6)
        }
    }

    // MARK: - Target Highlight

    private func targetHighlight(frame: CGRect) -> some View {
        let expandedFrame = frame.insetBy(dx: -8, dy: -8)

        return ZStack {
            // Pulsing gold glow
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.divineGold.opacity(targetGlowOpacity))
                .frame(width: expandedFrame.width, height: expandedFrame.height)

            // Gold ring
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.divineGold, lineWidth: AppTheme.Border.regular)
                .frame(width: expandedFrame.width, height: expandedFrame.height)
                .scaleEffect(targetPulseScale)
        }
        .position(x: expandedFrame.midX, y: expandedFrame.midY)
    }

    // MARK: - Animation

    private func animateEntrance() {
        // Card scales in
        withAnimation(AppTheme.Animation.sacredSpring.delay(0.15)) {
            isVisible = true
        }

        // Border draws in
        withAnimation(AppTheme.Animation.luminous.delay(0.4)) {
            borderProgress = 1.0
        }

        // Text fades in
        withAnimation(AppTheme.Animation.standard.delay(0.5)) {
            textOpacity = 1.0
        }

        // Sparkle rotation
        withAnimation(AppTheme.Animation.sacredRotation.delay(0.6)) {
            sparkleRotation = 360
        }

        // Target pulse animation
        if targetFrame != nil {
            withAnimation(AppTheme.Animation.pulse.delay(0.6)) {
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
                    IlluminatedCoachMark(
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
            .animation(AppTheme.Animation.standard, value: coachMarkManager.currentCoachMark)
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
        IlluminatedCoachMark(
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
        IlluminatedCoachMark(
            type: .multiSelectTutorial,
            targetFrame: nil,
            onBegin: { print("Begin tapped") },
            onLater: { print("Later tapped") }
        )
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.candlelitStone.ignoresSafeArea()
    }
    .overlay {
        IlluminatedCoachMark(
            type: .categoryTutorial,
            targetFrame: nil,
            onBegin: { print("Begin tapped") },
            onLater: { print("Later tapped") }
        )
    }
    .preferredColorScheme(.dark)
}
