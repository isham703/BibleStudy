import SwiftUI

// MARK: - Scripture Reference Detail Sheet
// Reveals cross-references and insights with scroll unfurling animation

struct ScriptureReferenceDetailSheet: View {
    let reference: SermonVerseReference
    @State private var appeared = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    // Header with verification badge
                    referenceHeader
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(Theme.Animation.stagger(index: 0), value: appeared)

                    // Rationale (why this reference matters)
                    if let rationale = reference.rationale {
                        rationaleSection(rationale)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                            .animation(Theme.Animation.stagger(index: 1), value: appeared)
                    }

                    // Cross-references (verified connections)
                    if let crossRefs = reference.crossReferences, !crossRefs.isEmpty {
                        crossReferencesSection(crossRefs)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 40)
                            .animation(Theme.Animation.stagger(index: 2), value: appeared)
                    }

                    // Bible insights
                    if let insights = reference.insights, !insights.isEmpty {
                        insightsSection(insights)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 50)
                            .animation(Theme.Animation.stagger(index: 3), value: appeared)
                    }

                    // Evidence trail (for verified refs)
                    if let verifiedBy = reference.verifiedBy, !verifiedBy.isEmpty {
                        evidenceSection(verifiedBy)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 60)
                            .animation(Theme.Animation.stagger(index: 4), value: appeared)
                    }

                    // Verification notes
                    if let notes = reference.verificationNotes, !notes.isEmpty {
                        notesSection(notes)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 70)
                            .animation(Theme.Animation.stagger(index: 5), value: appeared)
                    }

                    Spacer(minLength: 40)
                }
                .padding(Theme.Spacing.xxl)
            }
            .background(Color("AppBackground"))
            .navigationTitle(reference.reference)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("AccentBronze"))
                }
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var referenceHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "book.closed.fill")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color("AccentBronze"))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(reference.reference)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.appTextPrimary)

                HStack(spacing: Theme.Spacing.sm) {
                    if reference.isMentioned {
                        Label("Mentioned", systemImage: "quote.bubble")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AccentBronze"))
                    } else if let status = reference.verificationStatus {
                        HStack(spacing: Theme.Spacing.xs) {
                            VerificationStatusIndicator(status: status)
                            Text(statusLabel(for: status))
                                .font(Typography.Command.caption)
                                .foregroundStyle(statusColor(for: status))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
        )
    }

    // MARK: - Sections

    private func rationaleSection(_ rationale: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Why This Reference", icon: "lightbulb")

            Text(rationale)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.appTextPrimary)
                .padding()
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        }
    }

    private func crossReferencesSection(_ crossRefs: [EnrichedCrossRefSummary]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Related Passages", icon: "arrow.triangle.branch")

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(crossRefs) { crossRef in
                    HStack {
                        Image(systemName: "book.closed")
                            .font(Typography.Icon.xs)
                            .foregroundStyle(Color("AccentBronze"))

                        Text(crossRef.displayRef)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color.appTextPrimary)

                        Spacer()

                        if let weight = crossRef.weight {
                            Text("\(weight)%")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Color("AppSurface").opacity(Theme.Opacity.textSecondary))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                }
            }
        }
    }

    private func insightsSection(_ insights: [EnrichedInsightSummary]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Insights", icon: "sparkles")

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(insights) { insight in
                    HStack {
                        Image(systemName: "text.quote")
                            .font(Typography.Icon.xs)
                            .foregroundStyle(Color("AccentBronze"))

                        Text(insight.title)
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Color.appTextPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Color("AppSurface").opacity(Theme.Opacity.textSecondary))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
                }
            }
        }
    }

    private func evidenceSection(_ verifiedBy: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Verification Evidence", icon: "checkmark.seal")

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(verifiedBy, id: \.self) { sourceId in
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "arrow.right")
                            .font(Typography.Icon.xxs.weight(.medium))
                            .foregroundStyle(Color("FeedbackWarning"))

                        Text("Connected from \(formatCanonicalId(sourceId))")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            .padding()
            .background(Color("AccentBronze").opacity(Theme.Opacity.subtle / 2))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .stroke(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    private func notesSection(_ notes: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Notes", icon: "info.circle")

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(notes, id: \.self) { note in
                    Text(note)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .italic()
                }
            }
            .padding()
            .background(Color("AppSurface").opacity(Theme.Opacity.textSecondary))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.xs + 2) {
            Image(systemName: icon)
                .font(Typography.Icon.xs)
                .foregroundStyle(Color("AccentBronze"))

            Text(title)
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    private func statusLabel(for status: VerificationStatus) -> String {
        switch status {
        case .verified: return "Verified"
        case .partial: return "Valid Reference"
        case .unverified: return "AI-suggested"
        case .unknown: return ""
        }
    }

    private func statusColor(for status: VerificationStatus) -> Color {
        switch status {
        case .verified: return Color("AccentBronze")
        case .partial: return Color("AccentBronze").opacity(Theme.Opacity.pressed)
        case .unverified: return Color.appTextSecondary
        case .unknown: return Color.appTextSecondary
        }
    }

    private func formatCanonicalId(_ id: String) -> String {
        // Convert "43.3.16" to human-readable format
        if let components = ReferenceParser.parseCanonicalId(id),
           let book = Book.find(byId: components.bookId) {
            if let start = components.verseStart, let end = components.verseEnd {
                return "\(book.name) \(components.chapter):\(start)-\(end)"
            } else if let verse = components.verseStart {
                return "\(book.name) \(components.chapter):\(verse)"
            }
            return "\(book.name) \(components.chapter)"
        }
        return id
    }
}

// MARK: - Preview

#Preview("Detail Sheet") {
    ScriptureReferenceDetailSheet(
        reference: SermonVerseReference(
            reference: "Romans 8:28",
            bookId: 45,
            chapter: 8,
            verseStart: 28,
            verseEnd: 28,
            isMentioned: false,
            rationale: "This verse directly relates to the sermon's theme of God's providence in difficult times.",
            timestampSeconds: nil,
            verificationStatus: .verified,
            verifiedBy: ["43.3.16", "49.1.11"],
            crossReferences: [
                EnrichedCrossRefSummary(canonicalId: "1.50.20", displayRef: "Genesis 50:20", weight: 95),
                EnrichedCrossRefSummary(canonicalId: "24.29.11", displayRef: "Jeremiah 29:11", weight: 88)
            ]
        )
    )
}
