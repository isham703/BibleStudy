//
//  ImmersiveReaderChrome.swift
//  BibleStudy
//
//  Chrome visibility state machine for immersive reading
//  Priority: Selection > Sheet > Search > Menu > UserPinned > Reading
//

import SwiftUI
import UIKit

// MARK: - Chrome State

/// Priority-based state for reader chrome visibility
enum ChromeState: Int, Comparable {
    case reading = 0        // Default - chrome hidden
    case userPinned = 1     // User set "always show"
    case menuVisible = 2    // Reading Menu showing
    case searchActive = 3   // Search field focused
    case sheetPresented = 4 // Sheet is open
    case selectionActive = 5 // User selecting verses (highest priority)

    static func < (lhs: ChromeState, rhs: ChromeState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Immersive Reader Chrome

/// Manages chrome visibility for the immersive reading experience
/// Shows a single ReadingMenuButton when chrome is hidden
/// Opens ReadingMenuSheet when tapped
@Observable
@MainActor
final class ImmersiveReaderChrome {
    // MARK: - State

    /// Current chrome visibility state
    private(set) var state: ChromeState = .reading

    /// Whether user has selection active
    var hasSelection: Bool = false {
        didSet {
            updateState()
        }
    }

    /// Whether a sheet is currently presented
    var isSheetPresented: Bool = false {
        didSet {
            updateState()
        }
    }

    /// Whether search is active
    var isSearchActive: Bool = false {
        didSet {
            updateState()
        }
    }

    /// Whether reading menu is visible
    var isMenuVisible: Bool = false {
        didSet {
            updateState()
        }
    }

    // MARK: - User Preferences

    /// User preference to always show controls
    @ObservationIgnored
    @AppStorage("alwaysShowReadingControls") private var alwaysShowControls: Bool = false

    // MARK: - Auto-Hide Timer

    private var autoHideTask: Task<Void, Never>?
    private var recentlyUsedSettings: Bool = false
    private var recentlySearched: Bool = false

    // MARK: - Velocity-Based Reveal State

    /// Tracks scroll velocity for smart chrome reveal
    private var scrollVelocity: CGFloat = 0
    private var lastScrollOffset: CGFloat = 0
    private var lastScrollTime: Date = Date()
    private var velocityCheckTask: Task<Void, Never>?

    /// Whether chrome should reveal due to slow/stopped scroll
    private(set) var shouldRevealFromVelocity: Bool = false

    /// Adaptive timeout based on recent activity
    var autoHideDelay: TimeInterval {
        if recentlyUsedSettings { return AppTheme.Gesture.chromeExtendedHideDelay }
        if recentlySearched { return 10.0 }  // Search uses intermediate delay
        return AppTheme.Gesture.chromeAutoHideDelay
    }

    /// Conditions that disable auto-hide entirely
    var shouldDisableAutoHide: Bool {
        UIAccessibility.isVoiceOverRunning ||
        UIAccessibility.isReduceMotionEnabled ||
        alwaysShowControls
    }

    // MARK: - Computed Properties

    /// Whether the menu button should be visible
    /// Shows in reading/userPinned states OR when velocity-based reveal is active
    var showMenuButton: Bool {
        state == .reading || state == .userPinned || shouldRevealFromVelocity
    }

    /// Opacity for velocity-based reveal (subtle fade effect)
    var velocityRevealOpacity: Double {
        shouldRevealFromVelocity ? 0.9 : 1.0
    }

    /// Whether the selection toolbar should be visible
    var showSelectionToolbar: Bool {
        state == .selectionActive
    }

    /// Whether chrome is in "reading" mode (minimal UI)
    var isReadingMode: Bool {
        state == .reading
    }

    // MARK: - State Management

    private func updateState() {
        let newState: ChromeState

        if hasSelection {
            newState = .selectionActive
        } else if isSheetPresented {
            newState = .sheetPresented
        } else if isSearchActive {
            newState = .searchActive
        } else if isMenuVisible {
            newState = .menuVisible
        } else if shouldDisableAutoHide {
            newState = .userPinned
        } else {
            newState = .reading
        }

        if newState != state {
            state = newState

            // Manage auto-hide timer based on state
            if newState == .menuVisible && !shouldDisableAutoHide {
                startAutoHideTimer()
            } else {
                cancelAutoHideTimer()
            }
        }
    }

    // MARK: - Actions

    /// Called when user taps the menu button
    func showMenu() {
        isMenuVisible = true
    }

    /// Called when user dismisses the menu (tap outside, scroll, etc.)
    func hideMenu() {
        isMenuVisible = false
    }

    /// Called when user opens a sheet from the menu
    func openSheet() {
        isSheetPresented = true
        cancelAutoHideTimer()
    }

    /// Called when a sheet is dismissed
    func closeSheet() {
        isSheetPresented = false
        // Return to menu visible state briefly
        isMenuVisible = true
        // Track recent activity for adaptive timeout
        recentlyUsedSettings = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.recentlyUsedSettings = false
        }
    }

    /// Called when user starts a selection
    func startSelection() {
        hasSelection = true
        cancelAutoHideTimer()
    }

    /// Called when user clears selection
    func clearSelection() {
        hasSelection = false
    }

    /// Called when user starts scrolling (legacy - use onScrollUpdate for velocity tracking)
    func onScroll() {
        if state == .menuVisible {
            hideMenu()
        }
    }

    // MARK: - Velocity-Based Scroll Handling

    /// Called during scroll with current offset for velocity calculation
    /// - Parameters:
    ///   - offset: Current scroll offset (positive = scrolling down)
    ///   - isScrolling: Whether user is actively scrolling
    func onScrollUpdate(offset: CGFloat, isScrolling: Bool) {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastScrollTime)

        guard timeDelta > 0.01 else { return }  // Debounce very rapid updates

        // Calculate velocity (px/s)
        let offsetDelta = abs(offset - lastScrollOffset)
        scrollVelocity = offsetDelta / timeDelta

        lastScrollOffset = offset
        lastScrollTime = now

        // Determine scroll direction (negative = scrolling up/back)
        let isScrollingUp = offset < lastScrollOffset

        if isScrolling {
            // User is actively scrolling
            handleActiveScroll(velocity: scrollVelocity, isScrollingUp: isScrollingUp)
        } else {
            // User stopped scrolling - check for pause reveal
            handleScrollPause()
        }
    }

