import SwiftUI

// MARK: - Living Commentary View
// Chip-Based Selection Variant
// Dynamic marginalia that adapts to your reading
// Aesthetic: Editorial, layered, scholarly yet accessible

struct LivingCommentaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var selectedWord: String?
    @State private var showingInsight = false
    @State private var activeInsightIndex = 0
    @State private var highlightedPhrase: String?

    // Use shared demo data
    private let verseText = LivingCommentaryDemoData.verseText
    private let reference = LivingCommentaryDemoData.verseReference
    private let insights = LivingCommentaryDemoData.insights

    var body: some View {
        ZStack {
            // Reading background
            readingBackground

            VStack(spacing: 0) {
                // Header
                header

                // Main content - vertical layout for mobile
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Chapter heading
                        chapterHeading
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)

                        // Interactive verse text
                        interactiveVerseText
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

                        // Marginalia section (appears when phrase selected)
                        if let phrase = highlightedPhrase,
                           let insight = insights.first(where: { $0.phrase == phrase }) {
                            marginaliaCard(insight: insight, isActive: true)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(y: 20)),
                                    removal: .opacity
                                ))
                        } else {
                            // Tap hint
                            HStack(spacing: 6) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 12))
                                Text("Tap a phrase above to explore")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(Color(hex: "6366f1").opacity(0.5))
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
        }
    }

    // MARK: - Background

    private var readingBackground: some View {
        ZStack {
            // Warm paper tone
            Color(hex: "faf8f5")

            // Subtle texture
            Rectangle()
                .fill(Color(hex: "1a1a1a").opacity(0.02))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "1a1a1a").opacity(0.5))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("LIVING COMMENTARY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "6366f1"))

                Text(reference)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "1a1a1a").opacity(0.5))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "1a1a1a").opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 24)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Chapter Heading

    private var chapterHeading: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE GOSPEL OF")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color(hex: "1a1a1a").opacity(0.4))

            Text("John")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: "1a1a1a"))

            Text("Chapter 1")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "6366f1"))
        }
    }

    // MARK: - Interactive Verse Text

    private var interactiveVerseText: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Verse number and text
            HStack(alignment: .top, spacing: 12) {
                Text("1")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "6366f1"))
                    .frame(width: 16)

                // Full verse text with highlighted phrase
                buildVerseText()
            }

            // Tappable phrase chips
            phraseChips
        }
    }

    @ViewBuilder
    private func buildVerseText() -> some View {
        let activePhrase = highlightedPhrase

        Text(attributedVerse(highlighting: activePhrase))
            .font(.system(size: 19, weight: .regular, design: .serif))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func attributedVerse(highlighting phrase: String?) -> AttributedString {
        var result = AttributedString("In the beginning was the Word, and the Word was with God, and the Word was God.")
        result.font = .system(size: 19, weight: .regular, design: .serif)
        result.foregroundColor = Color(hex: "1a1a1a")

        // Highlight phrases
        for insight in insights {
            if let range = result.range(of: insight.phrase) {
                if phrase == insight.phrase {
                    // Active phrase - full highlight
                    result[range].foregroundColor = Color(hex: "6366f1")
                    result[range].backgroundColor = Color(hex: "6366f1").opacity(0.15)
                    result[range].underlineStyle = .single
                } else {
                    // Inactive phrase - subtle underline only
                    result[range].underlineStyle = .single
                }
            }
        }

        return result
    }

    private var phraseChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(insights, id: \.phrase) { insight in
                    Button(action: {
                        withAnimation(.spring(duration: 0.3)) {
                            if highlightedPhrase == insight.phrase {
                                highlightedPhrase = nil
                            } else {
                                highlightedPhrase = insight.phrase
                                activeInsightIndex = insights.firstIndex(where: { $0.phrase == insight.phrase }) ?? 0
                            }
                        }
                    }) {
                        Text(insight.phrase)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(highlightedPhrase == insight.phrase ? .white : Color(hex: "6366f1"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(highlightedPhrase == insight.phrase ? Color(hex: "6366f1") : Color(hex: "6366f1").opacity(0.1))
                            )
                    }
                }
            }
        }
    }

    // MARK: - Marginalia Card

    private func marginaliaCard(insight: MarginaliaInsight, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Type indicator
            HStack(spacing: 10) {
                Image(systemName: insight.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(insight.type.color)

                Text(insight.type.label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(insight.type.color)
                    .textCase(.uppercase)
            }

            // Title
            Text(insight.title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: "1a1a1a"))

            // Content
            Text(insight.content)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "1a1a1a").opacity(0.75))
                .lineSpacing(6)

            // Phrase reference
            HStack(spacing: 8) {
                Rectangle()
                    .fill(insight.type.color)
                    .frame(width: 3, height: 14)

                Text("\"\(insight.phrase)\"")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(Color(hex: "1a1a1a").opacity(0.5))
                    .italic()
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "f5f3f0"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(insight.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    LivingCommentaryView()
}
