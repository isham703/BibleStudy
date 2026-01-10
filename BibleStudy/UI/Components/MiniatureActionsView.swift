//
//  MiniatureActionsView.swift
//  BibleStudy
//
//  Apple Books-style expandable floating action button
//

import SwiftUI

// MARK: - Miniature Actions View

/// A floating action button that expands to reveal action options.
/// Inspired by Apple Books' quick actions UI pattern.
struct MiniatureActionsView<Actions: View, Background: View>: View {
    var innerScaling: CGFloat = 0.9
    var minimisedButtonSize: CGSize = .init(
        width: 56,
        height: 48
    )
    var animation: Animation = .smooth(duration: 0.35, extraBounce: 0)
    @Binding var isExpanded: Bool
    var isAIMode: Bool = false  // When true, shows AI mode indicator
    @ViewBuilder var actions: Actions
    @ViewBuilder var background: Background

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        actions
            // Disable interaction when minimized
            .allowsHitTesting(isExpanded)
            .contentShape(.rect)
            .compositingGroup()
            // Scale actions to fit into the button size using visual effect
            .visualEffect { [innerScaling, minimisedButtonSize, isExpanded] content, proxy in
                let maxValue = max(proxy.size.width, proxy.size.height)
                let minButtonValue = min(minimisedButtonSize.width, minimisedButtonSize.height)
                let fitScale = minButtonValue / maxValue
                let modifiedInnerScale = 0.55 * innerScaling

                return content
                    .scaleEffect(isExpanded ? 1 : modifiedInnerScale)
                    .scaleEffect(isExpanded ? 1 : fitScale)
            }
            // Tap overlay to expand when minimized
            .overlay {
                if !isExpanded {
                    ZStack {
                        // Tap target
                        Capsule()
                            .foregroundStyle(.clear)
                            .frame(
                                width: minimisedButtonSize.width,
                                height: minimisedButtonSize.height
                            )
                            .contentShape(.capsule)
                            .onTapGesture {
                                isExpanded = true
                            }

                        // AI mode indicator (sparkles badge)
                        if isAIMode {
                            Image(systemName: "sparkles")
                                .font(Typography.Command.meta)
                                .fontWeight(.medium)
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                .offset(x: 12, y: -10)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .transition(.identity)
                    .accessibilityLabel(isAIMode ? "AI study tools" : "Reading tools")
                    .accessibilityHint("Double tap to expand \(isAIMode ? "AI analysis" : "reading") options")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .background {
                background
                    .frame(
                        width: isExpanded ? nil : minimisedButtonSize.width,
                        height: isExpanded ? nil : minimisedButtonSize.height
                    )
                    .compositingGroup()
                    // Fade out with blur when expanded
                    .opacity(isExpanded ? 0 : 1)
                    .blur(radius: isExpanded ? 8 : 0)
            }
            .fixedSize()
            .frame(
                width: isExpanded ? nil : minimisedButtonSize.width,
                height: isExpanded ? nil : minimisedButtonSize.height
            )
            .accessibleAnimation(animation, value: isExpanded)
    }
}

// MARK: - Default Background

/// Default capsule background for MiniatureActionsView
struct MiniatureActionsBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var isExpanded: Bool
    var isAIMode: Bool = false  // When true, uses gold-tinted background

    var body: some View {
        ZStack {
            Capsule()
                .fill(isAIMode
                    ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(colorScheme == .dark ? 0.15 : 0.1)
                    : Color.elevatedBackground
                )

            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 1 : 0)
        }
        .shadow(
            color: .black.opacity(isExpanded ? 0 : Theme.Opacity.subtle),
            radius: 4,
            x: 2,
            y: 2
        )
        .shadow(
            color: .black.opacity(isExpanded ? 0 : Theme.Opacity.subtle),
            radius: 4,
            x: -2,
            y: -2
        )
    }
}

// MARK: - Quick Action Button

/// A button style for quick action items in the expanded state
struct QuickActionButton: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Text(title)

                Spacer(minLength: 0)

                Image(systemName: icon)
            }
            .font(Typography.Command.body)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isExpanded ? 1 : 0)
            .background {
                ZStack {
                    Rectangle()
                        .fill(Color.primaryText)
                        .opacity(isExpanded ? 0 : 1)

                    Rectangle()
                        .fill(Color.surfaceBackground)
                        .opacity(isExpanded ? 1 : 0)
                }
                .clipShape(.capsule)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Quick Action Icon Button

/// An icon-only button for compact quick actions
struct QuickActionIconButton: View {
    let icon: String
    let accessibilityLabel: String
    @Binding var isExpanded: Bool
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(isExpanded ? 1 : 0)
                .background {
                    ZStack {
                        Rectangle()
                            .fill(Color.primaryText)
                            .opacity(isExpanded ? 0 : 1)

                        Rectangle()
                            .fill(Color.surfaceBackground)
                            .opacity(isExpanded ? 1 : 0)
                    }
                    .clipShape(.capsule)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("Miniature Actions") {
    struct PreviewWrapper: View {
        @State private var isExpanded = false
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                Color.appBackground
                    .ignoresSafeArea()

                // Dim overlay when expanded
                if isExpanded {
                    Color.black.opacity(Theme.Opacity.lightMedium)
                        .ignoresSafeArea()
                        .onTapGesture { isExpanded = false }
                }

                MiniatureActionsView(isExpanded: $isExpanded) {
                    VStack(spacing: isExpanded ? Theme.Spacing.sm : Theme.Spacing.lg) {
                        QuickActionButton(
                            title: "Jump to Chapter",
                            icon: "arrow.up.and.down",
                            isExpanded: $isExpanded
                        )
                        .frame(width: 220, height: 44)

                        QuickActionButton(
                            title: "Daily Verse",
                            icon: "sun.max",
                            isExpanded: $isExpanded
                        )
                        .frame(width: 220, height: 44)

                        HStack(spacing: Theme.Spacing.md) {
                            QuickActionIconButton(
                                icon: "shuffle",
                                accessibilityLabel: "Random verse",
                                isExpanded: $isExpanded
                            )
                            QuickActionIconButton(
                                icon: "text.alignleft",
                                accessibilityLabel: "Toggle layout",
                                isExpanded: $isExpanded
                            )
                            QuickActionIconButton(
                                icon: "headphones",
                                accessibilityLabel: "Listen",
                                isExpanded: $isExpanded
                            )
                        }
                        .font(Typography.Command.title3)
                        .fontWeight(.medium)
                        .frame(width: 220, height: 48)
                    }
                    .foregroundStyle(Color.primaryText)
                } background: {
                    MiniatureActionsBackground(isExpanded: isExpanded)
                }
                .padding(.trailing, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .animation(Theme.Animation.settle, value: isExpanded)
        }
    }

    return PreviewWrapper()
}