    /// Handles chrome behavior during active scroll
    private func handleActiveScroll(velocity: CGFloat, isScrollingUp: Bool) {
        // Cancel any pending velocity reveal
        velocityCheckTask?.cancel()
        velocityCheckTask = nil

        if velocity > AppTheme.Gesture.velocityThresholdForHide {
            // Fast scroll - ensure chrome is hidden for immersion
            if state == .menuVisible {
                withAnimation(AppTheme.Animation.quick) {
                    hideMenu()
                }
            }
            shouldRevealFromVelocity = false
        } else if velocity < AppTheme.Gesture.velocityThresholdForReveal && isScrollingUp {
            // Slow scroll UP (user looking back) - consider revealing
            startVelocityRevealCheck()
        }
    }

    /// Handles chrome behavior when scroll stops
    private func handleScrollPause() {
        startVelocityRevealCheck()
    }

    /// Checks if chrome should reveal after pause
    private func startVelocityRevealCheck() {
        velocityCheckTask?.cancel()

        velocityCheckTask = Task { [weak self] in
            guard let self = self else { return }

            // Wait for pause duration
            try? await Task.sleep(for: .seconds(AppTheme.Gesture.pauseDurationForReveal))

            guard !Task.isCancelled else { return }

            await MainActor.run {
                // Only reveal if still in reading state and velocity is low
                if self.state == .reading && self.scrollVelocity < AppTheme.Gesture.velocityThresholdForReveal {
                    withAnimation(AppTheme.Animation.spring) {
                        self.shouldRevealFromVelocity = true
                    }

                    // Auto-hide after brief reveal unless user interacts
                    Task {
                        try? await Task.sleep(for: .seconds(AppTheme.Gesture.velocityRevealDuration))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            withAnimation(AppTheme.Animation.standard) {
                                self.shouldRevealFromVelocity = false
                            }
                        }
                    }
                }
            }
        }
    }

    /// Cancels velocity-based reveal
    func cancelVelocityReveal() {
        velocityCheckTask?.cancel()
        velocityCheckTask = nil
        shouldRevealFromVelocity = false
    }

    /// Called when search becomes active
    func activateSearch() {
        isSearchActive = true
        recentlySearched = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.recentlySearched = false
        }
    }

    /// Called when search is deactivated
    func deactivateSearch() {
        isSearchActive = false
    }

    // MARK: - Auto-Hide Timer

    private func startAutoHideTimer() {
        cancelAutoHideTimer()

        autoHideTask = Task { [weak self] in
            guard let self = self else { return }

            try? await Task.sleep(for: .seconds(self.autoHideDelay))

            guard !Task.isCancelled else { return }

            await MainActor.run {
                if self.state == .menuVisible && !self.shouldDisableAutoHide {
                    withAnimation(AppTheme.Animation.standard) {
                        self.hideMenu()
                    }
                }
            }
        }
    }

    private func cancelAutoHideTimer() {
        autoHideTask?.cancel()
        autoHideTask = nil
    }

}

