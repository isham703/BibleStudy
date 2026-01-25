import Auth
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sermon Input Phase
// Hero-style landing screen with segmented tab navigation.
// Adaptive default: Library for returning users, Record for first-time users.
// Features sticky tab control when hero scrolls away.

struct SermonInputPhase: View {
    @Bindable var flowState: SermonFlowState
    var onShowLibrary: (() -> Void)?
    var onShowProcessingQueue: (() -> Void)?
    var onSampleTap: (() -> Void)?
    var onSermonTap: ((Sermon) -> Void)?

    // Tab state
    @State private var selectedTab: SermonTab = .library
    @State private var isTabControlSticky = false

    // Content state
    @State private var showFilePicker = false
    @State private var isAwakened = false
    @State private var librarySermons: [Sermon] = []
    @State private var showSample = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let sampleService = SampleSermonService.shared
    private let syncService = SermonSyncService.shared

    // MARK: - Adaptive Default Tab

    private var adaptiveDefaultTab: SermonTab {
        let hasSermons = !realSermons.isEmpty
        let hasSample = sampleService.shouldShowSample(userId: SupabaseManager.shared.currentUser?.id)

        if hasSermons {
            return .library          // Returning user: show their sermons
        } else if hasSample {
            return .library          // New user with sample: show sample in library
        } else {
            return .recordNew        // New user, no sample: go straight to record
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Main scrollable content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero header with variable height
                    HeroHeader(
                        imageName: "SermonHero",
                        height: selectedTab == .library ? 200 : 280
                    )
                    .animation(reduceMotion ? nil : Theme.Animation.settle, value: selectedTab)

                    // Main content
                    VStack(spacing: Theme.Spacing.lg) {
                        // Title block - negative padding pulls content up to hero curve
                        titleBlock
                            .padding(.top, -Theme.Spacing.lg)

                        // Tab control (in-flow version)
                        SermonTabControl(selectedTab: $selectedTab)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: TabControlPositionKey.self,
                                        value: geo.frame(in: .global).minY
                                    )
                                }
                            )

