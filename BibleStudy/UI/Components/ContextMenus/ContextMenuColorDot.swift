//
//  ContextMenuColorDot.swift
//  BibleStudy
//
//  Shared color dot component for context menu highlight selection.
//  Unifies CompactColorDot (insightFirst) and ScholarColorDot (actionsFirst)
//  into a single configurable component.
//

import SwiftUI

// MARK: - Color Dot Style

/// Style variants for context menu color dots
enum ContextMenuColorDotStyle {
    /// Compact style for insightFirst mode: 20pt dot, 28pt slot
    case compact

    /// Standard style for actionsFirst mode: 18pt dot, 44pt slot (HIG compliant)
    case standard

    var dotSize: CGFloat {
        switch self {
        case .compact: return 20
        case .standard: return 18
        }
    }

    var slotSize: CGFloat {
        switch self {
        case .compact: return 28
        case .standard: return Theme.Size.minTapTarget  // 44pt HIG compliance
        }
    }

    var ringOffset: CGFloat {
        switch self {
        case .compact: return 4
        case .standard: return 6
        }
    }

    var checkmarkFont: Font {
        switch self {
        case .compact: return Typography.Icon.xxxs.weight(.bold)
        case .standard: return Typography.Icon.xxxs.weight(.semibold)
        }
    }
}

// MARK: - Context Menu Color Dot

/// A reusable color dot for highlight selection in context menus.
/// Supports compact (insightFirst) and standard (actionsFirst) styles.
struct ContextMenuColorDot: View {
    let color: HighlightColor
    let isSelected: Bool
    let style: ContextMenuColorDotStyle
    let onTap: () -> Void

    /// Optional custom accent color for selection ring (defaults to mode-appropriate color)
    var selectionRingColor: Color?

    var body: some View {
        Button {
            onTap()
        } label: {
            // Fixed slot - selection indicator drawn INSIDE, never affects layout
            ZStack {
                // Outer selection ring (inset, not expanding)
                if isSelected {
                    Circle()
                        .stroke(ringColor, lineWidth: Theme.Stroke.control)
                        .frame(
                            width: style.dotSize + style.ringOffset,
                            height: style.dotSize + style.ringOffset
                        )
                }

                // Color dot
                Circle()
                    .fill(color.color)
                    .frame(width: style.dotSize, height: style.dotSize)

                // Checkmark overlay
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(style.checkmarkFont)
                        .foregroundStyle(.white)
                }
            }
            // Fixed slot - NEVER changes size regardless of selection state
            .frame(width: style.slotSize, height: style.slotSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(color.accessibilityName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var ringColor: Color {
        if let custom = selectionRingColor {
            return custom
        }
        // Default ring colors per style
        switch style {
        case .compact:
            return Color("AccentBronze")
        case .standard:
            return Color("AppTextPrimary").opacity(Theme.Opacity.focusStroke)
        }
    }
}

// MARK: - Convenience Initializers

extension ContextMenuColorDot {
    /// Creates a compact color dot (for insightFirst mode)
    static func compact(
        color: HighlightColor,
        isSelected: Bool,
        accentColor: Color,
        onTap: @escaping () -> Void
    ) -> ContextMenuColorDot {
        var dot = ContextMenuColorDot(color: color, isSelected: isSelected, style: .compact, onTap: onTap)
        dot.selectionRingColor = accentColor
        return dot
    }

    /// Creates a standard color dot (for actionsFirst mode)
    static func standard(
        color: HighlightColor,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> ContextMenuColorDot {
        ContextMenuColorDot(color: color, isSelected: isSelected, style: .standard, onTap: onTap)
    }
}

// MARK: - Previews

#Preview("Compact Style (insightFirst)") {
    HStack(spacing: Theme.Spacing.xs + 2) {
        ForEach(HighlightColor.allCases, id: \.self) { color in
            ContextMenuColorDot.compact(
                color: color,
                isSelected: color == .amber,
                accentColor: Color("AccentBronze")
            ) {}
        }
    }
    .padding()
    .background(Color("AppSurface"))
}

#Preview("Standard Style (actionsFirst)") {
    HStack(spacing: 0) {
        ForEach(HighlightColor.allCases, id: \.self) { color in
            ContextMenuColorDot.standard(
                color: color,
                isSelected: color == .blue
            ) {}
        }
    }
    .padding()
    .background(Color("AppSurface"))
}
