//
//  SermonQuickAccessRow.swift
//  BibleStudy
//
//  Conditional quick access row for sermon landing page
//  Shows processing queue OR most recent ready sermon
//  Hidden when no meaningful state to display
//

import SwiftUI

// MARK: - Quick Access State

enum SermonQuickAccessState {
    case processing(count: Int)
    case continueSermon(Sermon)
    case hidden

    static func from(sermons: [Sermon]) -> SermonQuickAccessState {
        let processingCount = sermons.filter { $0.isProcessing }.count
        if processingCount > 0 {
            return .processing(count: processingCount)
        }

        // Find most recent ready sermon
        let readySermons = sermons.filter { $0.isComplete }
        if let mostRecent = readySermons.sorted(by: { $0.recordedAt > $1.recordedAt }).first {
            return .continueSermon(mostRecent)
        }

        return .hidden
    }
}

// MARK: - Sermon Quick Access Row

struct SermonQuickAccessRow: View {
    let state: SermonQuickAccessState
    let onProcessingTap: () -> Void
    let onContinueTap: (Sermon) -> Void

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch state {
            case .processing(let count):
                processingRow(count: count)
            case .continueSermon(let sermon):
                continueRow(sermon: sermon)
            case .hidden:
                EmptyView()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(Theme.Animation.settle.delay(0.2)) {
                    isVisible = true
                }
            }
        }
    }

    // MARK: - Processing Row

    private func processingRow(count: Int) -> some View {
        Button(action: onProcessingTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Pulsing indicator
                ZStack {
                    Circle()
                        .fill(Color("AppSurface"))
                        .frame(width: 36, height: 36)

                    Image(systemName: "waveform")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("TertiaryText"))
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("PROCESSING")
                            .font(Typography.Command.meta)
                            .tracking(Typography.Editorial.sectionTracking)
                            .foregroundStyle(Color("TertiaryText"))

                        // Count badge
                        Text("\(count)")
                            .font(Typography.Command.meta.monospacedDigit())
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color("TertiaryText").opacity(Theme.Opacity.selectionBackground))
                            )
                    }

                    Text(count == 1 ? "1 sermon transcribing..." : "\(count) sermons transcribing...")
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
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(QuickAccessButtonStyle())
        .accessibilityLabel("\(count) sermons processing")
        .accessibilityHint("Double tap to view processing queue")
    }

    // MARK: - Continue Row

    private func continueRow(sermon: Sermon) -> some View {
        Button {
            onContinueTap(sermon)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground))
                        .frame(width: 36, height: 36)

                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("AccentBronze"))
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("CONTINUE")
                        .font(Typography.Command.meta)
                        .tracking(Typography.Editorial.sectionTracking)
                        .foregroundStyle(Color("AccentBronze"))

                    Text(sermon.displayTitle)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("AccentBronze"))
            }
            .padding(Theme.Spacing.md)
            .background(Color("AccentBronze").opacity(Theme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(QuickAccessButtonStyle())
        .accessibilityLabel("Continue \(sermon.displayTitle)")
        .accessibilityHint("Double tap to open this sermon")
    }
}

// MARK: - Button Style

private struct QuickAccessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Processing State") {
    VStack {
        SermonQuickAccessRow(
            state: .processing(count: 2),
            onProcessingTap: { print("Processing tapped") },
            onContinueTap: { _ in }
        )

        SermonQuickAccessRow(
            state: .processing(count: 1),
            onProcessingTap: { print("Processing tapped") },
            onContinueTap: { _ in }
        )
    }
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Continue State") {
    SermonQuickAccessRow(
        state: .continueSermon(
            Sermon(
                id: UUID(),
                userId: UUID(),
                title: "The Good Samaritan — Luke 10:25-37",
                recordedAt: Date(),
                durationSeconds: 1200,
                transcriptionStatus: .succeeded,
                studyGuideStatus: .succeeded
            )
        ),
        onProcessingTap: {},
        onContinueTap: { sermon in print("Continue: \(sermon.title)") }
    )
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Hidden State") {
    VStack {
        Text("Row should be hidden below:")
        SermonQuickAccessRow(
            state: .hidden,
            onProcessingTap: {},
            onContinueTap: { _ in }
        )
        Text("(nothing above)")
    }
    .padding()
    .background(Color("AppBackground"))
}
