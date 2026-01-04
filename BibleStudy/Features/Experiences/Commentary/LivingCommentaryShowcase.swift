import SwiftUI

// MARK: - Living Commentary Showcase
// Directory for browsing all Living Commentary design variants
// Uses Candlelit Chapel dark theme for premium feel

struct LivingCommentaryShowcase: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    private let variants = CommentaryVariant.allCases

    var body: some View {
        NavigationStack {
            ZStack {
                // Candlelit dark background
                backgroundLayer

                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Variant cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            ForEach(Array(variants.enumerated()), id: \.element) { index, variant in
                                NavigationLink(destination: variant.destinationView) {
                                    variantCard(variant: variant, index: index)
                                }
                                .buttonStyle(VariantCardButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            // Candlelit stone
            Color(hex: "1A1816")

            // Subtle warm glow
            RadialGradient(
                colors: [
                    Color(hex: "2a2520").opacity(0.5),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )

            // Ambient gold accent
            RadialGradient(
                colors: [
                    Color.commentaryGold.opacity(0.03),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "E8E4DC").opacity(0.6))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            VStack(spacing: 8) {
                Text("LIVING COMMENTARY")
                    .font(.custom("Cinzel-Regular", size: 12))
                    .tracking(4)
                    .foregroundStyle(Color.commentaryAccent)

                Text("Design Variants")
                    .font(.custom("CormorantGaramond-SemiBold", size: 28))
                    .foregroundStyle(Color(hex: "E8E4DC"))

                Text("Explore three distinct approaches to\nAI-powered marginalia")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "E8E4DC").opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.bottom, 8)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .animation(.spring(duration: 0.6), value: isVisible)
    }

    // MARK: - Variant Card

    private func variantCard(variant: CommentaryVariant, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Preview graphic
            variant.previewGraphic
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1a1816"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.commentaryAccent.opacity(0.1), lineWidth: 1)
                )

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(variant.badge)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color.commentaryAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.commentaryAccent.opacity(0.15))
                        )

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.commentaryAccent.opacity(0.5))
                }

                Text(variant.title)
                    .font(.custom("CormorantGaramond-SemiBold", size: 20))
                    .foregroundStyle(Color(hex: "E8E4DC"))

                Text(variant.description)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "E8E4DC").opacity(0.6))
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "252220"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "3a3530"), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .spring(duration: 0.5).delay(0.1 + Double(index) * 0.1),
            value: isVisible
        )
    }
}

// MARK: - Variant Card Button Style

struct VariantCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Commentary Variant

enum CommentaryVariant: String, CaseIterable, Identifiable {
    case chipBased
    case editorialMargin
    case immersiveScroll

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chipBased: return "Chip-Based Selection"
        case .editorialMargin: return "Editorial Margin"
        case .immersiveScroll: return "Immersive Scroll"
        }
    }

    var badge: String {
        switch self {
        case .chipBased: return "INTERACTIVE"
        case .editorialMargin: return "MANUSCRIPT"
        case .immersiveScroll: return "PARALLAX"
        }
    }

    var description: String {
        switch self {
        case .chipBased:
            return "Tap phrase chips below the verse to reveal contextual marginalia cards one at a time."
        case .editorialMargin:
            return "Two-column manuscript layout with all insights visible simultaneously and animated connection lines."
        case .immersiveScroll:
            return "Vertical scrolling experience with parallax depth and AI that streams as cards enter the viewport."
        }
    }

    @ViewBuilder
    var previewGraphic: some View {
        switch self {
        case .chipBased:
            ChipBasedPreview()
        case .editorialMargin:
            EditorialMarginPreview()
        case .immersiveScroll:
            ImmersiveScrollPreview()
        }
    }

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .chipBased:
            LivingCommentaryView()
        case .editorialMargin:
            EditorialMarginView()
        case .immersiveScroll:
            ImmersiveScrollView()
        }
    }
}

// MARK: - Preview Graphics

struct ChipBasedPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            // Simulated verse text
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "E8E4DC").opacity(0.2))
                .frame(width: 180, height: 8)

            // Simulated chips
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i == 1 ? Color.commentaryAccent : Color.commentaryAccent.opacity(0.2))
                        .frame(width: i == 1 ? 60 : 50, height: 20)
                }
            }

            // Simulated card
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "E8E4DC").opacity(0.1))
                .frame(width: 160, height: 40)
        }
    }
}

struct EditorialMarginPreview: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left column (verse)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "E8E4DC").opacity(0.25))
                    .frame(width: 80, height: 6)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "E8E4DC").opacity(0.2))
                    .frame(width: 100, height: 6)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "E8E4DC").opacity(0.15))
                    .frame(width: 70, height: 6)
            }

            // Connection lines
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                path.addCurve(
                    to: CGPoint(x: 20, y: 5),
                    control1: CGPoint(x: 10, y: 10),
                    control2: CGPoint(x: 10, y: 5)
                )
            }
            .stroke(Color.commentaryAccent.opacity(0.4), lineWidth: 1)
            .frame(width: 20, height: 60)

            // Right column (marginalia)
            VStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "E8E4DC").opacity(0.1))
                        .frame(width: 60, height: 24)
                }
            }
        }
    }
}

struct ImmersiveScrollPreview: View {
    var body: some View {
        VStack(spacing: 10) {
            // Progress bar
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.commentaryAccent.opacity(0.3))
                .frame(width: 120, height: 2)
                .overlay(
                    HStack {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.commentaryAccent)
                            .frame(width: 40, height: 2)
                        Spacer()
                    }
                )

            // Stacked cards with parallax offset
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "E8E4DC").opacity(0.1 - Double(i) * 0.03))
                        .frame(width: 140 - CGFloat(i) * 10, height: 35)
                        .offset(y: CGFloat(i) * 12)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LivingCommentaryShowcase()
}
