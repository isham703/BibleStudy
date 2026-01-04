import SwiftUI

// MARK: - Cross Reference Peek Sheet
// Shows an inline preview of a cross-reference verse without navigating away
// Allows the user to read the verse in context before deciding to navigate

struct CrossRefPeekSheet: View {
    let crossRef: CrossReferenceDisplay
    let onNavigate: () -> Void
    let onLoadWhyLinked: (() async -> String)?

    @Environment(\.dismiss) private var dismiss
    @State private var isLoadingWhy = false
    @State private var whyLinked: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Verse Reference Header
                    referenceHeader

                    // Full Verse Text
                    verseTextSection

                    // Why Linked Section
                    whyLinkedSection

                    // Navigation Action
                    navigateButton
                }
                .padding()
            }
            .background(Color.surfaceBackground)
            .navigationTitle("Cross-Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Reference Header

    private var referenceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(crossRef.reference)
                    .font(Typography.UI.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentGold)

                // Direction indicator
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: crossRef.isIncoming ? "arrow.left.circle" : "arrow.right.circle")
                        .font(Typography.UI.caption1)
                    Text(crossRef.isIncoming ? "References this passage" : "Referenced from this passage")
                        .font(Typography.UI.caption1)
                }
                .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            // Relevance indicator
            RelevanceIndicator(weight: crossRef.weight)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.elevatedBackground)
        )
    }

    // MARK: - Verse Text Section

    private var verseTextSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "text.quote")
                    .foregroundStyle(Color.accentBlue)
                Text("Verse Text")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.accentBlue)
            }

            Text(crossRef.preview)
                .font(Typography.Scripture.body(size: 17))
                .foregroundStyle(Color.primaryText)
                .lineSpacing(6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.accentBlue.opacity(AppTheme.Opacity.lightMedium), lineWidth: AppTheme.Border.thin)
        )
    }

    // MARK: - Why Linked Section

    @ViewBuilder
    private var whyLinkedSection: some View {
        let linkedText = whyLinked ?? crossRef.whyLinked

        if let linkedText = linkedText {
            // Show the explanation
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "link.circle")
                        .foregroundStyle(Color.highlightPurple)
                    Text("Why Linked")
                        .font(Typography.UI.caption1Bold)
                        .foregroundStyle(Color.highlightPurple)
                }

                Text(linkedText)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.highlightPurple.opacity(AppTheme.Opacity.faint))
            )
        } else if let onLoadWhyLinked = onLoadWhyLinked {
            // Show button to load explanation
            Button {
                Task {
                    isLoadingWhy = true
                    whyLinked = await onLoadWhyLinked()
                    isLoadingWhy = false
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    if isLoadingWhy {
                        ProgressView()
                            .scaleEffect(AppTheme.Scale.reduced)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isLoadingWhy ? "Analyzing connection..." : "Why are these verses linked?")
                        .font(Typography.UI.subheadline)
                }
                .foregroundStyle(Color.highlightPurple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.highlightPurple.opacity(AppTheme.Opacity.subtle))
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoadingWhy)
        }
    }

    // MARK: - Navigate Button

    private var navigateButton: some View {
        Button {
            dismiss()
            // Small delay to let sheet dismiss before navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onNavigate()
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(Typography.UI.title3)
                Text("Go to \(crossRef.reference)")
                    .font(Typography.UI.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.accentGold)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, AppTheme.Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    CrossRefPeekSheet(
        crossRef: CrossReferenceDisplay(
            id: "1",
            reference: "John 1:4-5",
            preview: "In him was life; and the life was the light of men. And the light shineth in darkness; and the darkness comprehended it not.",
            weight: 0.95,
            whyLinked: nil,
            targetRange: VerseRange(bookId: 43, chapter: 1, verseStart: 4, verseEnd: 5)
        ),
        onNavigate: { print("Navigate") },
        onLoadWhyLinked: {
            try? await Task.sleep(for: .seconds(1))
            return "Both passages describe light as a symbol of divine presence and creative power. Genesis speaks of physical light created by God, while John uses light metaphorically to describe Christ as the source of spiritual life and understanding."
        }
    )
}
