//
//  IlluminatedActionButton.swift
//  BibleStudy
//
//  Miniature illuminated initial style buttons for the IlluminatedContextMenu.
//  Inspired by decorated initials in medieval manuscripts.
//

import SwiftUI

// MARK: - Illuminated Action Button

/// A button styled as a miniature illuminated initial letter.
/// Used for primary actions in the context menu: Copy (C), Highlight (H), Study (S)
struct IlluminatedActionButton: View {
    /// The initial letter to display (e.g., "C" for Copy)
    let letter: Character

    /// The label text below the letter
    let label: String

    /// Whether this is a primary action (shows gold glow)
    let isPrimary: Bool

    /// The action to perform when tapped
    let action: () -> Void

    /// Optional SF Symbol icon to display instead of letter
    var icon: String?

    // MARK: - State

    @State private var isPressed = false
    @State private var showGlow = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let letterSize: CGFloat = 28
    private let buttonSize: CGFloat = 56
    private let glowRadius: CGFloat = 8
    private let pressScale: CGFloat = 0.92
    private let normalScale: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            VStack(spacing: AppTheme.Spacing.xs) {
                // Letter or Icon container
                ZStack {
                    // Background panel for versal style
                    if isPrimary {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(
                                colorScheme == .dark
                                    ? Color.chapelShadow.opacity(AppTheme.Opacity.strong)
                                    : Color.monasteryStone.opacity(AppTheme.Opacity.medium)
                            )
                            .frame(width: buttonSize, height: buttonSize)

                        // Gold border
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.illuminatedGold,
                                        Color.burnishedGold
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: AppTheme.Border.thin
                            )
                            .frame(width: buttonSize, height: buttonSize)
                    }

                    // Glow effect for primary actions
                    if isPrimary && showGlow {
                        letterContent
                            .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                            .blur(radius: glowRadius)
                    }

                    // Main letter/icon with gradient
                    letterContent
                        .foregroundStyle(letterGradient)
                }
                .frame(width: buttonSize, height: buttonSize)

