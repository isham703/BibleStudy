//
//  AuroraDreamsPage.swift
//  BibleStudy
//
//  Style D: Aurora Dreams - Dark glassmorphism with animated northern lights
//  Viral-worthy: Mesmerizing animated gradients perfect for screenshots and screen recordings
//  Trend: Dark Glassmorphism with ambient "light leak" gradients
//

import SwiftUI

struct AuroraDreamsPage: View {
    @State private var prayerText: String = ""
    @State private var isGenerating = false
    @State private var generatedPrayer: String = ""
    @State private var showPrayer = false
    @State private var auroraPhase: CGFloat = 0
    @State private var secondaryPhase: CGFloat = 0
    @State private var tertiaryPhase: CGFloat = 0
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Aurora background
            AuroraBackground(
                phase1: auroraPhase,
                phase2: secondaryPhase,
                phase3: tertiaryPhase
            )

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    inputSection

                    if showPrayer {
                        resultSection
                    }

                    Spacer(minLength: 140)
                }
            }

            // Floating action button
            VStack {
                Spacer()
                generateButton
            }
        }
        .onAppear {
            startAuroraAnimations()
        }
    }

    // MARK: - Aurora Animations

    private func startAuroraAnimations() {
        // Primary aurora wave
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            auroraPhase = 1
        }
        // Secondary wave (offset)
        withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true).delay(2)) {
            secondaryPhase = 1
        }
        // Tertiary wave (slower)
        withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true).delay(4)) {
            tertiaryPhase = 1
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)

            // Glowing orb icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purpleAccent.opacity(Theme.Opacity.lightMedium),
                                Color.accentIndigo.opacity(Theme.Opacity.light),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Inner icon
                Image(systemName: "hands.and.sparkles.fill")
                    .font(Typography.Icon.hero.weight(.light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.fuchsiaPink, Color.purpleAccent, Color.accentIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title with gradient
            VStack(spacing: 8) {
                Text("Prayer")
                    .font(Typography.Scripture.display.weight(.ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.fuchsiaPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("FROM THE DEEP")
                    .font(Typography.Icon.xs.weight(.semibold))
                    .tracking(6)
                    .foregroundColor(Color.purpleAccent.opacity(Theme.Opacity.pressed))
            }

            // Tagline
            Text("Let the aurora of grace illuminate your words")
                .font(Typography.Command.subheadline.weight(.light))
                .foregroundColor(Color.white.opacity(Theme.Opacity.tertiary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section label
            Text("WHAT'S ON YOUR HEART?")
                .font(Typography.Icon.xxs.weight(.bold))
                .tracking(2)
                .foregroundColor(Color.purpleAccent.opacity(Theme.Opacity.heavy))
                .padding(.horizontal, 28)

            // Glass input card
            ZStack(alignment: .topLeading) {
                // Glass background
                RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isInputFocused ? 0.3 : 0.15),
                                        Color.purpleAccent.opacity(isInputFocused ? 0.4 : 0.1),
                                        Color.white.opacity(Theme.Opacity.faint)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.purpleAccent.opacity(isInputFocused ? 0.3 : 0.1), radius: 20, x: 0, y: 10)

                // Text input
                TextEditor(text: $prayerText)
                    .font(Typography.Command.body.weight(.light))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .padding(20)
                    .frame(minHeight: 160)

                // Placeholder
                if prayerText.isEmpty {
                    Text("Share your burdens, hopes, gratitude, or seek guidance...")
                        .font(Typography.Command.body.weight(.light))
                        .foregroundColor(Color.white.opacity(Theme.Opacity.disabled))
                        .padding(24)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)

            // Quick prompts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AuroraPromptChip(text: "Gratitude", icon: "heart.fill") {
                        prayerText = "I want to express my gratitude for "
                    }
                    AuroraPromptChip(text: "Guidance", icon: "compass.drawing") {
                        prayerText = "I'm seeking guidance about "
                    }
                    AuroraPromptChip(text: "Peace", icon: "leaf.fill") {
                        prayerText = "I need peace in my heart regarding "
                    }
                    AuroraPromptChip(text: "Healing", icon: "bandage.fill") {
                        prayerText = "I pray for healing for "
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: 24) {
            // Divider
            HStack(spacing: 16) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.purpleAccent.opacity(Theme.Opacity.medium)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)

                Image(systemName: "sparkle")
                    .font(Typography.Command.caption)
                    .foregroundColor(Color.fuchsiaPink)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purpleAccent.opacity(Theme.Opacity.medium), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
            .padding(.top, 32)

            // Prayer card
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.emeraldGreen)
                    Text("Your Prayer")
                        .font(Typography.Command.meta.weight(.semibold))
                        .foregroundColor(Color.emeraldGreen)
                    Spacer()
                }

                // Prayer text
                Text(generatedPrayer.isEmpty ? samplePrayer : generatedPrayer)
                    .font(Typography.Scripture.body.weight(.light))
                    .foregroundColor(.white)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)

                // Reference
                HStack {
                    Spacer()
                    Text("Inspired by Psalm 139")
                        .font(Typography.Icon.xs)
                        .foregroundColor(Color.purpleAccent.opacity(Theme.Opacity.pressed))
                }

                // Actions
                HStack(spacing: 12) {
                    AuroraActionButton(icon: "doc.on.doc", label: "Copy") {}
                    AuroraActionButton(icon: "square.and.arrow.up", label: "Share") {}
                    AuroraActionButton(icon: "heart", label: "Save") {}
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.purpleAccent.opacity(Theme.Opacity.subtle),
                                        Color.accentIndigo.opacity(Theme.Opacity.overlay),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generate) {
            HStack(spacing: 12) {
                if isGenerating {
                    // Custom aurora loading indicator
                    AuroraLoadingIndicator()
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(Typography.Icon.base)
                }

                Text(isGenerating ? "Composing..." : "Create Prayer")
                    .font(Typography.Command.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.purpleAccent, Color.accentIndigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(Theme.Opacity.light), lineWidth: 1)
                    )
                    .shadow(color: Color.purpleAccent.opacity(Theme.Opacity.medium), radius: 20, x: 0, y: 10)
            )
        }
        .disabled(isGenerating || prayerText.isEmpty)
        .opacity(prayerText.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }

    private func generate() {
        withAnimation(Theme.Animation.settle) {
            isGenerating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(Theme.Animation.settle) {
                isGenerating = false
                showPrayer = true
            }
        }
    }

    private var samplePrayer: String {
        """
        Heavenly Father, You who painted the aurora across the night sky, \
        I come before You with a heart full of wonder and need.

        Search me and know my anxious thoughts. \
        Lead me in the way everlasting.

        In the quiet of this moment, may Your light \
        dance through the darkness of my uncertainty, \
        illuminating the path You've prepared.

        Amen.
        """
    }
}

