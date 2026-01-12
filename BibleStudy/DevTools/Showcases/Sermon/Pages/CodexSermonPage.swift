import SwiftUI

// MARK: - The Codex Sermon Page

/// Manuscript-inspired sermon layout with expandable page-like sections.
/// Emphasizes transcript reading alongside audio with scholarly annotations.
struct CodexSermonPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAwakened = false
    @State private var isPlaying = false
    @State private var playbackSpeed: Double = 1.0
    @State private var currentProgress: Double = SermonShowcaseMockData.progress
    @State private var expandedSections: Set<CodexSection> = [.transcript]
    @State private var showSpeedPicker = false
    @State private var showAddNote = false

    enum CodexSection: String, CaseIterable {
        case transcript = "Transcript"
        case insights = "Insights"
        case references = "References"
        case studyGuide = "Study Guide"
        case notes = "Notes"
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    sermonHeader
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    audioPlayerSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    codexSections
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl * 2)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            // Parchment warmth from top-left
            RadialGradient(
                colors: [
                    Color("AccentBronze").opacity(Theme.Opacity.subtle / 3),
                    Color.clear
                ],
                center: .init(x: 0.2, y: 0.15),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Sermon Header

    private var sermonHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Status badge
            HStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(Color("AccentBronze"))
                    .frame(width: 6, height: 6)
                Text(SermonShowcaseMockData.status.uppercased())
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.referenceTracking)
                    .foregroundStyle(Color("AccentBronze"))
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            // Title
            Text(SermonShowcaseMockData.sermonTitle)
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.15), value: isAwakened)

            // Metadata row
            HStack(spacing: Theme.Spacing.md) {
                Label(SermonShowcaseMockData.speakerName, systemImage: "person.fill")
                Label(SermonShowcaseMockData.sermonDate, systemImage: "calendar")
            }
            .font(Typography.Command.body)
            .foregroundStyle(Color("AppTextSecondary"))
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            // Church
            Text(SermonShowcaseMockData.churchName)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.25), value: isAwakened)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Audio Player

    private var audioPlayerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Waveform scrubber
            CodexWaveformScrubber(progress: $currentProgress)
                .frame(height: 48)

            // Time labels
            HStack {
                Text(SermonShowcaseMockData.formattedCurrentTime)
                    .font(Typography.Command.caption.monospacedDigit())
                    .foregroundStyle(Color("AppTextSecondary"))

                Spacer()

                Text(SermonShowcaseMockData.formattedRemaining)
                    .font(Typography.Command.caption.monospacedDigit())
                    .foregroundStyle(Color("TertiaryText"))
            }

            // Playback controls
            HStack(spacing: Theme.Spacing.xl) {
                // Speed control
                Button {
                    showSpeedPicker.toggle()
                } label: {
                    Text("\(playbackSpeed, specifier: "%.1f")x")
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(width: 44, height: 44)
                }

                // Skip back
                Button {
                    // Skip back 15s
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(width: 44, height: 44)
                }

                // Play/Pause
                Button {
                    isPlaying.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color("AccentBronze"))
                            .frame(width: 64, height: 64)

                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(Typography.Icon.xl)
                            .foregroundStyle(colorScheme == .dark ? Color("AppBackground") : .white)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                }

                // Skip forward
                Button {
                    // Skip forward 15s
                } label: {
                    Image(systemName: "goforward.15")
                        .font(Typography.Icon.lg)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(width: 44, height: 44)
                }

                // Bookmark
                Button {
                    // Add bookmark
                } label: {
                    Image(systemName: "bookmark")
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
    }

    // MARK: - Codex Sections

    private var codexSections: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(Array(CodexSection.allCases.enumerated()), id: \.element) { index, section in
                CodexExpandableSection(
                    section: section,
                    isExpanded: expandedSections.contains(section),
                    onTap: {
                        withAnimation(Theme.Animation.settle) {
                            if expandedSections.contains(section) {
                                expandedSections.remove(section)
                            } else {
                                expandedSections.insert(section)
                            }
                        }
                    },
                    content: {
                        sectionContent(for: section)
                    }
                )
                .opacity(isAwakened ? 1 : 0)
                .offset(y: isAwakened ? 0 : 10)
                .animation(Theme.Animation.slowFade.delay(0.4 + Double(index) * 0.08), value: isAwakened)
            }
        }
    }

    @ViewBuilder
    private func sectionContent(for section: CodexSection) -> some View {
        switch section {
        case .transcript:
            transcriptContent
        case .insights:
            insightsContent
        case .references:
            referencesContent
        case .studyGuide:
            studyGuideContent
        case .notes:
            notesContent
        }
    }

    // MARK: - Transcript Content

    private var transcriptContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ForEach(Array(SermonShowcaseMockData.transcriptSegments.enumerated()), id: \.element.id) { index, segment in
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Timestamp
                    Text(segment.timestamp)
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(Color("TertiaryText"))

                    // Text with drop cap for first segment
                    if index == 0 {
                        CodexDropCapText(text: segment.text)
                    } else {
                        Text(segment.text)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    }
                }
                .padding(.vertical, Theme.Spacing.sm)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Seek to timestamp
                }

                if index < SermonShowcaseMockData.transcriptSegments.count - 1 {
                    Rectangle()
                        .fill(Color("AppDivider"))
                        .frame(height: Theme.Stroke.hairline)
                }
            }
        }
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // AI badge
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.xxs)
                Text("AI-GENERATED INSIGHTS")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
            }
            .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))

            // Summary
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Summary")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextSecondary"))

                Text(SermonShowcaseMockData.aiSummary)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
            }

            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Key Themes
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Key Themes")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextSecondary"))

                ForEach(SermonShowcaseMockData.aiThemes) { theme in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: "diamond.fill")
                            .font(Typography.Icon.xxxs)
                            .foregroundStyle(Color("AccentBronze"))
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.theme)
                                .font(Typography.Command.body)
                                .foregroundStyle(Color("AppTextPrimary"))

                            Text(theme.description)
                                .font(Typography.Command.caption)
                                .foregroundStyle(Color("TertiaryText"))
                        }
                    }
                }
            }

            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Outline
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Outline")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextSecondary"))

                ForEach(SermonShowcaseMockData.aiOutline) { section in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Text(section.title)
                                .font(Typography.Command.body.weight(.medium))
                                .foregroundStyle(Color("AppTextPrimary"))

                            Spacer()

                            Text(section.timestamp)
                                .font(Typography.Command.caption.monospacedDigit())
                                .foregroundStyle(Color("TertiaryText"))
                        }

                        ForEach(section.points, id: \.self) { point in
                            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                                Text("•")
                                    .foregroundStyle(Color("TertiaryText"))
                                Text(point)
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .padding(.leading, Theme.Spacing.md)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
        }
    }

    // MARK: - References Content

    private var referencesContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Primary reference (larger)
            if let primary = SermonShowcaseMockData.scriptureReferences.first(where: { $0.isPrimary }) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("PRIMARY PASSAGE")
                            .font(Typography.Command.meta)
                            .tracking(Typography.Editorial.labelTracking)
                            .foregroundStyle(Color("TertiaryText"))

                        if primary.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(Typography.Icon.xxs)
                                .foregroundStyle(Color("FeedbackSuccess"))
                        }
                    }

                    Text(primary.reference)
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(primary.text)
                        .font(Typography.Scripture.quote)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineSpacing(Typography.Scripture.quoteLineSpacing)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                )

                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)
                    .padding(.vertical, Theme.Spacing.sm)
            }

            // Additional references
            Text("ALSO REFERENCED")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            ForEach(SermonShowcaseMockData.scriptureReferences.filter { !$0.isPrimary }) { ref in
                Button {
                    // Open verse
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(ref.reference)
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                if ref.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(Typography.Icon.xxxs)
                                        .foregroundStyle(Color("FeedbackSuccess"))
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(Typography.Icon.xxxs)
                                        .foregroundStyle(Color("AppAccentAction"))
                                }
                            }

                            Text(ref.text)
                                .font(Typography.Command.caption)
                                .foregroundStyle(Color("TertiaryText"))
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }

            // Cross-references section
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)
                .padding(.vertical, Theme.Spacing.sm)

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.xxs)
                Text("AI-SUGGESTED CONNECTIONS")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
            }
            .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))

            ForEach(SermonShowcaseMockData.crossReferences) { ref in
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Text("→")
                        .foregroundStyle(Color("TertiaryText"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ref.reference)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextPrimary"))

                        Text(ref.connection)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                }
            }
        }
    }

    // MARK: - Study Guide Content

    private var studyGuideContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Key Takeaways
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Key Takeaways")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextSecondary"))

                ForEach(Array(SermonShowcaseMockData.keyTakeaways.enumerated()), id: \.offset) { index, takeaway in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Text("\(index + 1).")
                            .font(Typography.Command.body.monospacedDigit())
                            .foregroundStyle(Color("AccentBronze"))
                            .frame(width: 20, alignment: .trailing)

                        Text(takeaway)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    }
                }
            }

            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Discussion Questions
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Discussion Questions")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextSecondary"))

                ForEach(SermonShowcaseMockData.discussionQuestions) { question in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(question.type.rawValue.uppercased())
                            .font(Typography.Command.meta)
                            .tracking(Typography.Editorial.referenceTracking)
                            .foregroundStyle(questionTypeColor(question.type))

                        Text(question.question)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }

            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)

            // Reflection Prompts
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Reflection Prompts")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextSecondary"))

                ForEach(SermonShowcaseMockData.reflectionPrompts, id: \.self) { prompt in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: "circle")
                            .font(Typography.Icon.xxxs)
                            .foregroundStyle(Color("TertiaryText"))
                            .padding(.top, 6)

                        Text(prompt)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    }
                }
            }

            // Generate Full Study Guide CTA
            Button {
                // Generate study guide
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(Typography.Icon.md)

                    Text("Generate Full Study Guide")
                        .font(Typography.Command.cta)
                }
                .foregroundStyle(Color("AccentBronze"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(Color("AccentBronze"), lineWidth: Theme.Stroke.control)
                )
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    // MARK: - Notes Content

    private var notesContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Existing notes
            if !SermonShowcaseMockData.userNotes.isEmpty {
                ForEach(SermonShowcaseMockData.userNotes) { note in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Text(note.timestamp)
                                .font(Typography.Command.meta.monospacedDigit())
                                .foregroundStyle(Color("AccentBronze"))

                            Spacer()

                            Button {
                                // Edit note
                            } label: {
                                Image(systemName: "pencil")
                                    .font(Typography.Icon.sm)
                                    .foregroundStyle(Color("TertiaryText"))
                            }
                        }

                        Text(note.text)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    }
                    .padding(Theme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.input)
                            .fill(Color("AppSurface"))
                    )
                }

                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)
                    .padding(.vertical, Theme.Spacing.xs)
            }

            // Add note button
            Button {
                showAddNote = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(Typography.Icon.md)

                    Text("Add Note at Current Time")
                        .font(Typography.Command.body)
                }
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                        .fill(Color("AppSurface").opacity(0.5))
                )
            }
        }
    }

    // MARK: - Helpers

    private func questionTypeColor(_ type: DiscussionQuestion.QuestionType) -> Color {
        switch type {
        case .comprehension:
            return Color("FeedbackInfo")
        case .interpretation:
            return Color("AppAccentAction")
        case .application:
            return Color("FeedbackSuccess")
        case .reflection:
            return Color("AccentBronze")
        }
    }
}

