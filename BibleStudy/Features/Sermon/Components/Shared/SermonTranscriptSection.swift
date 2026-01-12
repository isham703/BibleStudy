import SwiftUI

// MARK: - Sermon Transcript Section
// Displays transcript with auto-scroll and highlighting

struct SermonTranscriptSection: View {
    let transcript: SermonTranscript?
    let viewModel: SermonViewingViewModel
    @Binding var autoScrollEnabled: Bool
    @Binding var copiedToClipboard: Bool
    let delay: Double
    let isAwakened: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header with auto-scroll toggle
                HStack {
                    Text("Transcript")
                        .font(Typography.Command.body.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))

                    Spacer()

                    // Auto-scroll toggle
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Auto-scroll")
                            .font(Typography.Command.meta)
                            .foregroundStyle(Color("TertiaryText"))

                        Toggle("", isOn: $autoScrollEnabled)
                            .labelsHidden()
                            .tint(Color("AppAccentAction"))
                            .scaleEffect(0.8)
                    }
                }

                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)

                if let transcript = transcript, !transcript.segments.isEmpty {
                    // Transcript segments with auto-scroll
                    ScrollViewReader { proxy in
                        LazyVStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            ForEach(Array(transcript.segments.enumerated()), id: \.element.id) { index, segment in
                                TranscriptRowView(
                                    segment: segment,
                                    index: index,
                                    viewModel: viewModel,
                                    onTap: {
                                        viewModel.seekToTime(segment.startTime)
                                        HapticService.shared.selectionChanged()
                                    }
                                )
                                .id(index)
                            }
                        }
                        .onChange(of: viewModel.currentSegmentIndex) { _, newIndex in
                            if autoScrollEnabled, let index = newIndex {
                                withAnimation(reduceMotion ? nil : Theme.Animation.settle) {
                                    proxy.scrollTo(index, anchor: .center)
                                }
                            }
                        }
                    }

                    // Footer
                    Rectangle()
                        .fill(Color("AppDivider"))
                        .frame(height: Theme.Stroke.hairline)

                    HStack {
                        Text("\(transcript.wordCount) words")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))

                        Spacer()

                        Button {
                            copyTranscript(transcript)
                        } label: {
                            Text("Copy")
                                .font(Typography.Command.label)
                                .foregroundStyle(Color("AppAccentAction"))
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "doc.text")
                            .font(Typography.Icon.lg)
                            .foregroundStyle(Color("TertiaryText"))

                        Text("Transcript unavailable")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                }
            }
        }
    }

    private func copyTranscript(_ transcript: SermonTranscript) {
        UIPasteboard.general.string = transcript.content
        HapticService.shared.success()
        copiedToClipboard = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                copiedToClipboard = false
            }
        }
    }
}

// MARK: - Transcript Row View (Plaud-style)

private struct TranscriptRowView: View {
    let segment: TranscriptDisplaySegment
    let index: Int
    let viewModel: SermonViewingViewModel
    let onTap: () -> Void

    private var isActive: Bool {
        index == viewModel.currentSegmentIndex
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Timestamp
                Text(TimestampFormatter.format(segment.startTime))
                    .font(Typography.Command.meta.monospacedDigit())
                    .foregroundStyle(isActive ? Color("AppAccentAction") : Color("TertiaryText"))

                // Text
                Text(segment.text)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(isActive ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .fill(isActive ? Color("AppAccentAction").opacity(Theme.Opacity.subtle) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Segment at \(TimestampFormatter.format(segment.startTime))")
        .accessibilityHint("Double tap to jump to this part")
    }
}
