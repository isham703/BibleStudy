import SwiftUI

// MARK: - Scripture Reference With Timestamp
// Wraps ScriptureReferenceChip with an optional TimestampChip for references
// that have audio timestamps. Used in the sermon viewing experience to
// enable quick navigation to where a scripture was mentioned.

struct ScriptureReferenceWithTimestamp: View {
    let reference: SermonVerseReference
    let onTimestampTap: (Double) -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ScriptureReferenceChip(reference: reference, isMentioned: reference.isMentioned)

            if let timestamp = reference.timestampSeconds {
                TimestampChip(timestamp: timestamp) {
                    onTimestampTap(timestamp)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        // Reference with timestamp
        ScriptureReferenceWithTimestamp(
            reference: SermonVerseReference(
                reference: "John 3:16",
                bookId: 43,
                chapter: 3,
                verseStart: 16,
                isMentioned: true,
                timestampSeconds: 120
            ),
            onTimestampTap: { _ in }
        )

        // Reference without timestamp
        ScriptureReferenceWithTimestamp(
            reference: SermonVerseReference(
                reference: "Romans 5:8",
                bookId: 45,
                chapter: 5,
                verseStart: 8,
                isMentioned: false,
                verificationStatus: .verified
            ),
            onTimestampTap: { _ in }
        )
    }
    .padding()
    .background(Color("AppBackground"))
}
