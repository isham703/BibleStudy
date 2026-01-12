import SwiftUI

// MARK: - Sermon Outline Section View
// Displays sermon outline with timestamps (Plaud-style)

struct SermonOutlineSectionView: View {
    let outline: [OutlineSection]
    let currentTime: TimeInterval
    let delay: Double
    let isAwakened: Bool
    let onSeek: (TimeInterval) -> Void

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
                        currentTime: currentTime,
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
    let currentTime: TimeInterval
    let onTap: () -> Void

    private var isActive: Bool {
        guard let start = section.startSeconds else { return false }
        let end = section.endSeconds ?? Double.infinity
        return currentTime >= start && currentTime < end
    }

    private var hasTimestamp: Bool {
        section.startSeconds != nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Timestamp (Plaud-style: underlined)
                if let startSeconds = section.startSeconds {
                    Text(TimestampFormatter.format(startSeconds))
                        .font(Typography.Command.caption.monospacedDigit())
                        .foregroundStyle(Color("AppTextSecondary"))
                        .underline()
                } else {
                    Text("--:--")
                        .font(Typography.Command.caption.monospacedDigit())
                        .foregroundStyle(Color("TertiaryText"))
                }

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
        }
        .buttonStyle(.plain)
        .disabled(!hasTimestamp)
        .accessibilityLabel("Section \(index + 1): \(section.title)")
        .accessibilityHint(hasTimestamp ? "Double tap to jump to this section" : "No timestamp available")
    }
}
