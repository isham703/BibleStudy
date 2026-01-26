//
//  AnchoredInsightCard.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Displays an anchored insight with:
//  - Title (SF Pro semibold) + optional TimestampChip
//  - Insight text (New York serif body)
//  - Supporting quote (italic, indented, lighter opacity)
//  - Scripture reference chips
//
//  The TimestampChip is the ONLY seek target to avoid scroll conflicts.
//

import Auth
import SwiftUI

// MARK: - Anchored Insight Card

struct AnchoredInsightCard: View {
    let insight: AnchoredInsight
    let sermonId: UUID
    let delay: Double
    let isAwakened: Bool
    let onSeek: ((TimeInterval) -> Void)?

    @Environment(AppState.self) private var appState

    private var engagementService: SermonEngagementService { .shared }

    private var targetId: String {
        SermonEngagement.fingerprint(
            sermonId: sermonId,
            type: .favoriteInsight,
            content: insight.title, insight.insight
        )
    }

    private var isFavorited: Bool {
        engagementService.isFavorited(type: .favoriteInsight, targetId: targetId)
    }

    // MARK: - Initialization

    init(
        insight: AnchoredInsight,
        sermonId: UUID,
        delay: Double,
        isAwakened: Bool,
        onSeek: ((TimeInterval) -> Void)? = nil
    ) {
        self.insight = insight
        self.sermonId = sermonId
        self.delay = delay
        self.isAwakened = isAwakened
        self.onSeek = onSeek
    }

    // MARK: - Body

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header: Title + Timestamp
                headerRow

                // Insight text
                Text(insight.insight)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

                // Supporting quote
                supportingQuoteView

                // Scripture references (if any)
                if let references = insight.references, !references.isEmpty {
                    scriptureReferencesView(references)
                }
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            // Title
            Text(insight.title)
                .font(Typography.Command.body.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()

            // Favorite toggle
            Button {
                HapticService.shared.lightTap()
                Task {
                    guard let userId = SupabaseManager.shared.currentUser?.id else { return }
                    await engagementService.toggleFavorite(
                        userId: userId,
                        sermonId: sermonId,
                        type: .favoriteInsight,
                        targetId: targetId
                    )
                }
            } label: {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(isFavorited ? Color("AccentBronze") : Color("TertiaryText"))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(SupabaseManager.shared.currentUser == nil)
            .accessibilityLabel(isFavorited ? "Unfavorite \(insight.title)" : "Favorite \(insight.title)")
            .accessibilityHint(SupabaseManager.shared.currentUser == nil ? "Sign in to favorite insights" : "")

            // Timestamp chip (primary seek target)
            if let timestamp = insight.timestampSeconds {
                TimestampChip(timestamp: timestamp) {
                    HapticService.shared.lightTap()
                    onSeek?(timestamp)
                }
            }
        }
    }

    // MARK: - Supporting Quote

    private var supportingQuoteView: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Quote mark indicator
            Text("\u{201C}")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.disabled))
                .offset(y: -4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(insight.supportingQuote)
                    .font(Typography.Scripture.quote)
                    .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))
                    .lineSpacing(Typography.Scripture.quoteLineSpacing)
                    .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)
            }
        }
        .padding(.leading, Theme.Spacing.sm)
    }

    // MARK: - Scripture References

    private func scriptureReferencesView(_ references: [String]) -> some View {
        SermonFlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(references, id: \.self) { reference in
                Button {
                    HapticService.shared.lightTap()
                    openScriptureInBible(reference)
                } label: {
                    scriptureChipLabel(reference)
                        .frame(minHeight: Theme.Size.minTapTarget)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(reference) in Bible")
            }
        }
    }

    private func scriptureChipLabel(_ reference: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "book.closed")
                .font(Typography.Icon.xs)

            Text(reference)
                .font(Typography.Command.label)
        }
        .foregroundStyle(Color("AccentBronze"))
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
        )
        .overlay(
            Capsule()
                .stroke(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
        )
    }

    private func openScriptureInBible(_ reference: String) {
        let result = ReferenceParser.parse(reference)
        guard case .success(let parsed) = result else { return }
        let location = parsed.location
        appState.saveLocation(location)
        if let verse = parsed.verseStart {
            appState.lastScrolledVerse = verse
        }
        NotificationCenter.default.post(
            name: .deepLinkNavigationRequested,
            object: nil,
            userInfo: ["location": location]
        )
    }
}

