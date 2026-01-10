import SwiftUI

// MARK: - Custom Tab Bar
// Pill-shaped tab container with Ask FAB
// Replaces standard TabView for custom layout

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var showAskModal: Bool
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Animation State
    @State private var tabBarAppeared = false
    @State private var shimmerOffset: CGFloat = -1

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Tab pill (left side)
            tabPill

            // Ask FAB (right side)
            AskFAB {
                showAskModal = true
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
        .offset(y: tabBarAppeared ? 0 : 80)
        .opacity(tabBarAppeared ? 1 : 0)
        .onAppear {
            startEntranceAnimation()
        }
    }

    // MARK: - Tab Pill

    private var tabPill: some View {
        HStack(spacing: 0) {
            TabBarButton(
                tab: .home,
                isSelected: selectedTab == .home
            ) {
                HapticService.shared.tabSwitch()
                withAnimation(Theme.Animation.slowFade) {
                    selectedTab = .home
                }
            }

            TabBarButton(
                tab: .bible,
                isSelected: selectedTab == .bible
            ) {
                HapticService.shared.tabSwitch()
                withAnimation(Theme.Animation.slowFade) {
                    selectedTab = .bible
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(pillBackground)
        .clipShape(Capsule())
    }

    // MARK: - Pill Background

    private var pillBackground: some View {
        Colors.Surface.surface(for: ThemeMode.current(from: colorScheme))
    }

    // MARK: - Animations

    private func startEntranceAnimation() {
        guard !tabBarAppeared else { return }

        if respectsReducedMotion {
            tabBarAppeared = true
            return
        }

        // Delay entrance after content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.settle) {
                tabBarAppeared = true
            }
        }
    }

    private func startShimmerAnimation() {
        guard !respectsReducedMotion else { return }

        withAnimation(Theme.Animation.fade) {
            shimmerOffset = 2
        }
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(tab.icon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                // Selection indicator bar
                Capsule()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: isSelected ? 20 : 0, height: 3)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.settle, value: isSelected)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to switch to \(tab.title) tab")
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: Tab = .home
        @State private var showAskModal = false

        var body: some View {
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, showAskModal: $showAskModal)
            }
            .background(Colors.Surface.background(for: .dark))
        }
    }

    return PreviewWrapper()
}
