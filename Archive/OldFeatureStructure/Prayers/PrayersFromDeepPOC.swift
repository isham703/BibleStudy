import SwiftUI

// MARK: - Prayers From the Deep POC
// AI crafts prayers in the language of the Psalms
// Aesthetic: Contemplative, liturgical, intimate

struct PrayersFromDeepPOC: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var inputText = ""
    @State private var isGenerating = false
    @State private var showingPrayer = false
    @State private var breathePhase: CGFloat = 0
    @State private var selectedTradition = 0
    @FocusState private var isInputFocused: Bool

    private let traditions = ["Psalmic Lament", "Desert Fathers", "Celtic", "Ignatian"]

    private let generatedPrayer = """
    O Lord, You who count the stars
    and call each one by name,
    surely You see my son
    wandering in distant places.

    My heart is heavy as stone in deep waters.
    I have cried until there are no more tears,
    yet still the ache remains,
    a wound that will not close.

    But I remember Your faithfulness—
    how You sought the lost sheep,
    how You waited for the prodigal,
    how Your arms never tire of reaching.

    So I will trust, even in this darkness.
    I will hope, even when hope seems foolish.
    For You are the God who brings
    dead things back to life.

    Watch over him, Lord.
    Where I cannot go, go with him.
    Where my voice cannot reach,
    let Your Spirit whisper love.

    Amen.
    """

    var body: some View {
        ZStack {
            // Contemplative background
            contemplativeBackground

            VStack(spacing: 0) {
                // Header
                header

                if showingPrayer {
                    prayerView
                } else if isGenerating {
                    generatingView
                } else {
                    inputView
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
        }
    }

    // MARK: - Background

    private var contemplativeBackground: some View {
        ZStack {
            // Deep sacred blue
            Color(hex: "0a0d1a")

            // Warm candlelight glow
            RadialGradient(
                colors: [
                    Color(hex: "f43f5e").opacity(0.08 + breathePhase * 0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            // Subtle golden accent
            RadialGradient(
                colors: [
                    Color(hex: "d4a853").opacity(0.05),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("PRAYERS FROM THE DEEP")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "f43f5e"))
            }

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "f43f5e").opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(1 + breathePhase * 0.1)

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "f43f5e"))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)

            // Title
            VStack(spacing: 12) {
                Text("What's on your heart?")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(.white)

                Text("Describe your situation, and I'll craft a prayer in the tradition of the Psalms.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)

            // Text input
            VStack(spacing: 16) {
                TextEditor(text: $inputText)
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .frame(height: 120)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "f43f5e").opacity(0.3), lineWidth: 1)
                            )
                    )
                    .focused($isInputFocused)

                if inputText.isEmpty {
                    Text("e.g., \"I'm anxious about my son who has drifted away...\"")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                        .italic()
                }
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)

            // Tradition selector
            VStack(spacing: 12) {
                Text("Prayer Tradition")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: 12) {
                    ForEach(Array(traditions.enumerated()), id: \.offset) { index, tradition in
                        Button(action: { selectedTradition = index }) {
                            Text(tradition)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(selectedTradition == index ? .white : .white.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedTradition == index ? Color(hex: "f43f5e").opacity(0.3) : Color.white.opacity(0.05))
                                )
                        }
                    }
                }
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.5), value: isVisible)

            Spacer()

            // Generate button
            Button(action: generatePrayer) {
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
                        .fill(Color(hex: "f43f5e"))
                )
            }
            .disabled(inputText.isEmpty)
            .opacity(inputText.isEmpty ? 0.5 : 1)
            .padding(.bottom, 40)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: isVisible)
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Breathing prayer animation
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color(hex: "f43f5e").opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(80 + i * 40), height: CGFloat(80 + i * 40))
                        .scaleEffect(1 + breathePhase * CGFloat(0.1 + Double(i) * 0.05))
                }

                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "f43f5e"))
            }

            VStack(spacing: 12) {
                Text("Crafting your prayer...")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(.white)

                Text("Drawing from the well of the Psalms")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
    }

    // MARK: - Prayer View

    private var prayerView: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Cross ornament
                    Text("✝")
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: "f43f5e").opacity(0.6))
                        .padding(.top, 32)

                    // Prayer text
                    Text(generatedPrayer)
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(12)
                        .padding(.horizontal, 32)

                    // Divider
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color(hex: "f43f5e").opacity(0.3))
                            .frame(width: 40, height: 1)
                        Circle()
                            .fill(Color(hex: "f43f5e").opacity(0.5))
                            .frame(width: 6, height: 6)
                        Rectangle()
                            .fill(Color(hex: "f43f5e").opacity(0.3))
                            .frame(width: 40, height: 1)
                    }
                    .padding(.vertical, 16)

                    // Tradition note
                    Text("In the tradition of Psalmic Lament")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .italic()
                }
                .padding(.bottom, 120)
            }

            // Actions
            HStack(spacing: 24) {
                actionButton(icon: "bookmark", label: "Save")
                actionButton(icon: "square.and.arrow.up", label: "Share")
                actionButton(icon: "arrow.counterclockwise", label: "New")
            }
            .padding(.vertical, 24)
            .background(Color(hex: "0a0d1a").opacity(0.95))
        }
        .transition(.opacity.combined(with: .offset(y: 30)))
    }

    private func actionButton(icon: String, label: String) -> some View {
        Button(action: {
            if label == "New" {
                withAnimation(.spring(duration: 0.4)) {
                    showingPrayer = false
                    inputText = ""
                }
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Actions

    private func generatePrayer() {
        isInputFocused = false
        withAnimation(.spring(duration: 0.4)) {
            isGenerating = true
        }

        // Simulate generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(duration: 0.6)) {
                isGenerating = false
                showingPrayer = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrayersFromDeepPOC()
}
