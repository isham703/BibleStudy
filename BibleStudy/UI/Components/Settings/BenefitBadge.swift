import SwiftUI

// MARK: - Benefit Badge
// Design Rationale: Displays subscription benefits with checkmark icon.
// Used in premium/scholar tier display to show included features.
// Flat styling with success color for checkmark.
// Stoic-Existential Renaissance design

struct BenefitBadge: View {
    let text: String
    let isIncluded: Bool

    init(_ text: String, isIncluded: Bool = true) {
        self.text = text
        self.isIncluded = isIncluded
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(Typography.Icon.xs)
                .foregroundStyle(isIncluded ? Color("FeedbackSuccess") : Color("AppTextSecondary"))

            Text(text)
                .font(Typography.Command.caption)
                .foregroundStyle(isIncluded ? Color("AppTextPrimary") : Color("AppTextSecondary"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text), \(isIncluded ? "included" : "not included")")
    }
}

// MARK: - Benefits Grid
// Convenience view for displaying multiple benefits in a grid

struct BenefitsGrid: View {
    let benefits: [String]
    let columns: Int

    init(benefits: [String], columns: Int = 2) {
        self.benefits = benefits
        self.columns = columns
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: columns),
            spacing: Theme.Spacing.xs
        ) {
            ForEach(benefits, id: \.self) { benefit in
                BenefitBadge(benefit)
            }
        }
    }
}

// MARK: - Feature Preview Row
// Used for showing locked features to free users

struct FeaturePreviewRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.Icon.xs)
                .foregroundStyle(Color("AppAccentAction"))
                .frame(width: 20)

            Text(text)
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppTextPrimary"))
        }
    }
}

// MARK: - Preview

#Preview("Benefit Badges") {
    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
        Text("Premium Benefits")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))

        BenefitsGrid(benefits: [
            "All translations",
            "Unlimited AI",
            "Unlimited notes",
            "Hebrew & Greek"
        ])

        Divider()

        Text("Individual Badges")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))

        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            BenefitBadge("Included feature", isIncluded: true)
            BenefitBadge("Not included", isIncluded: false)
        }

        Divider()

        Text("Feature Previews")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))

        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            FeaturePreviewRow(icon: "text.book.closed", text: "All Bible translations")
            FeaturePreviewRow(icon: "sparkles", text: "Unlimited AI insights")
            FeaturePreviewRow(icon: "note.text", text: "Unlimited notes")
        }
    }
    .padding()
    .background(Color.appSurface)
}
