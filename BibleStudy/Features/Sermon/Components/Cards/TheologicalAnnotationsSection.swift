//
//  TheologicalAnnotationsSection.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Phase 4: Theological Annotations (v2)
//
//  Surfaces doctrine connections with transcript grounding.
//  Collapsed by default as advanced AI-suggested content.
//
//  Typography:
//  - Doctrine name: Editorial header with tracking (all caps)
//  - Insight: Scripture.body (serif)
//  - Quote: Scripture.quote (italic serif)
//
//  Motion: Theme.Animation.settle - NO springs
//

import Auth
import SwiftUI

// MARK: - Theological Annotations Section

/// Collapsible section displaying theological depth annotations.
/// Each annotation connects a doctrine to sermon content with supporting quotes.
struct TheologicalAnnotationsSection: View {
    let annotations: [AnchoredInsight]
    let sermonId: UUID
    let baseDelay: Double
    let isAwakened: Bool
    let onSeek: ((TimeInterval) -> Void)?

    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section header with toggle
            sectionHeader

            // Content (collapsed by default)
            if isExpanded {
                expandedContent
            } else {
                collapsedPreview
            }
        }
        .ceremonialAppear(isAwakened: isAwakened, delay: baseDelay, includeDrift: false)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        Button {
            HapticService.shared.lightTap()
            withAnimation(reduceMotion ? nil : Theme.Animation.settle) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "building.columns")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color("AccentBronze"))

                Text("Theological Depth")
                    .font(Typography.Command.body.weight(.medium))
                    .foregroundStyle(Color("AppTextPrimary"))

                Spacer()

                // AI badge
                Text("AI")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                    )

                // Expand/collapse chevron
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Theological Depth section")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
        .accessibilityAddTraits([.isButton, .isHeader])
    }

    // MARK: - Collapsed Preview

    private var collapsedPreview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let first = annotations.first {
                Text(first.title.uppercased())
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))

                Text(first.insight)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(2)
            }

            if annotations.count > 1 {
                Text("+\(annotations.count - 1) more annotation\(annotations.count > 2 ? "s" : "")")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AccentBronze"))
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface").opacity(Theme.Opacity.subtle))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                )
        )
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ForEach(Array(annotations.enumerated()), id: \.element.id) { index, annotation in
                TheologicalAnnotationCard(
                    annotation: annotation,
                    sermonId: sermonId,
                    delay: baseDelay + 0.05 + Double(index) * 0.06,
                    isAwakened: isAwakened,
                    onSeek: onSeek
                )
            }
        }
    }
}

// MARK: - Theological Annotation Card

/// Individual card for a theological annotation with doctrine header styling.
private struct TheologicalAnnotationCard: View {
    let annotation: AnchoredInsight
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
            content: annotation.title, annotation.insight
        )
    }

    private var isFavorited: Bool {
        engagementService.isFavorited(type: .favoriteInsight, targetId: targetId)
    }

    var body: some View {
        SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Doctrine name (editorial header style)
                doctrineHeader

                // Separator
                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(height: Theme.Stroke.hairline)

                // Insight (serif body)
                Text(annotation.insight)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

                // Supporting quote with timestamp
                if !annotation.supportingQuote.isEmpty {
                    supportingQuoteView
                }

                // Scripture references
                if let references = annotation.references, !references.isEmpty {
                    scriptureReferencesView(references)
                }
            }
        }
    }

    // MARK: - Doctrine Header

    private var doctrineHeader: some View {
        HStack(alignment: .center) {
            Text(annotation.title.uppercased())
                .font(Typography.Command.label.weight(.medium))
                .tracking(Typography.Editorial.labelTracking)
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
            .accessibilityLabel(isFavorited ? "Unfavorite \(annotation.title)" : "Favorite \(annotation.title)")

            // Timestamp chip
            if let timestamp = annotation.timestampSeconds {
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
            // Decorative quote mark
            Text("\u{201C}")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.disabled))
                .offset(y: -4)
                .accessibilityHidden(true)

            Text(annotation.supportingQuote)
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))
                .lineSpacing(Typography.Scripture.quoteLineSpacing)
                .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)
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

// MARK: - Preview

#Preview("Theological Annotations Section") {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            TheologicalAnnotationsSection(
                annotations: [
                    AnchoredInsight(
                        title: "Justification by Faith",
                        insight: "The sermon connects Paul's doctrine of justification to the believer's daily identity, emphasizing that righteousness is imputed, not achieved.",
                        supportingQuote: "When the speaker says 'you are declared righteous,' he echoes the forensic language of Romans 5:1, where justification is a legal verdict, not a moral achievement.",
                        timestampSeconds: 765,
                        references: ["Romans 5:1", "Galatians 2:16"]
                    ),
                    AnchoredInsight(
                        title: "Covenant Faithfulness",
                        insight: "Explores God's hesed love as the foundation for the believer's security, drawing from Old Testament covenant language.",
                        supportingQuote: "God's covenant love—His hesed—is not contingent on our performance. It flows from His character, not our conduct.",
                        timestampSeconds: 1423,
                        references: ["Psalm 136:1", "Lamentations 3:22-23"]
                    ),
                    AnchoredInsight(
                        title: "Sanctification as Process",
                        insight: "Distinguishes between positional holiness (already complete in Christ) and practical holiness (ongoing transformation by the Spirit).",
                        supportingQuote: "You are already holy in God's eyes through Christ. Now the Spirit works to make your daily life match your divine position.",
                        timestampSeconds: 2156
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

#Preview("Theological Annotations - Single") {
    ScrollView {
        TheologicalAnnotationsSection(
            annotations: [
                AnchoredInsight(
                    title: "Grace Alone",
                    insight: "The sermon emphasizes sola gratia—salvation by grace alone—as the Reformation's central insight.",
                    supportingQuote: "We contribute nothing to our salvation except the sin that made it necessary.",
                    timestampSeconds: 512,
                    references: ["Ephesians 2:8-9"]
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
