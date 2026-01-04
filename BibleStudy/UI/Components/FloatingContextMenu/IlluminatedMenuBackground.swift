//
//  IlluminatedMenuBackground.swift
//  BibleStudy
//
//  Parchment-textured background with gold leaf border for the IlluminatedContextMenu.
//  Inspired by illuminated manuscript marginalia aesthetics.
//

import SwiftUI

// MARK: - Illuminated Menu Background

/// A manuscript-styled background for the context menu featuring:
/// - Aged parchment texture with vignette
/// - Gold leaf gradient border (from DropCapView pattern)
/// - Corner flourish dots
/// - Arrow indicator pointing to selected verse
struct IlluminatedMenuBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Direction the arrow points
    var arrowDirection: MenuArrowDirection = .down

    /// Horizontal offset of the arrow from center
    var arrowOffset: CGFloat = 0

    /// Whether to show corner flourishes
    var showCornerFlourishes: Bool = true

    /// Animation state for border shimmer
    @State private var shimmerPhase: CGFloat = 0

    // MARK: - Constants

    private let cornerRadius: CGFloat = 12
    private let borderWidth: CGFloat = 1.5
    private let arrowWidth: CGFloat = 16
    private let arrowHeight: CGFloat = 10
    private let flourishSize: CGFloat = 5
    private let flourishInset: CGFloat = 10

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let menuHeight = geometry.size.height - arrowHeight

            ZStack {
                VStack(spacing: 0) {
                    // Arrow at top when menu is below verse
                    if arrowDirection == .up {
                        illuminatedArrow
                            .offset(x: arrowOffset)
                    }

                    // Main menu background
                    ZStack {
                        // Layer 1: Base parchment fill
                        parchmentBackground

                        // Layer 2: Vignette effect
                        vignetteOverlay

                        // Layer 3: Gold leaf border
                        goldLeafBorder

                        // Layer 4: Corner flourishes
                        if showCornerFlourishes {
                            cornerFlourishes(in: geometry.size, menuHeight: menuHeight)
                        }
                    }
                    .frame(height: menuHeight)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                    // Arrow at bottom when menu is above verse
                    if arrowDirection == .down {
                        illuminatedArrow
                            .offset(x: arrowOffset)
                    }
                }

                // Outer glow
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.clear)
                    .frame(height: menuHeight)
                    .shadow(
                        color: Color.Glow.indigoAmbient,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .offset(y: arrowDirection == .up ? arrowHeight / 2 : -arrowHeight / 2)
            }
        }
    }

    // MARK: - Parchment Background

    private var parchmentBackground: some View {
        ZStack {
            // Base color (theme-aware)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.chapelShadow
                    : Color.agedParchment
                )

            // Subtle texture overlay using material
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.3 : 0.08)
        }
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12),
            radius: 16,
            x: 0,
            y: 8
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06),
            radius: 4,
            x: 0,
            y: 2
        )
    }

    // MARK: - Vignette Effect

    private var vignetteOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [
                        .clear,
                        .black.opacity(colorScheme == .dark ? 0.15 : 0.06)
                    ],
                    center: .center,
                    startRadius: 60,
                    endRadius: 180
                )
            )
    }

    // MARK: - Gold Leaf Border

    private var goldLeafBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.illuminatedGold,
                        Color.divineGold,
                        Color.burnishedGold,
                        Color.divineGold,
                        Color.illuminatedGold
                    ],
                    startPoint: UnitPoint(x: shimmerPhase, y: 0),
                    endPoint: UnitPoint(x: shimmerPhase + 1, y: 1)
                ),
                lineWidth: borderWidth
            )
            .onAppear {
                // Subtle shimmer animation
                withAnimation(AppTheme.Animation.contemplative.repeatForever(autoreverses: false)) {
                    shimmerPhase = 1
                }
            }
    }

    // MARK: - Corner Flourishes

    private func cornerFlourishes(in size: CGSize, menuHeight: CGFloat) -> some View {
        let halfWidth = (size.width / 2) - flourishInset
        let halfHeight = (menuHeight / 2) - flourishInset

        return ZStack {
            ForEach(0..<4, id: \.self) { corner in
                Circle()
                    .fill(Color.divineGold)
                    .frame(width: flourishSize, height: flourishSize)
                    .shadow(
                        color: Color.Glow.indigoBright,
                        radius: 3,
                        x: 0,
                        y: 0
                    )
                    .offset(
                        x: (corner % 2 == 0 ? -1 : 1) * halfWidth,
                        y: (corner < 2 ? -1 : 1) * halfHeight
                    )
            }
        }
        .offset(y: arrowDirection == .up ? arrowHeight / 2 : -arrowHeight / 2)
    }

    // MARK: - Arrow

    private var illuminatedArrow: some View {
        ZStack {
            // Arrow fill matching parchment
            MenuArrow(pointsUp: arrowDirection == .up)
                .fill(colorScheme == .dark
                    ? Color.chapelShadow
                    : Color.agedParchment
                )
                .frame(width: arrowWidth, height: arrowHeight)

            // Gold stroke on arrow
            MenuArrow(pointsUp: arrowDirection == .up)
                .stroke(
                    Color.divineGold,
                    lineWidth: borderWidth
                )
                .frame(width: arrowWidth, height: arrowHeight)
        }
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.lg) {
            IlluminatedMenuBackground(arrowDirection: .down)
                .frame(width: 260, height: 250)

            Text("Selected verse")
                .padding()
                .background(Color.selectedBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Selected verse")
                .padding()
                .background(Color.selectedBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

            IlluminatedMenuBackground(arrowDirection: .up)
                .frame(width: 260, height: 250)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Arrow Offset") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        HStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                IlluminatedMenuBackground(arrowDirection: .down, arrowOffset: -60)
                    .frame(width: 260, height: 200)

                HStack {
                    Text("Verse at edge")
                        .padding()
                        .background(Color.selectedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
    }
}

#Preview("No Flourishes") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        IlluminatedMenuBackground(
            arrowDirection: .up,
            showCornerFlourishes: false
        )
        .frame(width: 260, height: 200)
    }
}
