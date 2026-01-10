//
//  SacredMinimalPage.swift
//  BibleStudy
//
//  Style C: Stripped-back simplicity with gentle breathing animations and meditative whitespace
//  Focuses on contemplative experience with minimal UI distractions
//

import SwiftUI

struct SacredMinimalPage: View {
    @State private var prayerText: String = ""
    @State private var breathePhase: CGFloat = 0
    @State private var isGenerating = false
    @State private var generatedPrayer: String = ""
    @State private var showPrayer = false
    @State private var focusMode = false
    @FocusState private var isTextFocused: Bool

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            VStack(spacing: 0) {
                // Top breathing indicator
                breathingIndicator
                    .padding(.top, 100)

                Spacer()

                // Main content
                if showPrayer {
                    prayerResultView
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    inputSection
                        .transition(.opacity)
                }

                Spacer()

                // Bottom action
                actionSection
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            // Deep charcoal base
            Color(hex: "141414")

            // Subtle center glow
            RadialGradient(
                colors: [
                    Color(hex: "1F1F1F"),
                    Color(hex: "141414")
                ],
                center: .center,
                startRadius: 100,
                endRadius: UIScreen.main.bounds.height * 0.5
            )

            // Breathing light at top
            VStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.decorativeCream.opacity(0.03 + breathePhase * 0.02),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(y: -150)
                    .scaleEffect(1 + breathePhase * 0.1)

                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Breathing Indicator

    private var breathingIndicator: some View {
        VStack(spacing: 20) {
            // Concentric circles
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            Color.decorativeCream.opacity(0.1 - Double(index) * 0.03),
                            lineWidth: 1
                        )
                        .frame(
                            width: CGFloat(40 + index * 20) * (1 + breathePhase * 0.15),
                            height: CGFloat(40 + index * 20) * (1 + breathePhase * 0.15)
                        )
                }

                // Center dot
                Circle()
                    .fill(Color.decorativeCream.opacity(0.6 + breathePhase * 0.2))
                    .frame(width: 8, height: 8)
            }

            // Breathe text
            Text(breathePhase > 0.5 ? "exhale" : "inhale")
                .font(Typography.Command.meta.weight(.light))
                .tracking(4)
                .foregroundColor(Color.decorativeCream.opacity(Theme.Opacity.lightMedium))
                .animation(.easeInOut(duration: 2), value: breathePhase)
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 32) {
            // Prompt
            VStack(spacing: 12) {
                Text("What's on your heart?")
                    .font(Typography.Scripture.prompt.weight(.light))
                    .foregroundColor(Color.decorativeMarble)

                Text("Speak freely. Let your thoughts flow.")
                    .font(Typography.Icon.sm.weight(.light))
                    .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.heavy))
            }

            // Text input
            ZStack {
                // Subtle background
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
                    .opacity(isTextFocused ? 1 : 0)

                // Minimal line
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.decorativeCream.opacity(isTextFocused ? 0.3 : 0.15),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                }

                // Text editor
                TextEditor(text: $prayerText)
                    .font(Typography.Scripture.body.weight(.light))
                    .foregroundColor(Color.decorativeMarble)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFocused)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 120)

                // Placeholder
                if prayerText.isEmpty && !isTextFocused {
                    Text("Tap to begin...")
                        .font(Typography.Scripture.body.weight(.light))
                        .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.lightMedium))
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)

            // Word count (subtle)
            if !prayerText.isEmpty {
                Text("\(prayerText.split(separator: " ").count) words")
                    .font(Typography.Icon.xxs.weight(.light))
                    .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.subtle))
            }
        }
    }

    // MARK: - Prayer Result View

    private var prayerResultView: some View {
        VStack(spacing: 40) {
            // Small icon
            Image(systemName: "hands.clap")
                .font(Typography.Icon.lg.weight(.light))
                .foregroundColor(Color.decorativeCream.opacity(Theme.Opacity.tertiary))

            // Prayer text
            Text(generatedPrayer.isEmpty ? samplePrayer : generatedPrayer)
                .font(Typography.Scripture.body.weight(.light))
                .foregroundColor(Color.decorativeMarble)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .fixedSize(horizontal: false, vertical: true)

            // Scripture
            Text("Romans 8:26")
                .font(Typography.Icon.xs.weight(.light))
                .tracking(2)
                .foregroundColor(Color.decorativeCream.opacity(Theme.Opacity.medium))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: 24) {
            if showPrayer {
                // Action row
                HStack(spacing: 40) {
                    MinimalActionButton(icon: "arrow.counterclockwise", label: "Again") {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showPrayer = false
                            prayerText = ""
                        }
                    }

                    MinimalActionButton(icon: "square.and.arrow.up", label: "Share") {}

                    MinimalActionButton(icon: "heart", label: "Save") {}
                }
            } else {
                // Generate button
                Button(action: generate) {
                    HStack(spacing: 12) {
                        if isGenerating {
                            // Minimal loading indicator
                            Circle()
                                .fill(Color.decorativeCream)
                                .frame(width: 6, height: 6)
                                .scaleEffect(breathePhase > 0.5 ? 1.3 : 0.7)
                        } else {
                            Image(systemName: "wand.and.rays")
                                .font(Typography.Icon.md.weight(.light))
                        }

                        Text(isGenerating ? "Creating..." : "Create Prayer")
                            .font(Typography.Command.subheadline)
                            .tracking(1)
                    }
                    .foregroundColor(Color(hex: "141414"))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.decorativeCream)
                    )
                }
                .disabled(isGenerating || prayerText.isEmpty)
                .opacity(prayerText.isEmpty ? 0.4 : 1)

                // Skip option
                if !isGenerating {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showPrayer = true
                        }
                    }) {
                        Text("or use a guided template")
                            .font(Typography.Icon.xs.weight(.light))
                            .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.medium))
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func generate() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isGenerating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                isGenerating = false
                showPrayer = true
            }
        }
    }

    private var samplePrayer: String {
        """
        Lord, in the quiet of this moment,
        I bring my unspoken thoughts to You.

        You know what words cannot express,
        the longings too deep for language.

        Meet me here in the silence.
        Let Your Spirit intercede where I cannot.

        Amen.
        """
    }
}

// MARK: - Minimal Action Button

struct MinimalActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(Typography.Icon.base.weight(.light))
                Text(label)
                    .font(Typography.Icon.xxs.weight(.light))
                    .tracking(1)
            }
            .foregroundColor(Color.stoneGray)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SacredMinimalPage()
}