// MARK: - Key Takeaways Section

/// Container for displaying multiple anchored insights (key takeaways)
struct KeyTakeawaysSection: View {
    let takeaways: [AnchoredInsight]
    let sermonId: UUID
    let baseDelay: Double
    let isAwakened: Bool
    let onSeek: ((TimeInterval) -> Void)?

    /// Maximum number of takeaways to display
    private let maxTakeaways = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            sectionHeader

            // Takeaway cards (max 3)
            if takeaways.isEmpty {
                emptyState
            } else {
                ForEach(Array(takeaways.prefix(maxTakeaways).enumerated()), id: \.element.id) { index, takeaway in
                    AnchoredInsightCard(
                        insight: takeaway,
                        sermonId: sermonId,
                        delay: baseDelay + Double(index) * 0.06,
                        isAwakened: isAwakened,
                        onSeek: onSeek
                    )
                }
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lightbulb")
                .font(Typography.Icon.md)
                .foregroundStyle(Color("AccentBronze"))

            Text("Key Takeaways")
                .font(Typography.Command.body.weight(.medium))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Key Takeaways section")
        .ceremonialAppear(isAwakened: isAwakened, delay: baseDelay - 0.05, includeDrift: false)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("No key takeaways identified")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("TertiaryText"))
            .italic()
            .padding(.vertical, Theme.Spacing.sm)
            .ceremonialAppear(isAwakened: isAwakened, delay: baseDelay, includeDrift: false)
    }
}

// MARK: - Preview

#Preview("Anchored Insight Card") {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            AnchoredInsightCard(
                insight: AnchoredInsight(
                    title: "Grace Transforms Identity",
                    insight: "The believer's identity shifts from performance to position - not what we do, but who we are in Christ.",
                    supportingQuote: "When you understand grace, you stop trying to earn what you have already received through faith.",
                    timestampSeconds: 154,
                    references: ["John 3:16", "Ephesians 2:8-9"]
                ),
                sermonId: UUID(),
                delay: 0.2,
                isAwakened: true
            ) { timestamp in
                print("Seek to \(timestamp)")
            }

            AnchoredInsightCard(
                insight: AnchoredInsight(
                    title: "Rest in Finished Work",
                    insight: "The cross declares 'It is finished' - our striving adds nothing to Christ's completed work.",
                    supportingQuote: "We do not work for acceptance; we work from acceptance.",
                    timestampSeconds: 423,
                    references: ["Romans 5:1"]
                ),
                sermonId: UUID(),
                delay: 0.3,
                isAwakened: true
            ) { _ in }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}

#Preview("Key Takeaways Section") {
    ScrollView {
        KeyTakeawaysSection(
            takeaways: [
                AnchoredInsight(
                    title: "Grace Transforms Identity",
                    insight: "The believer's identity shifts from performance to position.",
                    supportingQuote: "When you understand grace, you stop trying to earn...",
                    timestampSeconds: 154,
                    references: ["John 3:16"]
                ),
                AnchoredInsight(
                    title: "Rest in Finished Work",
                    insight: "The cross declares 'It is finished'.",
                    supportingQuote: "We do not work for acceptance; we work from acceptance.",
                    timestampSeconds: 423
                ),
                AnchoredInsight(
                    title: "Love as Response",
                    insight: "Obedience flows from gratitude, not obligation.",
                    supportingQuote: "We love because He first loved us.",
                    timestampSeconds: 612,
                    references: ["1 John 4:19"]
                )
            ],
            sermonId: UUID(),
            baseDelay: 0.3,
            isAwakened: true
        ) { timestamp in
            print("Seek to \(timestamp)")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}
