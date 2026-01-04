import SwiftUI

// MARK: - Interpretation Card
// Displays structured interpretation with multiple sections

struct InterpretationCard: View {
    let interpretation: InterpretationResult

    @State private var selectedMode: InterpretationMode = .plain

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Mode Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(InterpretationMode.allCases, id: \.self) { mode in
                        ModeButton(
                            mode: mode,
                            isSelected: selectedMode == mode
                        ) {
                            withAnimation(AppTheme.Animation.quick) {
                                selectedMode = mode
                            }
                        }
                    }
                }
            }

            // Plain Meaning
            InterpretationSection(
                title: "Plain Meaning",
                icon: "text.alignleft",
                content: interpretation.plainMeaning
            )

            // Context
            InterpretationSection(
                title: "Context",
                icon: "arrow.left.and.right",
                content: interpretation.context
            )

            // Key Terms
            if !interpretation.keyTerms.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    SectionHeader(title: "Key Terms", icon: "character.book.closed")

                    FlowLayout(spacing: AppTheme.Spacing.sm) {
                        ForEach(interpretation.keyTerms, id: \.self) { term in
                            KeyTermChip(text: term)
                        }
                    }
                }
            }

            // Cross References
            if !interpretation.crossRefs.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    SectionHeader(title: "Cross-References", icon: "arrow.triangle.branch")

                    FlowLayout(spacing: AppTheme.Spacing.sm) {
                        ForEach(interpretation.crossRefs, id: \.self) { ref in
                            CrossRefChip(reference: ref)
                        }
                    }
                }
            }

            // Interpretation Notes (with uncertainty indicator)
            if interpretation.hasUncertainty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color.warning)
                        Text("Interpretation Notes")
                            .font(Typography.UI.warmSubheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Text(interpretation.interpretationNotes)
                        .font(Typography.UI.warmBody)
                        .foregroundStyle(Color.secondaryText)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .fill(Color.warning.opacity(AppTheme.Opacity.subtle))
                        )
                }
            }

            // Reflection Prompt (optional)
            if let prompt = interpretation.reflectionPrompt {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    SectionHeader(title: "Reflection", icon: "heart")

                    Text(prompt)
                        .font(Typography.UI.warmBody)
                        .foregroundStyle(Color.primaryText)
                        .italic()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .fill(Color.accentRose.opacity(AppTheme.Opacity.subtle))
                        )
                }
            }

            // Trust UX: Show Why Expander
            if let reasoning = interpretation.reasoning, !reasoning.isEmpty {
                ShowWhyExpander(reasoning: reasoning)
            }

            // Trust UX: Different Views Section
            if let views = interpretation.alternativeViews, !views.isEmpty {
                DifferentViewsSection(views: views)
            }

            // Trust UX: Grounding Sources
            GroundingSourcesRow(sources: interpretation.groundingSources)

            // Report Issue
            ReportIssueButton()
        }
    }
}

// MARK: - Interpretation Mode
enum InterpretationMode: String, CaseIterable {
    case plain
    case historical
    case literary
    case devotional

    var title: String {
        switch self {
        case .plain: return "Plain"
        case .historical: return "Historical"
        case .literary: return "Literary"
        case .devotional: return "Devotional"
        }
    }
}

// MARK: - Mode Button
struct ModeButton: View {
    let mode: InterpretationMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode.title)
                .font(Typography.UI.chipLabel)
                .foregroundStyle(isSelected ? .white : Color.primaryText)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentGold : Color.surfaceBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interpretation Section
struct InterpretationSection: View {
    let title: String
    let icon: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: title, icon: icon)

            Text(content)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)
                .lineSpacing(4)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentGold)
            Text(title)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.secondaryText)
        }
    }
}

// MARK: - Key Term Chip
struct KeyTermChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typography.UI.caption1)
            .foregroundStyle(Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
    }
}

// MARK: - Cross Ref Chip
struct CrossRefChip: View {
    let reference: String

    var body: some View {
        Text(reference)
            .font(Typography.UI.caption1)
            .foregroundStyle(Color.accentGold)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
            )
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        InterpretationCard(
            interpretation: InterpretationResult(
                plainMeaning: "God spoke and light came into existence, demonstrating His power over creation.",
                context: "This is the first of God's creative acts, establishing the pattern of divine speech.",
                keyTerms: ["Light (אוֹר)", "Let there be (יְהִי)"],
                crossRefs: ["John 1:4-5", "2 Cor 4:6"],
                interpretationNotes: "Interpretations vary on whether this 'light' is the same as sunlight (v.14).",
                reflectionPrompt: "How does God's creative word speak into the darkness of your life?",
                hasUncertainty: true,
                reasoning: [
                    ReasoningPoint(phrase: "Let there be", explanation: "Jussive form shows divine command."),
                    ReasoningPoint(phrase: "and there was", explanation: "Immediate fulfillment shows God's power.")
                ],
                alternativeViews: [
                    AlternativeView(viewName: "Cosmic Light View", summary: "Light distinct from sun.", traditions: nil),
                    AlternativeView(viewName: "Functional View", summary: "Sun began functioning on Day 4.", traditions: nil)
                ]
            )
        )
        .padding()
    }
    .background(Color.appBackground)
}
