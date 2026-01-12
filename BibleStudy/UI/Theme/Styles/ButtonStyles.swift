//
//  ButtonStyles.swift
//  BibleStudy
//
//  Button styles for the Stoic-Existential design system
//

import SwiftUI

// MARK: - Primary Button Style

/// Primary button style with filled background
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonContent(configuration: configuration)
    }
}

private struct PrimaryButtonContent: View {
    @Environment(\.isEnabled) var isEnabled
    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(Typography.Command.cta)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(Color("AppAccentAction"))
            .clipShape(Capsule())
            .opacity(opacity)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
            .animation(Theme.Animation.fade, value: isEnabled)
    }

    private var opacity: Double {
        if !isEnabled {
            return Theme.Opacity.disabled
        }
        return configuration.isPressed ? Theme.Opacity.pressed : 1.0
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// MARK: - Secondary Button Style

/// Secondary button style with stroke border
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButtonContent(configuration: configuration)
    }
}

private struct SecondaryButtonContent: View {
    @Environment(\.isEnabled) var isEnabled
    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .font(Typography.Command.cta)
            .foregroundStyle(Color("AppAccentAction"))
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Capsule()
                    .stroke(Color("AppAccentAction"), lineWidth: Theme.Stroke.hairline)
            )
            .opacity(opacity)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
            .animation(Theme.Animation.fade, value: isEnabled)
    }

    private var opacity: Double {
        if !isEnabled {
            return Theme.Opacity.disabled
        }
        return configuration.isPressed ? Theme.Opacity.pressed : 1.0
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
