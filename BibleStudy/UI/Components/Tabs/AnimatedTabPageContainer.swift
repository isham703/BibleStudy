//
//  AnimatedTabPageContainer.swift
//  BibleStudy
//
//  iOS-standard swipeable page container using TabView.
//  Uses Apple's built-in paging behavior for reliable gestures.
//
//  Motion: Uses Theme.Animation.settle (260ms easeOut) - NO springs
//

import SwiftUI

// MARK: - Animated Tab Page Container

/// A horizontal, swipeable page container using iOS's standard TabView.
///
/// This component uses Apple's built-in paging for reliable swipe navigation.
///
/// Usage:
/// ```swift
/// AnimatedTabPageContainer(
///     selectedIndex: $selectedIndex,
///     scrollProgress: $scrollProgress
/// ) {
///     SourcesView()
///     NotesView()
/// }
/// ```
struct AnimatedTabPageContainer<Content: View>: View {
    /// Currently selected page index (0-based)
    @Binding var selectedIndex: Int

    /// Optional: Continuous scroll progress for tab bar animation
    @Binding var scrollProgress: CGFloat

    /// Content views for each page
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TabView(selection: $selectedIndex) {
            content
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: selectedIndex) { _, newValue in
            // Sync scroll progress with selected index
            withAnimation(reduceMotion ? .none : Theme.Animation.settle) {
                scrollProgress = CGFloat(newValue)
            }
            HapticService.shared.tabSwitch()
        }
        .onAppear {
            scrollProgress = CGFloat(selectedIndex)
        }
    }
}

// MARK: - Preview

#Preview("Animated Tab Page Container") {
    AnimatedTabPageContainerPreview()
}

private struct AnimatedTabPageContainerPreview: View {
    @State private var selectedIndex = 0
    @State private var scrollProgress: CGFloat = 0.0

    var body: some View {
        VStack(spacing: 0) {
            // Debug info
            VStack(spacing: Theme.Spacing.xs) {
                Text("Selected: \(selectedIndex)")
                Text("Progress: \(scrollProgress, specifier: "%.2f")")
            }
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))
            .padding(Theme.Spacing.md)

            // Tab bar
            AnimatedTabBar(
                tabs: ["Sources", "Notes", "More"],
                selectedIndex: $selectedIndex,
                scrollProgress: scrollProgress
            )
            .padding(.horizontal, Theme.Spacing.lg)

            // Page container
            AnimatedTabPageContainer(
                selectedIndex: $selectedIndex,
                scrollProgress: $scrollProgress
            ) {
                ZStack {
                    Color.blue.opacity(0.2)
                    Text("Sources Content")
                        .font(Typography.Command.largeTitle)
                }
                .tag(0)

                ZStack {
                    Color.green.opacity(0.2)
                    Text("Notes Content")
                        .font(Typography.Command.largeTitle)
                }
                .tag(1)

                ZStack {
                    Color.orange.opacity(0.2)
                    Text("More Content")
                        .font(Typography.Command.largeTitle)
                }
                .tag(2)
            }
        }
        .background(Color("AppBackground"))
    }
}
