//
//  IconBadge.swift
//  BibleStudy
//
//  Reusable icon badge component for settings rows, menu items, and feature cards.
//  Stoic-Existential Renaissance design - flat, purposeful, no ornament.
//

import SwiftUI

// MARK: - Icon Badge

struct IconBadge: View {
    let systemName: String
    var color: Color = Color("AppAccentAction")
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: systemName)
            .font(iconFont)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color.opacity(Theme.Opacity.divider))
            )
    }

    // MARK: - Computed Properties

    private var iconFont: Font {
        switch size {
        case ...24:
            return Typography.Icon.xs.weight(.medium)
        case 25...30:
            return Typography.Icon.sm.weight(.medium)
        case 31...36:
            return Typography.Icon.md.weight(.medium)
        default:
            return Typography.Icon.base.weight(.medium)
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case ...24:
            return Theme.Radius.input + 1  // UsageRow style
        case 25...36:
            return Theme.Radius.tag  // Standard settings style
        default:
            return Theme.Radius.button  // Large menu style
        }
    }
}

// MARK: - Semantic Initializers

extension IconBadge {
    /// Settings row icon (standard 28x28)
    static func settings(_ systemName: String, color: Color = Color("AppAccentAction")) -> IconBadge {
        IconBadge(systemName: systemName, color: color, size: 28)
    }

    /// Compact icon for usage rows (24x24)
    static func compact(_ systemName: String, color: Color = Color("AppAccentAction")) -> IconBadge {
        IconBadge(systemName: systemName, color: color, size: 24)
    }

    /// Menu row icon (40x40)
    static func menu(_ systemName: String, color: Color = Color("AppAccentAction")) -> IconBadge {
        IconBadge(systemName: systemName, color: color, size: 40)
    }
}

// MARK: - Preview

#Preview("Icon Badge Variants") {
    VStack(spacing: Theme.Spacing.lg) {
        Text("Settings Style (28x28)")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))

        HStack(spacing: Theme.Spacing.lg) {
            IconBadge.settings("bell.fill", color: Color("AppAccentAction"))
            IconBadge.settings("flame.fill", color: Color("FeedbackWarning"))
            IconBadge.settings("sparkles", color: Color("AppAccentAction"))
        }

        Text("Compact Style (24x24)")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))

        HStack(spacing: Theme.Spacing.lg) {
            IconBadge.compact("sparkles", color: Color("AppAccentAction"))
            IconBadge.compact("crown.fill", color: Color("AccentBronze"))
            IconBadge.compact("checkmark", color: Color("FeedbackSuccess"))
        }

        Text("Menu Style (40x40)")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))

        HStack(spacing: Theme.Spacing.lg) {
            IconBadge.menu("book.fill", color: Color("AppAccentAction"))
            IconBadge.menu("gear", color: Color("AccentBronze"))
        }
    }
    .padding()
    .background(Color.appBackground)
}
