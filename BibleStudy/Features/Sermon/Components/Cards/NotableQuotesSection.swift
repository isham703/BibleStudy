//
//  NotableQuotesSection.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Phase 6: Notable Quotes Display (v2)
//
//  Highlights theologically significant quotes with gravitas.
//  Codex marginalia aesthetic with large decorative quotation marks.
//
//  Typography:
//  - Quote text: Scripture.prompt (24pt serif)
//  - Context: Command.caption with em-dash prefix
//
//  Motion: Theme.Animation.slowFade - NO springs
//

import Auth
import SwiftUI

// MARK: - Notable Quotes Section

/// Section displaying notable quotes from the sermon with decorative styling.
struct NotableQuotesSection: View {
    let quotes: [Quote]
    let sermonId: UUID
    let baseDelay: Double
    let isAwakened: Bool
    let onSeek: ((TimeInterval) -> Void)?

    /// Maximum number of quotes to display
    private let maxQuotes = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header
            sectionHeader

            // Quote cards
            if quotes.isEmpty {
                emptyState
            } else {
                ForEach(Array(quotes.prefix(maxQuotes).enumerated()), id: \.element.id) { index, quote in
                    NotableQuoteCard(
                        quote: quote,
                        sermonId: sermonId,
                        delay: baseDelay + 0.05 + Double(index) * 0.08,
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
            Image(systemName: "text.quote")
                .font(Typography.Icon.md)
                .foregroundStyle(Color("AccentBronze"))

            Text("Notable Quotes")
                .font(Typography.Command.body.weight(.medium))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Notable Quotes section")
        .ceremonialAppear(isAwakened: isAwakened, delay: baseDelay, includeDrift: false)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("No notable quotes identified")
            .font(Typography.Command.caption)
            .foregroundStyle(Color("TertiaryText"))
            .italic()
            .padding(.vertical, Theme.Spacing.sm)
            .ceremonialAppear(isAwakened: isAwakened, delay: baseDelay + 0.05, includeDrift: false)
    }
}

// MARK: - Notable Quote Card

/// Individual card for a notable quote with decorative marginalia styling.
private struct NotableQuoteCard: View {
    let quote: Quote
    let sermonId: UUID
    let delay: Double
    let isAwakened: Bool
    let onSeek: ((TimeInterval) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var engagementService: SermonEngagementService { .shared }

    /// Quote.id is already stable (derived from text content)
    private var targetId: String { quote.id }

    private var isFavorited: Bool {
        engagementService.engagements.contains {
            $0.engagementType == .favoriteQuote &&
            $0.targetId == targetId &&
            $0.sermonId == sermonId &&
            $0.isActive
        }
    }

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Quote with decorative mark
                quoteContent

                // Footer: Context and timestamp
                footerRow
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AccentBronze").opacity(0.03))
        )
    }

    // MARK: - Quote Content

    private var quoteContent: some View {
        ZStack(alignment: .topLeading) {
            // Large decorative quotation mark
            Text("\u{201C}")
                .font(.system(size: 48, weight: .regular, design: .serif))
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground))
                .offset(x: -4, y: -12)
                .accessibilityHidden(true)

            // Quote text
            Text(quote.text)
                .font(Typography.Scripture.prompt)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineSpacing(Typography.Scripture.promptLineSpacing)
                .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)
                .padding(.leading, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Footer Row

    private var footerRow: some View {
        HStack(alignment: .bottom) {
            // Context (if available)
            if let context = quote.context, !context.isEmpty {
                Text("— \(context)")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
                    .italic()
            }

            Spacer()

            // Favorite toggle
            Button {
                HapticService.shared.lightTap()
                Task {
                    guard let userId = SupabaseManager.shared.currentUser?.id else { return }
                    await engagementService.toggleFavorite(
                        userId: userId,
                        sermonId: sermonId,
                        type: .favoriteQuote,
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
            .accessibilityLabel(isFavorited ? "Unfavorite quote" : "Favorite quote")

            // Timestamp chip
            if let timestamp = quote.timestampSeconds {
                TimestampChip(timestamp: timestamp) {
                    onSeek?(timestamp)
                }
            }
        }
        .padding(.leading, Theme.Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Notable Quotes Section") {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            NotableQuotesSection(
                quotes: [
                    Quote(
                        text: "Grace is not a license to sin; it's the power to stop wanting to.",
                        timestampSeconds: 522,
                        context: "On the nature of grace"
                    ),
                    Quote(
                        text: "We do not work for acceptance; we work from acceptance. That changes everything.",
                        timestampSeconds: 1245,
                        context: "On identity in Christ"
                    ),
                    Quote(
                        text: "The cross doesn't make you better. It makes you new.",
                        timestampSeconds: 1890,
                        context: "On transformation"
                    )
                ],
                sermonId: UUID(),
                baseDelay: 0.2,
                isAwakened: true
            ) { timestamp in
                print("Seek to \(timestamp)")
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}

#Preview("Notable Quote - Single") {
    ScrollView {
        NotableQuotesSection(
            quotes: [
                Quote(
                    text: "When you finally understand that God's love is not contingent on your performance, you are free.",
                    timestampSeconds: 845,
                    context: nil
                )
            ],
            sermonId: UUID(),
            baseDelay: 0.2,
            isAwakened: true
        ) { _ in }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}

#Preview("Notable Quotes - Empty") {
    ScrollView {
        NotableQuotesSection(
            quotes: [],
            sermonId: UUID(),
            baseDelay: 0.2,
            isAwakened: true
        ) { _ in }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}
