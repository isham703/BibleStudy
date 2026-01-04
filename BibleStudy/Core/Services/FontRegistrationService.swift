import SwiftUI
import CoreText

// MARK: - Font Registration Service
// Handles registration and validation of custom fonts for the illuminated manuscript design
// Falls back to system serif (New York) if custom fonts unavailable

final class FontRegistrationService {
    static let shared = FontRegistrationService()

    // MARK: - Font Family Definitions

    /// Custom font families available in the app
    enum FontFamily: String, CaseIterable {
        case cormorantGaramond = "Cormorant Garamond"
        case ebGaramond = "EB Garamond"
        case cinzel = "Cinzel"

        /// System font to use as fallback
        var systemFallback: Font.Design {
            switch self {
            case .cormorantGaramond, .ebGaramond:
                return .serif
            case .cinzel:
                return .serif
            }
        }

        /// Primary font file name (without extension)
        var primaryFileName: String {
            switch self {
            case .cormorantGaramond: return "CormorantGaramond-Regular"
            case .ebGaramond: return "EBGaramond-Regular"
            case .cinzel: return "Cinzel-Regular"
            }
        }

        /// Font weights available for this family
        var availableWeights: [FontWeight] {
            switch self {
            case .cormorantGaramond:
                return [.light, .regular, .medium, .semibold, .bold]
            case .ebGaramond:
                return [.regular, .medium, .semibold, .bold]
            case .cinzel:
                return [.regular, .medium, .semibold, .bold]
            }
        }

        /// Description for display in settings
        var displayDescription: String {
            switch self {
            case .cormorantGaramond:
                return "Renaissance elegance, ideal for headers"
            case .ebGaramond:
                return "Premium serif for scripture body"
            case .cinzel:
                return "Roman capitals for decorative initials"
            }
        }
    }

    /// Font weight mapping
    enum FontWeight: String, CaseIterable {
        case light = "Light"
        case regular = "Regular"
        case medium = "Medium"
        case semibold = "SemiBold"
        case bold = "Bold"

        /// SwiftUI Font.Weight equivalent
        var swiftUIWeight: Font.Weight {
            switch self {
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            }
        }
    }

    // MARK: - State

    private(set) var registeredFonts: Set<String> = []
    private(set) var isInitialized: Bool = false

    // MARK: - Initialization

    private init() {}

    /// Register all custom fonts at app startup
    /// Call this in the app's init or during first launch
    func registerFonts() {
        guard !isInitialized else { return }

        for family in FontFamily.allCases {
            registerFontFamily(family)
        }

        isInitialized = true

        #if DEBUG
        printAvailableFonts()
        #endif
    }

    /// Register a specific font family
    private func registerFontFamily(_ family: FontFamily) {
        for weight in family.availableWeights {
            let fileName = "\(family.primaryFileName.replacingOccurrences(of: "-Regular", with: "-\(weight.rawValue)"))"
            if registerFont(named: fileName) {
                registeredFonts.insert("\(family.rawValue)-\(weight.rawValue)")
            }
        }
    }

    /// Register a single font file
    private func registerFont(named fontName: String) -> Bool {
        // Try .ttf first, then .otf
        for ext in ["ttf", "otf"] {
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: ext) {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                    return true
                } else if let cfError = error?.takeRetainedValue() {
                    let nsError = cfError as Error
                    // Font might already be registered - that's OK
                    if (nsError as NSError).code == 105 { // kCTFontManagerErrorAlreadyRegistered
                        return true
                    }
                    #if DEBUG
                    print("⚠️ Failed to register font \(fontName): \(nsError.localizedDescription)")
                    #endif
                }
            }
        }
        return false
    }

    // MARK: - Font Access

    /// Check if a custom font is available
    func isFontAvailable(_ family: FontFamily, weight: FontWeight = .regular) -> Bool {
        let fontKey = "\(family.rawValue)-\(weight.rawValue)"
        return registeredFonts.contains(fontKey)
    }

    /// Get font with fallback to system
    func font(
        _ family: FontFamily,
        size: CGFloat,
        weight: FontWeight = .regular
    ) -> Font {
        let fontName = fontName(for: family, weight: weight)

        if isFontAvailable(family, weight: weight) {
            return .custom(fontName, size: size)
        } else {
            // Fallback to system serif with appropriate weight
            return .system(size: size, weight: weight.swiftUIWeight, design: family.systemFallback)
        }
    }

    /// Get UIFont for use in UIKit contexts (like AttributedString)
    func uiFont(
        _ family: FontFamily,
        size: CGFloat,
        weight: FontWeight = .regular
    ) -> UIFont {
        let fontName = fontName(for: family, weight: weight)

        if let font = UIFont(name: fontName, size: size) {
            return font
        } else {
            // Fallback to system
            let uiWeight: UIFont.Weight = {
                switch weight {
                case .light: return .light
                case .regular: return .regular
                case .medium: return .medium
                case .semibold: return .semibold
                case .bold: return .bold
                }
            }()
            return UIFont.systemFont(ofSize: size, weight: uiWeight)
        }
    }

    /// Construct font name from family and weight
    private func fontName(for family: FontFamily, weight: FontWeight) -> String {
        switch family {
        case .cormorantGaramond:
            return "CormorantGaramond-\(weight.rawValue)"
        case .ebGaramond:
            return "EBGaramond-\(weight.rawValue)"
        case .cinzel:
            return "Cinzel-\(weight.rawValue)"
        }
    }

    // MARK: - Debug

    #if DEBUG
    private func printAvailableFonts() {
        print("📚 Registered Fonts:")
        if registeredFonts.isEmpty {
            print("   No custom fonts registered. Using system fallbacks.")
        } else {
            for font in registeredFonts.sorted() {
                print("   ✅ \(font)")
            }
        }

        // Print all available serif fonts for debugging
        print("\n📖 Available Serif Fonts on Device:")
        for family in UIFont.familyNames.sorted() {
            let fontNames = UIFont.fontNames(forFamilyName: family)
            // Filter for serif-like fonts
            if family.lowercased().contains("georgia") ||
               family.lowercased().contains("times") ||
               family.lowercased().contains("palatino") ||
               family.lowercased().contains("garamond") ||
               family.lowercased().contains("new york") ||
               family.lowercased().contains("serif") {
                print("   \(family): \(fontNames)")
            }
        }
    }
    #endif
}

