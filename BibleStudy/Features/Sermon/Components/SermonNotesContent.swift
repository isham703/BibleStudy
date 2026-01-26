//
//  SermonNotesContent.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Orchestration view for study guide content.
//  Composes all AI-generated sections with proper staggered animations.
//
//  Section Order:
//  1. Summary Card (enhanced with Central Thesis)
//  2. Key Takeaways (anchored insights)
//  3. Notable Quotes (decorative marginalia styling)
//  4. Scripture References (mentioned + suggested)
//  5. Theological Depth (collapsible AI-suggested annotations)
//  6. Discussion Questions (tappable for journal entries)
//  7. Reflection Prompts (tappable for journal entries)
//  8. Application Points (enhanced with anchored version)
//

import Auth
import SwiftUI

// MARK: - Sermon Notes Content

struct SermonNotesContent: View {
    let studyGuide: SermonStudyGuide
    let notesViewModel: SermonNotesViewModel
    let isAwakened: Bool
    let onSeek: (TimeInterval) -> Void
    @Binding var scrollTarget: SermonSectionID?

    init(
        studyGuide: SermonStudyGuide,
        notesViewModel: SermonNotesViewModel,
        isAwakened: Bool,
        onSeek: @escaping (TimeInterval) -> Void,
        scrollTarget: Binding<SermonSectionID?> = .constant(nil)
    ) {
        self.studyGuide = studyGuide
        self.notesViewModel = notesViewModel
        self.isAwakened = isAwakened
        self.onSeek = onSeek
        self._scrollTarget = scrollTarget
    }

    // MARK: - State

    @State private var selectedQuestion: StudyQuestion?
    @State private var selectedReflectionPrompt: IndexedString?

    private var engagementService: SermonEngagementService { .shared }

    // MARK: - Content Accessors

    private var content: StudyGuideContent { studyGuide.content }