                // Label
                Text(label)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? pressScale : normalScale)
        .animation(AppTheme.Animation.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            if isPrimary {
                // Delayed glow appearance for staggered reveal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(AppTheme.Animation.luminous) {
                        showGlow = true
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Letter Content

    @ViewBuilder
    private var letterContent: some View {
        if let iconName = icon {
            Image(systemName: iconName)
                .font(.system(size: AppTheme.IconSize.large - 4, weight: .medium))
        } else {
            Text(String(letter).uppercased())
                .font(Typography.Illuminated.dropCap(size: letterSize))
        }
    }

    // MARK: - Letter Gradient

    private var letterGradient: some ShapeStyle {
        if isPrimary {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.illuminatedGold,
                        Color.divineGold,
                        Color.burnishedGold
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else {
            return AnyShapeStyle(Color.primaryText)
        }
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic() {
        HapticService.shared.lightTap()
    }
}

// MARK: - Illuminated Highlight Color Button

/// A jewel-tone highlight color button with manuscript pigment label
struct IlluminatedHighlightColorButton: View {
    /// The highlight color to apply
    let color: HighlightColor

    /// Whether this color is currently selected
    let isSelected: Bool

    /// The action to perform when tapped
    let action: () -> Void

    // MARK: - State

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Constants

    private let buttonSize: CGFloat = 32
    private let selectedRingWidth: CGFloat = 2
    private let pressScale: CGFloat = 0.85

    // MARK: - Pigment Labels (Alchemical/Manuscript names)

    private var pigmentLabel: String {
        switch color {
        case .amber: return "Au"     // Aurum (connection amber)
        case .rose: return "Vm"      // Vermillion
        case .blue: return "Lz"      // Lapis Lazuli
        case .green: return "Ma"     // Malachite
        case .purple: return "Am"    // Amethyst
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            HapticService.shared.lightTap()
            action()
        }) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                ZStack {
                    // Outer ring when selected
                    if isSelected {
                        Circle()
                            .stroke(
                                Color.divineGold,
                                lineWidth: selectedRingWidth
                            )
                            .frame(width: buttonSize + AppTheme.Spacing.xs + 2, height: buttonSize + AppTheme.Spacing.xs + 2)
                    }

                    // Main color circle
                    Circle()
                        .fill(color.color)
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(
                            color: color.color.opacity(AppTheme.Opacity.disabled),
                            radius: isSelected ? AppTheme.Spacing.xs + 2 : 3,
                            x: 0,
                            y: AppTheme.Spacing.xxs
                        )

                    // Inner highlight
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(AppTheme.Opacity.medium),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)
                }

                // Pigment label
                Text(pigmentLabel)
                    .font(.system(size: Typography.Scale.xs - 2, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? pressScale : 1.0)
        .animation(AppTheme.Animation.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("\(color.displayName) highlight")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Illuminated Remove Highlight Button

/// Button to remove an existing highlight, styled as empty circle with slash
struct IlluminatedRemoveHighlightButton: View {
    let action: () -> Void

    @State private var isPressed = false

    private let buttonSize: CGFloat = 32

    var body: some View {
        Button(action: {
            HapticService.shared.lightTap()
            action()
        }) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                ZStack {
                    // Empty circle with border
                    Circle()
                        .stroke(
                            Color.tertiaryText,
                            lineWidth: AppTheme.Border.regular - 0.5
                        )
                        .frame(width: buttonSize, height: buttonSize)

                    // Diagonal slash
                    Rectangle()
                        .fill(Color.tertiaryText)
                        .frame(width: AppTheme.Border.regular - 0.5, height: buttonSize - AppTheme.Spacing.sm)
                        .rotationEffect(.degrees(45))
                }

                // Label
                Text("clear")
                    .font(.system(size: Typography.Scale.xs - 2, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? AppTheme.Scale.pressed - 0.1 : 1.0)
        .animation(AppTheme.Animation.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("Remove highlight")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Secondary Action Button

/// A compact button for secondary actions (Share, Note, Collection)
struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticService.shared.lightTap()
            action()
        }) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.UI.iconSm.weight(.medium))

                Text(title)
                    .font(Typography.UI.caption1)
            }
            .foregroundStyle(Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.sm + 2)
            .padding(.vertical, AppTheme.Spacing.xs + 2)
            .background(
                Capsule()
                    .fill(Color.surfaceBackground.opacity(AppTheme.Opacity.strong))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? AppTheme.Scale.pressed : 1.0)
        .animation(AppTheme.Animation.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("Illuminated Action Buttons") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.xxl) {
            // Primary actions
            HStack(spacing: AppTheme.Spacing.xl) {
                IlluminatedActionButton(
                    letter: "C",
                    label: "Copy",
                    isPrimary: true,
                    action: {}
                )

                IlluminatedActionButton(
                    letter: "H",
                    label: "Highlight",
                    isPrimary: true,
                    action: {}
                )

                IlluminatedActionButton(
                    letter: "S",
                    label: "Study",
                    isPrimary: true,
                    action: {}
                )
            }

            // Secondary (non-primary) style
            HStack(spacing: AppTheme.Spacing.xl) {
                IlluminatedActionButton(
                    letter: "N",
                    label: "Note",
                    isPrimary: false,
                    action: {}
                )

                IlluminatedActionButton(
                    letter: "A",
                    label: "Share",
                    isPrimary: false,
                    action: {},
                    icon: "square.and.arrow.up"
                )
            }
        }
    }
}

#Preview("Highlight Color Buttons") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.xl) {
            // Color palette
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    IlluminatedHighlightColorButton(
                        color: color,
                        isSelected: color == .amber,
                        action: {}
                    )
                }

                IlluminatedRemoveHighlightButton(action: {})
            }

            // Secondary actions
            HStack(spacing: AppTheme.Spacing.sm) {
                SecondaryActionButton(title: "Share", icon: "square.and.arrow.up", action: {})
                SecondaryActionButton(title: "Note", icon: "note.text", action: {})
                SecondaryActionButton(title: "Save", icon: "folder", action: {})
            }
        }
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        HStack(spacing: AppTheme.Spacing.xl) {
            IlluminatedActionButton(
                letter: "C",
                label: "Copy",
                isPrimary: true,
                action: {}
            )

            IlluminatedActionButton(
                letter: "H",
                label: "Highlight",
                isPrimary: true,
                action: {}
            )

            IlluminatedActionButton(
                letter: "S",
                label: "Study",
                isPrimary: true,
                action: {}
            )
        }
    }
    .preferredColorScheme(.dark)
}