// MARK: - Codex Waveform Scrubber

private struct CodexWaveformScrubber: View {
    @Binding var progress: Double

    private let barCount = 60
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bars
                HStack(spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { index in
                        let height = waveformHeight(for: index)
                        let isPlayed = Double(index) / Double(barCount) <= progress

                        RoundedRectangle(cornerRadius: 1)
                            .fill(isPlayed ? Color("AccentBronze") : Color("AppDivider"))
                            .frame(width: 3, height: height)
                    }
                }
                .frame(maxWidth: .infinity)

                // Playhead
                Rectangle()
                    .fill(Color("AccentBronze"))
                    .frame(width: 2, height: 48)
                    .offset(x: geometry.size.width * progress - 1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                        progress = newProgress
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }

    private func waveformHeight(for index: Int) -> CGFloat {
        // Generate pseudo-random wave pattern
        let seed = sin(Double(index) * 0.3) * cos(Double(index) * 0.5)
        let normalized = (seed + 1) / 2
        return 12 + CGFloat(normalized) * 30
    }
}

// MARK: - Codex Drop Cap Text

private struct CodexDropCapText: View {
    let text: String

    var body: some View {
        let firstLetter = String(text.prefix(1))
        let remainingText = String(text.dropFirst())

        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Drop cap
            Text(firstLetter)
                .font(Typography.Decorative.dropCapCompact)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color("AccentBronze"),
                            Color("AccentBronze").opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 48, alignment: .center)
                .offset(y: -4)

