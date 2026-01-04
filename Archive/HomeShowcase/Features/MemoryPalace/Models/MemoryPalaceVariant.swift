import SwiftUI

// MARK: - Memory Palace Variant
// Enum defining the three visual style variations for the Memory Palace showcase
// Each variant demonstrates scripture memorization with distinct aesthetics

enum MemoryPalaceVariant: String, CaseIterable, Identifiable {
    case candlelitPalace = "Candlelit Palace"
    case scholarlyStudy = "Scholarly Study"
    case celestialCathedral = "Celestial Cathedral"

    var id: String { rawValue }

    // MARK: - Display Properties

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .candlelitPalace:
            return "Gothic Romantic"
        case .scholarlyStudy:
            return "Editorial Minimalist"
        case .celestialCathedral:
            return "Cosmic Sacred"
        }
    }

    var description: String {
        switch self {
        case .candlelitPalace:
            return "Warm amber glow, medieval chapel atmosphere with flickering candlelight and floating embers."
        case .scholarlyStudy:
            return "Clean light-mode design with typography focus, marginalia annotations, and crisp paper texture."
        case .celestialCathedral:
            return "Mystical deep blues and purples, parallax starfield, nebula gradients and constellation effects."
        }
    }

    var icon: String {
        switch self {
        case .candlelitPalace:
            return "flame.fill"
        case .scholarlyStudy:
            return "text.book.closed.fill"
        case .celestialCathedral:
            return "sparkles"
        }
    }

    var accentColor: Color {
        switch self {
        case .candlelitPalace:
            return .candleAmber
        case .scholarlyStudy:
            return .scholarIndigo
        case .celestialCathedral:
            return .celestialPurple
        }
    }

    // Reuse existing BackgroundStyle from HomePageVariant.swift
    var backgroundStyle: HomePageVariant.BackgroundStyle {
        switch self {
        case .candlelitPalace, .celestialCathedral:
            return .dark
        case .scholarlyStudy:
            return .light
        }
    }

    // MARK: - Color Palette for Preview Strip

    func paletteColor(_ index: Int) -> Color {
        switch self {
        case .candlelitPalace:
            return [.candleAmber, .candleCore, .roseIncense, .moonlitParchment][index]
        case .scholarlyStudy:
            return [.scholarIndigo, .marginRed, .vellumCream, .scholarInk][index]
        case .celestialCathedral:
            return [.celestialPurple, .celestialPink, .celestialCyan, .starlight][index]
        }
    }

    // MARK: - Navigation Destination

    @ViewBuilder
    var page: some View {
        switch self {
        case .candlelitPalace:
            CandlelitPalacePage()
        case .scholarlyStudy:
            ScholarlyStudyPalacePage()
        case .celestialCathedral:
            CelestialCathedralPalacePage()
        }
    }
}
