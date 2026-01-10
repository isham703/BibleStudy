//
//  VerseContextMenu.swift
//  BibleStudy
//
//  Floating contextual menu that appears beside selected verses
//  Vertical layout inspired by illuminated manuscript margins
//  Follows UX laws: Fitts's Law, Hick's Law, Jakob's Law, and Apple HIG
//

import SwiftUI

// MARK: - Menu Position

/// Calculated position for the floating context menu
struct ContextMenuPosition {
    var menuOrigin: CGPoint
    var arrowOffset: CGFloat
    var arrowDirection: MenuArrowDirection

    static let zero = ContextMenuPosition(
        menuOrigin: .zero,
        arrowOffset: 0,
        arrowDirection: .down
    )
}

// MARK: - Verse Context Menu

/// A floating contextual menu that appears proximate to selected verses
/// Vertical layout with refined styling for contemplative Bible study
struct VerseContextMenu: View {
    /// The selected verse range
    let verseRange: VerseRange

    /// Bounds of the selected verse(s) in global coordinate space
    let selectionBounds: CGRect

    /// Currently applied highlight color (nil if not highlighted)
    let existingHighlightColor: HighlightColor?

    /// Safe area insets for positioning constraints
    let safeAreaInsets: EdgeInsets

    /// Container bounds for positioning
    let containerBounds: CGRect

    // MARK: - Action Callbacks

    let onCopy: () -> Void
    let onInterpret: () -> Void
    /// New callback for opening inline insight card (new UX)
    var onOpenInlineInsight: (() -> Void)?
    let onShare: () -> Void
    let onNote: () -> Void
    let onHighlight: (HighlightColor) -> Void
    let onRemoveHighlight: () -> Void
    let onDismiss: () -> Void

    // MARK: - State

    @State private var menuSize: CGSize = .zero
    @State private var isAppearing = false
    @State private var hoveredAction: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    // Scaled dimensions for Dynamic Type
    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var colorCircleSize: CGFloat = 26

    // MARK: - Constants

    private let menuPadding: CGFloat = 12
    private let arrowHeight: CGFloat = 8
    private let edgePadding: CGFloat = 16
    private let menuWidth: CGFloat = 180

    // MARK: - Computed Properties

    /// Calculate the optimal menu position based on selection and available space
    private var menuPosition: ContextMenuPosition {
        calculateMenuPosition()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { _ in
            let position = menuPosition

            ZStack(alignment: .topLeading) {
                // Menu content
                menuContent
                    .background(
                        GeometryReader { menuGeometry in
                            Color.clear
                                .onAppear {
                                    menuSize = menuGeometry.size
                                }
                                .onChange(of: menuGeometry.size) { _, newSize in
                                    menuSize = newSize
                                }
                        }
                    )
                    .background {
                        VerticalMenuBackground()
                    }
                    .position(
                        x: position.menuOrigin.x + menuSize.width / 2,
                        y: position.menuOrigin.y + menuSize.height / 2
                    )
                    .opacity(isAppearing ? 1 : 0)
                    .scaleEffect(isAppearing ? 1 : 0.9, anchor: .top)
                    .offset(y: isAppearing ? 0 : -8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAppearing = true
            }
        }
        // Accessibility configuration
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Verse actions menu for \(verseRange.reference)")
        .accessibilityHint("Contains 4 actions and 5 highlight colors")
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) {
            onDismiss()
        }
    }

    // MARK: - Menu Content

