import SwiftUI

// MARK: - The Study Sermon Page

/// Scholar-focused sermon layout with dense yet organized information.
/// Quick access to transcript, insights, references, and study tools in a unified view.
struct StudySermonPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAwakened = false
    @State private var isPlaying = false
    @State private var playbackSpeed: Double = 1.0
    @State private var currentProgress: Double = SermonShowcaseMockData.progress
    @State private var showFullTranscript = false
    @State private var activeSegmentIndex = 2
    @State private var selectedOutlineSection: UUID?

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Compact header
                    compactHeader
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.md)

                    // Mini audio player bar
                    audioBar
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)

                    // Two-column layout simulation
                    mainContent
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xxl * 2)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Theme.Spacing.sm) {
                    Button {
                        // Library
                    } label: {
                        Image(systemName: "folder")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }

                    Button {
                        // Share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
        }
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

            // Subtle blue tint for scholarly feel
            LinearGradient(
                colors: [
                    Color("FeedbackInfo").opacity(Theme.Opacity.subtle / 5),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Color("AccentBronze"))
                        .frame(width: 6, height: 6)
                    Text(SermonShowcaseMockData.status.uppercased())
                        .font(Typography.Command.meta)
                        .tracking(Typography.Editorial.referenceTracking)
                        .foregroundStyle(Color("AccentBronze"))
                }

                Text(SermonShowcaseMockData.sermonTitle)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(SermonShowcaseMockData.speakerName)
                    Text("•")
                    Text(SermonShowcaseMockData.sermonDate)
                }
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
            }

            Spacer()

            // Quick actions
            VStack(spacing: Theme.Spacing.xs) {
                StudyQuickButton(icon: "bookmark") {}
                StudyQuickButton(icon: "doc.on.doc") {}
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isAwakened)
    }

    // MARK: - Audio Bar

    private var audioBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Play button
            Button {
                isPlaying.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color("FeedbackInfo"))
                        .frame(width: 44, height: 44)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(Typography.Icon.md)
                        .foregroundStyle(colorScheme == .dark ? Color("AppBackground") : .white)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }

            // Progress and controls
            VStack(spacing: 4) {
                // Scrubber
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("AppDivider"))
                            .frame(height: 4)

                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("FeedbackInfo"))
                            .frame(width: geometry.size.width * currentProgress, height: 4)

                        // Thumb
                        Circle()
                            .fill(Color("FeedbackInfo"))
                            .frame(width: 12, height: 12)
                            .offset(x: geometry.size.width * currentProgress - 6)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                currentProgress = max(0, min(1, value.location.x / geometry.size.width))
                            }
                    )
                }
                .frame(height: 12)

                // Time
                HStack {
                    Text(SermonShowcaseMockData.formattedCurrentTime)
                        .font(Typography.Command.caption.monospacedDigit())
                        .foregroundStyle(Color("AppTextSecondary"))

                    Spacer()

                    Text(SermonShowcaseMockData.formattedRemaining)
                        .font(Typography.Command.caption.monospacedDigit())
                        .foregroundStyle(Color("TertiaryText"))
                }
            }

            // Skip controls
            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    // Skip back
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color("AppTextPrimary"))
                }

                Button {
                    // Skip forward
                } label: {
                    Image(systemName: "goforward.15")
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }

            // Speed
            Button {
                // Speed menu
            } label: {
                Text("\(playbackSpeed, specifier: "%.1f")×")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.tag)
                            .fill(Color("AppSurface"))
                    )
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.15), value: isAwakened)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Outline + Transcript row
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Outline sidebar
                outlinePanel
                    .frame(width: 120)

                // Transcript panel
                transcriptPanel
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)

            // Bottom panels row
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Scripture references
                referencesPanel

                // AI insights
                insightsPanel
            }
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)

            // Study tools row
            studyToolsRow
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)

            // Notes section
            notesPanel
                .opacity(isAwakened ? 1 : 0)
                .animation(Theme.Animation.slowFade.delay(0.5), value: isAwakened)
        }
    }

    // MARK: - Outline Panel

    private var outlinePanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("OUTLINE")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))
                .padding(.bottom, Theme.Spacing.xs)

            ForEach(SermonShowcaseMockData.aiOutline) { section in
                Button {
                    selectedOutlineSection = section.id
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(Typography.Command.caption)
                            .foregroundStyle(
                                selectedOutlineSection == section.id
                                    ? Color("FeedbackInfo")
                                    : Color("AppTextPrimary")
                            )
                            .lineLimit(1)

                        Text(section.timestamp)
                            .font(Typography.Command.meta.monospacedDigit())
                            .foregroundStyle(Color("TertiaryText"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Theme.Spacing.xs)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.tag)
                            .fill(
                                selectedOutlineSection == section.id
                                    ? Color("FeedbackInfo").opacity(Theme.Opacity.overlay)
                                    : Color.clear
                            )
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Transcript Panel

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("TRANSCRIPT")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()

                Button {
                    showFullTranscript.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(Typography.Icon.xxs)
                        Text("Expand")
                            .font(Typography.Command.caption)
                    }
                    .foregroundStyle(Color("FeedbackInfo"))
                }
            }
            .padding(.bottom, Theme.Spacing.xs)

            // Visible segments
            ForEach(Array(SermonShowcaseMockData.transcriptSegments.prefix(4).enumerated()), id: \.element.id) { index, segment in
                Button {
                    activeSegmentIndex = index
                } label: {
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Text(segment.timestamp)
                            .font(Typography.Command.meta.monospacedDigit())
                            .foregroundStyle(
                                index == activeSegmentIndex
                                    ? Color("FeedbackInfo")
                                    : Color("TertiaryText")
                            )
                            .frame(width: 36, alignment: .trailing)

                        Text(segment.text)
                            .font(Typography.Command.body)
                            .foregroundStyle(
                                index == activeSegmentIndex
                                    ? Color("AppTextPrimary")
                                    : Color("AppTextSecondary")
                            )
                            .lineSpacing(Typography.Command.bodyLineSpacing)
                            .lineLimit(index == activeSegmentIndex ? nil : 2)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Theme.Spacing.xs)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.tag)
                            .fill(
                                index == activeSegmentIndex
                                    ? Color("FeedbackInfo").opacity(Theme.Opacity.subtle)
                                    : Color.clear
                            )
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - References Panel

    private var referencesPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "book.closed")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AccentBronze"))

                Text("REFERENCES")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(.bottom, Theme.Spacing.xs)

            // Primary
            if let primary = SermonShowcaseMockData.scriptureReferences.first(where: { $0.isPrimary }) {
                Button {
                    // Open verse
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(primary.reference)
                                .font(Typography.Command.body.weight(.medium))
                                .foregroundStyle(Color("AppTextPrimary"))

                            Image(systemName: "checkmark.seal.fill")
                                .font(Typography.Icon.xxxs)
                                .foregroundStyle(Color("FeedbackSuccess"))
                        }

                        Text(primary.text)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                            .lineLimit(2)
                    }
                    .padding(Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.tag)
                            .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                    )
                }
            }

            // Additional refs in compact list
            ForEach(SermonShowcaseMockData.scriptureReferences.filter { !$0.isPrimary }.prefix(3)) { ref in
                Button {
                    // Open verse
                } label: {
                    HStack {
                        Text(ref.reference)
                            .font(Typography.Command.caption)
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

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(Typography.Icon.xxs)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Insights Panel

    private var insightsPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AppAccentAction"))

                Text("AI INSIGHTS")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(.bottom, Theme.Spacing.xs)

            // Summary (truncated)
            Text(SermonShowcaseMockData.aiSummary)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineSpacing(Typography.Command.bodyLineSpacing)
                .lineLimit(3)

            Rectangle()
                .fill(Color("AppDivider"))
                .frame(height: Theme.Stroke.hairline)
                .padding(.vertical, Theme.Spacing.xs)

            // Key themes as tags
            Text("THEMES")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.referenceTracking)
                .foregroundStyle(Color("TertiaryText"))

            HStack(spacing: Theme.Spacing.xs) {
                ForEach(SermonShowcaseMockData.aiThemes.prefix(2)) { theme in
                    Text(theme.theme)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppAccentAction"))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.tag)
                                .stroke(Color("AppAccentAction").opacity(0.3), lineWidth: Theme.Stroke.hairline)
                        )
                }

                Text("+\(SermonShowcaseMockData.aiThemes.count - 2)")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }

            Button {
                // View all insights
            } label: {
                Text("View All Insights")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppAccentAction"))
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Study Tools Row

    private var studyToolsRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("STUDY TOOLS")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            HStack(spacing: Theme.Spacing.md) {
                StudyToolCard(
                    icon: "doc.text.fill",
                    title: "Study Guide",
                    subtitle: "Questions & prompts",
                    accentColor: Color("AccentBronze")
                )

                StudyToolCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Discussion",
                    subtitle: "\(SermonShowcaseMockData.discussionQuestions.count) questions",
                    accentColor: Color("FeedbackInfo")
                )

                StudyToolCard(
                    icon: "list.bullet.rectangle",
                    title: "Takeaways",
                    subtitle: "\(SermonShowcaseMockData.keyTakeaways.count) points",
                    accentColor: Color("AppAccentAction")
                )
            }
        }
    }

    // MARK: - Notes Panel

    private var notesPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "note.text")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("FeedbackSuccess"))

                Text("MY NOTES")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Spacer()

                Button {
                    // Add note
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(Typography.Icon.xxs)
                        Text("Add")
                            .font(Typography.Command.caption)
                    }
                    .foregroundStyle(Color("FeedbackSuccess"))
                }
            }

            // Notes list
            if !SermonShowcaseMockData.userNotes.isEmpty {
                ForEach(SermonShowcaseMockData.userNotes) { note in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Text(note.timestamp)
                            .font(Typography.Command.meta.monospacedDigit())
                            .foregroundStyle(Color("FeedbackSuccess"))
                            .frame(width: 36, alignment: .trailing)

                        Text(note.text)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)

                        Spacer()

                        Button {
                            // Edit
                        } label: {
                            Image(systemName: "pencil")
                                .font(Typography.Icon.sm)
                                .foregroundStyle(Color("TertiaryText"))
                        }
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.tag)
                            .fill(Color("AppBackground"))
                    )
                }
            } else {
                HStack {
                    Text("No notes yet. Tap + to add your first note.")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
    }
}

// MARK: - Study Quick Button

private struct StudyQuickButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color("AppSurface"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                )
        }
    }
}

// MARK: - Study Tool Card

private struct StudyToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        Button {
            // Open tool
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.Icon.lg)
                    .foregroundStyle(accentColor)

                VStack(spacing: 2) {
                    Text(title)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.3),
                                Color("AppDivider")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
    }
}

#Preview {
    NavigationStack {
        StudySermonPage()
    }
    .preferredColorScheme(.dark)
}
