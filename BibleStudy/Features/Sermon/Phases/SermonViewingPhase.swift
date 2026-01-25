import SwiftUI
import AVFoundation

// MARK: - Sermon Viewing Phase
// Plaud-style design: Two tabs - Sources (audio/transcript) and Notes (AI content)

struct SermonViewingPhase: View {
    @Bindable var flowState: SermonFlowState
    @State private var viewModel = SermonViewingViewModel()
    @State private var showShareSheet = false
    @State private var copiedToClipboard = false
    @State private var isAwakened = false
    @State private var autoScrollEnabled = false
    @State private var showDeleteConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var retryAttempts: Int = 0

    // MARK: - Animated Tab State
    @State private var selectedTabIndex: Int = 0  // Start on Notes tab (now first)
    @State private var scrollProgress: CGFloat = 0.0

    /// Computed property for backward compatibility with existing code
    private var selectedTab: SermonTab {
        SermonTab.allCases[safe: selectedTabIndex] ?? .sources
    }

    // MARK: - State Detection

    private var isStudyGuideFailed: Bool {
        flowState.currentSermon?.canViewInDegradedMode ?? false
    }

    /// Whether the current sermon is the bundled sample (no audio)
    private var isSampleSermon: Bool {
        flowState.isViewingSample
    }

    /// Whether audio is available for playback
    /// All real sermons have audio (recorded or imported). Only sample is audio-free.
    private var hasAudio: Bool {
        !isSampleSermon
    }

    // Use flowState.flowState.isRetryingStudyGuide instead of duplicating the logic

    private var errorMessage: String {
        switch retryAttempts {
        case 0...1:
            return "We couldn't generate the study guide for this sermon."
        case 2:
            return "Still having trouble. Check your connection and try again."
        default:
            return "This is taking longer than usual. You can continue using the transcript."
        }
    }

    enum SermonTab: String, CaseIterable {
        case notes = "Notes"
        case sources = "Sources"
    }

