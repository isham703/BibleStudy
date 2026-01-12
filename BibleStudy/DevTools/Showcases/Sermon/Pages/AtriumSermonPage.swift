import SwiftUI

// MARK: - The Atrium Sermon Page

/// Open and spacious sermon layout with audio-first design.
/// Generous breathing room with floating cards and calm surfaces.
struct AtriumSermonPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAwakened = false
    @State private var isPlaying = false
    @State private var playbackSpeed: Double = 1.0
    @State private var currentProgress: Double = SermonShowcaseMockData.progress
    @State private var selectedTab: AtriumTab = .listen
    @State private var showTranscript = false
    @State private var showSpeedMenu = false

    enum AtriumTab: String, CaseIterable {
        case listen = "Listen"
        case study = "Study"
        case notes = "Notes"
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                // Fixed header with audio
                audioHeader
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                // Tab selector
                tabSelector
                    .padding(.top, Theme.Spacing.xl)
                    .padding(.horizontal, Theme.Spacing.lg)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.lg) {
                        switch selectedTab {
                        case .listen:
                            listenContent
                        case .study:
                            studyContent
                        case .notes:
                            notesContent
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.xl)
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

            // Soft central glow
            RadialGradient(
                colors: [
                    Color("AppAccentAction").opacity(Theme.Opacity.subtle / 4),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.25),
                startRadius: 0,
                endRadius: 450
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Audio Header

    private var audioHeader: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Metadata
            VStack(spacing: Theme.Spacing.xs) {
                Text(SermonShowcaseMockData.sermonDate.uppercased())
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.sectionTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Text(SermonShowcaseMockData.sermonTitle)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)

                Text(SermonShowcaseMockData.speakerName)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)

            // Circular progress player
            ZStack {
                // Track
                Circle()
                    .stroke(Color("AppDivider"), lineWidth: 4)
                    .frame(width: 160, height: 160)

                // Progress
                Circle()
                    .trim(from: 0, to: currentProgress)
                    .stroke(
                        Color("AppAccentAction"),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                // Play button
                Button {
                    isPlaying.toggle()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color("AppSurface"))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                            )

                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(Color("AppAccentAction"))
                            .offset(x: isPlaying ? 0 : 4)
                    }
                }
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            // Time and controls
            VStack(spacing: Theme.Spacing.md) {
                // Time display
                HStack(spacing: Theme.Spacing.lg) {
                    Text(SermonShowcaseMockData.formattedCurrentTime)
                        .font(Typography.Command.body.monospacedDigit())
                        .foregroundStyle(Color("AppTextPrimary"))

                    Rectangle()
                        .fill(Color("AppDivider"))
                        .frame(width: 1, height: 16)

                    Text(SermonShowcaseMockData.formattedDuration)
                        .font(Typography.Command.body.monospacedDigit())
                        .foregroundStyle(Color("TertiaryText"))
                }

                // Control row
                HStack(spacing: Theme.Spacing.xxl) {
                    // Speed
                    Button {
                        showSpeedMenu.toggle()
                    } label: {
                        Text("\(playbackSpeed, specifier: "%.1f")×")
                            .font(Typography.Command.label)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                    .fill(Color("AppSurface"))
                            )
                    }

                    // Skip back
                    Button {
                        // Skip back 15s
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(Typography.Icon.lg)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }

                    // Skip forward
                    Button {
                        // Skip forward 15s
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(Typography.Icon.lg)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }

                    // Bookmark
                    Button {
                        // Add bookmark
                    } label: {
                        Image(systemName: "bookmark")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AtriumTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(Theme.Animation.settle) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(tab.rawValue)
                            .font(Typography.Command.label)
                            .foregroundStyle(
                                selectedTab == tab
                                    ? Color("AppTextPrimary")
                                    : Color("TertiaryText")
                            )

                        Rectangle()
                            .fill(
                                selectedTab == tab
                                    ? Color("AppAccentAction")
                                    : Color.clear
                            )
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.bottom, Theme.Spacing.xs)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isAwakened)
    }

    // MARK: - Listen Content

    private var listenContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Transcript toggle card
            AtriumCard(delay: 0.4, isAwakened: isAwakened) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "doc.text")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AppAccentAction"))

                        Text("Transcript")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))

                        Spacer()

                        Toggle("", isOn: $showTranscript)
                            .labelsHidden()
                            .tint(Color("AppAccentAction"))
                    }

                    if showTranscript {
                        Rectangle()
                            .fill(Color("AppDivider"))
                            .frame(height: Theme.Stroke.hairline)

                        // Current segment
                        let currentSegment = SermonShowcaseMockData.transcriptSegments[2]

                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(currentSegment.timestamp)
                                .font(Typography.Command.meta.monospacedDigit())
                                .foregroundStyle(Color("AppAccentAction"))

                            Text(currentSegment.text)
                                .font(Typography.Scripture.body)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineSpacing(Typography.Scripture.bodyLineSpacing)
                        }

                        Button {
                            // View full transcript
                        } label: {
                            Text("View Full Transcript")
                                .font(Typography.Command.label)
                                .foregroundStyle(Color("AppAccentAction"))
                        }
                        .padding(.top, Theme.Spacing.sm)
                    }
                }
            }

            // Key takeaways card
            AtriumCard(delay: 0.5, isAwakened: isAwakened) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "lightbulb")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AccentBronze"))

                        Text("Key Takeaways")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }

                    ForEach(Array(SermonShowcaseMockData.keyTakeaways.prefix(3).enumerated()), id: \.offset) { index, takeaway in
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            Image(systemName: "diamond.fill")
                                .font(Typography.Icon.xxxs)
                                .foregroundStyle(Color("AccentBronze"))
                                .padding(.top, 6)

                            Text(takeaway)
                                .font(Typography.Command.body)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .lineSpacing(Typography.Command.bodyLineSpacing)
                        }
                    }
                }
            }

            // Scripture references card
            AtriumCard(delay: 0.6, isAwakened: isAwakened) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "book.closed")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("FeedbackInfo"))

                        Text("Scripture References")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }

                    // Reference chips in flow layout
                    FlowLayout(spacing: Theme.Spacing.sm) {
                        ForEach(SermonShowcaseMockData.scriptureReferences) { ref in
                            Button {
                                // Open verse
                            } label: {
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text(ref.reference)
                                        .font(Typography.Command.label)
                                        .foregroundStyle(Color("AppTextPrimary"))

                                    if ref.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(Typography.Icon.xxxs)
                                            .foregroundStyle(Color("FeedbackSuccess"))
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                        .fill(Color("FeedbackInfo").opacity(Theme.Opacity.overlay))
                                )
                            }
                        }
                    }
                }
            }

            // Actions row
            HStack(spacing: Theme.Spacing.md) {
                AtriumActionButton(
                    icon: "square.and.arrow.up",
                    label: "Share",
                    delay: 0.7,
                    isAwakened: isAwakened
                )

                AtriumActionButton(
                    icon: "checkmark.circle",
                    label: "Complete",
                    delay: 0.75,
                    isAwakened: isAwakened
                )

                AtriumActionButton(
                    icon: "ellipsis",
                    label: "More",
                    delay: 0.8,
                    isAwakened: isAwakened
                )
            }
        }
    }

    // MARK: - Study Content

    private var studyContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // AI Insights
            AtriumCard(delay: 0.4, isAwakened: isAwakened) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AppAccentAction"))

                        Text("AI Insights")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))

                        Spacer()

                        Text("AI-GENERATED")
                            .font(Typography.Command.meta)
                            .tracking(Typography.Editorial.referenceTracking)
                            .foregroundStyle(Color("TertiaryText"))
                    }

                    Text(SermonShowcaseMockData.aiSummary)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineSpacing(Typography.Scripture.bodyLineSpacing)

                    Rectangle()
                        .fill(Color("AppDivider"))
                        .frame(height: Theme.Stroke.hairline)

                    // Themes
                    Text("THEMES")
                        .font(Typography.Command.meta)
                        .tracking(Typography.Editorial.labelTracking)
                        .foregroundStyle(Color("TertiaryText"))

                    FlowLayout(spacing: Theme.Spacing.sm) {
                        ForEach(SermonShowcaseMockData.aiThemes) { theme in
                            Text(theme.theme)
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

            // Discussion Questions
            AtriumCard(delay: 0.5, isAwakened: isAwakened) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("FeedbackInfo"))

                        Text("Discussion Questions")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }

                    ForEach(Array(SermonShowcaseMockData.discussionQuestions.prefix(2).enumerated()), id: \.element.id) { index, question in
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("\(index + 1). \(question.question)")
                                .font(Typography.Command.body)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineSpacing(Typography.Command.bodyLineSpacing)
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }

                    Button {
                        // View all questions
                    } label: {
                        Text("View All Questions")
                            .font(Typography.Command.label)
                            .foregroundStyle(Color("FeedbackInfo"))
                    }
                }
            }

            // Study Guide CTA
            AtriumCard(delay: 0.6, isAwakened: isAwakened) {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "doc.text.fill")
                        .font(Typography.Icon.xl)
                        .foregroundStyle(Color("AccentBronze"))

                    Text("Study Guide")
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text("Generate a comprehensive study guide with discussion questions, reflection prompts, and application points.")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(Typography.Command.bodyLineSpacing)

                    Button {
                        // Generate study guide
                    } label: {
                        Text("Generate Study Guide")
                            .font(Typography.Command.cta)
                            .foregroundStyle(colorScheme == .dark ? Color("AppBackground") : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.button)
                                    .fill(Color("AccentBronze"))
                            )
                    }
                }
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
    }

    // MARK: - Notes Content

    private var notesContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Quick add note
            AtriumCard(delay: 0.4, isAwakened: isAwakened) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AppAccentAction"))

                        Text("Quick Note")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))

                        Spacer()

                        Text(SermonShowcaseMockData.formattedCurrentTime)
                            .font(Typography.Command.caption.monospacedDigit())
                            .foregroundStyle(Color("TertiaryText"))
                    }

                    TextField("Add a note at this timestamp...", text: .constant(""))
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input)
                                .fill(Color("AppBackground"))
                        )
                }
            }

            // Existing notes
            ForEach(Array(SermonShowcaseMockData.userNotes.enumerated()), id: \.element.id) { index, note in
                AtriumCard(delay: 0.5 + Double(index) * 0.1, isAwakened: isAwakened) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text(note.timestamp)
                                .font(Typography.Command.label.monospacedDigit())
                                .foregroundStyle(Color("AppAccentAction"))
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.overlay))
                                )

                            Spacer()

                            Menu {
                                Button("Edit", systemImage: "pencil") {}
                                Button("Delete", systemImage: "trash", role: .destructive) {}
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(Typography.Icon.md)
                                    .foregroundStyle(Color("TertiaryText"))
                                    .frame(width: 32, height: 32)
                            }
                        }

                        Text(note.text)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    }
                }
            }

            // Empty state if no notes
            if SermonShowcaseMockData.userNotes.isEmpty {
                AtriumCard(delay: 0.5, isAwakened: isAwakened) {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "note.text")
                            .font(Typography.Icon.xxl)
                            .foregroundStyle(Color("TertiaryText"))

                        Text("No notes yet")
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextSecondary"))

                        Text("Add notes while listening to capture your thoughts and insights.")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
        }
    }
}

// MARK: - Atrium Card

private struct AtriumCard<Content: View>: View {
    let delay: Double
    let isAwakened: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
            .opacity(isAwakened ? 1 : 0)
            .offset(y: isAwakened ? 0 : 10)
            .animation(Theme.Animation.slowFade.delay(delay), value: isAwakened)
    }
}

// MARK: - Atrium Action Button

private struct AtriumActionButton: View {
    let icon: String
    let label: String
    let delay: Double
    let isAwakened: Bool

    var body: some View {
        Button {
            // Action
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color("AppTextSecondary"))

                Text(label)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 10)
        .animation(Theme.Animation.slowFade.delay(delay), value: isAwakened)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let result = flowLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        AtriumSermonPage()
    }
    .preferredColorScheme(.dark)
}