// MARK: - Scripture Font Selection
// User-selectable font families for scripture reading

enum ScriptureFont: String, CaseIterable, Codable {
    case newYork = "newYork"           // System serif (default)
    case georgia = "georgia"           // Classic web serif
    case ebGaramond = "ebGaramond"     // Premium bundled (if available)

    var displayName: String {
        switch self {
        case .newYork: return "New York"
        case .georgia: return "Georgia"
        case .ebGaramond: return "EB Garamond"
        }
    }

    var manuscriptDescription: String {
        switch self {
        case .newYork: return "Apple's modern serif, optimized for reading"
        case .georgia: return "Classic web typography, familiar elegance"
        case .ebGaramond: return "Renaissance letterforms, scholarly beauty"
        }
    }

    /// Whether this font requires custom font registration
    var isCustomFont: Bool {
        switch self {
        case .newYork, .georgia: return false
        case .ebGaramond: return true
        }
    }

    /// Check if font is available (custom fonts may not be bundled)
    var isAvailable: Bool {
        switch self {
        case .newYork, .georgia:
            return true
        case .ebGaramond:
            return FontRegistrationService.shared.isFontAvailable(.ebGaramond)
        }
    }

    /// Get the font at specified size
    func font(size: CGFloat) -> Font {
        switch self {
        case .newYork:
            return .system(size: size, design: .serif)
        case .georgia:
            return .custom("Georgia", size: size)
        case .ebGaramond:
            return FontRegistrationService.shared.font(.ebGaramond, size: size)
        }
    }

    /// Fallback font if this one is unavailable
    var fallback: ScriptureFont {
        switch self {
        case .newYork: return .newYork
        case .georgia: return .newYork
        case .ebGaramond: return .newYork
        }
    }
}

// MARK: - Display Font Selection
// Font families for headers, titles, and decorative elements

enum DisplayFont: String, CaseIterable, Codable {
    case system = "system"                     // System serif
    case cormorantGaramond = "cormorant"       // Premium headers
    case cinzel = "cinzel"                     // Roman capitals/drop caps

    var displayName: String {
        switch self {
        case .system: return "System Serif"
        case .cormorantGaramond: return "Cormorant Garamond"
        case .cinzel: return "Cinzel"
        }
    }

    var manuscriptDescription: String {
        switch self {
        case .system: return "Clean, modern system typography"
        case .cormorantGaramond: return "Renaissance elegance, book titles"
        case .cinzel: return "Roman capitals, illuminated initials"
        }
    }

    /// Whether this font requires custom font registration
    var isCustomFont: Bool {
        switch self {
        case .system: return false
        case .cormorantGaramond, .cinzel: return true
        }
    }

    /// Check if font is available
    var isAvailable: Bool {
        switch self {
        case .system:
            return true
        case .cormorantGaramond:
            return FontRegistrationService.shared.isFontAvailable(.cormorantGaramond)
        case .cinzel:
            return FontRegistrationService.shared.isFontAvailable(.cinzel)
        }
    }

    /// Get the font at specified size and weight
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .system:
            return .system(size: size, weight: weight, design: .serif)
        case .cormorantGaramond:
            let fontWeight = mapWeight(weight)
            return FontRegistrationService.shared.font(.cormorantGaramond, size: size, weight: fontWeight)
        case .cinzel:
            let fontWeight = mapWeight(weight)
            return FontRegistrationService.shared.font(.cinzel, size: size, weight: fontWeight)
        }
    }

    private func mapWeight(_ swiftUIWeight: Font.Weight) -> FontRegistrationService.FontWeight {
        switch swiftUIWeight {
        case .light, .ultraLight, .thin:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold, .heavy, .black:
            return .bold
        default:
            return .regular
        }
    }
}
