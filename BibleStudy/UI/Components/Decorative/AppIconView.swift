import SwiftUI

// MARK: - Sanctuary Icon
// Unified icon component supporting both Streamline assets and SF Symbols
// Provides consistent styling aligned with the Stoic-Roman aesthetic

struct AppIconView: View {

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
    var color: Color = Color("AccentBronze")
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

extension AppIconView {

    /// Create an illuminated icon from an SF Symbol name
    init(
        systemName: String,
        size: CGFloat = 24,
        color: Color = Color("AccentBronze"),
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
        color: Color = Color("AccentBronze")
    ) {
        self.source = .streamline(assetName)
        self.size = size
        self.color = color
    }

    /// Create a two-color palette icon (gold + ink aesthetic)
    init(
        systemName: String,
        size: CGFloat = 24,
        primaryColor: Color = Color("AccentBronze"),
        secondaryColor: Color = Color("AppSurface")
    ) {
        self.source = .sfSymbol(systemName)
        self.size = size
        self.color = primaryColor
        self.secondaryColor = secondaryColor
        self.renderingMode = .palette
    }
}

// MARK: - View Modifiers

extension AppIconView {

    /// Apply hierarchical rendering for depth
    func hierarchical() -> AppIconView {
        var copy = self
        copy.renderingMode = .hierarchical
        return copy
    }

    /// Apply monochrome rendering
    func monochrome() -> AppIconView {
        var copy = self
        copy.renderingMode = .monochrome
        copy.secondaryColor = nil
        return copy
    }

    /// Set icon weight
    func weight(_ weight: Font.Weight) -> AppIconView {
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
            AppIconView(source: .sfSymbol("scroll.fill"), size: 28)
            AppIconView(source: .sfSymbol("book.closed.fill"), size: 28, color: Color("AppAccentAction"))
            AppIconView(source: .sfSymbol("paintbrush.pointed.fill"), size: 28, color: Color("FeedbackSuccess"))
        }

        Text("Palette Rendering")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.xl - 4) {
            AppIconView(
                source: .sfSymbol("text.book.closed.fill"),
                size: 28,
                color: Color("AccentBronze"),
                secondaryColor: Color("AppSurface")
            )
            AppIconView(
                source: .sfSymbol("seal.fill"),
                size: 28,
                color: Color("AppAccentAction"),
                secondaryColor: Color("AccentBronze")
            )
        }

        Text("Hierarchical Rendering")
            .font(Typography.Command.headline)

        HStack(spacing: Theme.Spacing.xl - 4) {
            AppIconView(source: .sfSymbol("sparkle.magnifyingglass"), size: 28)
                .hierarchical()
            AppIconView(source: .sfSymbol("books.vertical.fill"), size: 28, color: Color("AppAccentAction"))
                .hierarchical()
        }
    }
    .padding()
    .background(Color("AppBackground"))
}
