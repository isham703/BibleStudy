import SwiftUI

// MARK: - Main Tab View
// Root navigation with custom tab bar: Home, Read tabs + Ask FAB
// Home consolidates Memorize, Plans, and Discover content
// Read provides the core Bible reading experience
// Ask opens as full-screen modal via FAB

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .home
    @State private var showAskModal = false
    @State private var askViewModel = AskViewModel()
    @State private var audioService = AudioService.shared
    @State private var showFullPlayer = false

    // Tab switch golden flash
    @State private var tabSwitchFlash = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        // Tab content (fills available space, tab bar floats over it)
        ZStack {
            SanctuaryHomeView()
                .opacity(selectedTab == .home ? 1 : 0)
                .blur(radius: selectedTab == .home ? 0 : AppTheme.Blur.subtle)
                .allowsHitTesting(selectedTab == .home)
                .accessibilityHidden(selectedTab != .home)

            ReadTabView()
                .opacity(selectedTab == .read ? 1 : 0)
                .blur(radius: selectedTab == .read ? 0 : AppTheme.Blur.subtle)
                .allowsHitTesting(selectedTab == .read)
                .accessibilityHidden(selectedTab != .read)

            NavigationStack {
                ScholarReaderView()
            }
            .opacity(selectedTab == .scholar ? 1 : 0)
            .blur(radius: selectedTab == .scholar ? 0 : AppTheme.Blur.subtle)
            .allowsHitTesting(selectedTab == .scholar)
            .accessibilityHidden(selectedTab != .scholar)

            // Golden flash overlay for tab switches
            if !respectsReducedMotion {
                Rectangle()
                    .fill(Color.divineGold.opacity(tabSwitchFlash ? AppTheme.Opacity.light : 0))
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .animation(AppTheme.Animation.reverent, value: selectedTab)
        // Floating glass tab bar overlays content at bottom (hidden when in child views)
        .safeAreaInset(edge: .bottom) {
            if !appState.hideTabBar {
                VStack(spacing: 0) {
                    // Mini player (conditionally shown above tab bar)
                    if audioService.playbackState != .idle {
                        MiniPlayerView(
                            audioService: audioService,
                            onTap: {
                                showFullPlayer = true
                            },
                            onClose: {
                                withAnimation(AppTheme.Animation.quick) {
                                    audioService.stop()
                                }
                            }
                        )
                        .padding(.bottom, AppTheme.Spacing.sm)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(AppTheme.Animation.spring, value: audioService.playbackState)
                    }

                    // Glass tab bar floats over content with see-through background
                    GlassTabBar(selectedTab: $selectedTab, showAskModal: $showAskModal)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(AppTheme.Animation.standard, value: appState.hideTabBar)
        .ignoresSafeArea(.keyboard)
        .background(Color.appBackground)
        .onChange(of: selectedTab) { _, _ in
            triggerTabSwitchFlash()
        }
        .fullScreenCover(isPresented: $showAskModal) {
            AskModalView(viewModel: askViewModel)
        }
        .sheet(isPresented: $showFullPlayer) {
            AudioPlayerSheet(audioService: audioService)
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkAskRequested)) { _ in
            showAskModal = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkSearchRequested)) { _ in
            // Ensure Read tab is selected for search
            selectedTab = .read
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkSettingsRequested)) { _ in
            // Ensure Read tab is selected for settings
            selectedTab = .read
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkNavigationRequested)) { _ in
            // Ensure Read tab is selected for verse navigation
            selectedTab = .read
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkHomeRequested)) { _ in
            // Navigate to Home tab
            selectedTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkPracticeRequested)) { _ in
            // Navigate to Home tab for practice
            selectedTab = .home
        }
    }

    // MARK: - Tab Switch Flash

    private func triggerTabSwitchFlash() {
        guard !respectsReducedMotion else { return }

        tabSwitchFlash = true
        withAnimation(AppTheme.Animation.standard) {
            tabSwitchFlash = false
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case home
    case read
    case scholar

    var title: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .home: return AppIcons.TabBar.home
        case .read: return AppIcons.TabBar.read
        case .scholar: return AppIcons.TabBar.scholar
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(BibleService.shared)
}
