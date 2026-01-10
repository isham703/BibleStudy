//
//  BoldFaithPage.swift
//  BibleStudy
//
//  Style F: Bold Faith - Neubrutalist design that breaks conventions
//  Viral-worthy: Stands out dramatically, bold colors, thick borders, raw aesthetic
//  Trend: Neubrutalism - the rebellious counter-trend to glassmorphism
//

import SwiftUI

struct BoldFaithPage: View {
    @State private var prayerText: String = ""
    @State private var selectedTone: PrayerTone = .bold
    @State private var isGenerating = false
    @State private var generatedPrayer: String = ""
    @State private var showPrayer = false
    @State private var buttonBounce = false
    @FocusState private var isInputFocused: Bool

    enum PrayerTone: String, CaseIterable {
        case bold = "BOLD"
        case raw = "RAW"
        case honest = "HONEST"
        case loud = "LOUD"

        var color: Color {
            switch self {
            case .bold: return Color.brightRed
            case .raw: return Color.amberOrange
            case .honest: return Color.greenTeal
            case .loud: return Color.violetAccent
            }
        }
    }

    var body: some View {
        ZStack {
            // Stark background
            Color(hex: "FFFEF5")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    toneSelector
                    inputSection

                    if showPrayer {
                        resultSection
                    }

                    Spacer(minLength: 140)
                }
            }

            // Floating button
            VStack {
                Spacer()
                generateButton
            }

