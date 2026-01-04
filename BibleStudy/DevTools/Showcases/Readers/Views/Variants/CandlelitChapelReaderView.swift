import SwiftUI

// MARK: - Candlelit Chapel Reader View
// Vespers/Compline-based reader with paragraph flow, starfield, and candle glow

struct CandlelitChapelReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var selectedVerseRange: ClosedRange<Int>?
    @State private var breathingOpacity: Double = 0.7

    private let passage = PlaceholderScripture.psalm23

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background layers
                backgroundLayers

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Chapter header
                        chapterHeader
                            .padding(.top, AppTheme.Spacing.xxxl)

                        // Ornamental divider
                        ChapelDivider()
                            .padding(.vertical, AppTheme.Spacing.xxl)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)

                        // Paragraph content
                        paragraphSection
                            .padding(.horizontal, AppTheme.Spacing.xl)

                        // Bottom spacing for candle
                        Spacer()
                            .frame(height: AppTheme.Spacing.xxxl * 3)
                    }
                    .frame(minHeight: geometry.size.height)
                }

                // Floating candle at bottom
                VStack {
                    Spacer()
                    ChapelCandleFlame()
                        .offset(y: 20)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(passage.reference)
                    .font(.custom("Cinzel-Regular", size: 12))
                    .tracking(2)
                    .foregroundStyle(Color.moonMist.opacity(0.7))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }

            // Start breathing animation
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathingOpacity = 1.0
            }
        }
    }

    // MARK: - Background Layers

    private var backgroundLayers: some View {
        ZStack {
            // Base gradient
            Color.vespersSkyGradient
                .ignoresSafeArea()

            // Starfield
            StarfieldBackground()
                .opacity(reduceMotion ? 0.6 : breathingOpacity)

            // Ambient candle glow at bottom
            VStack {
                Spacer()
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.candleAmber.opacity(0.3),
                                Color.candleAmber.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 200)
                    .offset(y: 50)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Chapter Header

    private var chapterHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Book name
            Text(passage.bookName.uppercased())
                .font(.custom("Cinzel-Regular", size: 11))
                .tracking(4)
                .foregroundStyle(Color.candleAmber)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: isVisible)

            // Chapter number
            Text("\(passage.chapter)")
                .font(.custom("CormorantGaramond-Regular", size: 64))
                .foregroundStyle(Color.starlight)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isVisible)
        }
    }

    // MARK: - Paragraph Section

    private var paragraphSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Paragraph flow text with inline verse numbers
            Text(attributedParagraphText)
                .font(.custom("CormorantGaramond-Regular", size: 22))
                .foregroundStyle(Color.starlight)
                .lineSpacing(12)
                .multilineTextAlignment(.leading)
                .opacity(isVisible ? breathingOpacity : 0)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: isVisible)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.candleAmber.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Attributed Paragraph Text

    private var attributedParagraphText: AttributedString {
        var result = AttributedString()

        for verse in passage.verses {
            // Add verse number as superscript
            var verseNum = AttributedString("\(verse.id) ")
            verseNum.font = .custom("CormorantGaramond-Regular", size: 14)
            verseNum.foregroundColor = Color.moonMist.opacity(0.6)
            verseNum.baselineOffset = 6

            // Add verse text
            var verseText = AttributedString(verse.text + " ")
            verseText.font = .custom("CormorantGaramond-Regular", size: 22)
            verseText.foregroundColor = Color.starlight

            result.append(verseNum)
            result.append(verseText)
        }

        return result
    }
}

// MARK: - Chapel Divider

private struct ChapelDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left gradient line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.moonMist.opacity(0.2),
                            Color.candleAmber.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center ornament - moon/stars motif
            Image(systemName: "moon.stars")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.candleAmber)

            // Right gradient line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.candleAmber.opacity(0.4),
                            Color.moonMist.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Chapel Candle Flame

private struct ChapelCandleFlame: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flameScale: CGFloat = 1.0
    @State private var flameOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Flame
            ZStack {
                // Outer glow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.candleAmber.opacity(0.5),
                                Color.candleAmber.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 60)
                    .blur(radius: 15)

                // Inner flame
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.candleCore,
                                Color.candleAmber
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 16, height: 32)
                    .scaleEffect(y: flameScale)
                    .offset(x: flameOffset)
            }
            .offset(y: -10)

            // Candle body (just a hint)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "f5f0e6"),
                            Color(hex: "e8e0d0")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 14, height: 30)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
        .onAppear {
            guard !reduceMotion else { return }

            // Gentle flame flicker
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                flameScale = 1.08
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                flameOffset = 1.5
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CandlelitChapelReaderView()
    }
}
