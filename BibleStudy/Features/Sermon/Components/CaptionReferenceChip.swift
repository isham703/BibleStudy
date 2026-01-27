import SwiftUI

// MARK: - Caption Reference Chip
// Floating chip shown when a Bible reference is detected in live captions.
// Displays the reference short text with a "Go" action to navigate to the passage.
// Auto-dismisses after a timeout or on user tap.

struct CaptionReferenceChip: View {
    let reference: CaptionReferenceState.DetectedReference
    let onGoToPassage: (BibleLocation) -> Void
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?

    /// Auto-dismiss after 8 seconds
    private static let autoDismissDelay: TimeInterval = 8

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Scripture icon
            Image(systemName: "book.fill")
                .font(Typography.Icon.xs)
                .foregroundStyle(Color("AppAccentAction"))

            // Reference text
            Text(reference.parsed.shortDisplayText)
                .font(Typography.Command.body)
                .fontWeight(.medium)
                .foregroundStyle(Color("AppTextPrimary"))

            // Divider
            Rectangle()
                .fill(Color("AppDivider"))
                .frame(width: Theme.Stroke.hairline, height: 16)

            // Go to passage button
            Button {
                HapticService.shared.selectionChanged()
                onGoToPassage(reference.parsed.location)
                onDismiss()
            } label: {
                Text("Go")
                    .font(Typography.Command.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("AppAccentAction"))
            }

            // Dismiss button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color("AppAccentAction").opacity(Theme.Opacity.divider), lineWidth: Theme.Stroke.hairline)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isVisible = true
            }
            startAutoDismiss()
        }
        .onDisappear {
            dismissTask?.cancel()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Detected reference: \(reference.parsed.displayText)")
        .accessibilityHint("Double tap Go to navigate to this passage")
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation(Theme.Animation.fade) {
            isVisible = false
        }
        // Delay actual removal to let animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }

    private func startAutoDismiss() {
        dismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(Self.autoDismissDelay))
            } catch {
                return // Cancelled or unexpected — exit cleanly
            }
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Reference Chip") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        if let book = Book.find(byId: 45) {
            CaptionReferenceChip(
                reference: CaptionReferenceState.DetectedReference(
                    id: UUID(),
                    parsed: ParsedReference(book: book, chapter: 8, verseStart: 1, verseEnd: nil),
                    canonicalId: "45.8.1",
                    detectedAt: Date()
                ),
                onGoToPassage: { _ in },
                onDismiss: {}
            )
        }
    }
}
