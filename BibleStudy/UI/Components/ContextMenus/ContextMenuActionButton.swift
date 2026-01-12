//
//  ContextMenuActionButton.swift
//  BibleStudy
//
//  Shared action button component for context menus.
//  Unifies MiniActionIcon (insightFirst) and ScholarActionButton (actionsFirst)
//  into a single configurable component.
//

import SwiftUI

// MARK: - Button Style

/// Style variants for context menu action buttons
enum ContextMenuButtonStyle {
    /// Compact style for insightFirst mode: 44x40pt, smaller icons
    case compact

    /// Standard style for actionsFirst mode: 48x44pt, larger icons
    case standard

    var frameSize: CGSize {
        switch self {
        case .compact: return CGSize(width: 44, height: 40)
        case .standard: return CGSize(width: 48, height: 44)
        }
    }

    var iconFont: Font {
        switch self {
        case .compact: return Typography.Icon.md
        case .standard: return Typography.Command.headline
        }
    }

    var labelFont: Font {
        switch self {
        case .compact: return Typography.Icon.xxxs.weight(.medium)
        case .standard: return Typography.Icon.xxs
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: return 2
        case .standard: return Theme.Spacing.xs - 2
        }
    }
}

// MARK: - Context Menu Action Button

/// A reusable action button for context menus.
/// Supports compact (insightFirst) and standard (actionsFirst) styles.
struct ContextMenuActionButton: View {
    let icon: String
    let label: String
    let style: ContextMenuButtonStyle
    let action: () -> Void

    /// Optional accent color for the icon (defaults to AppTextSecondary)
    var iconColor: Color = Color("AppTextSecondary")

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: style.spacing) {
                Image(systemName: icon)
                    .font(style.iconFont)
                    .foregroundStyle(iconColor)

                Text(label)
                    .font(style.labelFont)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .frame(width: style.frameSize.width, height: style.frameSize.height)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Theme.Animation.fade) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Convenience Initializers

extension ContextMenuActionButton {
    /// Creates a compact action button (for insightFirst mode)
    static func compact(icon: String, label: String, action: @escaping () -> Void) -> ContextMenuActionButton {
        ContextMenuActionButton(icon: icon, label: label, style: .compact, action: action)
    }

    /// Creates a standard action button (for actionsFirst mode)
    static func standard(icon: String, label: String, action: @escaping () -> Void) -> ContextMenuActionButton {
        ContextMenuActionButton(icon: icon, label: label, style: .standard, action: action)
    }

    /// Creates an accented action button (for primary actions like Study)
    static func accented(
        icon: String,
        label: String,
        accentColor: Color = Color("AppAccentAction"),
        action: @escaping () -> Void
    ) -> ContextMenuActionButton {
        var button = ContextMenuActionButton(icon: icon, label: label, style: .standard, action: action)
        button.iconColor = accentColor
        return button
    }
}

// MARK: - Previews

#Preview("Compact Style (insightFirst)") {
    HStack(spacing: Theme.Spacing.xs) {
        ContextMenuActionButton.compact(icon: "doc.on.doc", label: "Copy") {}
        ContextMenuActionButton.compact(icon: "square.and.arrow.up", label: "Share") {}
        ContextMenuActionButton.compact(icon: "note.text", label: "Note") {}
    }
    .padding()
    .background(Color("AppSurface"))
}

#Preview("Standard Style (actionsFirst)") {
    HStack(spacing: Theme.Spacing.xs) {
        ContextMenuActionButton.standard(icon: "doc.on.doc", label: "Copy") {}
        ContextMenuActionButton.standard(icon: "square.and.arrow.up", label: "Share") {}
        ContextMenuActionButton.standard(icon: "note.text", label: "Note") {}
        ContextMenuActionButton.accented(icon: "book", label: "Study") {}
    }
    .padding()
    .background(Color("AppSurface"))
}
