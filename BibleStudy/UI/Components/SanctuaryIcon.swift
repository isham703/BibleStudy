import SwiftUI

// MARK: - Illuminated Icon
// Unified icon component supporting both Streamline assets and SF Symbols
// Provides consistent styling aligned with the Illuminated Manuscript aesthetic

struct SanctuaryIcon: View {

    // MARK: - Icon Source

    enum IconSource {
        case streamline(String)  // Asset catalog name
        case sfSymbol(String)    // SF Symbol name

        /// Convenience for getting the raw name
        var name: String {
            switch self {
            case .streamline(let name), .sfSymbol(let name):
                return name
            }
        }
    }

    // MARK: - Properties

    let source: IconSource
    var size: CGFloat = 24
    var color: Color = Color.accentBronze
    var secondaryColor: Color? = nil
    var renderingMode: SymbolRenderingMode = .monochrome
    var weight: Font.Weight = .regular

    // MARK: - Body

    var body: some View {
        switch source {
        case .streamline(let name):
            // Streamline icons from asset catalog
            Image(name)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundStyle(color)

        case .sfSymbol(let name):
            // SF Symbols with enhanced rendering
            // swiftlint:disable:next hardcoded_font_system
            if let secondary = secondaryColor {
                Image(systemName: name)
                    .symbolRenderingMode(.palette)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Font.system(size: size, weight: weight))
                    .foregroundStyle(color, secondary)
            } else {
                Image(systemName: name)
                    .symbolRenderingMode(renderingMode)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Font.system(size: size, weight: weight))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension IlluminatedIcon {

    /// Create an illuminated icon from an SF Symbol name
    init(
        systemName: String,
        size: CGFloat = 24,
        color: Color = Color.accentBronze,
        weight: Font.Weight = .regular
    ) {
        self.source = .sfSymbol(systemName)
        self.size = size
        self.color = color
        self.weight = weight
    }

    /// Create an illuminated icon from a Streamline asset name
    init(
        assetName: String,
        size: CGFloat = 24,
        color: Color = Color.accentBronze
    ) {
        self.source = .streamline(assetName)
        self.size = size
        self.color = color
    }

    /// Create a two-color palette icon (gold + ink aesthetic)
    init(
        systemName: String,
        size: CGFloat = 24,
        primaryColor: Color = Color.accentBronze,
        secondaryColor: Color = Color.surfaceRaised
    ) {
        self.source = .sfSymbol(systemName)
        self.size = size
        self.color = primaryColor
        self.secondaryColor = secondaryColor
        self.renderingMode = .palette
    }
}

// MARK: - View Modifiers

extension IlluminatedIcon {

    /// Apply hierarchical rendering for depth
    func hierarchical() -> IlluminatedIcon {
        var copy = self
        copy.renderingMode = .hierarchical
        return copy
    }

    /// Apply monochrome rendering
    func monochrome() -> IlluminatedIcon {
        var copy = self
        copy.renderingMode = .monochrome
        copy.secondaryColor = nil
        return copy
    }

    /// Set icon weight
    func weight(_ weight: Font.Weight) -> IlluminatedIcon {
        var copy = self
        copy.weight = weight
        return copy
    }
}

// MARK: - Preview

#Preview("Illuminated Icons") {
    VStack(spacing: Theme.Spacing.xl) {
        Text("SF Symbol Icons")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.xl - 4) {
            SanctuaryIcon(source: .sfSymbol("scroll.fill"), size: 28)
            SanctuaryIcon(source: .sfSymbol("book.closed.fill"), size: 28, color: Color.navyDeep)
            SanctuaryIcon(source: .sfSymbol("paintbrush.pointed.fill"), size: 28, color: Color.bibleOlive)
        }

        Text("Palette Rendering")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.xl - 4) {
            SanctuaryIcon(
                source: .sfSymbol("text.book.closed.fill"),
                size: 28,
                color: Color.accentBronze,
                secondaryColor: Color.surfaceRaised
            )
            SanctuaryIcon(
                source: .sfSymbol("seal.fill"),
                size: 28,
                color: Color.navyDeep,
                secondaryColor: Color.accentBronze
            )
        }

        Text("Hierarchical Rendering")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.xl - 4) {
            SanctuaryIcon(source: .sfSymbol("sparkle.magnifyingglass"), size: 28)
                .hierarchical()
            SanctuaryIcon(source: .sfSymbol("books.vertical.fill"), size: 28, color: Color.studyPurple)
                .hierarchical()
        }
    }
    .padding()
    .background(Color.surfaceParchment)
}
