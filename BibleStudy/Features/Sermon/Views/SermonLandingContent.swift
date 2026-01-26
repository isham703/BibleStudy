//
//  SermonLandingContent.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Variant B: Reflection-First Sermon Home.
//  The sermon is a place of formation, not just content.
//
//  Hub landing page with thesis pull quote, dual CTAs,
//  themes, progress strip, three door cards, and engagement-gated
//  "Continue Studying" shortcuts.
//  No floating bottom bar, no search, no filter — only quiet contemplation.
//

import SwiftUI

// MARK: - Sermon Landing Content

struct SermonLandingContent: View {
    @Bindable var flowState: SermonFlowState
    let viewModel: SermonViewingViewModel
    let notesViewModel: SermonNotesViewModel
    let bookmarks: [SermonBookmark]
    let isAwakened: Bool
    let onQuickCapture: () -> Void

    private let engagementService = SermonEngagementService.shared

    // MARK: - Computed

    private var sermon: Sermon? {
        flowState.currentSermon
    }

    private var studyGuide: SermonStudyGuide? {
        flowState.currentStudyGuide
    }

    private var isSampleSermon: Bool {
        flowState.isViewingSample
    }

    private var hasAudio: Bool {
        !isSampleSermon
    }

    private var hasListeningProgress: Bool {
        hasAudio && viewModel.currentTime > 0
    }

    private var favoritesCount: Int {
        engagementService.engagements.filter {
            $0.engagementType == .favoriteInsight || $0.engagementType == .favoriteQuote
        }.count
    }

    private var journalResponseCount: Int {
        engagementService.engagements.filter {
            $0.engagementType == .journalEntry
        }.count
    }

    private var bookmarkCount: Int {
        bookmarks.count
    }

    private var applicationCommitCount: Int {
        engagementService.engagements.filter { $0.engagementType == .applicationCommit }.count
    }

    private var hasEngagementData: Bool {
        favoritesCount > 0 || bookmarkCount > 0 || journalResponseCount > 0 || applicationCommitCount > 0
    }