            // Decorative corner stamp
            cornerStamp
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 70)

            // Raw label
            Text("NO FILTER.")
                .font(Typography.Icon.xxs.weight(.black))
                .tracking(2)
                .foregroundColor(Color.brightRed)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Rectangle()
                        .fill(Color(hex: "FEE2E2"))
                )
                .rotationEffect(.degrees(-2))

            // Main title - intentionally stacked
            VStack(alignment: .leading, spacing: -8) {
                Text("PRAYER")
                    .font(Typography.Icon.display.weight(.black))
                    .foregroundColor(Color.surfaceRaised)

                HStack(spacing: 12) {
                    Text("FROM")
                        .font(Typography.Icon.display.weight(.black))
                        .foregroundColor(Color.surfaceRaised)

                    Text("THE")
                        .font(Typography.Icon.display.weight(.black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Rectangle()
                                .fill(Color.surfaceRaised)
                        )
                        .rotationEffect(.degrees(2))
                }

                Text("DEEP")
                    .font(Typography.Icon.display.weight(.black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brightRed, Color(hex: "F97316")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Tagline with brutalist style
            HStack {
                Rectangle()
                    .fill(Color.surfaceRaised)
                    .frame(width: 40, height: 3)

                Text("God can handle your mess.")
                    .font(Typography.Command.caption.weight(.bold))
                    .foregroundColor(Color(hex: "52525B"))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    // MARK: - Tone Selector

    private var toneSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PICK YOUR VIBE:")
                .font(Typography.Command.meta.weight(.black))
                .tracking(1)
                .foregroundColor(Color(hex: "71717A"))
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PrayerTone.allCases, id: \.self) { tone in
                        BrutalToneChip(
                            tone: tone,
                            isSelected: selectedTone == tone,
                            action: {
                                withAnimation(Theme.Animation.settle) {
                                    selectedTone = tone
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            HStack {
                Text("SPILL IT:")
                    .font(Typography.Command.meta.weight(.black))
                    .tracking(1)
                    .foregroundColor(Color(hex: "71717A"))

                Spacer()

                if !prayerText.isEmpty {
                    Text("\(prayerText.count) chars")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(selectedTone.color)
                }
            }

            // Brutal input box
            ZStack(alignment: .topLeading) {
                // Shadow layer
                Rectangle()
                    .fill(Color.surfaceRaised)
                    .offset(x: 6, y: 6)

                // Main box
                Rectangle()
                    .fill(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.surfaceRaised, lineWidth: 3)
                    )

                // Text editor
                TextEditor(text: $prayerText)
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.surfaceRaised)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .padding(16)
                    .frame(minHeight: 160)

                // Placeholder
                if prayerText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's really going on?")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "A1A1AA"))

                        Text("// no judgment here")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "D4D4D8"))
                    }
                    .padding(20)
                    .allowsHitTesting(false)
                }

                // Corner accent
                Rectangle()
                    .fill(selectedTone.color)
                    .frame(width: 20, height: 20)
                    .offset(x: -3, y: -3)
            }
            .frame(height: 180)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Divider
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.surfaceRaised)
                    .frame(height: 3)

                Text("DONE")
                    .font(Typography.Icon.xs.weight(.black))
                    .foregroundColor(Color.surfaceRaised)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Rectangle()
                            .fill(Color.greenTeal)
                    )

                Rectangle()
                    .fill(Color.surfaceRaised)
                    .frame(height: 3)
            }
            .padding(.top, 32)

            // Prayer card
            ZStack(alignment: .topLeading) {
                // Shadow
                Rectangle()
                    .fill(Color.surfaceRaised)
                    .offset(x: 8, y: 8)

                // Card
                VStack(alignment: .leading, spacing: 16) {
                    // Header strip
                    HStack {
                        Circle()
                            .fill(Color.brightRed)
                            .frame(width: 12, height: 12)
                        Circle()
                            .fill(Color.amberOrange)
                            .frame(width: 12, height: 12)
                        Circle()
                            .fill(Color.greenTeal)
                            .frame(width: 12, height: 12)

                        Spacer()

                        Text("prayer.txt")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "71717A"))
                    }
                    .padding(.bottom, 8)

                    // Prayer text
                    Text(generatedPrayer.isEmpty ? samplePrayer : generatedPrayer)
                        .font(Typography.Command.headline)
                        .foregroundColor(Color.surfaceRaised)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)

                    // Reference
                    HStack {
                        Text("/* Psalm 62:8 */")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.greenTeal)

                        Spacer()
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        BrutalActionButton(text: "COPY", color: Color.blueAccent) {}
                        BrutalActionButton(text: "SHARE", color: Color.violetAccent) {}
                        BrutalActionButton(text: "SAVE", color: Color.brightRed) {}
                    }
                }
                .padding(20)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.surfaceRaised, lineWidth: 3)
                )
            }
        }
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generate) {
            ZStack {
                // Shadow
                Rectangle()
                    .fill(Color.surfaceRaised)
                    .offset(x: buttonBounce ? 2 : 6, y: buttonBounce ? 2 : 6)

                // Button
                HStack(spacing: 12) {
                    if isGenerating {
                        BrutalLoadingIndicator()
                    } else {
                        Text("⚡")
                            .font(Typography.Command.title3)
                    }

                    Text(isGenerating ? "WORKING..." : "MAKE IT PRAY")
                        .font(Typography.Icon.md.weight(.black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(selectedTone.color)
                .overlay(
                    Rectangle()
                        .stroke(Color.surfaceRaised, lineWidth: 3)
                )
                .offset(x: buttonBounce ? 4 : 0, y: buttonBounce ? 4 : 0)
            }
            .frame(height: 60)
        }
        .disabled(isGenerating || prayerText.isEmpty)
        .opacity(prayerText.isEmpty ? 0.6 : 1)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Corner Stamp

    private var cornerStamp: some View {
        VStack {
            HStack {
                Spacer()

                Text("2025")
                    .font(Typography.Icon.hero.weight(.black))
                    .foregroundColor(Color.surfaceRaised.opacity(Theme.Opacity.faint))
                    .rotationEffect(.degrees(90))
                    .offset(x: 20, y: 80)
            }

            Spacer()
        }
    }

    private func generate() {
        // Button press animation
        withAnimation(Theme.Animation.settle) {
            buttonBounce = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(Theme.Animation.settle) {
                buttonBounce = false
            }
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            isGenerating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(Theme.Animation.settle) {
                isGenerating = false
                showPrayer = true
            }
        }
    }

    private var samplePrayer: String {
        """
        God, I'm not gonna pretend everything's fine.

        You already know the mess I'm in. You see the thoughts I can't shake, the fears that keep me up at night.

        I'm tired of pretending. I need You to show up. Not in some distant, polite way—but right here, right now, in the middle of my chaos.

        You said to pour out my heart. Here it is. All of it.

        — Amen (I guess)
        """
    }
}

// MARK: - Brutal Tone Chip

private struct BrutalToneChip: View {
    let tone: BoldFaithPage.PrayerTone
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Shadow
                if isSelected {
                    Rectangle()
                        .fill(Color.surfaceRaised)
                        .offset(x: 4, y: 4)
                }

                // Chip
                Text(tone.rawValue)
                    .font(Typography.Command.meta.weight(.black))
                    .foregroundColor(isSelected ? .white : Color.surfaceRaised)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(isSelected ? tone.color : Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.surfaceRaised, lineWidth: isSelected ? 3 : 2)
                    )
                    .offset(x: isSelected ? -2 : 0, y: isSelected ? -2 : 0)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Brutal Action Button

private struct BrutalActionButton: View {
    let text: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(Color.surfaceRaised)
                    .offset(x: 3, y: 3)

                Text(text)
                    .font(Typography.Command.meta.weight(.black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(color)
                    .overlay(
                        Rectangle()
                            .stroke(Color.surfaceRaised, lineWidth: 2)
                    )
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Brutal Loading Indicator

private struct BrutalLoadingIndicator: View {
    @State private var frame = 0

    private let frames = ["[    ]", "[=   ]", "[==  ]", "[=== ]", "[====]", "[ ===]", "[  ==]", "[   =]"]

    var body: some View {
        Text(frames[frame])
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                    frame = (frame + 1) % frames.count
                }
            }
    }
}

// MARK: - Preview

#Preview {
    BoldFaithPage()
}
