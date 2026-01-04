import SwiftUI

// MARK: - Personalized Insight Model

struct PersonalizedInsight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let content: String
    let relatedVerses: [VerseRange]
    let generatedAt: Date

    enum InsightType: String {
        case themeFromReading     // "You've been reading about faith..."
        case connectionDiscovered // "Did you notice the connection between..."
        case reflectionPrompt     // "Consider how this applies to..."
        case topicSuggestion      // "Based on your reading, you might enjoy..."

        var icon: String {
            switch self {
            case .themeFromReading: return "sparkles"
            case .connectionDiscovered: return "link"
            case .reflectionPrompt: return "thought.bubble"
            case .topicSuggestion: return "lightbulb"
            }
        }

        var label: String {
            switch self {
            case .themeFromReading: return "Theme"
            case .connectionDiscovered: return "Connection"
            case .reflectionPrompt: return "Reflection"
            case .topicSuggestion: return "Suggestion"
            }
        }
    }

    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        content: String,
        relatedVerses: [VerseRange] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.relatedVerses = relatedVerses
        self.generatedAt = generatedAt
    }
}

// MARK: - AI Insight Card

struct AIInsightCard_Legacy: View {
    let insight: PersonalizedInsight
    var onDismiss: (() -> Void)?
    var onExplore: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack(spacing: AppTheme.Spacing.sm) {
                // Sparkle icon with glow
                Image(systemName: insight.type.icon)
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.accentGold)
                    .shadow(color: Color.accentGold.opacity(AppTheme.Opacity.disabled), radius: 6, x: 0, y: 0)

                Text("Insight")
                    .font(Typography.UI.caption1)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(Color.accentGold)

                Spacer()

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Title
            Text(insight.title)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            // Content (expandable)
            Text(insight.content)
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(isExpanded ? nil : 3)
                .animation(AppTheme.Animation.standard, value: isExpanded)

            // Related verses
            if !insight.relatedVerses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(insight.relatedVerses, id: \.self) { range in
                            VerseChip(reference: range.reference)
                        }
                    }
                }
            }

            // Actions
            if let onExplore = onExplore {
                HStack {
                    Button(action: { isExpanded.toggle() }) {
                        Text(isExpanded ? "Show Less" : "Read More")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: onExplore) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("Explore")
                                .font(Typography.UI.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "arrow.right")
                                .font(Typography.UI.caption1)
                        }
                        .foregroundStyle(Color.accentGold)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentGold.opacity(AppTheme.Opacity.faint - 0.02),
                            Color.accentGold.opacity(AppTheme.Opacity.faint - 0.06),
                            Color.surfaceBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        // Decorative corner glow
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.accentGold.opacity(AppTheme.Opacity.light), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .offset(x: 40, y: -40)
                .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.accentGold.opacity(AppTheme.Opacity.lightMedium), lineWidth: AppTheme.Border.thin)
        )
        .shadow(color: Color.black.opacity(AppTheme.Opacity.faint - 0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Verse Chip

private struct VerseChip: View {
    let reference: String

    var body: some View {
        Text(reference)
            .font(Typography.UI.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Color.accentGold)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle))
            )
            .overlay(
                Capsule()
                    .stroke(Color.accentGold.opacity(AppTheme.Opacity.lightMedium), lineWidth: AppTheme.Border.thin)
            )
    }
}

// MARK: - For You Section

struct ForYouSection: View {
    let insight: PersonalizedInsight?
    var onSeeAll: (() -> Void)?
    var onDismiss: (() -> Void)?
    var onExplore: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HomeSectionHeader(title: "For You", onSeeAll: onSeeAll)

            if let insight = insight {
                AIInsightCard_Legacy(
                    insight: insight,
                    onDismiss: onDismiss,
                    onExplore: onExplore
                )
            } else {
                // Empty state
                ForYouEmptyCard()
            }
        }
    }
}

// MARK: - Empty State

private struct ForYouEmptyCard: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "sparkles")
                .font(Typography.Display.title2)
                .foregroundStyle(Color.accentGold.opacity(AppTheme.Opacity.heavy))

            Text("Insights based on your reading")
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            Text("Read a chapter to unlock personalized insights")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.surfaceBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Previews

#Preview("AI Insight Card Legacy") {
    AIInsightCard_Legacy(
        insight: PersonalizedInsight(
            type: .themeFromReading,
            title: "A Theme in Your Reading",
            content: "You've been exploring passages about faith this week. Notice how Hebrews 11 connects to your recent reading in Romans about justification by faith. This connection reveals a beautiful thread running through Scripture.",
            relatedVerses: [
                VerseRange(bookId: 58, chapter: 11, verseStart: 1, verseEnd: 1),
                VerseRange(bookId: 45, chapter: 5, verseStart: 1, verseEnd: 1),
                VerseRange(bookId: 48, chapter: 3, verseStart: 11, verseEnd: 11)
            ]
        ),
        onDismiss: {},
        onExplore: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("For You Section - With Insight") {
    ForYouSection(
        insight: PersonalizedInsight(
            type: .connectionDiscovered,
            title: "Interesting Connection",
            content: "The shepherd imagery in Psalm 23 connects beautifully to Jesus calling himself the Good Shepherd in John 10.",
            relatedVerses: [
                VerseRange(bookId: 19, chapter: 23, verseStart: 1, verseEnd: 6),
                VerseRange(bookId: 43, chapter: 10, verseStart: 11, verseEnd: 11)
            ]
        ),
        onSeeAll: {},
        onDismiss: {},
        onExplore: {}
    )
    .padding()
    .background(Color.appBackground)
}

#Preview("For You Section - Empty") {
    ForYouSection(insight: nil)
        .padding()
        .background(Color.appBackground)
}
