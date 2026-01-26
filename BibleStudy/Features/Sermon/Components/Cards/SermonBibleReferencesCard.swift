//
//  SermonBibleReferencesCard.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Displays Bible references from the sermon:
//  - "Referenced in Sermon" (mentioned): Bronze-tinted chips in flow layout
//  - "Related Passages" (suggested): Expandable rows with verification UX
//
//  Uses existing components: ScriptureReferenceChip, VerificationStatusIndicator
//

import SwiftUI

// MARK: - Sermon Bible References Card

struct SermonBibleReferencesCard: View {
    let mentionedRefs: [SermonVerseReference]
    let suggestedRefs: [SermonVerseReference]
    let delay: Double
    let isAwakened: Bool

    // MARK: - Computed

    private var hasMentioned: Bool { !mentionedRefs.isEmpty }
    private var hasSuggested: Bool { !suggestedRefs.isEmpty }
    private var hasAnyRefs: Bool { hasMentioned || hasSuggested }

    // MARK: - Body

    var body: some View {
        if hasAnyRefs {
            SermonAtriumCard(delay: delay, isAwakened: isAwakened) {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Header
                    header

                    // Mentioned references
                    if hasMentioned {
                        mentionedSection
                    }

                    // Divider (if both sections present)
                    if hasMentioned && hasSuggested {
                        Rectangle()
                            .fill(Color("AppDivider"))
                            .frame(height: Theme.Stroke.hairline)
                    }

                    // Suggested references
                    if hasSuggested {
                        suggestedSection
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "book.closed")
                .font(Typography.Icon.md)
                .foregroundStyle(Color("AccentBronze"))

            Text("Scripture References")
                .font(Typography.Command.body.weight(.medium))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Scripture References section")
    }

    // MARK: - Mentioned Section

    private var mentionedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("REFERENCED IN SERMON")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            SermonFlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(mentionedRefs) { ref in
                    ScriptureReferenceChip(reference: ref, isMentioned: true)
                }
            }
        }
    }

    // MARK: - Suggested Section

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("RELATED PASSAGES")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            ForEach(suggestedRefs) { ref in
                SuggestedReferenceRow(reference: ref)
            }
        }
    }
}

// MARK: - Suggested Reference Row

/// Expandable row for suggested (AI-inferred) references with verification status
private struct SuggestedReferenceRow: View {
    let reference: SermonVerseReference
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Main row (always visible)
            Button {
                withAnimation(Theme.Animation.settle) {
                    isExpanded.toggle()
                }
            } label: {
                mainRow
            }
            .buttonStyle(.plain)

            // Expanded rationale
            if isExpanded, let rationale = reference.rationale {
                Text(rationale)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.leading, Theme.Spacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color("AppSurface"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
    }

    private var mainRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Verification indicator
            if let status = reference.verificationStatus {
                VerificationStatusIndicator(status: status)
            }

            // Reference text
            Text(reference.reference)
                .font(Typography.Command.label)
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()

            // Relation badge
            if let relation = reference.relation {
                relationBadge(relation)
            }

            // Expand indicator
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(Typography.Icon.xs)
                .foregroundStyle(Color("TertiaryText"))
        }
    }

    private func relationBadge(_ relation: CrossRefRelation) -> some View {
        HStack(spacing: 2) {
            Image(systemName: relation.icon)
                .font(Typography.Icon.xxs)

            Text(relation.displayName)
                .font(Typography.Command.meta)
        }
        .foregroundStyle(relationColor(relation))
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(relationColor(relation).opacity(Theme.Opacity.subtle))
        )
    }

    private func relationColor(_ relation: CrossRefRelation) -> Color {
        switch relation {
        case .supports: return Color("FeedbackSuccess")
        case .contrasts: return Color("FeedbackWarning")
        case .fulfills: return Color("AccentBronze")
        case .exemplifies: return Color("FeedbackInfo")
        case .clarifies: return Color("FeedbackInfo")
        case .warns: return Color("FeedbackWarning")
        case .unknown: return Color("TertiaryText")
        }
    }
}

// MARK: - Preview

#Preview("Bible References Card") {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            SermonBibleReferencesCard(
                mentionedRefs: [
                    SermonVerseReference(
                        reference: "John 3:16",
                        bookId: 43, chapter: 3, verseStart: 16,
                        isMentioned: true,
                        timestampSeconds: 120
                    ),
                    SermonVerseReference(
                        reference: "Romans 8:28",
                        bookId: 45, chapter: 8, verseStart: 28,
                        isMentioned: true,
                        timestampSeconds: 340
                    ),
                    SermonVerseReference(
                        reference: "Ephesians 2:8-9",
                        bookId: 49, chapter: 2, verseStart: 8, verseEnd: 9,
                        isMentioned: true,
                        timestampSeconds: 520
                    )
                ],
                suggestedRefs: [
                    SermonVerseReference(
                        reference: "Romans 5:1-2",
                        bookId: 45, chapter: 5, verseStart: 1, verseEnd: 2,
                        isMentioned: false,
                        rationale: "Justification by faith leads to peace with God - a direct connection to the sermon's theme of grace-based identity.",
                        verificationStatus: .verified,
                        relation: .supports
                    ),
                    SermonVerseReference(
                        reference: "Galatians 2:16",
                        bookId: 48, chapter: 2, verseStart: 16,
                        isMentioned: false,
                        rationale: "Clarifies that no one is justified by works of the law, but through faith in Christ.",
                        verificationStatus: .partial,
                        relation: .clarifies
                    ),
                    SermonVerseReference(
                        reference: "Titus 3:5",
                        bookId: 56, chapter: 3, verseStart: 5,
                        isMentioned: false,
                        rationale: "Emphasizes salvation not by works but by God's mercy - reinforcing the sermon's grace message.",
                        verificationStatus: .unverified,
                        relation: .supports
                    )
                ],
                delay: 0.2,
                isAwakened: true
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}
