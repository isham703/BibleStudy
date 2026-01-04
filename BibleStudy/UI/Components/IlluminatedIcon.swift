import SwiftUI

// MARK: - Illuminated Icon
// Unified icon component supporting both Streamline assets and SF Symbols
// Provides consistent styling aligned with the Illuminated Manuscript aesthetic

struct IlluminatedIcon: View {

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
    var color: Color = .divineGold
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
            if let secondary = secondaryColor {
                Image(systemName: name)
                    .symbolRenderingMode(.palette)
                    .font(Font.system(size: size, weight: weight))
                    .foregroundStyle(color, secondary)
            } else {
                Image(systemName: name)
                    .symbolRenderingMode(renderingMode)
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
        color: Color = .divineGold,
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
        color: Color = .divineGold
    ) {
        self.source = .streamline(assetName)
        self.size = size
        self.color = color
    }

    /// Create a two-color palette icon (gold + ink aesthetic)
    init(
        systemName: String,
        size: CGFloat = 24,
        primaryColor: Color = .divineGold,
        secondaryColor: Color = .agedInk
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
    VStack(spacing: AppTheme.Spacing.xl) {
        Text("SF Symbol Icons")
            .font(Typography.UI.headline)

        HStack(spacing: AppTheme.Spacing.xl - 4) {
            IlluminatedIcon(source: .sfSymbol("scroll.fill"), size: 28)
            IlluminatedIcon(source: .sfSymbol("book.closed.fill"), size: 28, color: .lapisLazuli)
            IlluminatedIcon(source: .sfSymbol("paintbrush.pointed.fill"), size: 28, color: .malachite)
        }

        Text("Palette Rendering")
            .font(Typography.UI.headline)

        HStack(spacing: AppTheme.Spacing.xl - 4) {
            IlluminatedIcon(
                source: .sfSymbol("text.book.closed.fill"),
                size: 28,
                color: .divineGold,
                secondaryColor: .monasteryBlack
            )
            IlluminatedIcon(
                source: .sfSymbol("seal.fill"),
                size: 28,
                color: .lapisLazuli,
                secondaryColor: .illuminatedGold
            )
        }

        Text("Hierarchical Rendering")
            .font(Typography.UI.headline)

        HStack(spacing: AppTheme.Spacing.xl - 4) {
            IlluminatedIcon(source: .sfSymbol("sparkle.magnifyingglass"), size: 28)
                .hierarchical()
            IlluminatedIcon(source: .sfSymbol("books.vertical.fill"), size: 28, color: .amethyst)
                .hierarchical()
        }
    }
    .padding()
    .background(Color.freshVellum)
}