// MARK: - Chrome View Modifier

/// View modifier that adds immersive chrome to a reading view
struct ImmersiveReaderChromeModifier: ViewModifier {
    @Bindable var chrome: ImmersiveReaderChrome
    @Binding var showReadingMenu: Bool

    // Reading state for menu
    let bookName: String
    let chapterNumber: Int
    let currentVerse: Int
    let totalVerses: Int
    let currentTranslation: String
    let isAudioPlaying: Bool

    // Actions
    let onContentsTap: () -> Void
    let onSearchTap: () -> Void
    let onTranslationTap: () -> Void
    let onSettingsTap: () -> Void
    let onAudioTap: () -> Void
    let onShareTap: () -> Void

    @AppStorage("readingMenuPosition") private var menuPosition: MenuPosition = .right

    func body(content: Content) -> some View {
        content
            .overlay(alignment: menuPosition.alignment) {
                if chrome.showMenuButton {
                    ReadingMenuButton(isExpanded: $showReadingMenu)
                        .padding(AppTheme.Spacing.lg)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .sheet(isPresented: $showReadingMenu) {
                ReadingMenuSheet(
                    bookName: bookName,
                    chapterNumber: chapterNumber,
                    currentVerse: currentVerse,
                    totalVerses: totalVerses,
                    currentTranslation: currentTranslation,
                    isAudioPlaying: isAudioPlaying,
                    onContentsTap: onContentsTap,
                    onSearchTap: onSearchTap,
                    onTranslationTap: onTranslationTap,
                    onSettingsTap: onSettingsTap,
                    onAudioTap: onAudioTap,
                    onShareTap: onShareTap
                )
            }
            .onChange(of: showReadingMenu) { _, newValue in
                if newValue {
                    chrome.showMenu()
                } else {
                    chrome.hideMenu()
                }
            }
            .animation(AppTheme.Animation.standard, value: chrome.state)
    }
}

// MARK: - View Extension

extension View {
    /// Adds immersive reader chrome to a view
    func immersiveReaderChrome(
        chrome: ImmersiveReaderChrome,
        showReadingMenu: Binding<Bool>,
        bookName: String,
        chapterNumber: Int,
        currentVerse: Int,
        totalVerses: Int,
        currentTranslation: String,
        isAudioPlaying: Bool,
        onContentsTap: @escaping () -> Void,
        onSearchTap: @escaping () -> Void,
        onTranslationTap: @escaping () -> Void,
        onSettingsTap: @escaping () -> Void,
        onAudioTap: @escaping () -> Void,
        onShareTap: @escaping () -> Void
    ) -> some View {
        modifier(ImmersiveReaderChromeModifier(
            chrome: chrome,
            showReadingMenu: showReadingMenu,
            bookName: bookName,
            chapterNumber: chapterNumber,
            currentVerse: currentVerse,
            totalVerses: totalVerses,
            currentTranslation: currentTranslation,
            isAudioPlaying: isAudioPlaying,
            onContentsTap: onContentsTap,
            onSearchTap: onSearchTap,
            onTranslationTap: onTranslationTap,
            onSettingsTap: onSettingsTap,
            onAudioTap: onAudioTap,
            onShareTap: onShareTap
        ))
    }
}

// MARK: - Preview

#Preview("Immersive Chrome - Reading Mode") {
    struct PreviewWrapper: View {
        @State private var chrome = ImmersiveReaderChrome()
        @State private var showMenu = false

        var body: some View {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack {
                    Text("In the beginning God created the heaven and the earth.")
                        .font(Typography.Scripture.body())
                        .padding()
                    Spacer()
                }
            }
            .immersiveReaderChrome(
                chrome: chrome,
                showReadingMenu: $showMenu,
                bookName: "Genesis",
                chapterNumber: 1,
                currentVerse: 1,
                totalVerses: 31,
                currentTranslation: "KJV",
                isAudioPlaying: false,
                onContentsTap: {},
                onSearchTap: {},
                onTranslationTap: {},
                onSettingsTap: {},
                onAudioTap: {},
                onShareTap: {}
            )
        }
    }

    return PreviewWrapper()
}
