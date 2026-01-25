//
//  SermonLibraryTab.swift
//  BibleStudy
//
//  Library tab content for sermon navigation.
//  Shows quick access, carousel with sample pinned first, and action buttons.
//

import SwiftUI

// MARK: - Sermon Library Tab

struct SermonLibraryTab: View {
    let sermons: [Sermon]
    let sampleSermon: Sermon?
    let showSample: Bool
    let quickAccessState: SermonQuickAccessState

    // Actions
    let onSermonTap: (Sermon) -> Void
    let onSampleTap: () -> Void
    let onSampleDismiss: () -> Void
    let onViewAllTap: () -> Void
    let onRecordTap: () -> Void
    let onProcessingTap: () -> Void

    @State private var isAwakened = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Quick access row (processing/continue states)
            if case .hidden = quickAccessState {
                // No quick access to show
            } else {
                SermonQuickAccessRow(
                    state: quickAccessState,
                    onProcessingTap: {
                        HapticService.shared.lightTap()
                        onProcessingTap()
                    },
                    onContinueTap: { sermon in
                        HapticService.shared.lightTap()
                        onSermonTap(sermon)
                    }
                )
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.1)
            }

            // Recent sermons carousel
            if !carouselSermons.isEmpty {
                carouselSection
            } else {
                emptyLibraryHint
                    .ceremonialAppear(isAwakened: isAwakened, delay: 0.15)
            }

            // View All Sermons button
            viewAllButton
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.2)

            // Record New Sermon shortcut
            recordShortcutButton
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.25)
        }
        .onAppear {
            if reduceMotion {
                isAwakened = true
            } else {
                withAnimation(Theme.Animation.settle) {
                    isAwakened = true
                }
            }
        }
    }

    // MARK: - Carousel Sermons

    /// Sermons to show in carousel: sample pinned first (if visible), then recent
    /// Excludes any sermon shown in the quick access "Continue" row to avoid duplication
    private var carouselSermons: [Sermon] {
        var result: [Sermon] = []

        // Sample pinned first if visible
        if showSample, let sample = sampleSermon {
            result.append(sample)
        }

        // Get the continue sermon ID to exclude from carousel
        let continueSermonId: UUID? = {
            if case .continueSermon(let sermon) = quickAccessState {
                return sermon.id
            }
            return nil
        }()

        // Add recent sermons (up to 4 to make 5 total with sample)
        let maxRecent = showSample ? 4 : 5
        let recent = sermons
            .filter { sermon in
                // Exclude sample from recent list to avoid duplication
                if let sample = sampleSermon, sermon.id == sample.id {
                    return false
                }
                // Exclude the sermon shown in Continue row to avoid duplication
                if let continueId = continueSermonId, sermon.id == continueId {
                    return false
                }
                return true
            }
            .prefix(maxRecent)

        result.append(contentsOf: recent)
        return result
    }

    // MARK: - Carousel Section

    private var carouselSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            Text("RECENT")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.12)

            // Horizontal carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(Array(carouselSermons.enumerated()), id: \.element.id) { index, sermon in
                        let isSample = sampleSermon?.id == sermon.id && showSample

                        LibraryCarouselCard(
                            sermon: sermon,
                            isSample: isSample,
                            onTap: {
                                HapticService.shared.lightTap()
                                if isSample {
                                    onSampleTap()
                                } else {
                                    onSermonTap(sermon)
                                }
                            },
                            onDismiss: isSample ? onSampleDismiss : nil
                        )
                        .ceremonialAppear(
                            isAwakened: isAwakened,
                            delay: reduceMotion ? 0 : 0.15 + Double(index) * 0.06
                        )
                    }
                }
                .padding(.horizontal, 1)  // Prevent clipping of card shadows
            }
        }
    }

    // MARK: - Empty Library Hint

    private var emptyLibraryHint: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "waveform.circle")
                .font(Typography.Icon.lg)
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Record your first sermon")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color.appTextPrimary)

                Text("Your recordings will appear here")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Color("AppSurface").opacity(Theme.Opacity.pressed))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - View All Button

    private var viewAllButton: some View {
        Button(action: onViewAllTap) {
            HStack {
                Text("View All Sermons")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextPrimary"))

                if !sermons.isEmpty {
                    Text("(\(sermons.count))")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .padding(Theme.Spacing.md)
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(LibraryButtonStyle())
        .accessibilityLabel("View all sermons")
        .accessibilityHint("Opens full sermon library")
    }

    // MARK: - Record Shortcut Button

    private var recordShortcutButton: some View {
        Button(action: onRecordTap) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "mic.fill")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AccentBronze"))

                Text("Record New Sermon")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AccentBronze"))

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Color("AccentBronze").opacity(Theme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(LibraryButtonStyle())
        .accessibilityLabel("Record new sermon")
        .accessibilityHint("Switches to recording tab")
    }
}

// MARK: - Library Carousel Card

/// Card for sermon carousel with sample badge and dismiss support.
struct LibraryCarouselCard: View {
    let sermon: Sermon
    let isSample: Bool
    let onTap: () -> Void
    let onDismiss: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header with status or sample badge
                HStack(spacing: Theme.Spacing.xs) {
                    if isSample {
                        // Sample badge
                        Text("SAMPLE")
                            .font(Typography.Editorial.labelSmall)
                            .tracking(Typography.Editorial.labelTracking)
                            .foregroundStyle(Color("AccentBronze"))
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground))
                            )
                    } else {
                        // Status indicator
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)

                        Text(statusText)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    Spacer()

                    // Dismiss button for sample
                    if isSample, let onDismiss = onDismiss {
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(Typography.Icon.xxs)
                                .foregroundStyle(Color("TertiaryText"))
                                .padding(Theme.Spacing.xs)
                                .background(Color("AppSurface").opacity(0.8))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss sample sermon")
                    }
                }

                // Title
                Text(sermon.displayTitle)
                    .font(Typography.Command.label)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Duration
                Text(sermon.formattedDuration)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(width: 200, height: 120, alignment: .topLeading)
            .padding(Theme.Spacing.md)
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        isSample
                            ? Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
                            : Color("AppDivider"),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(LibraryButtonStyle())
        .accessibilityLabel("\(sermon.displayTitle), \(sermon.formattedDuration), \(statusText)")
    }

    private var statusColor: Color {
        if sermon.hasError {
            return Color("FeedbackError")  // Error - red
        } else if sermon.isComplete || sermon.hasSuccessfulTranscription {
            return Color("AccentBronze")  // Ready/viewable - bronze
        } else if sermon.isProcessing {
            return Color("TertiaryText")  // Processing - neutral
        } else {
            return Color("TertiaryText")  // Pending - neutral
        }
    }

    private var statusText: String {
        if sermon.hasError {
            return "Error"
        } else if sermon.isComplete || sermon.hasSuccessfulTranscription {
            return "Ready"
        } else if sermon.isProcessing {
            return "Processing"
        } else {
            return "Pending"
        }
    }
}

