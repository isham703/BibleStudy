import SwiftUI

// MARK: - Phrase Reveal View
// Tap-to-reveal words for the Connect phase
// Uses FlowLayout for natural word wrapping

struct PhraseRevealView: View {
    let phrase: String
    @Binding var revealedWords: Set<Int>
    let accentColor: Color
    let style: PhraseRevealStyle
    let onWordRevealed: ((Int) -> Void)?
    let onAllRevealed: (() -> Void)?

    enum PhraseRevealStyle {
        case candlelit   // Warm glow, ignite effect
        case scholarly   // Clean underline draw
        case celestial   // Particle burst, stellar effect
    }

    private var words: [String] {
        phrase.split(separator: " ").map(String.init)
    }

    var body: some View {
        VStack(spacing: HomeShowcaseTheme.Spacing.lg) {
            FlowLayout(spacing: HomeShowcaseTheme.Spacing.sm) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    wordButton(index: index, word: word)
                }
            }
            .padding(.horizontal, HomeShowcaseTheme.Spacing.xxl)

            // Instruction text
            Text("Tap each word to reveal")
                .font(.system(size: 12))
                .foregroundStyle(style == .scholarly ? Color.footnoteGray : Color.white.opacity(0.4))
        }
    }

    @ViewBuilder
    private func wordButton(index: Int, word: String) -> some View {
        let isRevealed = revealedWords.contains(index)

        Button(action: {
            guard !isRevealed else { return }

            withAnimation(HomeShowcaseTheme.Animation.sacredSpring) {
                revealedWords.insert(index)
            }
            onWordRevealed?(index)

            // Check if all words are revealed
            if revealedWords.count == words.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onAllRevealed?()
                }
            }
        }) {
            Group {
                switch style {
                case .candlelit:
                    candlelitWord(word: word, isRevealed: isRevealed)
                case .scholarly:
                    scholarlyWord(word: word, isRevealed: isRevealed)
                case .celestial:
                    celestialWord(word: word, isRevealed: isRevealed)
                }
            }
        }
        .accessibilityLabel(isRevealed ? word : "Hidden word")
        .accessibilityHint(isRevealed ? "" : "Double tap to reveal")
    }

    // MARK: - Candlelit Style

    private func candlelitWord(word: String, isRevealed: Bool) -> some View {
        Text(isRevealed ? word : String(repeating: "\u{2022}", count: word.count))
            .font(.custom("CormorantGaramond-Regular", size: 22, relativeTo: .title2))
            .foregroundStyle(isRevealed ? Color.moonlitParchment : Color.white.opacity(0.3))
            .padding(.horizontal, HomeShowcaseTheme.Spacing.md)
            .padding(.vertical, HomeShowcaseTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.small)
                    .fill(isRevealed ? accentColor.opacity(0.3) : Color.white.opacity(0.05))
                    .shadow(color: isRevealed ? accentColor.opacity(0.4) : .clear, radius: 8)
            )
    }

    // MARK: - Scholarly Style

    private func scholarlyWord(word: String, isRevealed: Bool) -> some View {
        VStack(spacing: 2) {
            Text(isRevealed ? word : String(repeating: "\u{2013}", count: word.count))
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(isRevealed ? Color.scholarInk : Color.footnoteGray)

            // Underline that draws in
            Rectangle()
                .fill(isRevealed ? accentColor : Color.clear)
                .frame(height: 2)
                .scaleEffect(x: isRevealed ? 1 : 0, anchor: .leading)
                .accessibleAnimation(HomeShowcaseTheme.Animation.quick, value: isRevealed)
        }
        .padding(.horizontal, HomeShowcaseTheme.Spacing.sm)
        .padding(.vertical, HomeShowcaseTheme.Spacing.xs)
    }

    // MARK: - Celestial Style

    private func celestialWord(word: String, isRevealed: Bool) -> some View {
        ZStack {
            // Glow effect
            if isRevealed {
                RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.small)
                    .fill(accentColor.opacity(0.2))
                    .blur(radius: 8)
            }

            Text(isRevealed ? word : String(repeating: "\u{2731}", count: min(word.count, 3)))
                .font(.custom("CormorantGaramond-Regular", size: 22, relativeTo: .title2))
                .foregroundStyle(isRevealed ? Color.celestialStarlight : Color.white.opacity(0.3))
                .padding(.horizontal, HomeShowcaseTheme.Spacing.md)
                .padding(.vertical, HomeShowcaseTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.small)
                        .fill(isRevealed ? accentColor.opacity(0.25) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: HomeShowcaseTheme.CornerRadius.small)
                                .stroke(isRevealed ? accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Flow Layout
// Wraps content naturally like text, extracted from existing MemoryPalacePOC

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
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxX = max(maxX, currentX)
            }

            size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview("Phrase Reveal") {
    VStack(spacing: 40) {
        // Candlelit
        ZStack {
            Color(hex: "030308")
            PhraseRevealView(
                phrase: "The Lord is my shepherd",
                revealedWords: .constant([0, 1]),
                accentColor: .candleAmber,
                style: .candlelit,
                onWordRevealed: nil,
                onAllRevealed: nil
            )
        }
        .frame(height: 150)

        // Scholarly
        ZStack {
            Color.vellumCream
            PhraseRevealView(
                phrase: "I shall not want",
                revealedWords: .constant([0]),
                accentColor: .scholarIndigo,
                style: .scholarly,
                onWordRevealed: nil,
                onAllRevealed: nil
            )
        }
        .frame(height: 150)

        // Celestial
        ZStack {
            Color.celestialDeep
            PhraseRevealView(
                phrase: "is my shepherd",
                revealedWords: .constant([0, 1, 2]),
                accentColor: .celestialPurple,
                style: .celestial,
                onWordRevealed: nil,
                onAllRevealed: nil
            )
        }
        .frame(height: 150)
    }
}