// MARK: - Aurora Background

private struct AuroraBackground: View {
    let phase1: CGFloat
    let phase2: CGFloat
    let phase3: CGFloat

    var body: some View {
        ZStack {
            // Deep space base
            Color(hex: "0A0A0F")

            // Aurora layers
            GeometryReader { geo in
                ZStack {
                    // Primary aurora (purple/pink)
                    auroraLayer(
                        colors: [
                            Color.purpleAccent.opacity(Theme.Opacity.tertiary),
                            Color.fuchsiaPink.opacity(Theme.Opacity.lightMedium),
                            Color(hex: "EC4899").opacity(Theme.Opacity.subtle),
                            Color.clear
                        ],
                        phase: phase1,
                        yOffset: geo.size.height * 0.15,
                        height: geo.size.height * 0.5
                    )

                    // Secondary aurora (blue/cyan)
                    auroraLayer(
                        colors: [
                            Color.accentIndigo.opacity(Theme.Opacity.medium),
                            Color.blueAccent.opacity(Theme.Opacity.lightMedium),
                            Color(hex: "06B6D4").opacity(Theme.Opacity.light),
                            Color.clear
                        ],
                        phase: phase2,
                        yOffset: geo.size.height * 0.25,
                        height: geo.size.height * 0.4
                    )

                    // Tertiary glow (green hints)
                    auroraLayer(
                        colors: [
                            Color.greenTeal.opacity(Theme.Opacity.subtle),
                            Color.emeraldGreen.opacity(Theme.Opacity.light),
                            Color.clear
                        ],
                        phase: phase3,
                        yOffset: geo.size.height * 0.3,
                        height: geo.size.height * 0.3
                    )

                    // Stars
                    StarsOverlay()
                }
            }

            // Subtle noise texture
            Rectangle()
                .fill(Color.white.opacity(Theme.Opacity.faint))
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }

    private func auroraLayer(colors: [Color], phase: CGFloat, yOffset: CGFloat, height: CGFloat) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 600, height: height)
            .blur(radius: 60)
            .offset(
                x: -100 + phase * 200,
                y: yOffset - phase * 50
            )
            .scaleEffect(x: 1 + phase * 0.3, y: 1 + phase * 0.2)
    }
}

// MARK: - Stars Overlay

private struct StarsOverlay: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<80 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let starSize = CGFloat.random(in: 1...2.5)
                let opacity = Double.random(in: 0.3...0.8)

                let path = Circle().path(in: CGRect(x: x, y: y, width: starSize, height: starSize))
                context.fill(path, with: .color(Color.white.opacity(opacity)))
            }
        }
    }
}

// MARK: - Aurora Prompt Chip

private struct AuroraPromptChip: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(Typography.Command.meta)
                Text(text)
                    .font(Typography.Command.meta)
            }
            .foregroundColor(Color.fuchsiaPink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.purpleAccent.opacity(Theme.Opacity.divider))
                    .overlay(
                        Capsule()
                            .stroke(Color.purpleAccent.opacity(Theme.Opacity.subtle), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aurora Action Button

private struct AuroraActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(Typography.Command.callout)
                Text(label)
                    .font(Typography.Icon.xxs)
            }
            .foregroundColor(Color.white.opacity(Theme.Opacity.heavy))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .stroke(Color.white.opacity(Theme.Opacity.overlay), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aurora Loading Indicator

private struct AuroraLoadingIndicator: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(Theme.Opacity.light), lineWidth: 2)
                .frame(width: 20, height: 20)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [Color.fuchsiaPink, Color.purpleAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuroraDreamsPage()
}