    var body: some View {
        ZStack {
            backgroundLayer

            if isAwakened {
                // Main content (shown after loading)
                VStack(spacing: 0) {
                    // Animated top tab bar
                    animatedTabBar
                        .padding(.top, Theme.Spacing.sm)

                    // Swipeable content pages (iOS standard TabView)
                    AnimatedTabPageContainer(
                        selectedIndex: $selectedTabIndex,
                        scrollProgress: $scrollProgress
                    ) {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: Theme.Spacing.lg) {
                                notesContent
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.top, Theme.Spacing.md)
                            .padding(.bottom, Theme.Spacing.xxl * 2)
                        }
                        .tag(0)

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: Theme.Spacing.lg) {
                                sourcesContent
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.top, Theme.Spacing.md)
                            .padding(.bottom, Theme.Spacing.xxl * 2)
                        }
                        .tag(1)
                    }
                }
                .transition(.opacity)
            } else {
                // Loading state with sermon title
                loadingView
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : Theme.Animation.slowFade, value: isAwakened)
        .overlay(copiedOverlay)
        .onAppear {
            setupAudioPlayer()
            // Brief delay for loading state to be visible, then awaken
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Theme.Animation.settle) {
                    isAwakened = true
                }
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareText = generateShareText() {
                ShareSheet(items: [shareText])
            }
        }
        .confirmationDialog(
            "Delete \"\(flowState.currentSermon?.displayTitle ?? "Sermon")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await deleteCurrentSermon() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color("AppBackground")
            .ignoresSafeArea()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Sermon icon with subtle pulse
            ZStack {
                Circle()
                    .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                    .frame(width: 80, height: 80)

                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color("AccentBronze"))
            }

            // Sermon title
            VStack(spacing: Theme.Spacing.sm) {
                Text(flowState.currentSermon?.displayTitle ?? "Loading...")
                    .font(Typography.Scripture.title)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let duration = flowState.currentSermon?.formattedDuration {
                    Text(duration)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.xxl)

            // Loading indicator
            LoadingDotsView()
                .padding(.top, Theme.Spacing.md)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Animated Tab Bar (iOS Standard)

    private var animatedTabBar: some View {
        AnimatedTabBar(
            tabs: SermonTab.allCases.map(\.rawValue),
            selectedIndex: $selectedTabIndex,
            scrollProgress: scrollProgress
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)
    }

    // MARK: - Sources Content
    // Player + Outline + Transcript (like Plaud's Sources tab)

    private var sourcesContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Compact Player (hidden for sample/no-audio sermons)
            if hasAudio {
                SermonPlayerView(
                    viewModel: viewModel,
                    delay: 0.2,
                    isAwakened: isAwakened
                )

                // Outline section (with timestamps) - only show if audio available
                if let studyGuide = flowState.currentStudyGuide,
                   let outline = studyGuide.content.outline,
                   !outline.isEmpty {
                    SermonOutlineSectionView(
                        outline: outline,
                        currentTime: viewModel.currentTime,
                        delay: 0.3,
                        isAwakened: isAwakened,
                        onSeek: { time in
                            viewModel.seekAndPlay(time)
                        }
                    )
                }
            }

            // Transcript section
            SermonTranscriptSection(
                transcript: flowState.currentTranscript,
                viewModel: viewModel,
                autoScrollEnabled: $autoScrollEnabled,
                copiedToClipboard: $copiedToClipboard,
                delay: hasAudio ? 0.4 : 0.2,
                isAwakened: isAwakened,
                isStaticMode: !hasAudio // Disable tap-to-seek when no audio
            )
        }
    }

    // MARK: - Notes Content
    // AI-generated study content (like Plaud's Notes tab)

    private var notesContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Sample notice card (when viewing bundled sample)
            if isSampleSermon {
                sampleNoticeCard
            }

            // Priority: Data presence over status
            // If study guide exists, show it regardless of status (handles stale status after sync)
            if let studyGuide = flowState.currentStudyGuide {
                SermonNotesContent(
                    studyGuide: studyGuide,
                    isAwakened: isAwakened,
                    onSeek: { timestamp in
                        // Switch to Sources tab to show the verse
                        withAnimation(Theme.Animation.settle) {
                            selectedTabIndex = 1
                        }
                        // Seek to timestamp and play
                        viewModel.seekToTime(timestamp)
                        if !viewModel.isPlaying {
                            viewModel.togglePlayPause()
                        }
                    }
                )
            } else if flowState.isRetryingStudyGuide {
                // No data yet, actively generating
                studyGuideRetryingCard
            } else if isStudyGuideFailed {
                // No data, generation failed
                studyGuideErrorCard
            } else {
                // No data, not generating (shouldn't normally happen)
                studyGuideEmptyCard
            }

            // Actions row - ALWAYS visible for user agency
            actionsRow
        }
    }

    // MARK: - Sample Notice Card

    private var sampleNoticeCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "info.circle.fill")
                .font(Typography.Icon.base)
                .foregroundStyle(Color("FeedbackInfo"))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Sample Sermon")
                    .font(Typography.Command.headline)
                    .foregroundStyle(Color.appTextPrimary)

                Text("This is an example. Record your own to get started!")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("FeedbackInfo").opacity(Theme.Opacity.overlay))
        )
        .ceremonialAppear(isAwakened: isAwakened, delay: 0.15)
    }

    // MARK: - Study Guide Error Card

    private var studyGuideErrorCard: some View {
        SermonAtriumCard(delay: 0.2, isAwakened: isAwakened) {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "sparkles.slash")
                    .font(Typography.Command.title1)
                    .foregroundStyle(Color("FeedbackWarning"))

                Text("Study Guide Unavailable")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                // Dynamic message based on retry attempts
                Text(errorMessage)
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)

                Text("Your transcript is still available in the Sources tab.")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
                    .multilineTextAlignment(.center)

                Button {
                    retryAttempts += 1
                    Task { await flowState.retryStudyGuide() }
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(Typography.Command.cta)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Color("AppAccentAction"))
                    .clipShape(Capsule())
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
        }
    }

    // MARK: - Study Guide Retrying Card

    private var studyGuideRetryingCard: some View {
        SermonAtriumCard(delay: 0.2, isAwakened: isAwakened) {
            VStack(spacing: Theme.Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AppAccentAction")))
                    .scaleEffect(1.2)

                Text("Generating Study Guide...")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("You can continue viewing the transcript while this runs.")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xl)
        }
    }

    // MARK: - Study Guide Empty Card

    private var studyGuideEmptyCard: some View {
        SermonAtriumCard(delay: 0.2, isAwakened: isAwakened) {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(Typography.Command.title1)
                    .foregroundStyle(Color("TertiaryText"))

                Text("No Study Guide")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Study guide content will appear here once generated.")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
        }
    }

    // MARK: - Actions Row

    private var actionsRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            SermonAtriumActionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                delay: 0.6,
                isAwakened: isAwakened
            ) {
                showShareSheet = true
            }

            SermonAtriumActionButton(
                icon: "plus",
                label: "New",
                delay: 0.65,
                isAwakened: isAwakened
            ) {
                flowState.reset()
            }

            // Hide delete for sample sermons (they're "hidden" not "deleted")
            if !isSampleSermon {
                SermonAtriumActionButton(
                    icon: "trash",
                    label: "Delete",
                    tint: Color("FeedbackError"),
                    delay: 0.7,
                    isAwakened: isAwakened
                ) {
                    showDeleteConfirmation = true
                }
            }
        }
    }

    // MARK: - Copied Overlay

    private var copiedOverlay: some View {
        Group {
            if copiedToClipboard {
                VStack {
                    Spacer()

                    Text("Copied to clipboard")
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Color("AppSurface"))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(Theme.Opacity.focusStroke), radius: 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    Spacer().frame(height: 100)
                }
            }
        }
        .animation(Theme.Animation.settle, value: copiedToClipboard)
    }

    // MARK: - Helpers

    private func setupAudioPlayer() {
        // Gather waveform samples from chunks
        var allSamples: [Float] = []
        for chunk in flowState.audioChunks {
            if let samples = chunk.waveformSamples {
                allSamples.append(contentsOf: samples)
            }
        }
        viewModel.waveformSamples = allSamples.isEmpty ? Array(repeating: 0.3, count: 100) : allSamples

        // Set duration
        viewModel.duration = Double(flowState.currentSermon?.durationSeconds ?? 0)

        // Load audio URLs
        Task {
            do {
                guard let sermon = flowState.currentSermon else { return }
                let urls = try await SermonSyncService.shared.getChunkURLs(sermonId: sermon.id)
                await MainActor.run {
                    viewModel.loadAudio(urls: urls)
                }
            } catch {
                print("[SermonViewingPhase] Failed to load audio: \(error)")
            }
        }

        // Setup transcript sync
        if let transcript = flowState.currentTranscript {
            viewModel.segments = transcript.segments
        }
    }

    private func generateShareText() -> String? {
        guard let sermon = flowState.currentSermon else { return nil }

        var text = """
        \(sermon.displayTitle)
        """

        if let speaker = sermon.speakerName {
            text += "\nBy \(speaker)"
        }

        text += "\nRecorded: \(sermon.recordedAt.formatted(date: .long, time: .omitted))"
        text += "\nDuration: \(sermon.formattedDuration)"

        if let studyGuide = flowState.currentStudyGuide {
            text += "\n\n--- Summary ---\n\(studyGuide.content.summary)"

            if !studyGuide.content.keyThemes.isEmpty {
                text += "\n\n--- Key Themes ---"
                for theme in studyGuide.content.keyThemes {
                    text += "\n- \(theme)"
                }
            }
        }

        if let transcript = flowState.currentTranscript {
            text += "\n\n--- Transcript ---\n\(transcript.content)"
        }

        return text
    }

    private func deleteCurrentSermon() async {
        guard let sermon = flowState.currentSermon else { return }

        // Stop playback first
        viewModel.cleanup()

        do {
            try await SermonSyncService.shared.deleteSermon(sermon)
            HapticService.shared.deleteConfirmed()
            ToastService.shared.showSermonDeleted(title: sermon.displayTitle)
            flowState.reset()
        } catch {
            HapticService.shared.warning()
            ToastService.shared.showDeleteError(message: error.localizedDescription)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Safe Collection Subscript

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var flowState = SermonFlowState()

    SermonViewingPhase(flowState: flowState)
        .preferredColorScheme(.dark)
        .onAppear {
            flowState.currentSermon = Sermon(
                userId: UUID(),
                title: "The Power of Grace",
                speakerName: "Pastor John",
                recordedAt: Date(),
                durationSeconds: 2700
            )

            flowState.currentTranscript = SermonTranscript(
                sermonId: flowState.currentSermon!.id,
                content: "So today we're going to be talking about grace. What is grace? Grace is unmerited favor from God.",
                wordTimestamps: []
            )

            flowState.currentStudyGuide = SermonStudyGuide(
                sermonId: flowState.currentSermon!.id,
                content: StudyGuideContent(
                    title: "The Power of Grace",
                    summary: "This sermon explores the foundational Christian concept of grace as unmerited favor from God, transforming our identity and relationship with Him.",
                    keyThemes: ["Grace", "Identity", "Faith", "Transformation"],
                    centralThesis: "Grace is not merely God's response to our failure - it is the foundation upon which our entire identity in Christ is built.",
                    keyTakeaways: [
                        AnchoredInsight(
                            title: "Grace Transforms Identity",
                            insight: "The believer's identity shifts from performance to position - not what we do, but who we are in Christ.",
                            supportingQuote: "When you understand grace, you stop trying to earn what you have already received.",
                            timestampSeconds: 154,
                            references: ["John 3:16", "Ephesians 2:8-9"]
                        ),
                        AnchoredInsight(
                            title: "Rest in Finished Work",
                            insight: "The cross declares 'It is finished' - our striving adds nothing to Christ's completed work.",
                            supportingQuote: "We do not work for acceptance; we work from acceptance.",
                            timestampSeconds: 423,
                            references: ["Romans 5:1"]
                        )
                    ],
                    outline: [
                        OutlineSection(title: "Introduction to Grace", startSeconds: 0, endSeconds: 120, summary: nil),
                        OutlineSection(title: "Biblical Foundation", startSeconds: 120, endSeconds: 300, summary: nil),
                        OutlineSection(title: "Application", startSeconds: 300, endSeconds: 450, summary: nil)
                    ],
                    bibleReferencesMentioned: [
                        SermonVerseReference(reference: "John 3:16", bookId: 43, chapter: 3, verseStart: 16, isMentioned: true, timestampSeconds: 120),
                        SermonVerseReference(reference: "Romans 8:28", bookId: 45, chapter: 8, verseStart: 28, isMentioned: true, timestampSeconds: 340),
                        SermonVerseReference(reference: "Ephesians 2:8-9", bookId: 49, chapter: 2, verseStart: 8, verseEnd: 9, isMentioned: true, timestampSeconds: 520)
                    ],
                    bibleReferencesSuggested: [
                        SermonVerseReference(
                            reference: "Romans 5:1-2",
                            bookId: 45, chapter: 5, verseStart: 1, verseEnd: 2,
                            isMentioned: false,
                            rationale: "Justification by faith leads to peace with God - a direct connection to the sermon's theme of grace-based identity.",
                            verificationStatus: .verified,
                            relation: .supports
                        ),
                        SermonVerseReference(
                            reference: "Galatians 2:16",
                            bookId: 48, chapter: 2, verseStart: 16,
                            isMentioned: false,
                            rationale: "Clarifies that no one is justified by works of the law, but through faith in Christ.",
                            verificationStatus: .partial,
                            relation: .clarifies
                        )
                    ],
                    discussionQuestions: [
                        StudyQuestion(question: "How does understanding grace change your relationship with God?", type: .application)
                    ],
                    reflectionPrompts: ["Consider how you might extend grace to others this week."],
                    applicationPoints: [],
                    anchoredApplicationPoints: [
                        AnchoredInsight(
                            title: "Practice Sabbath Rest",
                            insight: "This week, set aside one day to disconnect from work and practice intentional rest.",
                            supportingQuote: "Reclaim the gift of Sabbath in our hustle culture.",
                            timestampSeconds: 2112
                        )
                    ]
                )
            )
        }
}
