import SwiftUI

// MARK: - Cross Reference Card
// Displays a cross-reference with optional "Why linked?" explanation

struct CrossRefCard: View {
    let crossRef: CrossReferenceDisplay
    var onTap: (() -> Void)?
    var onWhyLinked: (() async -> String)?

    @State private var isLoadingWhy = false
    @State private var whyLinked: String?
    @State private var showWhyLinked = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header
            HStack {
                Text(crossRef.reference)
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.scholarAccent)

                Spacer()

                // Relevance indicator
                RelevanceIndicator(weight: crossRef.weight)

                // Peek indicator
                Image(systemName: "eye.circle")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }

            // Preview text
            Text(crossRef.preview)
                .font(Typography.Scripture.body(size: 15))
                .foregroundStyle(Color.primaryText)
                .lineLimit(3)

            // Why Linked button/content
            if let whyLinked = whyLinked ?? crossRef.whyLinked {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Why linked:")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)

                    Text(whyLinked)
                        .font(Typography.UI.warmSubheadline)
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(.top, AppTheme.Spacing.xs)
            } else if let onWhyLinked = onWhyLinked {
                Button {
                    Task {
                        isLoadingWhy = true
                        whyLinked = await onWhyLinked()
                        isLoadingWhy = false
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        if isLoadingWhy {
                            ProgressView()
                                .scaleEffect(AppTheme.Scale.small)
                        } else {
                            Image(systemName: "questionmark.circle")
                        }
                        Text("Why linked?")
                    }
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.scholarAccent)
                }
                .disabled(isLoadingWhy)
            }
        }
        .padding()
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Relevance Indicator
struct RelevanceIndicator: View {
    let weight: Double

    var color: Color {
        if weight >= 0.9 { return .scholarAccent }
        if weight >= 0.7 { return .secondaryText }
        return .tertiaryText
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Double(index) / 3.0 < weight ? color : color.opacity(AppTheme.Opacity.medium))
                    .frame(width: AppTheme.ComponentSize.dotSmall, height: AppTheme.ComponentSize.dotSmall)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        CrossRefCard(
            crossRef: CrossReferenceDisplay(
                id: "1",
                reference: "John 1:4-5",
                preview: "In him was life; and the life was the light of men. And the light shineth in darkness...",
                weight: 0.95,
                whyLinked: nil
            )
        ) {
            print("Tapped")
        } onWhyLinked: {
            return "Both passages connect light with divine creative power."
        }

        CrossRefCard(
            crossRef: CrossReferenceDisplay(
                id: "2",
                reference: "2 Corinthians 4:6",
                preview: "For God, who commanded the light to shine out of darkness...",
                weight: 0.75,
                whyLinked: "Paul explicitly references Genesis 1:3 to describe spiritual enlightenment."
            )
        )
    }
    .padding()
    .background(Color.appBackground)
}
