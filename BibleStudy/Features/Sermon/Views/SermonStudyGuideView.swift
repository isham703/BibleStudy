//
//  SermonStudyGuideView.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Study Guide spoke — AI-generated insights, takeaways, quotes, etc.
//  Contains control strip (search + filter + contents), scroll tracking,
//  and floating bottom bar.
//

import SwiftUI

// MARK: - Sermon Study Guide View

struct SermonStudyGuideView: View {
    @Bindable var flowState: SermonFlowState
    let viewModel: SermonViewingViewModel
    @Bindable var notesViewModel: SermonNotesViewModel
    let scrollTo: SermonSectionID?
    let onAddNote: () -> Void
    let onShare: () -> Void
    let onNewSermon: () -> Void
    let onDelete: () -> Void

    // MARK: - State

    @State private var activeSectionID: SermonSectionID?
    @State private var sectionTrackingTask: Task<Void, Never>?
    @State private var isSearchExpanded = false
    @State private var showFilterSheet = false
    @State private var showContentsSheet = false
    @State private var pendingScrollTarget: SermonSectionID?
    @State private var isKeyboardVisible = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Computed

    private var isSampleSermon: Bool {
        flowState.isViewingSample
    }

    private var filterPillIsActive: Bool {
        notesViewModel.selectedFilter != .all || notesViewModel.isQuickRecapMode
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    studyGuideContent
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xxl * 2)
            }
            .coordinateSpace(name: "notesScroll")
            .onPreferenceChange(SectionVisibilityPreferenceKey.self) { prefs in
                sectionTrackingTask?.cancel()
                sectionTrackingTask = Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    let closest = prefs
                        .filter { $0.minY < 200 && $0.minY > -300 }
                        .min { abs($0.minY) < abs($1.minY) }
                    if let section = closest?.sectionID, section != activeSectionID {
                        activeSectionID = section
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                controlStrip
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
            .onChange(of: pendingScrollTarget) { _, newValue in
                if let target = newValue {
                    pendingScrollTarget = nil
                    // Clear search and reset filter if target section is hidden
                    notesViewModel.clearSearch()
                    if !notesViewModel.isSectionVisible(target) {
                        notesViewModel.selectedFilter = .all
                        notesViewModel.isQuickRecapMode = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(Theme.Animation.settle) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .sheet(isPresented: $showContentsSheet) {
                contentsSheet
            }
        }
        .navigationTitle("Study Guide")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncViewModel()
            if let target = scrollTo {
                pendingScrollTarget = target
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }

    // MARK: - Study Guide Content

    @ViewBuilder
    private var studyGuideContent: some View {
        if let studyGuide = flowState.currentStudyGuide {
            SermonNotesContent(
                studyGuide: studyGuide,
                notesViewModel: notesViewModel,
                isAwakened: true,
                onSeek: { timestamp in
                    viewModel.seekToTime(timestamp)
                    if !viewModel.isPlaying {
                        viewModel.togglePlayPause()
                    }
                },
                scrollTarget: $pendingScrollTarget
            )
        } else if flowState.isRetryingStudyGuide {
            studyGuideRetryingCard
        } else {
            studyGuideErrorCard
        }
    }

    // MARK: - Retrying Card

    private var studyGuideRetryingCard: some View {
        SermonAtriumCard(delay: 0.2, isAwakened: true) {
            VStack(spacing: Theme.Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AppAccentAction")))
                    .scaleEffect(1.2)

                Text("Generating Study Guide...")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("You can continue using other features while this runs.")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xl)
        }
    }

    // MARK: - Error Card

    private var studyGuideErrorCard: some View {
        SermonAtriumCard(delay: 0.2, isAwakened: true) {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle")
                    .font(Typography.Command.title1)
                    .foregroundStyle(Color("FeedbackWarning"))

                Text("Study Guide Unavailable")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("We couldn't generate the study guide for this sermon.")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)

                Button {
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

    // MARK: - Sync

    private func syncViewModel() {
        guard let studyGuide = flowState.currentStudyGuide else { return }
        notesViewModel.update(studyGuide: studyGuide)
    }

    // MARK: - Control Strip

    private var controlStrip: some View {
        VStack(spacing: 0) {
            if isSearchExpanded {
                SermonSearchBar(
                    searchQuery: $notesViewModel.searchQuery,
                    matchCount: notesViewModel.isSearchActive ? notesViewModel.matchingSectionCount : nil,
                    onDismiss: {
                        withAnimation(Theme.Animation.fade) {
                            notesViewModel.clearSearch()
                            isSearchExpanded = false
                        }
                    }
                )
                .padding(.horizontal, Theme.Spacing.lg)
            } else {
                // Compact control strip
                HStack(spacing: Theme.Spacing.md) {
                    // Search button
                    Button {
                        withAnimation(Theme.Animation.fade) {
                            isSearchExpanded = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search notes")

                    Spacer()

                    // Filter pill
                    Button { showFilterSheet = true } label: {
                        HStack(spacing: Theme.Spacing.xxs) {
                            if notesViewModel.isQuickRecapMode {
                                Image(systemName: "sparkles")
                                    .font(Typography.Icon.xxs)
                                Text("Recap")
                            } else {
                                Text(notesViewModel.selectedFilter == .all
                                     ? "All Sections"
                                     : notesViewModel.selectedFilter.displayLabel)
                            }
                            Image(systemName: "chevron.down")
                                .font(Typography.Icon.xxs)
                        }
                        .font(Typography.Command.caption)
                        .foregroundStyle(filterPillIsActive ? .white : Color("AppTextSecondary"))
                        .padding(.horizontal, Theme.Spacing.md)
                        .frame(minHeight: Theme.Size.minTapTarget)
                        .background(
                            Capsule().fill(filterPillIsActive ? Color("AppAccentAction") : Color("AppSurface"))
                        )
                        .overlay(
                            Capsule().stroke(
                                filterPillIsActive ? Color("AppAccentAction") : Color("AppDivider"),
                                lineWidth: Theme.Stroke.hairline
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filter: \(notesViewModel.isQuickRecapMode ? "Recap" : notesViewModel.selectedFilter.displayLabel)")
                    .accessibilityHint("Double tap to change filter")

                    Spacer()

                    // Contents button
                    Button { showContentsSheet = true } label: {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: "list.bullet")
                                .font(Typography.Icon.sm)
                            Text("Contents")
                                .font(Typography.Command.caption)
                        }
                        .foregroundStyle(Color("AccentBronze"))
                        .frame(minHeight: Theme.Size.minTapTarget)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Contents")
                    .accessibilityHint("Double tap to jump to a section")
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .padding(.vertical, Theme.Spacing.xxs)
        .background(reduceTransparency ? AnyShapeStyle(Color("AppBackground")) : AnyShapeStyle(.ultraThinMaterial))
        .animation(Theme.Animation.fade, value: isSearchExpanded)
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(SermonSectionFilter.allCases) { filter in
                        Button {
                            withAnimation(Theme.Animation.fade) {
                                notesViewModel.selectedFilter = filter
                                notesViewModel.isQuickRecapMode = false
                            }
                            HapticService.shared.selectionChanged()
                            showFilterSheet = false
                        } label: {
                            HStack(spacing: Theme.Spacing.md) {
                                Text(filter.displayLabel)
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Spacer()

                                if notesViewModel.selectedFilter == filter && !notesViewModel.isQuickRecapMode {
                                    Image(systemName: "checkmark")
                                        .font(Typography.Icon.sm)
                                        .foregroundStyle(Color("AppAccentAction"))
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                            .frame(minHeight: Theme.Size.minTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Rectangle()
                        .fill(Color("AppDivider"))
                        .frame(height: Theme.Stroke.hairline)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)

                    Button {
                        withAnimation(Theme.Animation.settle) {
                            notesViewModel.isQuickRecapMode.toggle()
                            if notesViewModel.isQuickRecapMode {
                                notesViewModel.selectedFilter = .all
                            }
                        }
                        HapticService.shared.selectionChanged()
                        showFilterSheet = false
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "sparkles")
                                .font(Typography.Icon.sm)
                                .foregroundStyle(Color("AppAccentAction"))

                            Text("Quick Recap")
                                .font(Typography.Command.body)
                                .foregroundStyle(Color("AppTextPrimary"))

                            Spacer()

                            if notesViewModel.isQuickRecapMode {
                                Image(systemName: "checkmark")
                                    .font(Typography.Icon.sm)
                                    .foregroundStyle(Color("AppAccentAction"))
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(minHeight: Theme.Size.minTapTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .background(Color("AppBackground"))
            .navigationTitle("Filter Sections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFilterSheet = false }
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Contents Sheet

    private var contentsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let sections = notesViewModel.jumpBarSections
                    if sections.isEmpty {
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "doc.text")
                                .font(Typography.Command.title1)
                                .foregroundStyle(Color("TertiaryText"))

                            Text("No sections available")
                                .font(Typography.Command.body)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.xxl)
                    } else {
                        ForEach(sections) { section in
                            Button {
                                activeSectionID = section
                                pendingScrollTarget = section
                                showContentsSheet = false
                            } label: {
                                HStack(spacing: Theme.Spacing.md) {
                                    Image(systemName: section.icon)
                                        .font(Typography.Icon.sm)
                                        .frame(width: Theme.Size.iconSize)
                                        .foregroundStyle(
                                            section == activeSectionID
                                                ? Color("AccentBronze")
                                                : Color("TertiaryText")
                                        )

                                    Text(section.displayLabel)
                                        .font(Typography.Command.body)
                                        .foregroundStyle(
                                            section == activeSectionID
                                                ? Color("AccentBronze")
                                                : Color("AppTextPrimary")
                                        )

                                    Spacer()

                                    if section == activeSectionID {
                                        Text("Current")
                                            .font(Typography.Command.meta)
                                            .foregroundStyle(Color("AccentBronze"))
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.lg)
                                .frame(minHeight: Theme.Size.minTapTarget)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(section.displayLabel)
                            .accessibilityHint(
                                section == activeSectionID
                                    ? "Current section"
                                    : "Double tap to jump to this section"
                            )
                        }
                    }
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .background(Color("AppBackground"))
            .navigationTitle("Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showContentsSheet = false }
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var flowState = SermonFlowState()

    NavigationStack {
        SermonStudyGuideView(
            flowState: flowState,
            viewModel: SermonViewingViewModel(),
            notesViewModel: SermonNotesViewModel(),
            scrollTo: nil,
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
        flowState.currentStudyGuide = SermonStudyGuide(
            sermonId: flowState.currentSermon!.id,
            content: StudyGuideContent(
                title: "The Power of Grace",
                summary: "This sermon explores grace as unmerited favor from God.",
                keyThemes: ["Grace", "Identity", "Faith"],
                centralThesis: "Grace is the foundation upon which our identity in Christ is built.",
                keyTakeaways: [
                    AnchoredInsight(
                        title: "Grace Transforms Identity",
                        insight: "The believer's identity shifts from performance to position.",
                        supportingQuote: "When you understand grace, you stop trying to earn what you have already received.",
                        timestampSeconds: 154,
                        references: ["Ephesians 2:8-9"]
                    )
                ],
                outline: [
                    OutlineSection(title: "Introduction to Grace", startSeconds: 0, endSeconds: 120, summary: nil),
                    OutlineSection(title: "Biblical Foundation", startSeconds: 120, endSeconds: 300, summary: nil)
                ],
                bibleReferencesMentioned: [
                    SermonVerseReference(reference: "John 3:16", bookId: 43, chapter: 3, verseStart: 16, isMentioned: true, timestampSeconds: 120)
                ],
                bibleReferencesSuggested: [],
                discussionQuestions: [
                    StudyQuestion(question: "How does grace change your relationship with God?", type: .application)
                ],
                reflectionPrompts: ["Consider how you might extend grace to others this week."],
                applicationPoints: [],
                anchoredApplicationPoints: []
            )
        )
    }
}