    private var shouldShowBridgeCard: Bool {
        !notesViewModel.isQuickRecapMode &&
        (notesViewModel.isSectionVisible(.discussionQuestions) ||
         notesViewModel.isSectionVisible(.reflectionPrompts) ||
         notesViewModel.isSectionVisible(.applicationPoints))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // 1. Summary Card (enhanced with Central Thesis + Key Themes)
            if notesViewModel.isSectionVisible(.summary) {
                summarySection
                    .id(SermonSectionID.summary)
                    .trackSectionVisibility(.summary, in: "notesScroll")
            }

            // 2. Key Takeaways (anchored insights with audio sync)
            if notesViewModel.isSectionVisible(.keyTakeaways), let takeaways = content.keyTakeaways {
                KeyTakeawaysSection(
                    takeaways: takeaways,
                    sermonId: studyGuide.sermonId,
                    baseDelay: 0.3,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
                .id(SermonSectionID.keyTakeaways)
                .trackSectionVisibility(.keyTakeaways, in: "notesScroll")
            }

            // 3. Notable Quotes (v2 - decorative marginalia styling)
            if notesViewModel.isSectionVisible(.notableQuotes), let quotes = content.notableQuotes, !quotes.isEmpty {
                NotableQuotesSection(
                    quotes: notesViewModel.isQuickRecapMode ? Array(quotes.prefix(1)) : quotes,
                    sermonId: studyGuide.sermonId,
                    baseDelay: 0.4,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
                .id(SermonSectionID.notableQuotes)
                .trackSectionVisibility(.notableQuotes, in: "notesScroll")
            }

            // 4. Scripture References (mentioned + suggested)
            if notesViewModel.isSectionVisible(.scriptureReferences) {
                SermonBibleReferencesCard(
                    mentionedRefs: content.bibleReferencesMentioned,
                    suggestedRefs: content.bibleReferencesSuggested,
                    delay: 0.5,
                    isAwakened: isAwakened
                )
                .id(SermonSectionID.scriptureReferences)
                .trackSectionVisibility(.scriptureReferences, in: "notesScroll")
            }

            // 5. Theological Depth (v2 - collapsible AI-suggested annotations)
            if notesViewModel.isSectionVisible(.theologicalDepth), let annotations = content.theologicalAnnotations, !annotations.isEmpty {
                TheologicalAnnotationsSection(
                    annotations: annotations,
                    sermonId: studyGuide.sermonId,
                    baseDelay: 0.55,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
                .id(SermonSectionID.theologicalDepth)
                .trackSectionVisibility(.theologicalDepth, in: "notesScroll")
            }

            // Reflect Bridge (between Read and Reflect/Apply sections)
            if shouldShowBridgeCard {
                ReflectBridgeCard(
                    notesViewModel: notesViewModel,
                    scrollTarget: $scrollTarget,
                    isAwakened: isAwakened,
                    delay: 0.6
                )
            }

            // 6. Discussion Questions (tappable for journal entries)
            if notesViewModel.isSectionVisible(.discussionQuestions) && !content.discussionQuestions.isEmpty {
                CollapsibleInsightCard(
                    icon: "bubble.left.and.bubble.right",
                    iconColor: Color("FeedbackInfo"),
                    title: "Discussion Questions",
                    items: content.discussionQuestions,
                    delay: 0.65,
                    isAwakened: isAwakened
                ) { question, index in
                    Button {
                        HapticService.shared.lightTap()
                        selectedQuestion = question
                    } label: {
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            let targetId = SermonEngagement.fingerprint(
                                sermonId: studyGuide.sermonId,
                                type: .journalEntry,
                                content: question.question
                            )
                            let hasEntry = engagementService.journalEntry(targetId: targetId) != nil

                            Image(systemName: hasEntry ? "checkmark.circle.fill" : "circle")
                                .font(Typography.Icon.sm)
                                .foregroundStyle(hasEntry ? Color("FeedbackSuccess") : Color("TertiaryText"))
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                Text("\(index + 1). \(question.question)")
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineSpacing(Typography.Command.bodyLineSpacing)
                                    .multilineTextAlignment(.leading)

                                Text(hasEntry ? "Edit response" : "Tap to answer")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(hasEntry ? Color("FeedbackSuccess") : Color("AccentBronze"))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(Typography.Icon.xs)
                                .foregroundStyle(Color("TertiaryText"))
                                .padding(.top, 2)
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .fill(Color("AppSurface").opacity(Theme.Opacity.subtle))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(question.question)")
                    .accessibilityHint(engagementService.journalEntry(targetId: SermonEngagement.fingerprint(sermonId: studyGuide.sermonId, type: .journalEntry, content: question.question)) != nil ? "Double tap to edit your response" : "Double tap to write a journal entry")
                }
                .id(SermonSectionID.discussionQuestions)
                .trackSectionVisibility(.discussionQuestions, in: "notesScroll")
            }

            // 7. Reflection Prompts (tappable for journal entries)
            if notesViewModel.isSectionVisible(.reflectionPrompts) && !content.reflectionPrompts.isEmpty {
                CollapsibleInsightCard(
                    icon: "heart.text.square",
                    iconColor: Color("AccentBronze"),
                    title: "Reflection Prompts",
                    items: content.reflectionPrompts.indexed,
                    delay: 0.7,
                    isAwakened: isAwakened
                ) { item, _ in
                    let targetId = SermonEngagement.fingerprint(
                        sermonId: studyGuide.sermonId,
                        type: .journalEntry,
                        content: item.value
                    )
                    let hasEntry = engagementService.journalEntry(targetId: targetId) != nil

                    Button {
                        HapticService.shared.lightTap()
                        selectedReflectionPrompt = item
                    } label: {
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Image(systemName: hasEntry ? "checkmark.circle.fill" : "arrow.turn.down.right")
                                .font(Typography.Icon.sm)
                                .foregroundStyle(hasEntry ? Color("FeedbackSuccess") : Color("AccentBronze"))
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                Text(item.value)
                                    .font(Typography.Scripture.body)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                    .italic()
                                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                                    .multilineTextAlignment(.leading)

                                Text(hasEntry ? "Edit reflection" : "Start reflection")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(hasEntry ? Color("FeedbackSuccess") : Color("AccentBronze"))
                            }

                            Spacer()

                            Image(systemName: "pencil.line")
                                .font(Typography.Icon.sm)
                                .foregroundStyle(Color("AccentBronze"))
                                .padding(.top, 2)
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.value)
                    .accessibilityHint(hasEntry ? "Double tap to edit your reflection" : "Double tap to write a reflection")
                }
                .id(SermonSectionID.reflectionPrompts)
                .trackSectionVisibility(.reflectionPrompts, in: "notesScroll")
            }

            // 8. Application Points (enhanced with anchored version)
            if notesViewModel.isSectionVisible(.applicationPoints) {
                applicationSection
                    .id(SermonSectionID.applicationPoints)
                    .trackSectionVisibility(.applicationPoints, in: "notesScroll")
            }
        }
        .sheet(item: $selectedQuestion) { question in
            let targetId = SermonEngagement.fingerprint(
                sermonId: studyGuide.sermonId,
                type: .journalEntry,
                content: question.question
            )
            JournalEntrySheet(
                question: question,
                sermonId: studyGuide.sermonId,
                existingContent: engagementService.journalEntry(targetId: targetId)?.content,
                onSave: { content in
                    Task {
                        guard let userId = SupabaseManager.shared.currentUser?.id else {
                            ToastService.shared.showError(message: "Sign in to save journal entries")
                            return
                        }
                        await engagementService.saveJournalEntry(
                            userId: userId,
                            sermonId: studyGuide.sermonId,
                            targetId: targetId,
                            content: content
                        )
                    }
                }
            )
        }
        .sheet(item: $selectedReflectionPrompt) { prompt in
            let targetId = SermonEngagement.fingerprint(
                sermonId: studyGuide.sermonId,
                type: .journalEntry,
                content: prompt.value
            )
            JournalEntrySheet(
                question: StudyQuestion(question: prompt.value, type: .application),
                sermonId: studyGuide.sermonId,
                existingContent: engagementService.journalEntry(targetId: targetId)?.content,
                onSave: { content in
                    Task {
                        guard let userId = SupabaseManager.shared.currentUser?.id else {
                            ToastService.shared.showError(message: "Sign in to save journal entries")
                            return
                        }
                        await engagementService.saveJournalEntry(
                            userId: userId,
                            sermonId: studyGuide.sermonId,
                            targetId: targetId,
                            content: content
                        )
                    }
                }
            )
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        SermonAtriumCard(delay: 0.2, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Title
                if !content.title.isEmpty {
                    Text(content.title)
                        .font(Typography.Scripture.title)
                        .foregroundStyle(Color("AppTextPrimary"))
                }

                // Summary
                if !content.summary.isEmpty {
                    Text(content.summary)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineSpacing(Typography.Scripture.bodyLineSpacing)
                        .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)
                }

                // Central Thesis (NEW - bronze accent bar)
                if let thesis = content.centralThesis, !thesis.isEmpty {
                    CentralThesisCallout(
                        thesis: thesis,
                        delay: 0.25,
                        isAwakened: isAwakened
                    )
                }

                // Key Themes
                if !content.keyThemes.isEmpty {
                    Rectangle()
                        .fill(Color("AppDivider"))
                        .frame(height: Theme.Stroke.hairline)

                    Text("THEMES")
                        .font(Typography.Command.meta)
                        .tracking(Typography.Editorial.labelTracking)
                        .foregroundStyle(Color("TertiaryText"))

                    SermonFlowLayout(spacing: Theme.Spacing.sm) {
                        ForEach(content.keyThemes, id: \.self) { theme in
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

    // MARK: - Application Section

    @ViewBuilder
    private var applicationSection: some View {
        // Prioritize anchored application points over plain
        if let anchored = content.anchoredApplicationPoints, !anchored.isEmpty {
            let items = notesViewModel.isQuickRecapMode ? Array(anchored.prefix(1)) : anchored
            anchoredApplicationSection(items)
        } else if !content.applicationPoints.isEmpty {
            let items = notesViewModel.isQuickRecapMode ? Array(content.applicationPoints.prefix(1)) : content.applicationPoints
            plainApplicationSection(items)
        }
    }

    private func anchoredApplicationSection(_ insights: [AnchoredInsight]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "hand.raised")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color("FeedbackSuccess"))

                Text("Application Points")
                    .font(Typography.Command.body.weight(.medium))
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Application Points section")
            .ceremonialAppear(isAwakened: isAwakened, delay: 0.75, includeDrift: false)

            // Anchored application cards
            ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                AnchoredApplicationRow(
                    index: index + 1,
                    insight: insight,
                    sermonId: studyGuide.sermonId,
                    delay: 0.77 + Double(index) * 0.06,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
            }
        }
    }

    private func plainApplicationSection(_ items: [String]) -> some View {
        CollapsibleInsightCard(
            icon: "hand.raised",
            iconColor: Color("FeedbackSuccess"),
            title: "Application Points",
            items: items.indexed,
            delay: 0.75,
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
}

// MARK: - Anchored Application Row

private struct AnchoredApplicationRow: View {
    let index: Int
    let insight: AnchoredInsight
    let sermonId: UUID
    let delay: Double
    let isAwakened: Bool
    let onSeek: (TimeInterval) -> Void

    private var engagementService: SermonEngagementService { .shared }

    private var targetId: String {
        SermonEngagement.fingerprint(
            sermonId: sermonId,
            type: .applicationCommit,
            content: insight.title, insight.insight
        )
    }

    private var isCommitted: Bool {
        engagementService.isCommitted(targetId: targetId)
    }

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header with index, title, and commit toggle
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    // Commit toggle
                    Button {
                        HapticService.shared.lightTap()
                        Task {
                            guard let userId = SupabaseManager.shared.currentUser?.id else {
                                ToastService.shared.showError(message: "Sign in to commit to application points")
                                return
                            }
                            await engagementService.toggleCommit(
                                userId: userId,
                                sermonId: sermonId,
                                targetId: targetId
                            )
                            if engagementService.isCommitted(targetId: targetId) {
                                ToastService.shared.showSuccess(message: "Committed to: \(insight.title)")
                            }
                        }
                    } label: {
                        Image(systemName: isCommitted ? "checkmark.circle.fill" : "circle")
                            .font(Typography.Icon.md)
                            .foregroundStyle(isCommitted ? Color("FeedbackSuccess") : Color("TertiaryText"))
                            .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isCommitted ? "Committed: \(insight.title)" : "Commit to: \(insight.title)")

                    Text(insight.title)
                        .font(Typography.Command.body.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Spacer()

                    // Timestamp chip
                    if let timestamp = insight.timestampSeconds {
                        TimestampChip(timestamp: timestamp) {
                            HapticService.shared.lightTap()
                            onSeek(timestamp)
                        }
                    }
                }

                // Insight text
                Text(insight.insight)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    .padding(.leading, Theme.Size.minTapTarget + Theme.Spacing.sm)
                    .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

                // Supporting quote
                if !insight.supportingQuote.isEmpty {
                    HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                        Text("\u{201C}")
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.disabled))
                            .accessibilityHidden(true)

                        Text(insight.supportingQuote)
                            .font(Typography.Scripture.quote)
                            .foregroundStyle(Color("TertiaryText"))
                            .lineSpacing(Typography.Scripture.quoteLineSpacing)
                    }
                    .padding(.leading, Theme.Size.minTapTarget + Theme.Spacing.sm)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Sermon Notes Content") {
    SermonNotesContentPreviewWrapper()
}

private struct SermonNotesContentPreviewWrapper: View {
    @State private var notesViewModel: SermonNotesViewModel

    private let studyGuide: SermonStudyGuide

    init() {
        let sg = SermonStudyGuide(
            sermonId: UUID(),
            content: StudyGuideContent(
                title: "The Power of Grace",
                summary: "This sermon explores the foundational Christian concept of grace as unmerited favor from God, transforming our identity and relationship with Him.",
                keyThemes: ["Grace", "Identity", "Faith", "Transformation"],
                centralThesis: "Grace is not merely God's response to our failure - it is the foundation upon which our entire identity in Christ is built.",
                keyTakeaways: [
                    AnchoredInsight(
                        title: "Grace Transforms Identity",
                        insight: "The believer's identity shifts from performance to position.",
                        supportingQuote: "When you understand grace, you stop trying to earn what you have already received.",
                        timestampSeconds: 154,
                        references: ["John 3:16"]
                    ),
                    AnchoredInsight(
                        title: "Rest in Finished Work",
                        insight: "The cross declares 'It is finished'.",
                        supportingQuote: "We do not work for acceptance; we work from acceptance.",
                        timestampSeconds: 423
                    )
                ],
                theologicalAnnotations: [
                    AnchoredInsight(
                        title: "Justification by Faith",
                        insight: "The sermon connects Paul's doctrine of justification to the believer's daily identity, emphasizing that righteousness is imputed, not achieved.",
                        supportingQuote: "When the speaker says 'you are declared righteous,' he echoes the forensic language of Romans 5:1.",
                        timestampSeconds: 765,
                        references: ["Romans 5:1", "Galatians 2:16"]
                    ),
                    AnchoredInsight(
                        title: "Covenant Faithfulness",
                        insight: "Explores God's hesed love as the foundation for the believer's security.",
                        supportingQuote: "God's covenant love is not contingent on our performance.",
                        timestampSeconds: 1423,
                        references: ["Psalm 136:1"]
                    )
                ],
                notableQuotes: [
                    Quote(
                        text: "Grace is not a license to sin; it's the power to stop wanting to.",
                        timestampSeconds: 522,
                        context: "On the nature of grace"
                    ),
                    Quote(
                        text: "We do not work for acceptance; we work from acceptance. That changes everything.",
                        timestampSeconds: 1245,
                        context: "On identity in Christ"
                    )
                ],
                bibleReferencesMentioned: [
                    SermonVerseReference(reference: "John 3:16", bookId: 43, chapter: 3, verseStart: 16, isMentioned: true),
                    SermonVerseReference(reference: "Ephesians 2:8-9", bookId: 49, chapter: 2, verseStart: 8, verseEnd: 9, isMentioned: true)
                ],
                bibleReferencesSuggested: [
                    SermonVerseReference(
                        reference: "Romans 5:1",
                        bookId: 45, chapter: 5, verseStart: 1,
                        isMentioned: false,
                        rationale: "Justification by faith leads to peace with God.",
                        verificationStatus: .verified,
                        relation: .supports
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
        self.studyGuide = sg
        self._notesViewModel = State(initialValue: SermonNotesViewModel(studyGuide: sg))
    }

    var body: some View {
        ScrollView {
            SermonNotesContent(
                studyGuide: studyGuide,
                notesViewModel: notesViewModel,
                isAwakened: true
            ) { timestamp in
                print("Seek to \(timestamp)")
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Color("AppBackground"))
    }
}
