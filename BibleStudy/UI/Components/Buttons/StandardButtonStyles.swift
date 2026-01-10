//
//  StandardButtonStyles.swift
//  BibleStudy
//
//  Standard button styles for the Stoic-Existential design system
//

import SwiftUI

// MARK: - Primary Button Style

/// Primary button style with filled background
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.Command.cta)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// MARK: - Secondary Button Style

/// Secondary button style with stroke border
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.Command.cta)
            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Capsule()
                    .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.hairline)
            )
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
