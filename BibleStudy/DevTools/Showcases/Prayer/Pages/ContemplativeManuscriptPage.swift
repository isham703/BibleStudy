//
//  ContemplativeManuscriptPage.swift
//  BibleStudy
//
//  Style A: Illuminated manuscript-inspired prayer creation experience
//  Features ornate gold accents, flowing calligraphy typography, and reverent animations
//

import SwiftUI

struct ContemplativeManuscriptPage: View {
    @State private var prayerText: String = ""
    @State private var selectedCategory: PrayerCategory = .gratitude
    @State private var isGenerating = false
    @State private var generatedPrayer: String = ""
    @State private var showPrayer = false
    @State private var illuminationPhase: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool

    enum PrayerCategory: String, CaseIterable {
        case gratitude = "Gratitude"
        case guidance = "Guidance"
        case healing = "Healing"
        case peace = "Peace"
        case strength = "Strength"
        case wisdom = "Wisdom"

        var icon: String {
            switch self {
            case .gratitude: return "heart.fill"
            case .guidance: return "star.fill"
            case .healing: return "leaf.fill"
            case .peace: return "wind"
            case .strength: return "flame.fill"
            case .wisdom: return "lightbulb.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // Parchment Background
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Ornamental Header
                    headerSection

                    // Main Content Area
                    contentSection

                    // Generated Prayer Display
                    if showPrayer {
                        generatedPrayerSection
                    }

                    Spacer(minLength: 100)
                }
            }

