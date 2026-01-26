//
//  SermonListenReadView.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Listen & Read spoke — audio player, outline, transcript.
//  Contains floating bottom bar, auto-scroll toggle,
//  and inline "Find in transcript" search.
//

import SwiftUI

// MARK: - Sermon Listen Read View

struct SermonListenReadView: View {
    @Bindable var flowState: SermonFlowState
    let viewModel: SermonViewingViewModel
    let autoPlay: Bool
    let onAddNote: () -> Void
    let onShare: () -> Void
    let onNewSermon: () -> Void
    let onDelete: () -> Void

    // MARK: - State

    @State private var autoScrollEnabled = false
    @State private var copiedToClipboard = false
    @State private var isKeyboardVisible = false
    @State private var isSearchExpanded = false
    @State private var transcriptSearchQuery = ""

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Computed

    private var isSampleSermon: Bool {
        flowState.isViewingSample
    }

    private var hasAudio: Bool {
        !isSampleSermon
    }

    /// Filtered transcript segments based on search query.
    private var filteredSegments: [TranscriptDisplaySegment]? {
        guard !transcriptSearchQuery.isEmpty,
              let transcript = flowState.currentTranscript else {
            return nil
        }
        let query = transcriptSearchQuery
        return transcript.segments.filter {
            $0.text.localizedCaseInsensitiveContains(query)
        }
    }

    private var searchResultCount: Int {
        filteredSegments?.count ?? 0
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.lg) {
                sourcesContent
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl * 2)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if isSearchExpanded {
                transcriptSearchBar
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SermonFloatingBottomBar(
                isVisible: !isKeyboardVisible,
                isSampleSermon: isSampleSermon,
                onAddNoteTap: onAddNote,
                onShareTap: onShare,
                onNewSermonTap: onNewSermon,
                onDeleteTap: onDelete
            )
        }
        .overlay(copiedOverlay)
        .navigationTitle("Listen & Read")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(Theme.Animation.fade) {
                        isSearchExpanded.toggle()
                        if !isSearchExpanded {
                            transcriptSearchQuery = ""
                        }
                    }
                } label: {
                    Image(systemName: isSearchExpanded ? "xmark" : "magnifyingglass")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("AppAccentAction"))
                }
                .accessibilityLabel(isSearchExpanded ? "Close search" : "Find in transcript")
            }
        }
        .onAppear {
            if autoPlay && !viewModel.isPlaying {
                viewModel.togglePlayPause()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }

    // MARK: - Sources Content

    private var sourcesContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Compact Player (hidden for sample/no-audio sermons)
            if hasAudio {
                SermonPlayerView(
                    viewModel: viewModel,
                    delay: 0.2,
                    isAwakened: true
                )

                // Outline section (with timestamps)
                if let studyGuide = flowState.currentStudyGuide,
                   let outline = studyGuide.content.outline,
                   !outline.isEmpty {
                    SermonOutlineSectionView(
                        outline: outline,
                        currentTime: viewModel.currentTime,
                        delay: 0.3,
                        isAwakened: true,
                        onSeek: { time in
                            viewModel.seekAndPlay(time)
                        }
                    )
                }
            }

            // Transcript section
            if let filtered = filteredSegments {
                filteredTranscriptSection(segments: filtered)
            } else {
                SermonTranscriptSection(
                    transcript: flowState.currentTranscript,
                    viewModel: viewModel,
                    autoScrollEnabled: $autoScrollEnabled,
                    copiedToClipboard: $copiedToClipboard,
                    delay: hasAudio ? 0.4 : 0.2,
                    isAwakened: true,
                    isStaticMode: !hasAudio
                )
            }
        }
    }

    // MARK: - Transcript Search Bar

    private var transcriptSearchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("TertiaryText"))

            TextField("Find in transcript...", text: $transcriptSearchQuery)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !transcriptSearchQuery.isEmpty {
                Text("\(searchResultCount) match\(searchResultCount == 1 ? "" : "es")")
                    .font(Typography.Command.meta)
                    .foregroundStyle(searchResultCount > 0 ? Color("AccentBronze") : Color("FeedbackWarning"))
                    .transition(.opacity)
            }

            Button {
                withAnimation(Theme.Animation.fade) {
                    transcriptSearchQuery = ""
                    isSearchExpanded = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("TertiaryText"))
                    .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close search")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .frame(minHeight: Theme.Size.minTapTarget)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(reduceTransparency ? AnyShapeStyle(Color("AppBackground")) : AnyShapeStyle(.ultraThinMaterial))
    }

    // MARK: - Filtered Transcript

    private func filteredTranscriptSection(segments: [TranscriptDisplaySegment]) -> some View {
        SermonAtriumCard(delay: 0.2, isAwakened: true) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Text("Transcript")
                        .font(Typography.Command.body.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Spacer()

                    Text("\(segments.count) result\(segments.count == 1 ? "" : "s")")
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color("AccentBronze"))
                }

                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)

                if segments.isEmpty {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(Typography.Icon.lg)
                            .foregroundStyle(Color("TertiaryText"))

                        Text("No matches found")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                } else {
                    LazyVStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        ForEach(segments) { segment in
                            Button {
                                guard hasAudio else { return }
                                viewModel.seekToTime(segment.startTime)
                                HapticService.shared.selectionChanged()
                            } label: {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    if hasAudio {
                                        Text(TimestampFormatter.format(segment.startTime))
                                            .font(Typography.Command.meta.monospacedDigit())
                                            .foregroundStyle(Color("TertiaryText"))
                                    }

                                    Text(segment.text)
                                        .font(Typography.Scripture.body)
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .lineSpacing(Typography.Scripture.bodyLineSpacing)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!hasAudio)
                        }
                    }
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
}

// MARK: - Preview

#Preview {
    @Previewable @State var flowState = SermonFlowState()

    NavigationStack {
        SermonListenReadView(
            flowState: flowState,
            viewModel: SermonViewingViewModel(),
            autoPlay: false,
            onAddNote: {},
            onShare: {},
            onNewSermon: {},
            onDelete: {}
        )
    }
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
    }
}
