import Combine
import SwiftUI

// MARK: - Ink Flow Text View
// Character-by-character text reveal animation
// Creates the effect of ink flowing onto parchment

struct InkFlowTextView: View {
    let text: String
    let isAnimating: Bool
    var onAnimationComplete: (() -> Void)?

    @State private var visibleCharCount: Int = 0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    // 30ms per character for smooth ink flow effect
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(visibleText)
            .font(Typography.Scripture.body)
            .foregroundStyle(Color.primaryText)
            .lineSpacing(Typography.Scripture.bodyLineSpacing)
            .multilineTextAlignment(.leading)
            .onReceive(timer) { _ in
                guard isAnimating, !respectsReducedMotion else { return }
                advanceCharacter()
            }
            .onAppear {
                if respectsReducedMotion || !isAnimating {
                    visibleCharCount = text.count
                    onAnimationComplete?()
                }
            }
            .onChange(of: text) { _, newText in
                if isAnimating && !respectsReducedMotion {
                    visibleCharCount = 0
                } else {
                    visibleCharCount = newText.count
                }
            }
    }

    // MARK: - Computed Properties

    private var visibleText: String {
        guard visibleCharCount < text.count else { return text }
        let endIndex = text.index(text.startIndex, offsetBy: visibleCharCount)
        return String(text[..<endIndex])
    }

    // MARK: - Animation Logic

    private func advanceCharacter() {
        guard visibleCharCount < text.count else {
            onAnimationComplete?()
            return
        }
        visibleCharCount += 1
    }
}

// MARK: - Ink Flow Text with Illuminated Capital
// Combines illuminated first letter with flowing text

struct IlluminatedInkFlowText: View {
    let text: String
    let isAnimating: Bool
    var onAnimationComplete: (() -> Void)?

    @State private var showCapital = false
    @State private var textComplete = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            // Illuminated capital (first letter)
            if let firstChar = text.first {
                IlluminatedCapitalView(
                    letter: String(firstChar),
                    isVisible: showCapital
                )
            }

            // Flowing text (rest of the content)
            InkFlowTextView(
                text: remainingText,
                isAnimating: isAnimating && showCapital
            ) {
                textComplete = true
                onAnimationComplete?()
            }
        }
        .onAppear {
            if respectsReducedMotion {
                showCapital = true
            } else if isAnimating {
                // Small delay before revealing capital
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(Theme.Animation.settle) {
                        showCapital = true
                    }
                }
            } else {
                showCapital = true
            }
        }
    }

    private var remainingText: String {
        guard text.count > 1 else { return "" }
        return String(text.dropFirst())
    }
}

// MARK: - Preview

#if DEBUG
struct InkFlowTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Text("Ink Flow Animation")
                .font(Typography.Command.headline)

            InkFlowTextView(
                text: "Blessed are the poor in spirit, for theirs is the kingdom of heaven.",
                isAnimating: true
            )
            .padding()
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .padding()
        .background(Color.appBackground)
        .previewDisplayName("Ink Flow Text")
    }
}

struct IlluminatedInkFlowText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Text("Illuminated Text")
                .font(Typography.Command.headline)

            IlluminatedInkFlowText(
                text: "When Jesus saw the crowds, he went up on a mountainside and sat down.",
                isAnimating: true
            )
            .padding()
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .padding()
        .background(Color.appBackground)
        .previewDisplayName("Illuminated Ink Flow")
    }
}
#endif
