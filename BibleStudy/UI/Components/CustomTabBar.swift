import SwiftUI

// MARK: - Custom Tab Bar
// Pill-shaped tab container with Ask FAB
// Replaces standard TabView for custom layout

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var showAskModal: Bool

    // MARK: - Animation State
    @State private var tabBarAppeared = false
    @State private var shimmerOffset: CGFloat = -1

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Tab pill (left side)
            tabPill

            // Ask FAB (right side)
            AskFAB {
                showAskModal = true
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(Color.appBackground)
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
                withAnimation(AppTheme.Animation.reverent) {
                    selectedTab = .home
                }
            }

            TabBarButton(
                tab: .bible,
                isSelected: selectedTab == .bible
            ) {
                HapticService.shared.tabSwitch()
                withAnimation(AppTheme.Animation.reverent) {
                    selectedTab = .bible
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(pillBackground)
        .clipShape(Capsule())
    }

    // MARK: - Pill Background

    private var pillBackground: some View {
        ZStack {
            // Base background
            Color.surfaceBackground.opacity(AppTheme.Opacity.nearOpaque)

            // Subtle shimmer overlay (ambient)
            if !respectsReducedMotion {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.divineGold.opacity(AppTheme.Opacity.faint),
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: shimmerOffset, y: 0),
                            endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 1)
                        )
                    )
                    .onAppear {
                        startShimmerAnimation()
                    }
            }
        }
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
            withAnimation(AppTheme.Animation.sacredSpring) {
                tabBarAppeared = true
            }
        }
    }

    private func startShimmerAnimation() {
        guard !respectsReducedMotion else { return }

        withAnimation(AppTheme.Animation.shimmerContinuous) {
            shimmerOffset = 2
        }
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let tab: Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xxs) {
                Image(tab.icon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(isSelected ? Color.scholarAccent : Color.secondaryText)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                // Selection indicator bar
                Capsule()
                    .fill(Color.scholarAccent)
                    .frame(width: isSelected ? 20 : 0, height: 3)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(width: AppTheme.TouchTarget.minimum, height: AppTheme.TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Animation.sacredSpring, value: isSelected)
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
            .background(Color.appBackground)
        }
    }

    return PreviewWrapper()
}
