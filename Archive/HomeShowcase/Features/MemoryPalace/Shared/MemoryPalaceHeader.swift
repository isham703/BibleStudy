import SwiftUI

// MARK: - Memory Palace Header
// Shared header component for all Memory Palace variants
// Contains dismiss button, title, verse reference, and help button

struct MemoryPalaceHeader: View {
    @Environment(\.dismiss) private var dismiss
    let accentColor: Color
    let reference: String
    let isVisible: Bool

    init(
        accentColor: Color,
        reference: String = PalaceRoom.verseReference,
        isVisible: Bool = true
    ) {
        self.accentColor = accentColor
        self.reference = reference
        self.isVisible = isVisible
    }

    var body: some View {
        HStack {
            // Dismiss button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: HomeShowcaseTheme.Size.touchTarget, height: HomeShowcaseTheme.Size.touchTarget)
            }

            Spacer()

            // Center title and reference
            VStack(spacing: 2) {
                Text("MEMORY PALACE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(accentColor)

                Text(reference)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Help button
            Button(action: {}) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: HomeShowcaseTheme.Size.touchTarget, height: HomeShowcaseTheme.Size.touchTarget)
            }
        }
        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
        .accessibleAnimation(HomeShowcaseTheme.Animation.reverent, value: isVisible)
    }
}

// MARK: - Light Mode Variant

struct MemoryPalaceHeaderLight: View {
    @Environment(\.dismiss) private var dismiss
    let accentColor: Color
    let reference: String
    let isVisible: Bool

    init(
        accentColor: Color,
        reference: String = PalaceRoom.verseReference,
        isVisible: Bool = true
    ) {
        self.accentColor = accentColor
        self.reference = reference
        self.isVisible = isVisible
    }

    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.scholarInk.opacity(0.5))
                    .frame(width: HomeShowcaseTheme.Size.touchTarget, height: HomeShowcaseTheme.Size.touchTarget)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("MEMORY PALACE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(accentColor)

                Text(reference)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.scholarInk.opacity(0.5))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.scholarInk.opacity(0.5))
                    .frame(width: HomeShowcaseTheme.Size.touchTarget, height: HomeShowcaseTheme.Size.touchTarget)
            }
        }
        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
        .accessibleAnimation(HomeShowcaseTheme.Animation.reverent, value: isVisible)
    }
}

// MARK: - Preview

#Preview("Dark Header") {
    ZStack {
        Color.celestialDeep
        MemoryPalaceHeader(accentColor: .celestialPurple)
    }
    .ignoresSafeArea()
}

#Preview("Light Header") {
    ZStack {
        Color.vellumCream
        MemoryPalaceHeaderLight(accentColor: .scholarIndigo)
    }
    .ignoresSafeArea()
}
