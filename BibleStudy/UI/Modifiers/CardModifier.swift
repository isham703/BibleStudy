//
//  CardModifier.swift
//  BibleStudy
//
//  Standard card styling with surface background and hairline border
//

import SwiftUI

// MARK: - Card Modifier

extension View {
    /// Standard card styling with surface background and hairline border
    /// Use for: content cards, list items, section containers
    func card() -> some View {
        modifier(CardModifier())
    }

    /// Applies pressed state feedback (scale + opacity)
    /// Use inside ButtonStyle for interactive cards
    func applyPressedState(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: isPressed)
    }
}

private struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let mode = ThemeMode.current(from: colorScheme)

        content
            .padding(Theme.Spacing.lg)
            .background(Colors.Surface.surface(for: mode))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Colors.Surface.divider(for: mode), lineWidth: Theme.Stroke.hairline)
            )
    }
}
