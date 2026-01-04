import SwiftUI

// MARK: - Balanced Display Phase
// Full-screen prayer reveal with word-by-word animation

struct BalancedDisplayPhase: View {
    let prayer: any PrayerDisplayable
    let tradition: PrayerTradition

    var onSave: () -> Void
    var onShare: () -> Void
    var onNew: () -> Void

    @State private var revealedLineCount: Int = 0
    @State private var isRevealComplete = false
    @State private var hasAppeared = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Cross ornament
                crossOrnament
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: hasAppeared)

                // Prayer text with line-by-line reveal
                prayerText
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: hasAppeared)

                // Amen
                Text(prayer.amen)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(DeepPrayerColors.secondaryText)
                    .italic()
                    .opacity(isRevealComplete ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: isRevealComplete)

                // Divider
                divider
                    .opacity(isRevealComplete ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: isRevealComplete)

                // Attribution
                Text("In the tradition of \(tradition.rawValue)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DeepPrayerColors.tertiaryText)
                    .italic()
                    .opacity(isRevealComplete ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: isRevealComplete)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            skipToFullReveal()
        }
        .safeAreaInset(edge: .bottom) {
            // Action bar pinned to bottom
            actionBar
                .opacity(isRevealComplete ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: isRevealComplete)
        }
        .onAppear {
            hasAppeared = true
            startLineReveal()
        }
    }

    // MARK: - Cross Ornament

    private var crossOrnament: some View {
        Text("\u{2720}")  // Maltese cross
            .font(.system(size: 32))
            .foregroundStyle(DeepPrayerColors.roseAccent.opacity(0.6))
    }

    // MARK: - Prayer Text

    private var prayerText: some View {
        VStack(alignment: .center, spacing: 16) {
            ForEach(Array(prayer.lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundStyle(DeepPrayerColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .opacity(reduceMotion || index < revealedLineCount ? 1 : 0)
                    .offset(y: reduceMotion || index < revealedLineCount ? 0 : 10)
                    .animation(
                        .easeOut(duration: 0.5)
                        .delay(Double(index) * 0.15),
                        value: revealedLineCount
                    )
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(DeepPrayerColors.roseAccent.opacity(0.3))
                .frame(width: 40, height: 1)
            Circle()
                .fill(DeepPrayerColors.roseAccent.opacity(0.5))
                .frame(width: 6, height: 6)
            Rectangle()
                .fill(DeepPrayerColors.roseAccent.opacity(0.3))
                .frame(width: 40, height: 1)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 40) {
            actionButton(icon: "bookmark", label: "Save", action: onSave)
            actionButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
            actionButton(icon: "arrow.counterclockwise", label: "New", action: onNew)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background {
            DeepPrayerColors.sacredNavy
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(DeepPrayerColors.secondaryText)
        }
    }

    // MARK: - Animation

    private func startLineReveal() {
        guard !reduceMotion else {
            revealedLineCount = prayer.lines.count
            isRevealComplete = true
            return
        }

        // Reveal lines one by one
        let totalLines = prayer.lines.count
        for index in 0..<totalLines {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                withAnimation {
                    revealedLineCount = index + 1
                }
            }
        }

        // Mark complete after all lines revealed
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(totalLines) * 0.3 + 0.5) {
            withAnimation {
                isRevealComplete = true
            }
        }
    }

    private func skipToFullReveal() {
        guard !isRevealComplete else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            revealedLineCount = prayer.lines.count
            isRevealComplete = true
        }
    }
}

// MARK: - Preview

#Preview("Balanced Display") {
    BalancedDisplayPhase(
        prayer: MockPrayer.psalmicLament,
        tradition: .psalmicLament,
        onSave: {},
        onShare: {},
        onNew: {}
    )
    .background(DeepPrayerColors.sacredNavy)
}
