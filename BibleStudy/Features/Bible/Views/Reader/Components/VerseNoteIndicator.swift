import SwiftUI

// MARK: - Verse Note Indicator
// Small tappable indicator showing note presence on a verse
// Displays template icon with optional count badge for multiple notes
// Tapping shows preview; tap again to edit

struct VerseNoteIndicator: View {
    let template: NoteTemplate
    let noteCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: template.icon)
                    .font(Typography.Icon.xs)

                if noteCount > 1 {
                    Text("\(noteCount)")
                        .font(Typography.Command.meta.monospacedDigit())
                }
            }
            .foregroundStyle(template.accentColor)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(template.accentColor.opacity(Theme.Opacity.subtle))
            )
            .overlay(
                Capsule()
                    .stroke(
                        template.accentColor.opacity(Theme.Opacity.selectionBackground),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
        // Align badge to top so tap area extends downward (not centered)
        .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double-tap to preview, tap again to edit")
    }

    private var accessibilityLabel: String {
        if noteCount > 1 {
            return "\(noteCount) \(template.displayName) notes"
        } else {
            return "\(template.displayName) note"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        // Single note indicators for each template
        HStack(spacing: Theme.Spacing.md) {
            VerseNoteIndicator(template: .freeform, noteCount: 1, onTap: {})
            VerseNoteIndicator(template: .observation, noteCount: 1, onTap: {})
            VerseNoteIndicator(template: .application, noteCount: 1, onTap: {})
        }

        HStack(spacing: Theme.Spacing.md) {
            VerseNoteIndicator(template: .questions, noteCount: 1, onTap: {})
            VerseNoteIndicator(template: .exegesis, noteCount: 1, onTap: {})
            VerseNoteIndicator(template: .prayer, noteCount: 1, onTap: {})
        }

        // Multiple notes
        HStack(spacing: Theme.Spacing.md) {
            VerseNoteIndicator(template: .freeform, noteCount: 3, onTap: {})
            VerseNoteIndicator(template: .observation, noteCount: 5, onTap: {})
        }
    }
    .padding()
    .background(Color("AppBackground"))
}