            // Remaining text
            Text(remainingText)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineSpacing(Typography.Scripture.bodyLineSpacing)
        }
    }
}

// MARK: - Codex Expandable Section

private struct CodexExpandableSection<Content: View>: View {
    let section: CodexSermonPage.CodexSection
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    Image(systemName: sectionIcon)
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color("AccentBronze"))
                        .frame(width: 24)

                    Text(section.rawValue)
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.Icon.sm.weight(.medium))
                        .foregroundStyle(Color("TertiaryText"))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(Theme.Spacing.lg)
            }

            // Content
            if isExpanded {
                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)
                    .padding(.horizontal, Theme.Spacing.lg)

                content()
                    .padding(Theme.Spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    isExpanded
                        ? Color("AccentBronze").opacity(colorScheme == .dark ? 0.3 : 0.2)
                        : Color("AppDivider"),
                    lineWidth: Theme.Stroke.hairline
                )
        )
    }

    private var sectionIcon: String {
        switch section {
        case .transcript:
            return "doc.text"
        case .insights:
            return "sparkles"
        case .references:
            return "book.closed"
        case .studyGuide:
            return "list.bullet.rectangle"
        case .notes:
            return "note.text"
        }
    }
}

#Preview {
    NavigationStack {
        CodexSermonPage()
    }
    .preferredColorScheme(.dark)
}