    private var journalBadgeText: String? {
        let parts: [String] = [
            bookmarkCount > 0 ? "\(bookmarkCount) note\(bookmarkCount == 1 ? "" : "s")" : nil,
            journalResponseCount > 0 ? "\(journalResponseCount) response\(journalResponseCount == 1 ? "" : "s")" : nil
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var listenReadSubtext: String {
        var parts: [String] = []
        if hasListeningProgress {
            let formatted = TimestampFormatter.format(viewModel.currentTime)
            parts.append("Resume at \(formatted)")
        }
        if flowState.currentTranscript != nil {
            parts.append("Transcript ready")
        }
        return parts.isEmpty ? "Audio player and transcript" : parts.joined(separator: " · ")
    }

    private var studyGuideSectionCount: Int {
        notesViewModel.jumpBarSections.count
    }

    private var studyGuideSubtext: String {
        let parts: [String] = [
            favoritesCount > 0 ? "\(favoritesCount) saved" : nil,
            applicationCommitCount > 0 ? "\(applicationCommitCount) committed" : nil
        ].compactMap { $0 }

        if !parts.isEmpty {
            return parts.joined(separator: " · ")
        }

        let sectionLabel = "\(studyGuideSectionCount) section\(studyGuideSectionCount == 1 ? "" : "s")"
        return "Overview · \(sectionLabel)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Hero section
            heroSection
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.15)

            // Central thesis pull quote
            if let thesis = studyGuide?.content.centralThesis, !thesis.isEmpty {
                thesisPullQuote(thesis)
                    .ceremonialAppear(isAwakened: isAwakened, delay: 0.25)
            }

            // Dual CTAs
            dualCTAs
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.35)

            // Themes
            if let themes = studyGuide?.content.keyThemes, !themes.isEmpty {
                themesSection(themes)
                    .ceremonialAppear(isAwakened: isAwakened, delay: 0.45)
            }

            // Three door cards
            doorCards

            // Continue Studying (engagement-gated shortcuts)
            if studyGuide != nil && hasEngagementData {
                continueStudyingSection
                    .ceremonialAppear(isAwakened: isAwakened, delay: 0.70)
            }
        }
    }

    // MARK: - Hero Section

    /// Prefer study guide title (AI-generated, e.g. "A Double Woe") over the
    /// model's displayTitle which falls back to "Sermon — Jan 25, 2026".
    private var heroTitle: String {
        if let guideTitle = studyGuide?.content.title,
           !guideTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return guideTitle
        }
        return sermon?.displayTitle ?? "Sermon"
    }

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(heroTitle)
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)

            HStack(spacing: Theme.Spacing.sm) {
                if let speaker = sermon?.speakerName {
                    Text(speaker)
                }

                if sermon?.speakerName != nil && sermon?.recordedAt != nil {
                    Text("·")
                }

                if let date = sermon?.recordedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                }

                if let duration = sermon?.formattedDuration {
                    Text("·")
                    Text(duration)
                }
            }
            .font(Typography.Command.caption)
            .foregroundStyle(Color("TertiaryText"))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Thesis Pull Quote

    private func thesisPullQuote(_ thesis: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Bronze vertical rule
            RoundedRectangle(cornerRadius: 1)
                .fill(Color("AccentBronze"))
                .frame(width: Theme.Stroke.control)

            Text(thesis)
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineSpacing(Typography.Scripture.bodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Dual CTAs

    private var dualCTAs: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Quick Note (outlined)
            Button(action: onQuickCapture) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "pencil.line")
                        .font(Typography.Icon.sm)
                    Text("Quick Note")
                        .font(Typography.Command.cta)
                }
                .foregroundStyle(Color("AccentBronze"))
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.Size.minTapTarget)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Color("AccentBronze"), lineWidth: Theme.Stroke.control)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quick Note")

            // Play / Resume (filled) — hidden for sample sermon
            if hasAudio {
                NavigationLink(value: SermonDestination.listenRead(autoPlay: true)) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "play.fill")
                            .font(Typography.Icon.sm)
                        Text(playButtonLabel)
                            .font(Typography.Command.cta.monospacedDigit())
                    }
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .fill(Color("AppAccentAction"))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(playButtonLabel)
            }
        }
    }

    private var playButtonLabel: String {
        if hasListeningProgress {
            let formatted = TimestampFormatter.format(viewModel.currentTime)
            return "Resume \(formatted)"
        }
        return "Play"
    }

    // MARK: - Themes Section

    private func themesSection(_ themes: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("THEMES")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            SermonFlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(themes, id: \.self) { theme in
                    Text(theme)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AccentBronze"))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                .stroke(Color("AccentBronze").opacity(0.3), lineWidth: Theme.Stroke.hairline)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Continue Studying Section

    private var continueStudyingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("CONTINUE STUDYING")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            VStack(spacing: 0) {
                continueStudyingRow(
                    icon: "bubble.left.and.bubble.right",
                    text: "Discussion questions",
                    destination: .studyGuide(scrollTo: .discussionQuestions)
                )

                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)
                    .padding(.horizontal, Theme.Spacing.md)

                continueStudyingRow(
                    icon: "hand.raised",
                    text: "Application points",
                    destination: .studyGuide(scrollTo: .applicationPoints)
                )

                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)
                    .padding(.horizontal, Theme.Spacing.md)

                continueStudyingRow(
                    icon: "quote.opening",
                    text: "Notable quotes",
                    destination: .studyGuide(scrollTo: .notableQuotes)
                )
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
            )
        }
    }

    private func continueStudyingRow(icon: String, text: String, destination: SermonDestination) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AccentBronze"))
                    .frame(width: 24)

                Text(text)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Door Cards

    private var doorCards: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Door 1: My Journal (promoted to #1)
            doorCard(
                icon: "book.closed",
                accentColor: Color("FeedbackSuccess"),
                title: "My Journal",
                subtext: journalBadgeText ?? "No entries yet",
                badge: journalBadgeText,
                destination: .journal
            )
            .ceremonialAppear(isAwakened: isAwakened, delay: 0.55)

            // Door 2: Listen & Read
            doorCard(
                icon: "headphones",
                accentColor: Color("AppAccentAction"),
                title: "Listen & Read",
                subtext: listenReadSubtext,
                badge: viewModel.isPlaying ? "Listening" : nil,
                destination: .listenRead()
            )
            .ceremonialAppear(isAwakened: isAwakened, delay: 0.60)

            // Door 3: Study Guide
            studyGuideDoorCard
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.65)
        }
    }

    private func doorCard(
        icon: String,
        accentColor: Color,
        title: String,
        subtext: String,
        badge: String?,
        destination: SermonDestination
    ) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon in colored circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(Theme.Opacity.subtle))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(Typography.Icon.base)
                        .foregroundStyle(accentColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(subtext)
                        .font(Typography.Command.caption.monospacedDigit())
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(1)
                }

                Spacer()

                // Badge (subtle status indicator)
                if let badge {
                    Text(badge)
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Study Guide Door (Special States)

    @ViewBuilder
    private var studyGuideDoorCard: some View {
        if studyGuide != nil {
            doorCard(
                icon: "text.book.closed",
                accentColor: Color("AccentBronze"),
                title: "Study Guide",
                subtext: studyGuideSubtext,
                badge: nil,
                destination: .studyGuide()
            )
        } else if flowState.isRetryingStudyGuide {
            // Generating state
            studyGuideDoorGenerating
        } else {
            // Failed/unavailable state
            studyGuideDoorFailed
        }
    }

    private var studyGuideDoorGenerating: some View {
        NavigationLink(value: SermonDestination.studyGuide()) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                        .frame(width: 40, height: 40)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentBronze")))
                        .scaleEffect(0.8)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Study Guide")
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Generating...")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var studyGuideDoorFailed: some View {
        NavigationLink(value: SermonDestination.studyGuide()) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color("FeedbackWarning").opacity(Theme.Opacity.subtle))
                        .frame(width: 40, height: 40)

                    Image(systemName: "exclamationmark.triangle")
                        .font(Typography.Icon.base)
                        .foregroundStyle(Color("FeedbackWarning"))
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Study Guide")
                        .font(Typography.Command.headline)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Unavailable — tap to retry")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("FeedbackWarning"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var flowState = SermonFlowState()

    NavigationStack {
        ScrollView(showsIndicators: false) {
            SermonLandingContent(
                flowState: flowState,
                viewModel: SermonViewingViewModel(),
                notesViewModel: SermonNotesViewModel(),
                bookmarks: [],
                isAwakened: true,
                onQuickCapture: {}
            )
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
        }
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
            content: "So today we're going to be talking about grace.",
            wordTimestamps: []
        )
        flowState.currentStudyGuide = SermonStudyGuide(
            sermonId: flowState.currentSermon!.id,
            content: StudyGuideContent(
                title: "The Power of Grace",
                summary: "This sermon explores grace as unmerited favor from God.",
                keyThemes: ["Grace", "Identity", "Faith"],
                centralThesis: "Grace is not merely God's response to our failure - it is the foundation upon which our entire identity in Christ is built.",
                keyTakeaways: [],
                outline: [],
                bibleReferencesMentioned: [],
                bibleReferencesSuggested: [],
                discussionQuestions: [
                    StudyQuestion(question: "How does grace change your relationship with God?", type: .application)
                ],
                reflectionPrompts: [],
                applicationPoints: [],
                anchoredApplicationPoints: []
            )
        )
    }
}
