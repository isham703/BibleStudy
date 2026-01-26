//
//  ReflectBridgeCard.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Bridge interstitial between Read sections (1–5) and Reflect/Apply
//  sections (6–8) in the Study Guide. Signals the transition from
//  comprehension to response with a contemplative prompt and
//  navigation-toned action rows.
//
//  Typography: "REFLECT" header (tracked sans) + serif italic body
//  Visual: Bronze accent bar, tinted background (CentralThesisCallout pattern)
//

import SwiftUI

// MARK: - Reflect Bridge Card

struct ReflectBridgeCard: View {
    let notesViewModel: SermonNotesViewModel
    @Binding var scrollTarget: SermonSectionID?
    let isAwakened: Bool
    let delay: Double

    // MARK: - Row Data

    private struct BridgeRow: Identifiable {
        let id: SermonSectionID
        let icon: String
        let label: String
    }

    private var visibleRows: [BridgeRow] {
        let allRows: [BridgeRow] = [
            BridgeRow(id: .discussionQuestions, icon: "bubble.left.and.bubble.right", label: "Discussion questions"),
            BridgeRow(id: .applicationPoints, icon: "hand.raised", label: "Application points"),
            BridgeRow(id: .notableQuotes, icon: "quote.opening", label: "Notable quotes"),
        ]
        return allRows.filter { notesViewModel.isSectionVisible($0.id) }
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Bronze accent bar (CentralThesisCallout pattern)
            Rectangle()
                .fill(Color("AccentBronze"))
                .frame(width: 2)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header
                Text("REFLECT")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("AccentBronze"))

                // Contemplative body prompt
                Text("Let this settle. How does it speak to your life?")
                    .font(Typography.Scripture.quote)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineSpacing(Typography.Scripture.quoteLineSpacing)
                    .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

                // Navigation rows
                if !visibleRows.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(visibleRows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 {
                                Rectangle()
                                    .fill(Color("AppDivider"))
                                    .frame(height: Theme.Stroke.hairline)
                            }

                            Button {
                                HapticService.shared.lightTap()
                                scrollTarget = row.id
                            } label: {
                                HStack(spacing: Theme.Spacing.md) {
                                    Image(systemName: row.icon)
                                        .font(Typography.Icon.sm)
                                        .foregroundStyle(Color("AccentBronze"))
                                        .frame(width: Theme.Size.iconSize)

                                    Text(row.label)
                                        .font(Typography.Command.body)
                                        .foregroundStyle(Color("AppTextPrimary"))

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(Typography.Icon.xxs)
                                        .foregroundStyle(Color("TertiaryText"))
                                }
                                .frame(minHeight: Theme.Size.minTapTarget)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Jump to \(row.label)")
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
        )
        .ceremonialAppear(isAwakened: isAwakened, delay: delay)
    }
}

// MARK: - Preview

#Preview("Reflect Bridge Card") {
    struct PreviewContainer: View {
        @State private var scrollTarget: SermonSectionID?
        @State private var notesViewModel: SermonNotesViewModel

        init() {
            let sg = SermonStudyGuide(
                sermonId: UUID(),
                content: StudyGuideContent(
                    title: "The Power of Grace",
                    summary: "This sermon explores grace.",
                    keyThemes: ["Grace"],
                    centralThesis: nil,
                    keyTakeaways: [],
                    outline: [],
                    bibleReferencesMentioned: [],
                    bibleReferencesSuggested: [],
                    discussionQuestions: [
                        StudyQuestion(question: "How does grace change your life?", type: .application)
                    ],
                    reflectionPrompts: ["Consider extending grace this week."],
                    applicationPoints: ["Practice Sabbath rest."],
                    anchoredApplicationPoints: []
                )
            )
            self._notesViewModel = State(initialValue: SermonNotesViewModel(studyGuide: sg))
        }

        var body: some View {
            ScrollView {
                ReflectBridgeCard(
                    notesViewModel: notesViewModel,
                    scrollTarget: $scrollTarget,
                    isAwakened: true,
                    delay: 0.2
                )
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.xl)
            }
            .background(Color("AppBackground"))
            .onChange(of: scrollTarget) { _, target in
                if let target {
                    print("Scroll to: \(target)")
                    scrollTarget = nil
                }
            }
        }
    }

    return PreviewContainer()
}
