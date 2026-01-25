//
//  AnimatedTabBar.swift
//  BibleStudy
//
//  iOS-standard tab bar implementation with animated indicator.
//  Uses standard Button pattern for reliable tap handling.
//
//  Motion: Uses Theme.Animation.fade (220ms easeInOut) - NO springs
//

import SwiftUI

// MARK: - Animated Tab Bar

/// A horizontal tab bar with animated label colors and sliding indicator.
///
/// Uses iOS-standard Button implementation for reliable tap handling.
///
/// Usage:
/// ```swift
/// AnimatedTabBar(
///     tabs: ["Sources", "Notes"],
///     selectedIndex: $selectedIndex
/// )
/// ```
struct AnimatedTabBar: View {
    /// Tab labels to display
    let tabs: [String]

    /// Currently selected tab index
    @Binding var selectedIndex: Int

    /// Optional scroll progress for smooth indicator animation during swipes
    var scrollProgress: CGFloat?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, label in
                tabButton(label: label, index: index)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) {
            // Sliding indicator
            GeometryReader { geometry in
                let tabWidth = geometry.size.width / CGFloat(tabs.count)
                let progress = scrollProgress ?? CGFloat(selectedIndex)

                Rectangle()
                    .fill(Color("AppTextPrimary"))
                    .frame(width: tabWidth * 0.5, height: 2)
                    .offset(x: tabWidth * progress + tabWidth * 0.25)
                    .animation(
                        reduceMotion ? .none : Theme.Animation.settle,
                        value: progress
                    )
            }
            .frame(height: 2)
        }
    }

    // MARK: - Tab Button

    private func tabButton(label: String, index: Int) -> some View {
        Button {
            HapticService.shared.tabSwitch()
            withAnimation(Theme.Animation.fade) {
                selectedIndex = index
            }
        } label: {
            Text(label)
                .font(Typography.Command.body.weight(index == selectedIndex ? .semibold : .regular))
                .foregroundStyle(index == selectedIndex ? Color("AppTextPrimary") : Color("TertiaryText"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) tab")
        .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
        .accessibilityHint("Double tap to switch to \(label)")
    }
}

// MARK: - Preview

#Preview("Animated Tab Bar") {
    AnimatedTabBarPreview()
}

private struct AnimatedTabBarPreview: View {
    @State private var selectedIndex = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Text("Selected: \(selectedIndex)")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))

            AnimatedTabBar(
                tabs: ["Sources", "Notes"],
                selectedIndex: $selectedIndex
            )
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()
        }
        .padding(.top, Theme.Spacing.xxl)
        .background(Color("AppBackground"))
    }
}
