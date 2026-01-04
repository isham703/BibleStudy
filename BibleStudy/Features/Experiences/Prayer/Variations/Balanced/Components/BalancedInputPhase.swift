import SwiftUI

// MARK: - Balanced Input Phase
// Full-screen input with breathing icon and staggered reveal

struct BalancedInputPhase: View {
    @Binding var text: String
    @Binding var selectedTradition: PrayerTradition

    var canGenerate: Bool
    var onGenerate: () -> Void

    @State private var isVisible = false
    @State private var breathePhase: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Breathing icon
                breathingIcon
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: isVisible)

                // Title section
                titleSection
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)

                // Text input
                textInput
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)

                // Tradition selector
                traditionSelector
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            // Generate button
            generateButton
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: isVisible)
        }
        .onAppear {
            isVisible = true
            startBreathingAnimation()
        }
    }

    // MARK: - Breathing Icon

    private var breathingIcon: some View {
        ZStack {
            // Outer glow circle
            Circle()
                .fill(DeepPrayerColors.roseAccent.opacity(0.1))
                .frame(width: 100, height: 100)
                .scaleEffect(reduceMotion ? 1.0 : 1 + breathePhase * 0.1)

            // Inner icon
            Image(systemName: "hands.sparkles.fill")
                .font(.system(size: 40))
                .foregroundStyle(DeepPrayerColors.roseAccent)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("What's on your heart?")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(DeepPrayerColors.primaryText)

            Text("Describe your situation, and I'll craft a prayer in the \(selectedTradition.displayName) tradition.")
                .font(.system(size: 15))
                .foregroundStyle(DeepPrayerColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Text Input

    private var textInput: some View {
        VStack(spacing: 16) {
            TextEditor(text: $text)
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(DeepPrayerColors.primaryText)
                .scrollContentBackground(.hidden)
                .frame(height: 120)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(DeepPrayerColors.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isInputFocused
                                        ? DeepPrayerColors.roseBorder
                                        : DeepPrayerColors.surfaceBorder,
                                    lineWidth: 1
                                )
                        )
                )
                .focused($isInputFocused)

            if text.isEmpty {
                Text("e.g., \"I'm anxious about my son who has drifted away...\"")
                    .font(.system(size: 13))
                    .foregroundStyle(DeepPrayerColors.placeholderText)
                    .italic()
            }
        }
    }

    // MARK: - Tradition Selector

    private var traditionSelector: some View {
        VStack(spacing: 12) {
            Text("Prayer Tradition")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DeepPrayerColors.tertiaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PrayerTradition.allCases) { tradition in
                        traditionButton(tradition)
                    }
                }
            }
        }
    }

    private func traditionButton(_ tradition: PrayerTradition) -> some View {
        let isSelected = selectedTradition == tradition

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTradition = tradition
            }
        }) {
            Text(tradition.shortName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isSelected
                        ? DeepPrayerColors.primaryText
                        : DeepPrayerColors.secondaryText
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? DeepPrayerColors.roseHighlight
                                : DeepPrayerColors.surfaceElevated
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                isInputFocused = false
                onGenerate()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                    Text("Craft Prayer")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(DeepPrayerColors.roseAccent)
                )
            }
            .disabled(!canGenerate)
            .opacity(canGenerate ? 1 : 0.5)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background {
            DeepPrayerColors.sacredNavy
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Animation

    private func startBreathingAnimation() {
        guard !reduceMotion else { return }
        withAnimation(
            .easeInOut(duration: 4)
            .repeatForever(autoreverses: true)
        ) {
            breathePhase = 1
        }
    }
}

// MARK: - Preview

#Preview("Balanced Input") {
    BalancedInputPhase(
        text: .constant(""),
        selectedTradition: .constant(.psalmicLament),
        canGenerate: false,
        onGenerate: {}
    )
    .background(DeepPrayerColors.sacredNavy)
}