                        // Tab content with crossfade
                        tabContent
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl * 2)
                }
            }
            .onPreferenceChange(TabControlPositionKey.self) { position in
                let shouldBeSticky = position < 0
                if shouldBeSticky != isTabControlSticky {
                    withAnimation(Theme.Animation.fade) {
                        isTabControlSticky = shouldBeSticky
                    }
                }
            }

            // Sticky tab control overlay (when scrolled past hero)
            if isTabControlSticky {
                stickyTabControl
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(colorScheme == .dark ? Color.warmCharcoal : Color.appBackground)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await flowState.importAudio(from: url)
                    }
                }
            case .failure(let error):
                print("[SermonInputPhase] File picker error: \(error)")
            }
        }
        .onAppear {
            // Check if sync service already has data (means we're returning, not fresh load)
            let hasExistingData = !syncService.sermons.isEmpty
            if hasExistingData {
                // Instant appearance on return - no ceremonial animation
                isAwakened = true
                // Restore state from service cache
                let userId = SupabaseManager.shared.currentUser?.id
                showSample = sampleService.shouldShowSample(userId: userId)
                librarySermons = syncService.sermons.filter { !sampleService.isSample($0) }
                // Set adaptive default
                selectedTab = adaptiveDefaultTab
            } else {
                // First appearance - use ceremonial animation
                withAnimation(Theme.Animation.settle) {
                    isAwakened = true
                }
            }
        }
        .task {
            // Only fetch from network if service cache is empty (first load)
            if syncService.sermons.isEmpty {
                await loadLibrary()
                // Set adaptive default after loading
                selectedTab = adaptiveDefaultTab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sampleSermonUnhidden)) { _ in
            withAnimation(Theme.Animation.settle) {
                showSample = true
            }
        }
    }

    // MARK: - Computed Properties

    /// Real sermons (excluding sample)
    private var realSermons: [Sermon] {
        librarySermons.filter { !sampleService.isSample($0) }
    }

    /// Quick access state based on sermon statuses
    private var quickAccessState: SermonQuickAccessState {
        SermonQuickAccessState.from(sermons: realSermons)
    }

    /// Sample sermon if available
    private var sampleSermon: Sermon? {
        showSample ? sampleService.sampleSermon(userId: SupabaseManager.shared.currentUser?.id) : nil
    }

    /// Whether the user is first time (no sermons)
    private var isFirstTimeUser: Bool {
        realSermons.isEmpty && !showSample
    }

    // MARK: - Library Loading

    private func loadLibrary() async {
        let userId = SupabaseManager.shared.currentUser?.id
        showSample = sampleService.shouldShowSample(userId: userId)
        await syncService.loadSermons(includeSample: false)
        librarySermons = syncService.sermons
    }

    private func hideSample() {
        let userId = SupabaseManager.shared.currentUser?.id
        sampleService.hideSample(userId: userId)
        withAnimation(Theme.Animation.settle) {
            showSample = false
        }
        HapticService.shared.deleteConfirmed()

        // Show undo toast
        ToastService.shared.showSampleHidden { [sampleService] in
            sampleService.unhideSample(userId: userId)
            // Post notification for view to restore sample visibility
            NotificationCenter.default.post(name: .sampleSermonUnhidden, object: nil)
        }
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("SERMONS")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            Text("Your Sermons")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Record, organize, and study your sermons.")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.top, Theme.Spacing.xs)
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        ZStack {
            // Library tab
            SermonLibraryTab(
                sermons: realSermons,
                sampleSermon: sampleSermon,
                showSample: showSample,
                quickAccessState: quickAccessState,
                onSermonTap: { sermon in
                    onSermonTap?(sermon)
                },
                onSampleTap: {
                    onSampleTap?()
                },
                onSampleDismiss: {
                    hideSample()
                },
                onViewAllTap: {
                    HapticService.shared.lightTap()
                    onShowLibrary?()
                },
                onRecordTap: {
                    HapticService.shared.lightTap()
                    withAnimation(Theme.Animation.settle) {
                        selectedTab = .recordNew
                    }
                },
                onProcessingTap: {
                    onShowProcessingQueue?()
                }
            )
            .opacity(selectedTab == .library ? 1 : 0)
            .zIndex(selectedTab == .library ? 1 : 0)
            .allowsHitTesting(selectedTab == .library)

            // Record tab
            SermonRecordTab(
                isFirstTimeUser: isFirstTimeUser,
                hasSampleInLibrary: showSample,
                onRecordTap: {
                    HapticService.shared.mediumTap()
                    Task {
                        await flowState.startRecording()
                    }
                },
                onImportTap: {
                    HapticService.shared.lightTap()
                    showFilePicker = true
                },
                onSeeExampleTap: {
                    HapticService.shared.lightTap()
                    withAnimation(Theme.Animation.settle) {
                        selectedTab = .library
                    }
                }
            )
            .opacity(selectedTab == .recordNew ? 1 : 0)
            .zIndex(selectedTab == .recordNew ? 1 : 0)
            .allowsHitTesting(selectedTab == .recordNew)
        }
        .animation(reduceMotion ? nil : Theme.Animation.fade, value: selectedTab)
    }

    // MARK: - Sticky Tab Control

    private var stickyTabControl: some View {
        VStack(spacing: 0) {
            SermonTabControl(selectedTab: $selectedTab)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(.ultraThinMaterial)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Tab Control Position Key

private struct TabControlPositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SermonInputPhase(flowState: SermonFlowState())
    }
    .preferredColorScheme(.dark)
}

// MARK: - Notification Names

extension Notification.Name {
    static let sampleSermonUnhidden = Notification.Name("sampleSermonUnhidden")
}
