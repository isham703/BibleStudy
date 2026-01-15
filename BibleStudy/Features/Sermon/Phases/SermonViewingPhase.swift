import SwiftUI
import AVFoundation

// MARK: - Sermon Viewing Phase
// Plaud-style design: Two tabs - Sources (audio/transcript) and Notes (AI content)

struct SermonViewingPhase: View {
    @Bindable var flowState: SermonFlowState
    @State private var viewModel = SermonViewingViewModel()
    @State private var selectedTab: SermonTab = .sources
    @State private var showShareSheet = false
    @State private var copiedToClipboard = false
    @State private var isAwakened = false
    @State private var autoScrollEnabled = true
    @State private var showDeleteConfirmation = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum SermonTab: String, CaseIterable {
        case sources = "Sources"
        case notes = "Notes"
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                // Plaud-style top tab bar
                topTabBar
                    .padding(.top, Theme.Spacing.sm)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {
                        switch selectedTab {
                        case .sources:
                            sourcesContent
                        case .notes:
                            notesContent
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xxl * 2)
                }
            }
        }
        .overlay(copiedOverlay)
        .onAppear {
            setupAudioPlayer()
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
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

    // MARK: - Top Tab Bar (Plaud-style)

    private var topTabBar: some View {
        HStack(spacing: Theme.Spacing.xl) {
            ForEach(SermonTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(Theme.Animation.settle) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(tab.rawValue)
                            .font(Typography.Command.body.weight(selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(
                                selectedTab == tab
                                    ? Color("AppTextPrimary")
                                    : Color("TertiaryText")
                            )

                        Rectangle()
                            .fill(
                                selectedTab == tab
                                    ? Color("AppTextPrimary")
                                    : Color.clear
                            )
                            .frame(height: 2)
                    }
                }
                .accessibilityLabel("\(tab.rawValue) tab")
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)
    }

    // MARK: - Sources Content
    // Player + Outline + Transcript (like Plaud's Sources tab)

    private var sourcesContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Compact Player
            SermonPlayerView(
                viewModel: viewModel,
                delay: 0.2,
                isAwakened: isAwakened
            )

            // Outline section (with timestamps)
            if let studyGuide = flowState.currentStudyGuide,
               let outline = studyGuide.content.outline,
               !outline.isEmpty {
                SermonOutlineSectionView(
                    outline: outline,
                    currentTime: viewModel.currentTime,
                    delay: 0.3,
                    isAwakened: isAwakened,
                    onSeek: { time in
                        viewModel.seekToTime(time)
                    }
                )
            }

            // Transcript section
            SermonTranscriptSection(
                transcript: flowState.currentTranscript,
                viewModel: viewModel,
                autoScrollEnabled: $autoScrollEnabled,
                copiedToClipboard: $copiedToClipboard,
                delay: 0.4,
                isAwakened: isAwakened
            )
        }
    }

    // MARK: - Notes Content
    // AI-generated study content (like Plaud's Notes tab)

    private var notesContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // AI Summary
            if let studyGuide = flowState.currentStudyGuide,
               !studyGuide.content.summary.isEmpty {
                SermonAtriumCard(delay: 0.2, isAwakened: isAwakened) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        // Title
                        if !studyGuide.content.title.isEmpty {
                            Text(studyGuide.content.title)
                                .font(Typography.Scripture.title)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }

                        // Summary
                        Text(studyGuide.content.summary)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)

                        // Key themes
                        if !studyGuide.content.keyThemes.isEmpty {
                            Rectangle()
                                .fill(Color("AppDivider"))
                                .frame(height: Theme.Stroke.hairline)

                            Text("THEMES")
                                .font(Typography.Command.meta)
                                .tracking(Typography.Editorial.labelTracking)
                                .foregroundStyle(Color("TertiaryText"))

                            SermonFlowLayout(spacing: Theme.Spacing.sm) {
                                ForEach(studyGuide.content.keyThemes, id: \.self) { theme in
                                    Text(theme)
                                        .font(Typography.Command.label)
                                        .foregroundStyle(Color("AppAccentAction"))
                                        .padding(.horizontal, Theme.Spacing.sm)
                                        .padding(.vertical, Theme.Spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                                .stroke(Color("AppAccentAction").opacity(0.3), lineWidth: Theme.Stroke.hairline)
                                        )
                                }
                            }
                        }
                    }
                }
            }

            // Discussion Questions
            if let studyGuide = flowState.currentStudyGuide,
               !studyGuide.content.discussionQuestions.isEmpty {
                CollapsibleInsightCard(
                    icon: "bubble.left.and.bubble.right",
                    iconColor: Color("FeedbackInfo"),
                    title: "Discussion Questions",
                    items: studyGuide.content.discussionQuestions,
                    delay: 0.3,
                    isAwakened: isAwakened
                ) { question, index in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("\(index + 1). \(question.question)")
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineSpacing(Typography.Command.bodyLineSpacing)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }

            // Reflection Prompts
            if let studyGuide = flowState.currentStudyGuide,
               !studyGuide.content.reflectionPrompts.isEmpty {
                CollapsibleInsightCard(
                    icon: "heart.text.square",
                    iconColor: Color("AccentBronze"),
                    title: "Reflection Prompts",
                    items: studyGuide.content.reflectionPrompts.indexed,
                    delay: 0.4,
                    isAwakened: isAwakened
                ) { item, _ in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color("AccentBronze"))
                            .padding(.top, 2)

                        Text(item.value)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .italic()
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    }
                }
            }

            // Application Points
            if let studyGuide = flowState.currentStudyGuide,
               !studyGuide.content.applicationPoints.isEmpty {
                CollapsibleInsightCard(
                    icon: "hand.raised",
                    iconColor: Color("FeedbackSuccess"),
                    title: "Application Points",
                    items: studyGuide.content.applicationPoints.indexed,
                    delay: 0.5,
                    isAwakened: isAwakened
                ) { item, _ in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Text("\(item.id + 1)")
                            .font(Typography.Command.label)
                            .foregroundStyle(Color("FeedbackSuccess"))
                            .frame(width: 20)

                        Text(item.value)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineSpacing(Typography.Command.bodyLineSpacing)
                    }
                }
            }

            // Actions row
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
                    summary: "This sermon explores the foundational Christian concept of grace as unmerited favor from God.",
                    keyThemes: ["Grace", "Salvation", "Faith"],
                    outline: [
                        OutlineSection(title: "Introduction to Grace", startSeconds: 0, endSeconds: 120, summary: nil),
                        OutlineSection(title: "Biblical Foundation", startSeconds: 120, endSeconds: 300, summary: nil),
                        OutlineSection(title: "Application", startSeconds: 300, endSeconds: 450, summary: nil)
                    ],
                    discussionQuestions: [
                        StudyQuestion(question: "How does understanding grace change your relationship with God?", type: .application)
                    ],
                    reflectionPrompts: ["Consider how you might extend grace to others"],
                    applicationPoints: ["Rest in God's grace rather than striving to earn approval"]
                )
            )
        }
}