            // Floating Create Button
            VStack {
                Spacer()
                createButton
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                illuminationPhase = 1
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Base dark parchment
            Color.surfaceCharcoal

            // Vignette effect
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.lightMedium)
                ],
                center: .center,
                startRadius: UIScreen.main.bounds.width * 0.3,
                endRadius: UIScreen.main.bounds.width * 0.8
            )

            // Subtle texture overlay
            GeometryReader { geo in
                Canvas { context, size in
                    for _ in 0..<50 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let path = Circle().path(in: CGRect(x: x, y: y, width: 1, height: 1))
                        context.fill(path, with: .color(Color.accentBronze.opacity(Theme.Opacity.faint)))
                    }
                }
            }

            // Animated gold shimmer at edges
            LinearGradient(
                colors: [
                    Color.accentBronze.opacity(0.08 + illuminationPhase * 0.04),
                    Color.clear,
                    Color.clear,
                    Color.accentBronze.opacity(0.08 + illuminationPhase * 0.04)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Ornamental top border
            ShowcaseOrnamentalDivider()
                .padding(.top, 80)

            // Illuminated initial
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentBronze.opacity(Theme.Opacity.subtle),
                                Color.accentBronze.opacity(Theme.Opacity.overlay),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + illuminationPhase * 0.1)

                // Inner circle
                Circle()
                    .fill(Color.surfaceWarm)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.goldWarm, Color.accentBronze, Color.ochreDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                // Letter P (for Prayer)
                Text("P")
                    .font(.custom("Cinzel", size: 42))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.goldWarm, Color.accentBronze],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            // Title
            VStack(spacing: 8) {
                Text("PRAYER")
                    .font(.custom("Cinzel", size: 14))
                    .fontWeight(.bold)
                    .tracking(6)
                    .foregroundColor(Color.accentBronze)

                Text("from the Deep")
                    .font(.custom("Cormorant Garamond", size: 32))
                    .italic()
                    .foregroundColor(Color.decorativeMarble)
            }

            // Subtitle
            Text("Let the Spirit guide your words as you pour out your heart in sacred conversation")
                .font(.custom("Cormorant Garamond", size: 16))
                .foregroundColor(Color.stoneGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            ShowcaseOrnamentalDivider()
        }
        .padding(.bottom, 32)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 28) {
            // Category Selection
            categorySelection

            // Prayer Intention Input
            intentionInput
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Category Selection

    private var categorySelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Label
            Text("INTENTION")
                .font(Typography.Icon.xxs.weight(.bold))
                .tracking(2.5)
                .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))

            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PrayerCategory.allCases, id: \.self) { category in
                        ShowcaseCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Intention Input

    private var intentionInput: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Label
            Text("YOUR HEART'S CRY")
                .font(Typography.Icon.xxs.weight(.bold))
                .tracking(2.5)
                .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))

            // Input Area
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color.surfaceWarm)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(
                                isTextFieldFocused
                                    ? LinearGradient(
                                        colors: [Color.accentBronze.opacity(Theme.Opacity.medium), Color.ochreDeep.opacity(Theme.Opacity.subtle)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.accentBronze.opacity(Theme.Opacity.divider), Color.ochreDeep.opacity(Theme.Opacity.overlay)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: 1
                            )
                    )

                // Text Editor
                TextEditor(text: $prayerText)
                    .font(.custom("Cormorant Garamond", size: 18))
                    .foregroundColor(Color.decorativeMarble)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFieldFocused)
                    .padding(16)
                    .frame(minHeight: 140)

                // Placeholder
                if prayerText.isEmpty {
                    Text("Share what weighs on your heart, what fills you with joy, or where you seek divine guidance...")
                        .font(.custom("Cormorant Garamond", size: 18))
                        .foregroundColor(Color.stoneGray.opacity(Theme.Opacity.tertiary))
                        .padding(20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Generated Prayer Section

    private var generatedPrayerSection: some View {
        VStack(spacing: 20) {
            // Divider
            ShowcaseOrnamentalDivider()
                .padding(.top, 32)

            // Section Label
            Text("YOUR PRAYER")
                .font(Typography.Icon.xxs.weight(.bold))
                .tracking(2.5)
                .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))

            // Prayer Card
            VStack(spacing: 16) {
                // Drop cap and text
                HStack(alignment: .top, spacing: 12) {
                    Text("L")
                        .font(.custom("Cinzel", size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.goldWarm, Color.accentBronze],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 48)

                    Text(generatedPrayer.isEmpty ? samplePrayer : generatedPrayer)
                        .font(.custom("Cormorant Garamond", size: 18))
                        .foregroundColor(Color.decorativeMarble)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Scripture Reference
                HStack {
                    Spacer()
                    Text("- Based on Psalm 42:1")
                        .font(.custom("Cormorant Garamond", size: 14))
                        .italic()
                        .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Color.surfaceWarm.opacity(Theme.Opacity.pressed))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.accentBronze.opacity(Theme.Opacity.subtle), Color.ochreDeep.opacity(Theme.Opacity.divider)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 24)

            // Action Buttons
            HStack(spacing: 16) {
                ShowcaseActionButton(icon: "doc.on.doc", label: "Copy") {}
                ShowcaseActionButton(icon: "square.and.arrow.up", label: "Share") {}
                ShowcaseActionButton(icon: "bookmark", label: "Save") {}
            }
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.6)) {
                isGenerating = true
            }
            // Simulate AI generation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isGenerating = false
                    showPrayer = true
                }
            }
        }) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.surfaceCharcoal))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "sparkles")
                        .font(Typography.Icon.base)
                }
                Text(isGenerating ? "Creating Prayer..." : "Create Prayer")
                    .font(.custom("Cinzel", size: 16))
                    .fontWeight(.medium)
            }
            .foregroundColor(Color.surfaceCharcoal)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.goldWarm, Color.accentBronze, Color(hex: "C9943D")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.accentBronze.opacity(Theme.Opacity.lightMedium), radius: 12, x: 0, y: 6)
            )
        }
        .disabled(isGenerating)
        .padding(.bottom, 40)
    }

    private var samplePrayer: String {
        "ord, as the deer pants for streams of water, so my soul longs for You. In this moment of stillness, I bring before You the burdens I carry and the hopes I hold. Fill me with Your peace that surpasses all understanding. Guide my steps along the paths of righteousness. Let Your light illuminate the dark places within me, transforming my fears into faith and my worries into worship. Amen."
    }
}

// MARK: - Showcase Ornamental Divider

private struct ShowcaseOrnamentalDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.accentBronze.opacity(Theme.Opacity.lightMedium)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center ornament
            HStack(spacing: 4) {
                Image(systemName: "diamond.fill")
                    .font(Typography.Icon.xxxs)
                Image(systemName: "diamond.fill")
                    .font(Typography.Icon.xxxs)
                Image(systemName: "diamond.fill")
                    .font(Typography.Icon.xxxs)
            }
            .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.tertiary))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentBronze.opacity(Theme.Opacity.lightMedium), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Showcase Category Chip

private struct ShowcaseCategoryChip: View {
    let category: ContemplativeManuscriptPage.PrayerCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(Typography.Command.caption)
                Text(category.rawValue)
                    .font(.custom("Cinzel", size: 12))
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? Color.surfaceCharcoal : Color.accentBronze)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.goldWarm, Color.accentBronze],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.surfaceWarm, Color.surfaceWarm],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                Color.accentBronze.opacity(isSelected ? 0 : 0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Showcase Action Button

private struct ShowcaseActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(Typography.Icon.base)
                Text(label)
                    .font(Typography.Icon.xxs)
            }
            .foregroundColor(Color.accentBronze)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Color.surfaceWarm)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .stroke(Color.accentBronze.opacity(Theme.Opacity.light), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ContemplativeManuscriptPage()
}
