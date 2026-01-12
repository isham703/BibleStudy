import SwiftUI

// MARK: - Scripture Reference Chip
// Tappable chip showing a scripture reference with verification status

struct ScriptureReferenceChip: View {
    let reference: SermonVerseReference
    let isMentioned: Bool
    @State private var showDetail = false

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            showDetail = true
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "book.closed")
                    .font(Typography.Icon.xs)

                Text(reference.reference)
                    .font(Typography.Command.label)

                // Verification indicator (only for suggested refs with status)
                if !isMentioned, let status = reference.verificationStatus {
                    VerificationStatusIndicator(status: status)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(chipForegroundColor)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(chipBackground)
            .clipShape(Capsule())
            .overlay(chipBorder)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ScriptureReferenceDetailSheet(reference: reference)
        }
    }

    private var chipForegroundColor: Color {
        if isMentioned { return Color("AccentBronze") }
        switch reference.verificationStatus {
        case .verified: return Color("AccentBronze").opacity(Theme.Opacity.textPrimary)
        case .partial: return Color("AccentBronze").opacity(Theme.Opacity.pressed)
        case .unverified, .unknown, .none: return Color.appTextSecondary
        }
    }

    private var chipBackground: some View {
        Group {
            if isMentioned {
                Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
            } else if reference.verificationStatus == .verified {
                Color("AccentBronze").opacity(Theme.Opacity.subtle)
            } else {
                Color("AppSurface")
            }
        }
    }

    private var chipBorder: some View {
        Capsule().stroke(
            isMentioned ? Color("AccentBronze").opacity(Theme.Opacity.focusStroke) :
            reference.verificationStatus == .verified ? Color("AccentBronze").opacity(Theme.Opacity.selectionBackground) :
            Color.appTextSecondary.opacity(Theme.Opacity.selectionBackground),
            lineWidth: Theme.Stroke.hairline
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        // Mentioned reference
        ScriptureReferenceChip(
            reference: SermonVerseReference(
                reference: "John 3:16",
                bookId: 43,
                chapter: 3,
                verseStart: 16,
                isMentioned: true
            ),
            isMentioned: true
        )

        // Verified suggested reference
        ScriptureReferenceChip(
            reference: SermonVerseReference(
                reference: "Romans 5:8",
                bookId: 45,
                chapter: 5,
                verseStart: 8,
                isMentioned: false,
                verificationStatus: .verified
            ),
            isMentioned: false
        )

        // Partial suggested reference
        ScriptureReferenceChip(
            reference: SermonVerseReference(
                reference: "Ephesians 2:8",
                bookId: 49,
                chapter: 2,
                verseStart: 8,
                isMentioned: false,
                verificationStatus: .partial
            ),
            isMentioned: false
        )
    }
    .padding()
    .background(Color("AppBackground"))
}
