//
//  VerseContextMenuBackground.swift
//  BibleStudy
//
//  Background component for floating verse context menu with arrow indicator
//

import SwiftUI

// MARK: - Arrow Direction

enum MenuArrowDirection {
    case down  // Arrow points down, menu is above verse
    case up    // Arrow points up, menu is below verse
}

// MARK: - Menu Arrow Shape

/// Triangular arrow that connects the menu to the selected verse
struct MenuArrow: Shape {
    var pointsUp: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsUp {
            // Arrow pointing up (menu below verse)
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            // Arrow pointing down (menu above verse)
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Verse Context Menu Background

/// Capsule background with arrow indicator for the floating context menu
/// Follows the MiniatureActionsBackground visual pattern
struct VerseContextMenuBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Direction the arrow points
    var arrowDirection: MenuArrowDirection = .down

    /// Horizontal offset of the arrow from center (to point at verse)
    var arrowOffset: CGFloat = 0

    /// Arrow dimensions
    private let arrowWidth: CGFloat = 16
    private let arrowHeight: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main background shape
                VStack(spacing: 0) {
                    if arrowDirection == .up {
                        // Arrow at top when menu is below verse
                        arrowView
                            .offset(x: arrowOffset)
                    }

                    // Capsule body
                    capsuleBackground
                        .frame(height: geometry.size.height - arrowHeight)

                    if arrowDirection == .down {
                        // Arrow at bottom when menu is above verse
                        arrowView
                            .offset(x: arrowOffset)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var capsuleBackground: some View {
        ZStack {
            // Base fill
            Capsule()
                .fill(Color.elevatedBackground)

            // Material overlay for dark mode
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 1 : 0)
        }
        .shadow(
            color: .black.opacity(Theme.Opacity.subtle),
            radius: 4,
            x: 0,
            y: 2
        )
        .shadow(
            color: .black.opacity(Theme.Opacity.faint),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    private var arrowView: some View {
        MenuArrow(pointsUp: arrowDirection == .up)
            .fill(
                Colors.Surface.surface(for: ThemeMode.current(from: colorScheme))
                    .opacity(colorScheme == .dark ? Theme.Opacity.high : 1.0)
            )
            .frame(width: arrowWidth, height: arrowHeight)
    }
}

// MARK: - Preview

#Preview("Arrow Down (Menu Above)") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.lg) {
            VerseContextMenuBackground(arrowDirection: .down)
                .frame(width: 300, height: 64)

            Text("Selected verse here")
                .padding()
                .background(Color.selectedBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        }
    }
}

#Preview("Arrow Up (Menu Below)") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.lg) {
            Text("Selected verse here")
                .padding()
                .background(Color.selectedBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))

            VerseContextMenuBackground(arrowDirection: .up)
                .frame(width: 300, height: 64)
        }
    }
}

#Preview("Arrow Offset") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: Theme.Spacing.lg) {
            VerseContextMenuBackground(arrowDirection: .down, arrowOffset: -80)
                .frame(width: 300, height: 64)

            HStack {
                Text("Verse at edge")
                    .padding()
                    .background(Color.selectedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}