    private var menuContent: some View {
        VStack(spacing: 0) {
            // Action buttons - vertical stack
            VStack(spacing: 2) {
                actionRow(
                    icon: "sparkles",
                    label: "Interpret",
                    accentColor: .accentIndigo,
                    isFirst: true
                ) {
                    HapticService.shared.buttonPress()
                    // Use inline insight callback if available (new UX), otherwise legacy
                    if let openInline = onOpenInlineInsight {
                        withAnimation(Theme.Animation.fade) {
                            isAppearing = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onDismiss()
                            openInline()
                        }
                    } else {
                        onInterpret()
                    }
                }

                actionRow(
                    icon: "note.text",
                    label: "Add Note",
                    accentColor: Color.accentIndigo,
                    isFirst: false
                ) {
                    HapticService.shared.buttonPress()
                    onNote()
                }

                actionRow(
                    icon: "doc.on.doc",
                    label: "Copy",
                    accentColor: .primaryText,
                    isFirst: false
                ) {
                    HapticService.shared.success()
                    onCopy()
                }

                actionRow(
                    icon: "square.and.arrow.up",
                    label: "Share",
                    accentColor: .primaryText,
                    isFirst: false,
                    isLast: true
                ) {
                    HapticService.shared.buttonPress()
                    onShare()
                }
            }

            // Divider with subtle gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)).opacity(0),
                            Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                            Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)).opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Stroke.hairline)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)

            // Highlight colors - horizontal row
            highlightColorRow
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
        }
        .frame(width: menuWidth)
    }

    // MARK: - Action Row

    private func actionRow(
        icon: String,
        label: String,
        accentColor: Color,
        isFirst: Bool = false,
        isLast: Bool = false,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Icon with subtle background
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(Theme.Opacity.subtle + 0.02))
                        .frame(width: 24, height: 24)

                    Image(systemName: icon)
                        .font(Typography.Icon.md.weight(.medium))
                        .foregroundStyle(accentColor)
                }

                // Label
                Text(label)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                // Subtle chevron indicator
                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .frame(height: rowHeight)
            .background(
                RoundedRectangle(cornerRadius: isFirst || isLast ? Theme.Radius.button + 2 : Theme.Radius.input)
                    .fill(hoveredAction == label ? Color.selectedBackground : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(VerticalMenuButtonStyle())
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to \(label.lowercased())")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in hoveredAction = label }
                .onEnded { _ in hoveredAction = nil }
        )
    }

    // MARK: - Highlight Color Row

    private var highlightColorRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Remove highlight circle (if highlight exists)
            if existingHighlightColor != nil {
                Button {
                    HapticService.shared.lightTap()
                    onRemoveHighlight()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.primaryText, lineWidth: Theme.Stroke.control - 0.5)
                            .frame(width: colorCircleSize, height: colorCircleSize)

                        Image(systemName: "xmark")
                            .font(Typography.Icon.xxs.weight(.bold))
                            .foregroundStyle(Color.primaryText)
                    }
                }
                .buttonStyle(ColorCircleButtonStyle())
                .accessibilityLabel("Remove highlight")
            }

            // Color circles
            ForEach(HighlightColor.allCases, id: \.self) { color in
                Button {
                    HapticService.shared.verseHighlighted()
                    onHighlight(color)
                } label: {
                    ZStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: colorCircleSize, height: colorCircleSize)

                        // Checkmark for selected color
                        if existingHighlightColor == color {
                            Image(systemName: "checkmark")
                                .font(Typography.Icon.xxs.weight(.bold))
                                .foregroundStyle(.white)
                        }

                        // Selection ring
                        if existingHighlightColor == color {
                            Circle()
                                .stroke(Color.primaryText, lineWidth: Theme.Stroke.control)
                                .frame(width: colorCircleSize + Theme.Spacing.xs, height: colorCircleSize + Theme.Spacing.xs)
                        }
                    }
                }
                .buttonStyle(ColorCircleButtonStyle())
                .accessibilityLabel("Highlight \(color.displayName)")
                .accessibilityAddTraits(existingHighlightColor == color ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Position Calculation

    /// Calculates the optimal position for the menu based on selection bounds and available space
    /// Menu appears directly below the verse (preferred) or above if verse is too far down
    private func calculateMenuPosition() -> ContextMenuPosition {
        // Estimate menu height based on content
        let estimatedMenuHeight = (rowHeight * 4) + 60 // 4 rows + colors + padding
        let verticalGap: CGFloat = 0 // Tight - menu touches verse

        // Convert selection bounds from global to local coordinate space
        let localSelectionMinY = selectionBounds.minY - containerBounds.minY
        let localSelectionMaxY = selectionBounds.maxY - containerBounds.minY
        let localSelectionMinX = selectionBounds.minX - containerBounds.minX

        // Calculate available space below the selection (in local coords)
        let spaceBelow = containerBounds.height - localSelectionMaxY - safeAreaInsets.bottom - menuPadding

        let minimumClearance = estimatedMenuHeight + menuPadding

        // Determine vertical position - prefer below, fallback to above
        var menuY: CGFloat
        var arrowDirection: MenuArrowDirection

        if spaceBelow >= minimumClearance {
            // Preferred: Menu below verse
            arrowDirection = .up
            menuY = localSelectionMaxY + verticalGap
        } else {
            // Fallback: Menu above verse (when verse is too far down)
            arrowDirection = .down
            menuY = localSelectionMinY - estimatedMenuHeight - verticalGap
        }

        // Align menu's leading edge with the verse's leading edge (in local coords)
        var menuX = localSelectionMinX

        // Constrain to screen edges
        let minX = edgePadding
        let maxX = containerBounds.width - menuWidth - edgePadding
        menuX = max(minX, min(menuX, maxX))

        // Calculate arrow offset (not used in this design, but kept for compatibility)
        let localSelectionMidX = selectionBounds.midX - containerBounds.minX
        let menuCenterX = menuX + menuWidth / 2
        let arrowOffset = localSelectionMidX - menuCenterX

        return ContextMenuPosition(
            menuOrigin: CGPoint(x: menuX, y: menuY),
            arrowOffset: arrowOffset,
            arrowDirection: arrowDirection
        )
    }
}

