import SwiftUI

// MARK: - Main Tab View
// Root navigation with custom tab bar: Home, Bible tabs + Ask FAB
// Home consolidates Memorize, Plans, and Discover content
// Bible provides the Scholar reading experience with insights
// Ask opens as full-screen modal via FAB

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
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

    private var isUITestingReader: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui_testing_reader")
    }

    var body: some View {
        // Tab content (fills available space, tab bar floats over it)
        ZStack {
            SanctuaryHomeView()
                .opacity(selectedTab == .home ? 1 : 0)
                .blur(radius: selectedTab == .home ? 0 : 4)
                .allowsHitTesting(selectedTab == .home)
                .accessibilityHidden(selectedTab != .home)

            BibleTabView()
                .opacity(selectedTab == .bible ? 1 : 0)
                .blur(radius: selectedTab == .bible ? 0 : 4)
                .allowsHitTesting(selectedTab == .bible)
                .accessibilityHidden(selectedTab != .bible)

            // Golden flash overlay for tab switches
            if !respectsReducedMotion {
                Rectangle()
                    .fill(Color("AccentBronze").opacity(tabSwitchFlash ? Theme.Opacity.selectionBackground : 0))
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .animation(Theme.Animation.slowFade, value: selectedTab)
        .onAppear {
            if isUITestingReader {
                selectedTab = .bible
            }
        }
        // Floating glass tab bar overlays content at bottom (hidden when in child views)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                // Mini player (always shown when audio is active, even with tab bar hidden)
                if audioService.playbackState != .idle {
                    MiniPlayerView(
                        audioService: audioService,
                        onTap: {
                            showFullPlayer = true
                        },
                        onClose: {
                            withAnimation(Theme.Animation.fade) {
                                audioService.stop()
                            }
                        }
                    )
                    .padding(.bottom, appState.hideTabBar ? 0 : Theme.Spacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(Theme.Animation.settle, value: audioService.playbackState)
                }

                // Glass tab bar floats over content with see-through background (hidden in child views)
                if !appState.hideTabBar {
                    GlassTabBar(selectedTab: $selectedTab, showAskModal: $showAskModal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(Theme.Animation.settle, value: appState.hideTabBar)
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
            // Ensure Bible tab is selected for search
            selectedTab = .bible
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkSettingsRequested)) { _ in
            // Ensure Bible tab is selected for settings
            selectedTab = .bible
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkNavigationRequested)) { _ in
            // Ensure Bible tab is selected for verse navigation
            selectedTab = .bible
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
        withAnimation(Theme.Animation.settle) {
            tabSwitchFlash = false
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case home
    case bible

    var title: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .home: return AppIcons.TabBar.home
        case .bible: return AppIcons.TabBar.scholar
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(BibleService.shared)
}
