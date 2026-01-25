import SwiftUI

// MARK: - Sermon Outline Section View
// Displays sermon outline with timestamps (Plaud-style)

struct SermonOutlineSectionView: View {
    let outline: [OutlineSection]
    let currentTime: TimeInterval
    let delay: Double
    let isAwakened: Bool
    let onSeek: (TimeInterval) -> Void

    /// Determines the active section index based on current playback time.
    /// Returns the section with the highest timestamp that is still <= currentTime.
    /// Handles unsorted timestamps from approximate matching.
    private var activeIndex: Int? {
        var bestIndex: Int?
        var bestTime: TimeInterval = -1

        for (index, section) in outline.enumerated() {
            guard let start = section.startSeconds else { continue }
            // Find the section with the highest timestamp <= currentTime
            if currentTime >= start && start > bestTime {
                bestIndex = index
                bestTime = start
            }
        }
        return bestIndex
    }

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header
                Text("Outline")
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))

                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)

                // Outline rows (Plaud-style: timestamp + title)
                ForEach(Array(outline.enumerated()), id: \.element.id) { index, section in
                    OutlineRowView(
                        section: section,
                        index: index,
                        isActive: index == activeIndex,
                        onTap: {
                            if let startSeconds = section.startSeconds {
                                onSeek(startSeconds)
                                HapticService.shared.selectionChanged()
                            }
                        }
                    )

                    if index < outline.count - 1 {
                        Rectangle()
                            .fill(Color("AppDivider"))
                            .frame(height: Theme.Stroke.hairline)
                    }
                }
            }
        }
    }
}

// MARK: - Outline Row View (Plaud-style)

private struct OutlineRowView: View {
    let section: OutlineSection
    let index: Int
    let isActive: Bool
    let onTap: () -> Void

    private var hasTimestamp: Bool {
        section.startSeconds != nil
    }

    /// Whether the timestamp match is approximate (low confidence)
    private var isApproximate: Bool {
        guard section.startSeconds != nil else { return false }
        return (section.matchConfidence ?? 1.0) < 0.7
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Timestamp with 3 states: loading, approximate, precise
                timestampView
                    .frame(width: 48, alignment: .leading)

                // Title
                Text(section.title)
                    .font(Typography.Command.body)
                    .foregroundStyle(isActive ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .fill(isActive ? Color("AppAccentAction").opacity(Theme.Opacity.subtle) : Color.clear)
            )
            .opacity(hasTimestamp ? 1.0 : Theme.Opacity.disabled)
        }
        .buttonStyle(.plain)
        .disabled(!hasTimestamp)
        .animation(Theme.Animation.fade, value: hasTimestamp)
        .accessibilityLabel("Section \(index + 1): \(section.title)")
        .accessibilityHint(accessibilityHintText)
    }

    /// Timestamp display with 3 states
    @ViewBuilder
    private var timestampView: some View {
        if let startSeconds = section.startSeconds {
            // Has timestamp - show with optional approximate indicator
            HStack(spacing: 0) {
                if isApproximate {
                    Text("~")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                Text(TimestampFormatter.format(startSeconds))
                    .font(Typography.Command.caption.monospacedDigit())
                    .foregroundStyle(Color("AppTextSecondary"))
                    .underline()
            }
        } else {
            // No timestamp - shimmer loading state
            Text("00:00")
                .font(Typography.Command.caption.monospacedDigit())
                .foregroundStyle(Color("TertiaryText"))
                .redacted(reason: .placeholder)
        }
    }

    private var accessibilityHintText: String {
        if !hasTimestamp {
            return "Timestamp loading"
        } else if isApproximate {
            return "Approximate position. Double tap to jump to this section"
        } else {
            return "Double tap to jump to this section"
        }
    }
}