// MARK: - Button Style

private struct LibraryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Library Tab - With Sermons") {
    let sampleSermon = Sermon(
        id: UUID(),
        userId: UUID(),
        title: "Sermon on the Mount — Matthew 5:1-12",
        recordedAt: Date().addingTimeInterval(-86400),
        durationSeconds: 2843,
        transcriptionStatus: .succeeded,
        studyGuideStatus: .succeeded
    )

    let sermons = [
        Sermon(
            id: UUID(),
            userId: UUID(),
            title: "Romans 8:28 — All Things Work Together",
            recordedAt: Date(),
            durationSeconds: 2118,
            transcriptionStatus: .succeeded,
            studyGuideStatus: .succeeded
        ),
        Sermon(
            id: UUID(),
            userId: UUID(),
            title: "John 3 — Born Again",
            recordedAt: Date().addingTimeInterval(-3600),
            durationSeconds: 3121,
            transcriptionStatus: .running,
            studyGuideStatus: .pending
        )
    ]

    ScrollView {
        SermonLibraryTab(
            sermons: sermons,
            sampleSermon: sampleSermon,
            showSample: true,
            quickAccessState: .processing(count: 1),
            onSermonTap: { print("Sermon: \($0.title)") },
            onSampleTap: { print("Sample tapped") },
            onSampleDismiss: { print("Sample dismissed") },
            onViewAllTap: { print("View all") },
            onRecordTap: { print("Record") },
            onProcessingTap: { print("Processing") }
        )
        .padding(Theme.Spacing.lg)
    }
    .background(Color("AppBackground"))
}

#Preview("Library Tab - Empty") {
    ScrollView {
        SermonLibraryTab(
            sermons: [],
            sampleSermon: nil,
            showSample: false,
            quickAccessState: .hidden,
            onSermonTap: { _ in },
            onSampleTap: {},
            onSampleDismiss: {},
            onViewAllTap: { print("View all") },
            onRecordTap: { print("Record") },
            onProcessingTap: {}
        )
        .padding(Theme.Spacing.lg)
    }
    .background(Color("AppBackground"))
}