// MARK: - Vertical Menu Background

/// Elegant background for the vertical context menu
private struct VerticalMenuBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Base shape with rounded corners
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .fill(Color.elevatedBackground)

            // Subtle inner border for definition
            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? Theme.Opacity.subtle : Theme.Opacity.heavy),
                            Color.white.opacity(colorScheme == .dark ? Theme.Opacity.faint - 0.03 : Theme.Opacity.lightMedium)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: Theme.Stroke.hairline
                )

            // Material overlay for dark mode
            if colorScheme == .dark {
                RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .shadow(
            color: .black.opacity(colorScheme == .dark ? Theme.Opacity.disabled : Theme.Opacity.subtle + 0.02),
            radius: 20,
            x: 0,
            y: Theme.Spacing.sm
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? Theme.Opacity.lightMedium : Theme.Opacity.faint - 0.02),
            radius: Theme.Spacing.xs + 2,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Button Styles

/// Button style for vertical menu action rows
private struct VerticalMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

/// Button style for color circle buttons
private struct ColorCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 - 0.1 : 1.0)
            .animation(Theme.Animation.settle, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Vertical Menu - No Highlight") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        GeometryReader { geometry in
            let bounds = CGRect(
                x: 20,
                y: geometry.size.height / 2,
                width: geometry.size.width - 40,
                height: 60
            )

            VStack {
                Spacer()

                // Simulated selected verse
                Text("2 And the earth was without form, and void; and darkness was upon the face of the deep.")
                    .padding()
                    .background(Color.selectedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                    .padding(.horizontal)

                Spacer()
            }

            VerseContextMenu(
                verseRange: .genesis1_1,
                selectionBounds: bounds,
                existingHighlightColor: nil,
                safeAreaInsets: geometry.safeAreaInsets,
                containerBounds: geometry.frame(in: .global),
                onCopy: { print("Copy") },
                onInterpret: { print("Interpret") },
                onShare: { print("Share") },
                onNote: { print("Note") },
                onHighlight: { print("Highlight: \($0)") },
                onRemoveHighlight: { print("Remove") },
                onDismiss: { print("Dismiss") }
            )
        }
    }
}

#Preview("Vertical Menu - With Highlight") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        GeometryReader { geometry in
            let bounds = CGRect(
                x: 20,
                y: geometry.size.height / 2,
                width: geometry.size.width - 40,
                height: 60
            )

            VerseContextMenu(
                verseRange: VerseRange(bookId: 1, chapter: 1, verseStart: 2, verseEnd: 2),
                selectionBounds: bounds,
                existingHighlightColor: .amber,
                safeAreaInsets: geometry.safeAreaInsets,
                containerBounds: geometry.frame(in: .global),
                onCopy: { },
                onInterpret: { },
                onShare: { },
                onNote: { },
                onHighlight: { _ in },
                onRemoveHighlight: { },
                onDismiss: { }
            )
        }
    }
}

#Preview("Vertical Menu - Dark Mode") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        GeometryReader { geometry in
            let bounds = CGRect(
                x: 20,
                y: geometry.size.height / 2,
                width: geometry.size.width - 40,
                height: 60
            )

            VerseContextMenu(
                verseRange: .genesis1_1,
                selectionBounds: bounds,
                existingHighlightColor: .rose,
                safeAreaInsets: geometry.safeAreaInsets,
                containerBounds: geometry.frame(in: .global),
                onCopy: { },
                onInterpret: { },
                onShare: { },
                onNote: { },
                onHighlight: { _ in },
                onRemoveHighlight: { },
                onDismiss: { }
            )
        }
    }
    .preferredColorScheme(.dark)
}
