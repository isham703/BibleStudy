import SwiftUI

// MARK: - Prayer Display View
// Prayer text renderer with variant-specific typography

struct PrayerDisplayView: View {
    let prayer: MockPrayer
    let variant: PrayersShowcaseVariant
    let revealedWordCount: Int
    let isRevealComplete: Bool

    var body: some View {
        switch variant {
        case .sacredManuscript:
            manuscriptStyle
        case .desertSilence:
            silenceStyle
        case .auroraVeil:
            auroraStyle
        }
    }

    // MARK: - Sacred Manuscript Style

    private var manuscriptStyle: some View {
        VStack(spacing: 24) {
            // Cross ornament
            Text("✝")
                .font(.system(size: 28))
                .foregroundStyle(Color.manuscriptGold.opacity(0.6))

            // Prayer with drop cap
            ManuscriptPrayerText(prayer: prayer)

            // Ornamental divider
            OrnamentalDivider()
                .frame(width: 120)

            // Tradition note
            Text("In the tradition of \(prayer.tradition.rawValue)")
                .font(.custom("CormorantGaramond-Italic", size: 13))
                .foregroundStyle(Color.manuscriptOxide.opacity(0.7))

            // Amen
            Text(prayer.amen)
                .font(.custom("Cinzel-Regular", size: 14))
                .tracking(6)
                .foregroundStyle(Color.manuscriptVermillion)
        }
    }

    // MARK: - Desert Silence Style (Word-by-word reveal)

    private var silenceStyle: some View {
        VStack(spacing: 32) {
            // Word-by-word prayer text
            DesertSilencePrayerText(
                words: prayer.words,
                revealedCount: revealedWordCount
            )

            // Amen (appears after reveal complete)
            if isRevealComplete {
                Text(prayer.amen.uppercased())
                    .font(.system(size: 13, weight: .light))
                    .tracking(8)
                    .foregroundStyle(Color.desertSumiInk)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Aurora Veil Style

    private var auroraStyle: some View {
        VStack(spacing: 20) {
            // Prayer text with aurora glow
            Text(prayer.content)
                .font(.system(size: 19))
                .foregroundStyle(.white)
                .lineSpacing(8)
                .multilineTextAlignment(.center)

            // Divider
            HStack(spacing: 16) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.auroraViolet.opacity(0.5), .auroraTeal.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 2)

                Circle()
                    .fill(Color.auroraViolet)
                    .frame(width: 6, height: 6)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.auroraTeal.opacity(0.3), .auroraRose.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 2)
            }

            // Tradition + Amen
            VStack(spacing: 8) {
                Text(prayer.tradition.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.auroraStarlight.opacity(0.6))

                Text(prayer.amen)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Manuscript Prayer Text (with Drop Cap)

private struct ManuscriptPrayerText: View {
    let prayer: MockPrayer
    @State private var showDropCap = false

    var body: some View {
        let firstLetter = String(prayer.content.prefix(1))
        let restOfText = String(prayer.content.dropFirst())

        HStack(alignment: .top, spacing: 8) {
            // Drop cap
            Text(firstLetter)
                .font(.custom("Cinzel-Regular", size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.manuscriptGold, .manuscriptOxide],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .manuscriptUmber.opacity(0.3), radius: 2, x: 1, y: 2)
                .scaleEffect(showDropCap ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showDropCap)

            // Rest of prayer
            Text(restOfText)
                .font(.custom("CormorantGaramond-SemiBold", size: 20))
                .foregroundStyle(Color.manuscriptUmber)
                .lineSpacing(10)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showDropCap = true
            }
        }
    }
}

// MARK: - Desert Silence Prayer Text (Word-by-word)

private struct DesertSilencePrayerText: View {
    let words: [String]
    let revealedCount: Int

    var body: some View {
        // Use a flow layout for words
        PrayerFlowLayout(spacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(.system(size: 21, design: .serif))
                    .foregroundStyle(Color.desertSumiInk)
                    .opacity(index < revealedCount ? 1 : 0)
                    .offset(y: index < revealedCount ? 0 : 8)
                    .animation(
                        .easeOut(duration: 0.3),
                        value: revealedCount
                    )
            }
        }
        .multilineTextAlignment(.center)
        .lineSpacing(12)
    }
}

// MARK: - Prayer Flow Layout (for word-by-word)

private struct PrayerFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            if index < result.positions.count {
                let position = result.positions[index]
                subview.place(
                    at: CGPoint(
                        x: bounds.minX + position.x,
                        y: bounds.minY + position.y
                    ),
                    proposal: .unspecified
                )
            }
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

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
            totalWidth = max(totalWidth, currentX)
        }

        return (
            CGSize(width: totalWidth, height: currentY + lineHeight),
            positions
        )
    }
}

// MARK: - Preview

#Preview("Sacred Manuscript") {
    ScrollView {
        ZStack {
            Color.manuscriptVellum.ignoresSafeArea()
            PrayerDisplayView(
                prayer: .psalmicLament,
                variant: .sacredManuscript,
                revealedWordCount: 100,
                isRevealComplete: true
            )
            .padding()
        }
    }
}

#Preview("Desert Silence") {
    ZStack {
        Color.desertDawnMist.ignoresSafeArea()
        PrayerDisplayView(
            prayer: .desertFathers,
            variant: .desertSilence,
            revealedWordCount: 20,
            isRevealComplete: false
        )
        .padding()
    }
}

#Preview("Aurora Veil") {
    ZStack {
        Color.auroraVoid.ignoresSafeArea()
        PrayerDisplayView(
            prayer: .celtic,
            variant: .auroraVeil,
            revealedWordCount: 100,
            isRevealComplete: true
        )
        .padding()
    }
}
