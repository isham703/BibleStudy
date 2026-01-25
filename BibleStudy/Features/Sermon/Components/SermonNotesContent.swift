//
//  SermonNotesContent.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Orchestration view for the Notes tab content.
//  Composes all study guide sections with proper staggered animations.
//
//  Section Order:
//  1. Summary Card (enhanced with Central Thesis)
//  2. Key Takeaways (anchored insights)
//  3. Notable Quotes (v2 - decorative marginalia styling)
//  4. Scripture References (mentioned + suggested)
//  5. Theological Depth (v2 - collapsible AI-suggested annotations)
//  6. Discussion Questions (existing)
//  7. Reflection Prompts (existing)
//  8. Application Points (enhanced with anchored version)
//

import SwiftUI

// MARK: - Sermon Notes Content

struct SermonNotesContent: View {
    let studyGuide: SermonStudyGuide
    let isAwakened: Bool
    let onSeek: (TimeInterval) -> Void

    // MARK: - Content Accessors

    private var content: StudyGuideContent { studyGuide.content }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // 1. Summary Card (enhanced with Central Thesis + Key Themes)
            summarySection

            // 2. Key Takeaways (anchored insights with audio sync)
            if let takeaways = content.keyTakeaways {
                KeyTakeawaysSection(
                    takeaways: takeaways,
                    baseDelay: 0.3,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
            }

            // 3. Notable Quotes (v2 - decorative marginalia styling)
            if let quotes = content.notableQuotes, !quotes.isEmpty {
                NotableQuotesSection(
                    quotes: quotes,
                    baseDelay: 0.4,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
            }

            // 4. Scripture References (mentioned + suggested)
            SermonBibleReferencesCard(
                mentionedRefs: content.bibleReferencesMentioned,
                suggestedRefs: content.bibleReferencesSuggested,
                delay: 0.5,
                isAwakened: isAwakened
            )

            // 5. Theological Depth (v2 - collapsible AI-suggested annotations)
            if let annotations = content.theologicalAnnotations, !annotations.isEmpty {
                TheologicalAnnotationsSection(
                    annotations: annotations,
                    baseDelay: 0.55,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
            }

            // 6. Discussion Questions
            if !content.discussionQuestions.isEmpty {
                CollapsibleInsightCard(
                    icon: "bubble.left.and.bubble.right",
                    iconColor: Color("FeedbackInfo"),
                    title: "Discussion Questions",
                    items: content.discussionQuestions,
                    delay: 0.65,
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

            // 7. Reflection Prompts
            if !content.reflectionPrompts.isEmpty {
                CollapsibleInsightCard(
                    icon: "heart.text.square",
                    iconColor: Color("AccentBronze"),
                    title: "Reflection Prompts",
                    items: content.reflectionPrompts.indexed,
                    delay: 0.7,
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

            // 8. Application Points (enhanced with anchored version)
            applicationSection
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
            anchoredApplicationSection(anchored)
        } else if !content.applicationPoints.isEmpty {
            plainApplicationSection
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
            .ceremonialAppear(isAwakened: isAwakened, delay: 0.75, includeDrift: false)

            // Anchored application cards
            ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                AnchoredApplicationRow(
                    index: index + 1,
                    insight: insight,
                    delay: 0.77 + Double(index) * 0.06,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
            }
        }
    }

    private var plainApplicationSection: some View {
        CollapsibleInsightCard(
            icon: "hand.raised",
            iconColor: Color("FeedbackSuccess"),
            title: "Application Points",
            items: content.applicationPoints.indexed,
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
    let delay: Double
    let isAwakened: Bool
    let onSeek: (TimeInterval) -> Void

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header with index and title
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Text("\(index)")
                        .font(Typography.Command.label.weight(.semibold))
                        .foregroundStyle(Color("FeedbackSuccess"))
                        .frame(width: 20, alignment: .leading)

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
                    .padding(.leading, 28) // Align with title
                    .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

                // Supporting quote
                if !insight.supportingQuote.isEmpty {
                    HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                        Text("\u{201C}")
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.disabled))

                        Text(insight.supportingQuote)
                            .font(Typography.Scripture.quote)
                            .foregroundStyle(Color("TertiaryText"))
                            .lineSpacing(Typography.Scripture.quoteLineSpacing)
                    }
                    .padding(.leading, 28)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Sermon Notes Content") {
    ScrollView {
        SermonNotesContent(
            studyGuide: SermonStudyGuide(
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
            ),
            isAwakened: true
        ) { timestamp in
            print("Seek to \(timestamp)")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}
