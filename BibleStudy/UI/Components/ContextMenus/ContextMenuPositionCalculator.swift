//
//  MenuPositioning.swift
//  BibleStudy
//
//  Two-phase positioning algorithm for the IlluminatedContextMenu.
//  Fixes the current issue of using estimated heights by measuring actual dimensions.
//

import SwiftUI
import Combine

// MARK: - Arrow Direction

/// Direction the menu arrow points relative to the selected verse
enum MenuArrowDirection {
    case down  // Arrow points down, menu is above verse
    case up    // Arrow points up, menu is below verse
}

// MARK: - Menu Position

/// Calculated position for the context menu
struct IlluminatedMenuPosition: Equatable {
    /// Origin point for the menu (top-left corner in local coordinates)
    var origin: CGPoint

    /// Direction the arrow should point
    var arrowDirection: MenuArrowDirection

    /// Horizontal offset of the arrow from menu center to point at selection
    var arrowOffset: CGFloat

    static let zero = IlluminatedMenuPosition(
        origin: .zero,
        arrowDirection: .down,
        arrowOffset: 0
    )
}

// MARK: - Menu Position Calculator

/// Calculates optimal menu position based on selection bounds and available space.
/// Uses a two-phase approach: estimate position, then recalculate with actual dimensions.
struct MenuPositionCalculator {

    // MARK: - Configuration

    /// Padding from screen edges
    private let edgePadding: CGFloat = 16

    /// Gap between menu and selected verse
    private let verticalGap: CGFloat = 8

    /// Fixed menu width (must match IlluminatedContextMenu.menuWidth)
    private let menuWidth: CGFloat = 300

    /// Minimum clearance needed for menu placement
    private let minimumClearance: CGFloat = 100

    // MARK: - Input Properties

    /// Bounds of the selected verse(s) in global coordinate space
    let selectionBounds: CGRect

    /// Container bounds (typically the reader view)
    let containerBounds: CGRect

    /// Safe area insets
    let safeAreaInsets: EdgeInsets

    /// Current keyboard height (0 if not visible)
    let keyboardHeight: CGFloat

    // MARK: - Calculation

    /// Calculate the optimal menu position
    /// - Parameter menuHeight: Actual measured height of the menu content
    /// - Returns: Calculated position with origin, arrow direction, and offset
    func calculatePosition(menuHeight: CGFloat) -> IlluminatedMenuPosition {
        // Convert selection bounds from global to local coordinate space
        let localSelectionMinY = selectionBounds.minY - containerBounds.minY
        let localSelectionMaxY = selectionBounds.maxY - containerBounds.minY
        let localSelectionMinX = selectionBounds.minX - containerBounds.minX
        let localSelectionMidX = selectionBounds.midX - containerBounds.minX

        // Calculate available space
        let usableBottom = containerBounds.height
            - safeAreaInsets.bottom
            - keyboardHeight
            - edgePadding

        let spaceBelow = usableBottom - localSelectionMaxY - verticalGap
        let spaceAbove = localSelectionMinY - safeAreaInsets.top - edgePadding - verticalGap

        // Determine vertical position - prefer below, fallback to above
        var menuY: CGFloat
        var arrowDirection: MenuArrowDirection

        if spaceBelow >= menuHeight {
            // Position below verse (preferred)
            arrowDirection = .up
            menuY = localSelectionMaxY + verticalGap
        } else if spaceAbove >= menuHeight {
            // Position above verse (fallback)
            arrowDirection = .down
            menuY = localSelectionMinY - menuHeight - verticalGap
        } else {
            // Constrained space: center vertically, prefer below
            arrowDirection = .up
            menuY = max(
                safeAreaInsets.top + edgePadding,
                min(localSelectionMaxY + verticalGap, usableBottom - menuHeight)
            )
        }

        // Calculate horizontal position - align with selection's leading edge
        var menuX = localSelectionMinX

        // Constrain to screen edges
        let minX = edgePadding
        let maxX = containerBounds.width - menuWidth - edgePadding
        menuX = max(minX, min(menuX, maxX))

        // Calculate arrow offset to point at selection center
        let menuCenterX = menuX + menuWidth / 2
        let arrowOffset = (localSelectionMidX - menuCenterX).clamped(to: -80...80)

        return IlluminatedMenuPosition(
            origin: CGPoint(x: menuX, y: menuY),
            arrowDirection: arrowDirection,
            arrowOffset: arrowOffset
        )
    }

    /// Estimate initial position before menu is measured
    /// Uses a conservative height estimate
    func estimateInitialPosition() -> IlluminatedMenuPosition {
        // Conservative estimate for menu with all sections visible
        let estimatedHeight: CGFloat = 280
        return calculatePosition(menuHeight: estimatedHeight)
    }
}

// MARK: - Keyboard Height Observer

/// Observable object that tracks keyboard visibility and height.
/// Uses singleton pattern to avoid multiple Combine subscriptions.
@Observable
final class KeyboardHeightObserver {
    /// Shared singleton instance - use this instead of creating new instances
    static let shared = KeyboardHeightObserver()

    var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupKeyboardObservers()
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                return frame.height
            }
            .sink { [weak self] height in
                withAnimation(Theme.Animation.settle) {
                    self?.keyboardHeight = height
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                withAnimation(Theme.Animation.settle) {
                    self?.keyboardHeight = 0
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Comparable Extension

private extension Comparable {
    /// Clamp value to a given range
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Preview

#Preview("Position Calculation Demo") {
    GeometryReader { geometry in
        let calculator = MenuPositionCalculator(
            selectionBounds: CGRect(x: 50, y: 200, width: 300, height: 60),
            containerBounds: geometry.frame(in: .global),
            safeAreaInsets: geometry.safeAreaInsets,
            keyboardHeight: 0
        )

        let position = calculator.calculatePosition(menuHeight: 200)

        ZStack {
            Color.appBackground.ignoresSafeArea()

            // Simulated selected verse
            Rectangle()
                .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                .frame(width: 300, height: 60)
                .position(x: 200, y: 230)

            // Simulated menu position
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
                .stroke(Color("AccentBronze"), lineWidth: Theme.Stroke.control)
                .frame(width: 260, height: 200)
                .position(
                    x: position.origin.x + 130,
                    y: position.origin.y + 100
                )

            // Debug info
            VStack {
                Spacer()
                Text("Arrow: \(position.arrowDirection == .up ? "Up" : "Down")")
                Text("Offset: \(position.arrowOffset, specifier: "%.1f")")
            }
            .padding()
        }
    }
}
