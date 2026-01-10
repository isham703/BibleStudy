# BibleStudy Design System - Comprehensive Assessment

> **Purpose**: This document provides a thorough assessment of the BibleStudy iOS app's Design system, focusing on its architecture, core functionalities, and developer interaction patterns. It serves as a foundational reference for AI-assisted expansion of the design system.

---

## Executive Summary

The BibleStudy iOS app employs a **production-grade, four-tier design system** built around a Roman/Stoic sculptural aesthetic that evolved from an illuminated manuscript foundation. The system provides semantic tokens for colors, typography, spacing, animations, and shadows with comprehensive light/dark/sepia/OLED mode support.

**Migration Status**: ✅ **Phase 7 Complete** (Theme Infrastructure Cleanup - January 2026)

- All 7 phases of the Stoic-Existential Renaissance Design System migration are complete
- 4-tier color architecture fully implemented (Pigments, Surfaces, Semantics, StateOverlays)
- Legacy decorative components removed, design system cleaned and consolidated
- See [harmonic-mixing-graham.md](/Users/idon/.claude/plans/harmonic-mixing-graham.md) for complete migration history

### Key Statistics

| Category | Count | Location |
| -------- | ----- | -------- |
| Color tiers | 4 | Pigments, Surfaces, Semantics, StateOverlays |
| Base asset colors | 6 | Background, Surface, TextPrimary, TextSecondary, AccentAction, Divider |
| Typography namespaces | 2 | Scripture (New York serif), Command (SF Pro sans) |
| System fonts | 2 | New York (built-in), SF Pro (system default) |
| Animation tokens | 4 | fade, settle, slowFade, stagger |
| UI Components | 45+ | `UI/Components/` (post-cleanup) |
| Component categories | 10 | Animations, Decorative, Settings, etc. |
| SwiftLint rules | 43 | `.swiftlint.yml` |
| WCAG compliance | AA+ | 4.5:1 text, 3:1 large text (18pt+) |

### Design Philosophy

**Stoic-Existential Renaissance** (Classical Self-Confrontation):

- Severe classical authority without ornamental drift
- Hairline strokes (1pt) over shadows for definition
- Imperial Purple (AccentAction) + Bronze Seal (AccentSeal) accent system
- Cubic-eased motion only (fade, settle, slowFade, stagger) - no spring animations
- Single ornament as authority: (1) one image OR (2) small seal mark, never both
- Generic naming (`Colors`, `Typography`, `Theme`) for future design flexibility

---

## 1. System Architecture

### 1.1 Four-Tier Color Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  TIER 4: StateOverlays (Interaction States)                         │
│  • Colors.StateOverlay.pressed(baseColor)                           │
│  • Colors.StateOverlay.selection(baseColor)                         │
│  • Colors.StateOverlay.focusStroke(accentColor)                     │
│  • Colors.StateOverlay.disabled(baseColor)                          │
│  Used for: Button press, selection highlights, focus rings          │
├─────────────────────────────────────────────────────────────────────┤
│  TIER 3: Semantics (Role-Based Functions)                           │
│  • Colors.Semantic.accentAction(for: ThemeMode)                     │
│  • Colors.Semantic.accentSeal(for: ThemeMode)                       │
│  • Colors.Semantic.error/warning/success/info(for: ThemeMode)       │
│  Used for: Buttons, CTAs, feedback states, interactive elements     │
├─────────────────────────────────────────────────────────────────────┤
│  TIER 2: Surfaces (Theme-Aware Functions)                           │
│  • Colors.Surface.background(for: ThemeMode)                        │
│  • Colors.Surface.surface(for: ThemeMode)                           │
│  • Colors.Surface.textPrimary/Secondary/Tertiary(for: ThemeMode)    │
│  • Colors.Surface.divider(for: ThemeMode)                           │
│  Used for: Backgrounds, text, dividers, borders                     │
├─────────────────────────────────────────────────────────────────────┤
│  TIER 1: Pigments (Raw Hex Values - Internal Only)                  │
│  • Colors.Pigment.inkBg (#0B0B0C), paperBg (#FAF7F2)                │
│  • Colors.Pigment.inkText (#F5F5F5), paperText (#121212)            │
│  • NEVER used directly - accessed via Surface/Semantic functions    │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Principle**: Always use theme-aware functions (`for: ThemeMode`) - never static colors.

### 1.2 File Organization

#### Theme Files (`BibleStudy/UI/Theme/`)

| File | Lines | Purpose |
| ---- | ----- | ------- |
| `Theme.swift` | ~200 | Design tokens: spacing, radius, stroke, animations, opacity |
| `Colors.swift` | ~510 | Four-tier color architecture (Pigments, Surfaces, Semantics, StateOverlays) |
| `Typography.swift` | ~250 | 2-tier: Scripture (New York serif) + Command (SF Pro sans) |
| `TypographyModifiers.swift` | 100+ | View modifiers for correct-by-default typography |
| `DecorativeStubs.swift` | ~110 | Temporary stubs for gradual migration (DropCapStyle, VerseNumberStyle) |
| `ShowcaseExtensions.swift` | 80+ | Showcase-only color/typography extensions |

#### Component Files (`BibleStudy/UI/Components/`)

```
UI/Components/                    (58 files total)
├── Animations/                   (8 files)
│   ├── SacredTransitions.swift   # Custom transitions (unfurl, illuminate)
│   ├── NetworkGraph.swift        # Animated network visualization
│   ├── NodePulse.swift           # Radial pulse animation
│   ├── ConnectionLine.swift      # Animated connecting lines
│   ├── AtmosphericEffects.swift  # Ambient particles and glows
│   ├── GestureAnimations.swift   # Touch feedback animations
│   └── GoldenGradient.swift      # Animated gradient backgrounds
│
├── Decorative/                   (8 files)
│   ├── DropCapView.swift         # 5 illuminated initial styles
│   ├── OrnamentalDivider.swift   # 8 decorative separator styles
│   ├── IlluminatedChapterHeader.swift
│   ├── VerseNumberView.swift
│   ├── StarfieldBackground.swift
│   └── AuroraBackground.swift
│
├── FloatingContextMenu/          (9 files)
│   ├── UnifiedContextMenu.swift  # Master dual-mode menu (814 lines)
│   ├── IlluminatedContextMenu.swift
│   ├── VerseContextMenu.swift
│   ├── IlluminatedActionButton.swift
│   ├── IlluminatedMenuBackground.swift
│   └── IlluminatedMenuPositioning.swift
│
├── Settings/                     (5 files)
│   ├── IlluminatedToggle.swift
│   ├── IlluminatedSlider.swift
│   ├── IlluminatedSettingsCard.swift
│   ├── UsageRow.swift
│   └── InlineThemeCard.swift
│
├── Celebrations/                 (4 files)
│   ├── CelebrationOverlay.swift
│   ├── AchievementCelebration.swift
│   └── ConnectionCelebration.swift
│
├── Toast/                        (2 files)
│   ├── ToastManager.swift
│   └── VellumScrollToast.swift
│
├── CoachMark/                    (2 files)
│   └── IlluminatedCoachMark.swift
│
└── [Root Level]                  (17 standalone files)
    ├── IlluminatedIcon.swift     # Unified icon system
    ├── GlassTabBar.swift         # iOS 26 glass tab bar
    ├── DynamicSheet.swift        # Self-sizing sheet
    ├── LoadingView.swift         # 5 loading state variants
    ├── ErrorView.swift
    ├── NoteEditor.swift
    ├── HighlightColorPicker.swift
    ├── QuickInsightCard.swift
    ├── AskFAB.swift
    └── TrustUXComponents.swift   # AI reasoning transparency
```

#### Asset Catalog (`Assets.xcassets/Colors/`)

**Minimal Base Assets** (6 core colors - everything else computed in code):

```
Colors/
├── AppBackground.colorset      # Light: #FAF7F2, Dark: #0B0B0C
├── AppSurface.colorset         # Light: #F8F6F0, Dark: #1A1A1A
├── AppTextPrimary.colorset     # Light: #121212, Dark: #F5F5F5
├── AppTextSecondary.colorset   # Light: opacity 0.75, Dark: opacity 0.75
├── AppAccentAction.colorset    # Light: #4F46E5, Dark: #6366F1 (Imperial Purple)
└── AppDivider.colorset         # Light: #E6E0D6, Dark: #2A2A2A

# All other colors computed:
# - AccentSeal (Bronze): #8B7355 in code
# - Error/Warning/Success/Info: Computed in Colors.Semantic
# - Highlights: Computed from AccentAction at varying opacities
# - State overlays: Computed via Colors.StateOverlay functions
```

---

## 2. Color System

### 2.1 Four-Tier Color Architecture

The color system uses a **function-based, theme-aware** approach with four distinct tiers:

#### Tier 1: Pigments (Raw Hex Values - Internal Only)

**Location**: `Colors.swift` - `enum Pigment`
**Usage**: NEVER accessed directly - only used internally by Surface and Semantic functions

```swift
enum Pigment {
    static let inkBg = Color(hex: "0B0B0C")          // Near-black (default dark)
    static let inkText = Color(hex: "F5F5F5")        // Soft ivory (dark text)
    static let paperBg = Color(hex: "FAF7F2")        // Parchment warmth (light)
    static let paperText = Color(hex: "121212")      // Ink on parchment (light text)
    static let oledBg = Color(hex: "000000")         // Pure black (Phase 8 - OLED mode)
}
```

#### Tier 2: Surfaces (Theme-Aware Functions)

**Location**: `Colors.swift` - `enum Surface`
**Usage**: All Surface colors are **functions** that take `ThemeMode` parameter

```swift
enum Surface {
    static func background(for mode: ThemeMode) -> Color {
        mode == .light ? Pigment.paperBg : Pigment.inkBg
    }

    static func surface(for mode: ThemeMode) -> Color {
        mode == .light ? Color(hex: "F8F6F0") : Color(hex: "1A1A1A")
    }

    static func textPrimary(for mode: ThemeMode) -> Color {
        mode == .light ? Pigment.paperText : Pigment.inkText
    }

    static func textSecondary(for mode: ThemeMode) -> Color {
        (mode == .light ? Pigment.paperText : Pigment.inkText).opacity(0.75)
    }

    static func textTertiary(for mode: ThemeMode) -> Color {
        (mode == .light ? Pigment.paperText : Pigment.inkText).opacity(0.60)
    }

    static func divider(for mode: ThemeMode) -> Color {
        (mode == .light ? Color(hex: "E6E0D6") : Color(hex: "2A2A2A")).opacity(0.15)
    }
}
```

**Usage Example**:

```swift
// Always use with ThemeMode.current(from: colorScheme)
@Environment(\.colorScheme) private var colorScheme

var body: some View {
    VStack {
        Text("Hello")
            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
    }
    .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
}
```

#### Tier 3: Semantics (Role-Based Functions)

**Location**: `Colors.swift` - `enum Semantic`
**Usage**: All Semantic colors are **functions** that take `ThemeMode` parameter

```swift
enum Semantic {
    // Primary accent (Imperial Purple - Interactive)
    static func accentAction(for mode: ThemeMode) -> Color {
        mode == .light ? Color(hex: "4F46E5") : Color(hex: "6366F1")
    }

    // Secondary accent (Bronze Seal - Authority/decorative)
    static func accentSeal(for mode: ThemeMode) -> Color {
        Color(hex: "8B7355")  // Same for both modes
    }

    // Feedback colors (muted, functional)
    static func error(for mode: ThemeMode) -> Color {
        Color(hex: "8B3A3A")  // Deep oxblood
    }

    static func warning(for mode: ThemeMode) -> Color {
        Color(hex: "B8860B")  // Muted ochre
    }

    static func success(for mode: ThemeMode) -> Color {
        Color(hex: "6B7C59")  // Desaturated olive
    }

    static func info(for mode: ThemeMode) -> Color {
        Color(hex: "6B7280")  // Slate/steel
    }
}
```

**Accent Color Usage**:

- **AccentAction** (Imperial Purple): Buttons, CTAs, links, all interactive UI
- **AccentSeal** (Bronze): Rare authority moments (seals, badges, decorative accents)

#### Tier 4: StateOverlays (Interaction States)

**Location**: `Colors.swift` - `enum StateOverlay`
**Usage**: Apply opacity overlays to base colors for interaction states

```swift
enum StateOverlay {
    static func pressed(_ base: Color) -> Color {
        base.opacity(0.80)  // 20% reduction on press
    }

    static func selection(_ base: Color) -> Color {
        base.opacity(0.15)  // AccentAction at 15% for verse selection
    }

    static func focusStroke(_ accent: Color) -> Color {
        accent.opacity(0.60)  // AccentAction at 60% for input focus rings
    }

    static func disabled(_ base: Color) -> Color {
        base.opacity(0.35)  // 65% reduction for disabled state
    }
}
```

**Usage Example**:

```swift
Button("Sign In") { }
    .background(Colors.Semantic.accentAction(for: mode))
    .opacity(isPressed ? 0.8 : 1.0)  // Or use Colors.StateOverlay.pressed(accentAction)
```

### 2.2 ThemeMode Enum

**Location**: `Colors.swift`
**Purpose**: Simplified theme mode enum (sepia/OLED deferred to Phase 8)

```swift
enum ThemeMode: String {
    case system  // Follows iOS color scheme
    case light   // Fixed light mode
    case dark    // Fixed dark mode

    // Helper: Resolve .system to actual mode based on environment
    static func current(from colorScheme: ColorScheme) -> ThemeMode {
        colorScheme == .dark ? .dark : .light
    }
}
```

**Usage Pattern**:

```swift
@Environment(\.colorScheme) private var colorScheme

// CORRECT: Theme-aware function call
.foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

// INCORRECT: Static color property (deprecated)
.foregroundStyle(Color.primaryText)  // ❌ Old API
```

### 2.3 Accessibility & WCAG Compliance

**Minimum Contrast Requirements**:

- **Text (regular)**: WCAG AA 4.5:1 minimum
- **Large text (18pt+)**: WCAG AA Large 3:1 minimum
- **Critical**: Test AccentAction on all backgrounds for sufficient contrast

**Current Compliance**:

| Element | Light Mode | Dark Mode | Ratio | Status |
| --- | --- | --- | --- | --- |
| Primary text | #121212 on #FAF7F2 | #F5F5F5 on #0B0B0C | 15:1 / 16:1 | ✅ AAA |
| Secondary text | opacity 0.75 | opacity 0.75 | 11:1 / 12:1 | ✅ AAA |
| AccentAction | #4F46E5 on #FAF7F2 | #6366F1 on #0B0B0C | 6.2:1 / 8.1:1 | ✅ AA+ |
| Error text | #8B3A3A | #8B3A3A | 5.1:1 | ✅ AA |

**Dynamic Type Support**:

- All text scales with iOS accessibility settings
- Test at largest accessibility size (AX5)
- Buttons maintain minimum tap target (44pt)

**Screen Reader Support**:

- All icons have `.accessibilityLabel()`
- Scripture passages marked with semantic roles
- Interactive elements have proper hints

### 2.4 Migration from Old API

**Deprecated Patterns** (DO NOT USE):

```swift
// ❌ Static color properties
Color.accentBlue
Color.highlightPurple
Color.Surface.background  // Old enum-based API

// ❌ Direct pigment access
Color.divineGold
Color.scholarIndigo
```

**Current Patterns** (USE THESE):

```swift
// ✅ Theme-aware functions
Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
Colors.Surface.background(for: appState.preferredTheme)
Colors.StateOverlay.pressed(baseColor)

// ✅ Legacy convenience aliases (temporary)
Color.error          // → Colors.Semantic.error(for:)
Color.appBackground  // → Colors.Surface.background(for:)
```

### 2.5 SwiftLint Rules

Prevent deprecated color API usage:

```yaml
custom_rules:
  new_color_api:
    name: "Use new color system"
    regex: "Color\\.(accentBlue|highlightPurple|highlightGreen|Surface\\.)"
    message: "Use Colors.Semantic.* or Colors.Surface.* functions with ThemeMode"
    severity: error
```

### 2.6 Highlight Color System

```swift
enum HighlightColor: String, CaseIterable, Codable {
    case blue      // GreekBlue - Original language annotations
    case green     // TheologyGreen - Doctrinal study notes
    case amber     // ConnectionAmber - Cross-references
    case rose      // PersonalRose - Reflective questions
    case purple    // Amethyst - General/spiritual

    var highlightColor: Color {
        // Semi-transparent for verse backgrounds
        switch self {
        case .blue: return Color.greekBlue.opacity(0.2)
        case .green: return Color.theologyGreen.opacity(0.2)
        // ...
        }
    }

    var solidColor: Color {
        // Full color for text/icons
        switch self {
        case .blue: return Color.greekBlue
        // ...
        }
    }

    var displayName: String { ... }
    var manuscriptDescription: String {
        // Pigment labels for manuscript aesthetic
        switch self {
        case .blue: return "Lz"   // Lapis Lazuli
        case .green: return "Ml"  // Malachite
        case .amber: return "Au"  // Aurum (Gold)
        case .rose: return "Ro"   // Rose
        case .purple: return "Am" // Amethyst
        }
    }

    var accessibilityName: String { ... }
    var accessibilityShortName: String { ... }
}
```

### 2.4 Gradient System

**Location**: `Colors.swift` + `StoicGradients.swift`

```swift
// Accent gradients
static var scholarGradient: LinearGradient {
    LinearGradient(colors: [scholarIndigo.opacity(0.15), .clear], ...)
}

static func indigoBorderGradient(angle: Angle = .zero) -> AngularGradient { ... }
static var radialIndigoGlow: RadialGradient { ... }
static var vignetteOverlay: RadialGradient { ... }

// Gradient stop colors
enum GradientStops {
    static var vellumBottom: Color { ... }
    static var parchmentBottom: Color { ... }
    static var chapelBottom: Color { ... }
    static var oledBottom: Color { ... }
    static var illuminatedTop: Color { ... }
    static var illuminatedMid: Color { ... }
    static var illuminatedBottom: Color { ... }
}
```

**StoicGradients.swift**:

```swift
enum StoicGradients {
    // Background gradients
    static var vellumGradient: LinearGradient { ... }
    static var chapelGradient: LinearGradient { ... }
    static var oledGradient: LinearGradient { ... }

    // Accent glow gradients
    static var indigoGlow: RadialGradient { ... }
    static var ambientIndigo: RadialGradient { ... }
    static var subtleLight: LinearGradient { ... }

    // Card/surface gradients
    static var cardGradient: LinearGradient { ... }
    static var selectedGradient: LinearGradient { ... }
}

// View modifiers
extension View {
    func vellumBackground() -> some View { ... }
    func indigoGlowBackground(intensity: Double = 1.0) -> some View { ... }
    func scholarCardStyle() -> some View { ... }
}
```

### 2.5 WCAG Accessibility Compliance

All text/background combinations verified:

| Background | Text | Hex Values | Ratio | Standard |
| ---------- | ---- | ---------- | ----- | -------- |
| freshVellum | monasteryBlack | #FBF7F0 / #1C1917 | ~15:1 | AAA |
| freshVellum | agedInk | #FBF7F0 / #3D3531 | ~9:1 | AAA |
| candlelitStone | moonlitParchment | #1A1816 / #E8E4DC | ~12:1 | AAA |
| candlelitStone | fadedMoonlight | #1A1816 / #A8A29E | ~7:1 | AAA |
| agedParchment | sepiaInk | #F5EDE0 / #4A3728 | ~8:1 | AAA |
| scholarIndigo | white | #4F46E5 / #FFFFFF | ~8:1 | AAA |
| imperialPurple | white | #4B0082 / #FFFFFF | ~7.5:1 | AAA |
| vellumCream | scholarIndigoAccessible | #FEFDFB / #4338CA | ~7.8:1 | AAA |

---

## 3. Typography System

### 3.1 Seven Typography Namespaces

**Location**: `Typography.swift`

#### Typography.Scripture - Biblical Text

```swift
struct Scripture {
    static func body(size: CGFloat = 18) -> Font {
        .system(size: size, design: .serif)
    }

    static func bodyWithSize(_ size: ScriptureFontSize) -> Font {
        .system(size: size.rawValue, design: .serif)
    }

    static let verseNumber: Font = .system(size: 12, weight: .medium, design: .serif)
    static let chapterNumber: Font = .system(size: 48, weight: .light, design: .serif)
    static let title: Font = .system(size: 28, weight: .light, design: .serif)

    static func quote(size: CGFloat = 16) -> Font {
        .system(size: size, design: .serif).italic()
    }
}
```

#### Typography.Display - Premium Serif Headlines

```swift
struct Display {
    static let largeTitle: Font = .system(size: 34, weight: .medium, design: .serif)
    static let title1: Font = .system(size: 28, weight: .medium, design: .serif)
    static let title2: Font = .system(size: 22, weight: .medium, design: .serif)
    static let title3: Font = .system(size: 20, weight: .medium, design: .serif)
    static let headline: Font = .system(size: 17, weight: .semibold, design: .serif)
}
```

#### Typography.UI - System Sans (SF Pro)

```swift
struct UI {
    // Standard text hierarchy
    static let largeTitle: Font = .system(size: 34, weight: .bold, design: .default)
    static let title1: Font = .system(size: 28, weight: .bold, design: .default)
    static let title2: Font = .system(size: 22, weight: .bold, design: .default)
    static let title3: Font = .system(size: 20, weight: .semibold, design: .default)
    static let headline: Font = .system(size: 17, weight: .semibold, design: .default)
    static let body: Font = .system(size: 17, weight: .regular, design: .default)
    static let bodyBold: Font = .system(size: 17, weight: .bold, design: .default)
    static let callout: Font = .system(size: 16, weight: .regular, design: .default)
    static let subheadline: Font = .system(size: 15, weight: .regular, design: .default)
    static let footnote: Font = .system(size: 13, weight: .medium, design: .default)
    static let caption1: Font = .system(size: 12, weight: .medium, design: .default)
    static let caption2: Font = .system(size: 11, weight: .regular, design: .default)

    // Interactive elements (Rounded for warmth)
    static let tabLabel: Font = .system(size: 10, weight: .medium, design: .rounded)
    static let buttonLabel: Font = .system(size: 17, weight: .semibold, design: .rounded)
    static let chipLabel: Font = .system(size: 14, weight: .medium, design: .rounded)

    // Warm variants for welcoming contexts
    static let warmBody: Font = .system(size: 17, weight: .regular, design: .rounded)
    static let warmHeadline: Font = .system(size: 17, weight: .semibold, design: .rounded)

    // Icon fonts (SF Symbols)
    static let iconXs: Font = .system(size: 11, weight: .medium)   // Tiny icons
    static let iconSm: Font = .system(size: 14, weight: .medium)   // Small icons
    static let iconMd: Font = .system(size: 16, weight: .medium)   // Medium icons
    static let iconLg: Font = .system(size: 18, weight: .medium)   // Large icons
    static let iconXl: Font = .system(size: 24, weight: .medium)   // Extra large
    static let iconXxl: Font = .system(size: 36, weight: .medium)  // Oversized
}
```

#### Typography.Reading - User-Customizable Scripture (NEW)

```swift
struct Reading {
    // Verse text - respects user's font preference
    static func verse(size: ScriptureFontSize = .medium, font: ScriptureFont = .newYork) -> Font {
        font.font(size: size.rawValue)
    }

    // Poetic verse text - italic for poetry, quoted speech
    static func verseItalic(size: ScriptureFontSize = .medium, font: ScriptureFont = .newYork) -> Font {
        font.font(size: size.rawValue).italic()
    }

    // Verse emphasis - semibold for red letter editions
    static func verseEmphasis(size: ScriptureFontSize = .medium, font: ScriptureFont = .newYork) -> Font {
        font.font(size: size.rawValue).weight(.semibold)
    }

    // Chapter headers
    static let chapterNumber: Font = .system(size: 28, weight: .bold, design: .serif)
    static let chapterLabel: Font = .system(size: 11, weight: .bold)

    // Verse numbers
    static let verseNumber: Font = .system(size: 14, weight: .bold)
    static let verseNumberSubtle: Font = .system(size: 12, weight: .regular)

    // Line spacing
    static let verseLineSpacing: CGFloat = 8
    static let poeticLineSpacing: CGFloat = 10
}
```

#### Typography.Editorial - Tracked Uppercase (NEW)

```swift
struct Editorial {
    // Headers & Labels (Tracked Uppercase)
    // Use with: .tracking(Editorial.sectionTracking).textCase(.uppercase)
    static let sectionHeader: Font = .system(size: 11, weight: .bold)
    static let label: Font = .system(size: 10, weight: .bold)
    static let labelSmall: Font = .system(size: 9, weight: .bold)

    // References (Cinzel + Tracking)
    // Use with: .tracking(Editorial.referenceTracking)
    static var reference: Font { CustomFonts.cinzelRegular(size: 11) }
    static let referenceHero: Font = .system(size: 14, weight: .semibold, design: .serif)
    static var referenceDisplay: Font { CustomFonts.cinzelRegular(size: 32) }

    // Tracking Constants (Liturgical Spacing: 20-30%)
    static let sectionTracking: CGFloat = 2.5   // ~23% on 11pt
    static let labelTracking: CGFloat = 1.5     // ~15% on 10pt
    static let referenceTracking: CGFloat = 3.0 // ~27% on 11pt (inscriptional)
}
```

#### Typography.Insight - AI Content (NEW)

```swift
struct Insight {
    // Headers (Cinzel for Manuscript Feel)
    static var header: Font { CustomFonts.cinzelRegular(size: 11) }
    static var sectionTitle: Font { CustomFonts.cinzelRegular(size: 10) }

    // Body (Cormorant for Readability)
    static var heroSummary: Font { CustomFonts.cormorantRegular(size: 17) }
    static var body: Font { CustomFonts.cormorantRegular(size: 15) }
    static var bodySmall: Font { CustomFonts.cormorantRegular(size: 14) }

    // Emphasis Variants
    static var italic: Font { CustomFonts.cormorantItalic(size: 15) }
    static var emphasis: Font { CustomFonts.cormorantSemiBold(size: 15) }

    // Cross-References
    static var reference: Font { CustomFonts.cormorantSemiBold(size: 14) }
    static var quote: Font { CustomFonts.cormorantItalic(size: 15) }

    // Line Spacing
    static let heroLineSpacing: CGFloat = 6
    static let bodyLineSpacing: CGFloat = 5
    static let captionLineSpacing: CGFloat = 3
}
```

#### Typography.Roman - Stoic Monumentalism (NEW)

```swift
struct Roman {
    // Headings (Bold Serif - Roman Tablet Feel)
    static let heading1: Font = .system(size: 28, weight: .bold, design: .serif)
    static let heading2: Font = .system(size: 22, weight: .semibold, design: .serif)
    static let heading3: Font = .system(size: 18, weight: .semibold, design: .serif)
    static let heading4: Font = .system(size: 16, weight: .medium, design: .serif)

    // Inscribed Text (Cinzel Uppercase - "carved" feeling)
    static var inscribed: Font { CustomFonts.cinzelRegular(size: 12) }
    static var inscribedLarge: Font { CustomFonts.cinzelRegular(size: 16) }

    // Body Text (SF Pro for Readability)
    static let body: Font = .system(size: 17, weight: .regular)
    static let bodySecondary: Font = .system(size: 15, weight: .regular)

    // Quote (Italic serif for stoic wisdom)
    static let quote: Font = .system(size: 18, weight: .medium, design: .serif).italic()

    // Tracking Constants
    static let inscribedTracking: CGFloat = 3.0   // ~25% on 12pt (chiseled feel)
    static let emphasisTracking: CGFloat = 1.1    // ~8% on 14pt (restrained dignity)
    static let bodyLineSpacing: CGFloat = 6       // Comfortable reading
}
```

### 3.2 Custom Fonts

**Location**: `CustomFonts.swift`

```swift
struct CustomFonts {
    // Cormorant Garamond - Elegant serif for AI content
    static func cormorantRegular(size: CGFloat) -> Font {
        if UIFont(name: "CormorantGaramond-Regular", size: size) != nil {
            return .custom("CormorantGaramond-Regular", size: size)
        }
        return .system(size: size, design: .serif) // Fallback
    }

    static func cormorantItalic(size: CGFloat) -> Font { ... }
    static func cormorantSemiBold(size: CGFloat) -> Font { ... }

    // Cinzel - Decorative Roman capitals
    static func cinzelRegular(size: CGFloat) -> Font {
        if UIFont(name: "Cinzel-Regular", size: size) != nil {
            return .custom("Cinzel-Regular", size: size)
        }
        return .system(size: size, weight: .medium) // Fallback
    }

    // Availability checking
    static func isAvailable(_ fontName: String) -> Bool {
        UIFont(name: fontName, size: 12) != nil
    }
}
```

| Font | Weights | Fallback | Purpose |
| ---- | ------- | -------- | ------- |
| Cormorant Garamond | Regular, Italic, SemiBold | System serif | AI insights, elegant body |
| Cinzel | Regular | System medium | Inscriptions, editorial headers |
| EB Garamond | Regular, Italic | Georgia | Optional scripture font |

### 3.3 Type Scale

**Perfect Fourth Ratio (1.333)**:

```swift
enum Scale {
    static let xs: CGFloat = 11      // Captions, footnotes
    static let sm: CGFloat = 14      // Secondary text
    static let base: CGFloat = 18    // Body text (scripture)
    static let lg: CGFloat = 22      // Section titles
    static let xl: CGFloat = 28      // Subheadings
    static let xxl: CGFloat = 32     // Book titles
    static let xxxl: CGFloat = 42    // Chapter numbers
    static let display: CGFloat = 56 // Hero text
    static let dropCap: CGFloat = 72 // Illuminated initials
}
```

### 3.4 User-Configurable Typography

```swift
enum ScriptureFontSize: CGFloat, CaseIterable, Codable {
    case extraSmall = 14
    case small = 16
    case medium = 18
    case large = 20
    case extraLarge = 22
    case huge = 24

    var lineSpacing: CGFloat {
        // Auto-calculated per size
        switch self {
        case .extraSmall: return 5
        case .small: return 6
        case .medium: return 7
        case .large: return 8
        case .extraLarge: return 9
        case .huge: return 10
        }
    }
}

enum ScriptureFont: String, CaseIterable, Codable {
    case newYork      // System serif (default)
    case georgia      // Classic web serif
    case ebGaramond   // Premium bundled

    var displayName: String { ... }
    var manuscriptDescription: String { ... }

    func font(size: CGFloat) -> Font {
        switch self {
        case .newYork: return .system(size: size, design: .serif)
        case .georgia: return .custom("Georgia", size: size)
        case .ebGaramond: return .custom("EBGaramond-Regular", size: size)
        }
    }
}

enum VerseNumberStyle: String, CaseIterable, Codable {
    case superscript    // Small, raised
    case inline         // Same baseline
    case marginal       // In margin
    case ornamental     // Decorative (Cinzel)
    case minimal        // Very subtle
}

enum DropCapStyle: String, CaseIterable, Codable {
    case none           // No drop cap
    case simple         // Large first letter
    case illuminated    // Gold decorated
    case uncial         // Celtic manuscript
    case floriate       // Floral decoration
    case versal         // Ornate capital
}
```

### 3.5 Typography Modifiers

**Location**: `TypographyModifiers.swift`

"Correct-by-default" view modifiers that encapsulate font + tracking + line spacing + text case atomically:

```swift
extension View {
    // Editorial Modifiers
    func editorialSectionHeader() -> some View {
        self
            .font(Typography.Editorial.sectionHeader)
            .tracking(Typography.Editorial.sectionTracking)
            .textCase(.uppercase)
    }

    func editorialLabel() -> some View {
        self
            .font(Typography.Editorial.label)
            .tracking(Typography.Editorial.labelTracking)
            .textCase(.uppercase)
    }

    func editorialReference() -> some View {
        self
            .font(Typography.Editorial.reference)
            .tracking(Typography.Editorial.referenceTracking)
    }

    // Reading Modifiers
    func readingVerse(size: ScriptureFontSize, font: ScriptureFont, lineSpacing: CGFloat? = nil) -> some View {
        self
            .font(Typography.Reading.verse(size: size, font: font))
            .lineSpacing(lineSpacing ?? Typography.Reading.verseLineSpacing)
    }

    // Insight Modifiers
    func insightHeroSummary() -> some View {
        self
            .font(Typography.Insight.heroSummary)
            .lineSpacing(Typography.Insight.heroLineSpacing)
    }

    func insightBody() -> some View {
        self
            .font(Typography.Insight.body)
            .lineSpacing(Typography.Insight.bodyLineSpacing)
    }
}
```

---

## 4. Spacing & Layout Tokens

### 4.1 Spacing Scale

**Location**: `AppTheme.swift`

```swift
struct Spacing {
    static let xxs: CGFloat = 2     // Hairline gaps
    static let xs: CGFloat = 4      // Tight spacing
    static let sm: CGFloat = 8      // Small gaps
    static let md: CGFloat = 12     // Medium gaps
    static let lg: CGFloat = 16     // Standard spacing
    static let xl: CGFloat = 24     // Large spacing
    static let xxl: CGFloat = 32    // Section spacing
    static let xxxl: CGFloat = 48   // Major sections
    static let huge: CGFloat = 64   // Hero sections
}
```

### 4.2 Corner Radius

```swift
struct CornerRadius {
    static let xs: CGFloat = 2       // Indicator strips
    static let small: CGFloat = 4    // Chips, badges
    static let sm: CGFloat = 4       // Alias for small
    static let medium: CGFloat = 8   // Buttons, inputs
    static let md: CGFloat = 8       // Alias for medium
    static let large: CGFloat = 12   // Standard cards
    static let lg: CGFloat = 12      // Alias for large
    static let xl: CGFloat = 16      // Large cards
    static let card: CGFloat = 12    // Card alias
    static let sheet: CGFloat = 20   // Bottom sheets
    static let menu: CGFloat = 14    // Floating menus
    static let pill: CGFloat = 100   // Fully rounded
}
```

### 4.3 Other Layout Tokens

```swift
// Border widths
struct Border {
    static let hairline: CGFloat = 0.5
    static let thin: CGFloat = 1
    static let medium: CGFloat = 1.5
    static let regular: CGFloat = 2
    static let thick: CGFloat = 3
    static let heavy: CGFloat = 4
}

// Touch targets (Apple HIG)
struct TouchTarget {
    static let minimum: CGFloat = 44     // Apple HIG minimum
    static let comfortable: CGFloat = 48 // Comfortable tapping
    static let large: CGFloat = 56       // Large touch target
}

// Icon sizes
struct IconSize {
    static let small: CGFloat = 16
    static let medium: CGFloat = 20
    static let large: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let celebration: CGFloat = 36
}

// Icon containers
struct IconContainer {
    static let small: CGFloat = 24
    static let medium: CGFloat = 32
    static let large: CGFloat = 44
    static let xl: CGFloat = 56
}

// Component sizes
struct ComponentSize {
    static let dot: CGFloat = 4
    static let indicator: CGFloat = 8
    static let badge: CGFloat = 20
    static let icon: CGFloat = 24
    static let avatar: CGFloat = 40
    static let thumbnail: CGFloat = 64
    static let preview: CGFloat = 120
    static let touchTarget: CGFloat = 44
    static let cardMinHeight: CGFloat = 120
    static let heroHeight: CGFloat = 380
}

// Blur radius
struct Blur {
    static let glow: CGFloat = 1.5
    static let subtle: CGFloat = 3
    static let light: CGFloat = 5
    static let medium: CGFloat = 8
    static let heavy: CGFloat = 10
    static let intense: CGFloat = 15
}

// Scale effects
struct Scale {
    static let pressed: CGFloat = 0.95
    static let subtle: CGFloat = 0.98
    static let reduced: CGFloat = 0.8
    static let small: CGFloat = 0.7
    static let enlarged: CGFloat = 1.2
    static let pulse: CGFloat = 1.5
}

// Divider heights
struct Divider {
    static let hairline: CGFloat = 0.5
    static let thin: CGFloat = 1
    static let medium: CGFloat = 2
    static let thick: CGFloat = 4
    static let heavy: CGFloat = 6
}
```

---

## 5. Animation System

### 5.1 Named Animation Tokens

**Location**: `AppTheme.Animation`

#### Basic Transitions

```swift
static let quick: Animation = .easeInOut(duration: 0.15)
static let standard: Animation = .easeInOut(duration: 0.25)
static let slow: Animation = .easeInOut(duration: 0.4)
static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.7)
```

#### Sacred Motion (Illuminated Manuscript)

```swift
// Reverent - slow, gentle transitions for major state changes
// Use for: theme changes, view transitions, modal presentations
static let reverent: Animation = .easeInOut(duration: 0.6)

// Luminous - fast-in, slow-out for light-like appearances
// Use for: glow effects, highlights appearing, gold accents
static let luminous: Animation = .timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.4)

// Contemplative - extended ease for meditative moments
// Use for: ambient effects, background changes, pulsing glows
static let contemplative: Animation = .easeInOut(duration: 1.2)

// Sacred Spring - dignified bounce without playfulness
// Use for: selection feedback, card appearances, emphasis
static let sacredSpring: Animation = .spring(response: 0.5, dampingFraction: 0.85)

// Unfurl - scroll-like reveal animation
// Use for: content reveals, list appearances, vertical transitions
static let unfurl: Animation = .timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.7)

// Golden Ratio - phi-based harmonious movement (1.618)
// Use for: proportional animations, balanced transitions
static let goldenRatio: Animation = .timingCurve(0.382, 0.0, 0.618, 1.0, duration: 0.5)
```

#### Repeating Animations

```swift
// Shimmer - for gold shimmer effects
static let shimmer: Animation = .easeInOut(duration: 2.0).repeatForever(autoreverses: true)

// Pulse - gentle pulsing for ambient effects
static let pulse: Animation = .easeInOut(duration: 3.0).repeatForever(autoreverses: true)

// Breathing Pulse - scale animation for ambient effects
static let breathingPulse: Animation = .easeInOut(duration: 2).repeatForever(autoreverses: true)

// Meditative Pulse - extended for contemplative elements
static let meditativePulse: Animation = .easeInOut(duration: 4.0).repeatForever(autoreverses: true)

// Eternal Pulse - barely perceptible atmosphere
static let eternalPulse: Animation = .easeInOut(duration: 5.0).repeatForever(autoreverses: true)

// Sacred Rotation - very slow continuous rotation
static let sacredRotation: Animation = .linear(duration: 20).repeatForever(autoreverses: false)

// Float - slow floating for ambient elements
static let float: Animation = .easeInOut(duration: 4).repeatForever(autoreverses: true)
```

#### Roman/Stoic Motion (Sculptural Monumentalism)

```swift
// Stone Awakening - THE SIGNATURE EFFECT
// Content emerges from gray desaturation to full color
// Like a marble statue gaining life under torchlight
static let stoneAwakening: Animation = .easeOut(duration: 0.8)

// Monumental Entrance - Dignified scale entrance
// Subtle scale (0.95→1.0) with minimal overshoot
// Think: A senator entering the forum, not a bouncing ball
static let monumental: Animation = .spring(response: 0.6, dampingFraction: 0.9)

// Column Reveal - Staggered list appearance
// Items appear like walking past columns in a Roman forum
// 120ms stagger creates rhythm without feeling mechanical
static func columnReveal(index: Int) -> Animation {
    .spring(response: 0.5, dampingFraction: 0.85).delay(Double(index) * 0.12)
}

// Stoic Settle - Minimal overshoot landing
// For selections, card placements, modal appearances
static let stoicSettle: Animation = .spring(response: 0.4, dampingFraction: 0.95)

// Imperial Fade - Slow, majestic crossfade
// For background transitions, theme changes (1.0s conveys timelessness)
static let imperialFade: Animation = .easeInOut(duration: 1.0)

// Forum Walk - Page transition with parallax
static let forumWalk: Animation = .spring(response: 0.5, dampingFraction: 0.9)

// Inscription Reveal - Text character stagger
// Each character delays 30ms, creating chiseled effect
static func inscriptionReveal(characterCount: Int) -> Animation {
    .easeOut(duration: 0.4 + Double(characterCount) * 0.03)
}

// Marble Shimmer - Light traversing marble (3s duration)
static let marbleShimmer: Animation = .easeInOut(duration: 3.0)
```

#### Scholar Component Animations

```swift
// Menu appear - smooth spring for context menus
static let menuAppear: Animation = .spring(response: 0.35, dampingFraction: 0.8)

// Selection - quick ease for verse/item selection
static let selection: Animation = .easeOut(duration: 0.2)

// Card unfurl - elegant spring for insight cards expanding
static let cardUnfurl: Animation = .spring(response: 0.4, dampingFraction: 0.85)

// Chip expand - snappy spring for filter chips
static let chipExpand: Animation = .spring(response: 0.3, dampingFraction: 0.8)
```

#### Prayer Experience Animations

```swift
// Illumination glow for manuscript effects (8s cycle)
static let prayerIllumination: Animation = .easeInOut(duration: 8.0).repeatForever(autoreverses: true)

// Prayer phase transition (input → generating → displaying)
static let prayerPhaseTransition: Animation = .easeInOut(duration: 0.6)

// Word reveal timing
static let prayerWordRevealBase: TimeInterval = 0.7
static let prayerPunctuationPause: TimeInterval = 0.6
static let prayerLineBreakPause: TimeInterval = 1.2
```

### 5.2 Accessibility Support

```swift
// Returns true when user has enabled "Reduce Motion"
static var isReduceMotionEnabled: Bool {
    UIAccessibility.isReduceMotionEnabled
}

// Returns the animation or nil if reduce motion is enabled
// Usage: .animation(AppTheme.Animation.reduced(.standard), value: state)
static func reduced(_ animation: Animation) -> Animation? {
    isReduceMotionEnabled ? nil : animation
}

// Returns a subtle fade animation when reduce motion is enabled
// Use for important state changes that need some visual feedback
static func accessible(_ animation: Animation) -> Animation {
    isReduceMotionEnabled ? .easeInOut(duration: 0.1) : animation
}

// Stagger delay helper for sequential animations
static func stagger(index: Int, delay: Double = 0.08) -> Animation {
    .spring(duration: 0.5, bounce: 0.15).delay(Double(index) * delay)
}

// Staggered entrance with sacred timing
static func staggeredEntrance(index: Int, baseDelay: Double = 0.1) -> Animation {
    sacredSpring.delay(Double(index) * baseDelay)
}
```

**View Extensions**:

```swift
extension View {
    // Applies animation only when reduce motion is disabled
    func reducedMotionAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(AppTheme.Animation.reduced(animation), value: value)
    }

    // Applies accessible animation (subtle fade when reduce motion enabled)
    func accessibleAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.animation(AppTheme.Animation.accessible(animation), value: value)
    }
}
```

### 5.3 Signature Visual Effects

**Location**: `RomanEffects.swift`

#### Stone Awakening Modifier

The signature effect where content emerges from gray desaturation to full color:

```swift
struct StoneAwakeningModifier: ViewModifier {
    let isAwake: Bool
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            // Core effect: desaturation 0.3 (stone) → 1.0 (alive)
            .saturation(reduceMotion ? 1.0 : (isAwake ? 1.0 : 0.3))
            // Secondary: slight darkening when dormant
            .brightness(reduceMotion ? 0 : (isAwake ? 0 : -0.05))
            // Tertiary: subtle blur when dormant
            .blur(radius: reduceMotion ? 0 : (isAwake ? 0 : 0.5))
            // Fallback for reduce motion (opacity)
            .opacity(reduceMotion ? (isAwake ? 1.0 : 0) : 1.0)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) : AppTheme.Animation.stoneAwakening.delay(delay),
                value: isAwake
            )
    }
}

extension View {
    func stoneAwakening(_ isAwake: Bool, delay: Double = 0) -> some View {
        modifier(StoneAwakeningModifier(isAwake: isAwake, delay: delay))
    }
}
```

**Usage**:

```swift
ForEach(items.indices, id: \.self) { index in
    ItemView(items[index])
        .stoneAwakening(isAwake, delay: Double(index) * 0.12)
}
```

#### Imperial Button Style

Press effect that feels like pressing into carved marble:

```swift
struct ImperialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            // Inward shadow when pressed (into the stone)
            .shadow(
                color: configuration.isPressed ? Color.stoicCharcoal.opacity(0.3) : .clear,
                radius: 2, y: 2
            )
            // Purple glow lifts when not pressed
            .shadow(
                color: configuration.isPressed ? .clear : Color.imperialPurple.opacity(0.15),
                radius: 8, y: 4
            )
            .animation(AppTheme.Animation.stoicSettle, value: configuration.isPressed)
    }
}
```

#### Additional Roman Effects

- **LaurelSelectionBorder**: Golden border draws in from corners like laurel wreath forming
- **SculpturalCardModifier**: Cards feel carved from marble with inner/outer shadows
- **ImperialGlowBackground**: Living purple radiance with subtle pulse
- **InscribedTextStyle**: Text feels carved with emboss effect
- **StoicQuoteStyle**: All-caps with dignified authority
- **ForumWalkTransition**: Page transition with parallax depth
- **MonumentalEntrance**: Dignified scale animation (0.95→1.0)
- **ColumnReveal**: Staggered list appearance (120ms delays)
- **ImperialLoading**: Circular progress gaining color as it loads

---

## 6. Shadow System

**Location**: `AppTheme.Shadow`

```swift
struct Shadow {
    // Standard shadows
    static let small = ShadowStyle(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let large = ShadowStyle(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)

    // Floating menu shadow
    static let menu = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 6)
    static let menuDark = ShadowStyle(color: .black.opacity(0.5), radius: 16, x: 0, y: 6)

    // Accent glow
    static let indigoGlow = ShadowStyle(color: .scholarIndigo.opacity(0.3), radius: 8, x: 0, y: 0)

    // Aliases
    static let card = small

    // Computed shadow colors for components
    static var menuColor: Color { .black.opacity(0.12) }
    static var cardColor: Color { .scholarIndigo.opacity(0.08) }
    static var elevatedColor: Color { .black.opacity(0.06) }
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
```

---

## 7. Opacity Tokens

**Location**: `AppTheme.Opacity`

```swift
struct Opacity: Sendable {
    // General purpose
    static let faint: Double = 0.08       // Very subtle backgrounds
    static let subtle: Double = 0.1       // Subtle backgrounds
    static let light: Double = 0.15       // Light highlights
    static let lightMedium: Double = 0.2  // Light to medium
    static let quarter: Double = 0.25     // Light shadows, borders
    static let medium: Double = 0.3       // Standard opacity
    static let disabled: Double = 0.4     // Disabled states
    static let midHeavy: Double = 0.45    // Semi-prominent UI
    static let heavy: Double = 0.5        // Heavy/emphasized
    static let strong: Double = 0.6       // Strong visibility
    static let overlay: Double = 0.7      // Overlays
    static let pressed: Double = 0.8      // Pressed states
    static let high: Double = 0.9         // Very visible
    static let nearOpaque: Double = 0.95  // Almost fully visible

    // Gradient-specific
    static let glassTop: Double = 0.08
    static let glassBottom: Double = 0.02
    static let vignetteEdge: Double = 0.3
    static let candleGlowInner: Double = 0.4
    static let candleGlowOuter: Double = 0.1

    // Shadow-specific
    static let shadowSmall: Double = 0.1
    static let shadowMedium: Double = 0.15
    static let shadowLarge: Double = 0.2
    static let shadowMenu: Double = 0.15
    static let shadowMenuDark: Double = 0.5
    static let shadowGoldGlow: Double = 0.3
}
```

---

## 8. Gesture Thresholds

**Location**: `AppTheme.Gesture`

```swift
struct Gesture {
    // Swipe navigation
    static let swipeThreshold: CGFloat = 80
    static let maxDragOffset: CGFloat = 100
    static let minimumDragDistance: CGFloat = 30

    // Long press
    static let longPressDuration: TimeInterval = 0.5

    // Chrome auto-hide
    static let chromeAutoHideDelay: TimeInterval = 8.0
    static let chromeExtendedHideDelay: TimeInterval = 12.0

    // Velocity-based chrome reveal
    static let velocityThresholdForHide: CGFloat = 150    // px/s
    static let velocityThresholdForReveal: CGFloat = 30   // px/s
    static let pauseDurationForReveal: TimeInterval = 0.5
    static let velocityRevealDuration: TimeInterval = 3.0
}
```

---

## 9. UI Components Library

### 9.1 Key Reusable Components

#### IlluminatedIcon

Unified icon system supporting SF Symbols + Streamline assets:

```swift
struct IlluminatedIcon: View {
    let source: IconSource
    var size: CGFloat = 24
    var weight: Font.Weight = .medium
    var renderingMode: IconRenderingMode = .monochrome

    enum IconSource {
        case streamline(String)  // Asset catalog
        case sfSymbol(String)    // SF Symbols
    }

    enum IconRenderingMode {
        case monochrome
        case hierarchical
        case palette(primary: Color, secondary: Color)
    }

    // Builder pattern
    func hierarchical() -> IlluminatedIcon { ... }
    func monochrome() -> IlluminatedIcon { ... }
    func weight(_ weight: Font.Weight) -> IlluminatedIcon { ... }
}
```

#### UnifiedContextMenu

Dual-mode verse selection menu (814 lines):

```swift
enum UnifiedMenuMode {
    case insightFirst  // Read tab: AI insight is hero, actions below
    case actionsFirst  // Scholar tab: Actions only, no insight

    var accentColor: Color {
        switch self {
        case .insightFirst: return .laurelGold
        case .actionsFirst: return .imperialPurple
        }
    }
}

struct UnifiedContextMenu: View {
    let mode: UnifiedMenuMode
    let verseRange: VerseRange
    let onCopy: () -> Void
    let onHighlight: (HighlightColor) -> Void
    let onStudy: () -> Void
    let onDismiss: () -> Void
    // ...
}
```

#### GlassTabBar

iOS 26 glass effect tab bar with Ask FAB:

```swift
struct GlassTabBar: View {
    @Binding var selectedTab: Tab
    let onAskTapped: () -> Void

    // Features:
    // - Pill-shaped segment control
    // - Integrated Ask FAB
    // - Haptic feedback on selection
    // - Glass material background
}
```

#### DynamicSheet

Self-sizing sheet that animates height changes:

```swift
struct DynamicSheet<Content: View>: View {
    var animation: Animation = .smooth(duration: 0.35, extraBounce: 0)
    @ViewBuilder var content: Content

    // Automatically measures content and animates height changes
}
```

#### IlluminatedSettingsCard

Settings section container:

```swift
struct IlluminatedSettingsCard<Content: View>: View {
    let icon: String?
    let title: String
    @ViewBuilder var content: Content

    // Features:
    // - Consistent padding (AppTheme.Spacing)
    // - Theme-aware backgrounds
    // - Optional icon with indigo tint
}
```

#### LoadingView

Multiple loading state variants:

```swift
struct LoadingView: View       // Full-screen loading
struct InlineLoadingView: View // Inline loading
struct SkeletonView: View      // Shimmer placeholder
struct AILoadingView: View     // AI-specific with pulsing sparkle

struct StreamingContentView: View {
    // Progressive AI response reveal with:
    // - Skeleton loading → Ink-bleed animation → Staggered reveal
    // - Progress stages: analyzing → generating → formatting → complete
}
```

### 9.2 Component Patterns

#### State Management

```swift
@State private var isPressed = false
@State private var glowRadius: CGFloat = 0
@Environment(\.colorScheme) private var colorScheme
```

#### Gesture Feedback

```swift
.onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
    isPressed = pressing
    HapticService.shared.lightTap()
}, perform: {})
.scaleEffect(isPressed ? AppTheme.Scale.pressed : 1.0)
.animation(AppTheme.Animation.quick, value: isPressed)
```

#### Theme Integration

```swift
VStack(spacing: AppTheme.Spacing.md) {
    content
        .padding(AppTheme.Spacing.lg)
        .background(Color.Surface.card(for: mode))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(AppTheme.Shadow.small)
}
```

#### Accessibility

```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("Verse actions menu for \(verseRange.reference)")
.accessibilityHint("Contains 4 actions and 5 highlight colors")
.accessibilityAddTraits(.isModal)
.accessibilityAction(.escape) { onDismiss() }

// Dynamic Type support
@ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 44
@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 18
```

---

## 10. Developer Interaction Patterns

### 10.1 Correct Usage Examples

#### Colors

```swift
// ✅ CORRECT - Semantic colors
Text("Edit").foregroundStyle(Color.Semantic.accent)
background.fill(Color.Surface.background(for: theme))
cardBackground.fill(Color.surfaceBackground)

// ❌ INCORRECT - Raw colors
Text("Edit").foregroundStyle(Color(hex: "4F46E5"))
background.fill(Color.red.opacity(0.5))
```

#### Typography

```swift
// ✅ CORRECT - Named typography
Text("CHAPTER 1")
    .font(Typography.Editorial.sectionHeader)
    .tracking(Typography.Editorial.sectionTracking)
    .textCase(.uppercase)

Text(verse.text)
    .font(Typography.Reading.verse(size: .medium, font: .newYork))
    .lineSpacing(Typography.Reading.verseLineSpacing)

// ❌ INCORRECT - Inline definitions
Text("CHAPTER 1").font(.system(size: 11, weight: .bold))
```

#### Spacing

```swift
// ✅ CORRECT - Token-based
VStack(spacing: AppTheme.Spacing.lg) { }
.padding(AppTheme.Spacing.xl)
.cornerRadius(AppTheme.CornerRadius.card)

// ❌ INCORRECT - Hardcoded values
VStack(spacing: 16) { }
.padding(24)
.cornerRadius(12)
```

#### Animations

```swift
// ✅ CORRECT - Named animations with accessibility
withAnimation(AppTheme.Animation.accessible(.spring)) {
    state = newState
}

.animation(AppTheme.Animation.reduced(.standard), value: isVisible)

// ❌ INCORRECT - Inline animations
withAnimation(.easeInOut(duration: 0.3)) { }
```

### 10.2 SwiftLint Enforcement

**Location**: `.swiftlint.yml`
**Rule Count**: 43 custom rules

#### Forbidden Patterns

| Category | Forbidden | Allowed |
| -------- | --------- | ------- |
| Colors | `Color(red:green:blue:)`, `Color(white:)` | `Color.primaryText`, `Color.Semantic.accent` |
| Typography | `.font(.system(size:))`, `.font(.title2)` | `Typography.UI.body`, `Typography.Reading.verse()` |
| Spacing | `.padding(8)`, `spacing: 16` | `.padding(AppTheme.Spacing.sm)` |
| Corner Radius | `.cornerRadius(12)` | `.cornerRadius(AppTheme.CornerRadius.card)` |
| Animations | `.easeOut(duration:)`, `.spring(response:)` | `AppTheme.Animation.standard` |
| Opacity | `.opacity(0.5)` | `.opacity(AppTheme.Opacity.heavy)` |
| Borders | `lineWidth: 2` | `lineWidth: AppTheme.Border.regular` |

#### Escape Hatch Pattern

For justified exceptions:

```swift
// swiftlint:disable:next hardcoded_padding_single
// Reason: Pixel-perfect alignment for third-party component integration
.padding(13)
```

**Valid Reasons**:
- Third-party component integration
- Accessibility edge cases
- Temporary prototyping (with timeline)

**Invalid Reasons**:
- "Looks better"
- "Didn't know the token"
- "It's faster"

#### Migration Rules

```yaml
deprecated_scholar_indigo:
  regex: '\.scholarIndigo(?!Light|Dark|Accessible|Pressed)'
  message: "Migrate to .imperialPurple or Color.Stoic.accent for Roman/Stoic design"
  severity: warning

deprecated_divine_gold:
  regex: '\.divineGold'
  message: "Use .laurelGold for Roman/Stoic decorative elements"
  severity: warning
```

### 10.3 Theme Mode Handling

```swift
// Simple light/dark (asset catalog auto-adaptive)
Color.primaryText
Color.appBackground
Color.surfaceBackground

// All 4 modes (sepia + OLED)
@Environment(\.appState) private var appState

Color.Surface.background(for: appState.preferredTheme)
Color.Surface.text(for: appState.preferredTheme)
Color.Surface.card(for: appState.preferredTheme)

// ColorScheme fallback (when AppState unavailable)
@Environment(\.colorScheme) private var colorScheme

Color.Surface.textPrimary(colorScheme: colorScheme)
Color.Surface.card(colorScheme: colorScheme)
```

---

## 11. Design System Showcases

### 11.1 DevTools Directory

**Location**: `BibleStudy/DevTools/Showcases/`

```
Showcases/
├── Home/              (5 page variants)
│   ├── Pages/
│   │   ├── TheForumPage.swift        # Stoic wisdom center
│   │   ├── TheStoaPage.swift         # Contemplative forum
│   │   ├── ThePorticoPage.swift      # Architectural marketplace
│   │   ├── TheScriptoriumPage.swift  # Manuscript workshop
│   │   └── TheMeditationChamberPage.swift
│   ├── Components/
│   ├── Models/
│   └── Views/
│
├── Chat/              (3 variants)
│   ├── Views/Variants/
│   │   ├── WarmSanctuaryChatView.swift
│   │   ├── MinimalStudioChatView.swift
│   │   └── ScholarlyCompanionChatView.swift
│   ├── Theme/ChatPalette.swift
│   └── Models/ChatVariant.swift
│
├── Prayer/            (3 UX variants)
│   ├── Variations/
│   │   ├── Balanced/   # Breathing circle, phases
│   │   ├── Minimal/    # Compact, focused
│   │   └── Ornate/     # Rich, decorative
│   ├── Pages/
│   └── Shared/
│
├── Readers/           (2 variants)
│   ├── Views/Variants/
│   │   ├── CandlelitChapelReaderView.swift
│   │   └── IlluminatedScriptoriumReaderView.swift
│   └── Models/ReaderVariant.swift
│
├── Settings/          (2 variants)
│   └── Variants/
│       ├── DivineHubSettings.swift
│       └── SacredScrollSettings.swift
│
├── Onboarding/        (3 variants)
│   └── Pages/
│       ├── ImmersiveCardsOnboardingView.swift
│       ├── TechForwardOnboardingView.swift
│       └── ElegantMinimalOnboardingView.swift
│
└── Scripture/
    └── LivingScriptureView.swift  # Interactive exploration
```

### 11.2 Showcase Purpose

Each showcase demonstrates:

1. **Color Palette Variations** - Different semantic color mappings per mood
2. **Typography Hierarchy** - Varying scales and weights
3. **Spacing & Layout** - Different uses of `AppTheme.Spacing.*`
4. **Component Theming** - How reusable components adapt
5. **Animation Behaviors** - Specialized motion treatments

### 11.3 Feature Consumption Summary

| Feature | Primary Colors | Typography | Key Components |
| ------- | -------------- | ---------- | -------------- |
| Home | Stoic.accent, liturgical hours | Roman.heading1, inscribed | RomanBackground, cards |
| Bible | scholarIndigo, highlights | Reading.verse, Insight.* | UnifiedContextMenu, InsightCard |
| Ask | Semantic.accent | Insight.*, UI.body | LivingScrollView, InputBar |
| Settings | Stoic.accent | UI.headline, body | IlluminatedSettingsCard |
| Prayer | threshold colors | Reading.verseItalic | DeepPrayerBackground |
| Stories | scholarIndigo | Display.title1, UI.body | StoryCard, TimelineView |

---

## 12. Design Philosophy

### 12.1 Roman/Stoic Sculptural Monumentalism

The current design language emphasizes:

- **Monumental Clarity**: Clean, structured layouts with bold hierarchies
- **Heroic Resilience**: Stone awakening effects - content emerges from gray to full color
- **Imperial Harmony**: Balance of Imperial Purple accents with Laurel Gold decorative touches
- **Dignified Motion**: Animations convey weight and permanence, not playfulness

#### Visual Language Principles

1. **UI feels "carved from marble"** - Subtle depth via inner/outer shadows
2. **Elements "awaken from stone"** - Desaturation animations on content reveals
3. **Typefaces evoke inscription** - Cinzel for carved capitals, Cormorant for humanist warmth
4. **Color palette reflects Roman world** - Imperial purple, laurel gold, marble whites

#### Color Strategy

| Proportion | Usage |
| ---------- | ----- |
| 50% | Stoic Neutrals (marble, stone, earth tones) |
| 30-40% | Imperial Purple (primary accents, interactive) |
| 10-20% | Laurel Gold (decorative, ornamental) |
| 10-20% | Historical Roman accents (semantic status colors) |

### 12.2 Evolution from Illuminated Manuscript

The design system evolved from an earlier illuminated manuscript aesthetic:

| Original | Current |
| -------- | ------- |
| Gold-based palette | Imperial Purple primary |
| Decorative warmth | Dignified monumentalism |
| Calligraphy aesthetics | Preserved in drop caps |
| Sacred ornamentation | Chapter headers, dividers |

**Migration Approach**:
- Deprecated names map to new names via computed properties
- Old API continues working with migration guidance
- Gradual component updates without breaking builds

### 12.3 Core Design Principles

1. **Semantic Over Primitive** - Tokens express meaning, not just values
2. **Adaptive by Default** - Light/dark/sepia/OLED built-in from start
3. **Strict Enforcement** - SwiftLint prevents backsliding to hardcoded values
4. **Graceful Deprecation** - Old patterns work while encouraging new ones
5. **Accessibility First** - Haptics, motion preferences, WCAG compliance
6. **Component Composition** - Small focused pieces compose into larger features
7. **Showcases as Documentation** - Interactive galleries serve as pattern library

---

## 13. Quick Reference Tables

### 13.1 Color Semantic Mapping

| Semantic | Light Mode | Dark Mode | Usage |
| -------- | ---------- | --------- | ----- |
| `Semantic.accent` | scholarIndigo | scholarIndigo | Primary CTA |
| `Semantic.accentPressed` | scholarIndigoPressed | scholarIndigoPressed | Pressed state |
| `Semantic.success` | theologyGreen | theologyGreen | Positive status |
| `Semantic.error` | vermillionJewel | vermillionJewel | Error states |
| `Semantic.warning` | connectionAmber | connectionAmber | Caution |
| `Semantic.info` | greekBlue | greekBlue | Information |
| `Stoic.accent` | imperialPurple | imperialPurple | Roman feature accent |
| `Stoic.decorativeAccent` | laurelGold | laurelGold | Decorative elements |

### 13.2 Typography Quick Reference

| Context | Namespace | Example Usage |
| ------- | --------- | ------------- |
| Verse text | `Typography.Reading` | `.verse(size: .medium, font: .newYork)` |
| AI insights | `Typography.Insight` | `.body`, `.heroSummary`, `.emphasis` |
| Section headers | `Typography.Editorial` | `.sectionHeader` + tracking + uppercase |
| References | `Typography.Editorial` | `.reference` + tracking |
| UI elements | `Typography.UI` | `.body`, `.buttonLabel`, `.caption1` |
| Display titles | `Typography.Display` | `.largeTitle`, `.title1` |
| Stoic design | `Typography.Roman` | `.heading1`, `.inscribed` |
| Drop caps | `Typography.Illuminated` | `.dropCap(size:)` |

### 13.3 Animation Quick Reference

| Intent | Animation | Duration |
| ------ | --------- | -------- |
| Quick feedback | `.quick` | 0.15s |
| Standard transition | `.standard` | 0.25s |
| Reverent change | `.reverent` | 0.6s |
| Glow effect | `.luminous` | 0.4s (fast-in, slow-out) |
| Stone reveal | `.stoneAwakening` | 0.8s |
| Dignified entrance | `.monumental` | 0.6s spring |
| Staggered list | `.columnReveal(index:)` | 120ms/item |
| Stoic landing | `.stoicSettle` | 0.4s |
| Majestic crossfade | `.imperialFade` | 1.0s |
| Menu appear | `.menuAppear` | 0.35s spring |
| Selection | `.selection` | 0.2s |

### 13.4 Spacing Quick Reference

| Token | Value | Common Usage |
| ----- | ----- | ------------ |
| `xxs` | 2pt | Hairline gaps |
| `xs` | 4pt | Tight spacing |
| `sm` | 8pt | Small gaps |
| `md` | 12pt | Medium gaps |
| `lg` | 16pt | Standard spacing |
| `xl` | 24pt | Large spacing |
| `xxl` | 32pt | Section spacing |
| `xxxl` | 48pt | Major sections |
| `huge` | 64pt | Hero sections |

---

## 14. Key Files Reference

| File | Lines | Purpose |
| ---- | ----- | ------- |
| `AppTheme.swift` | 660 | Design tokens: spacing, radius, shadows, animations, opacity |
| `Colors.swift` | 1,850 | Three-tier color architecture with WCAG compliance |
| `Typography.swift` | 890 | 7 typography namespaces with custom fonts |
| `CustomFonts.swift` | 74 | Font loading with availability checks and fallbacks |
| `StoicTheme.swift` | 300 | Roman/Stoic themed feature aggregation |
| `StoicGradients.swift` | 80+ | Gradient definitions and view modifiers |
| `RomanEffects.swift` | 80+ | Visual effects (StoneAwakening, ImperialButton) |
| `TypographyModifiers.swift` | 100+ | Correct-by-default view modifiers |
| `UnifiedContextMenu.swift` | 814 | Dual-mode verse selection menu |
| `ToastManager.swift` | 238 | Observable singleton toast system |
| `SacredTransitions.swift` | 406 | Custom transition library |
| `IlluminatedToggle.swift` | 223 | Settings toggle with glow animation |

---

## Document Purpose

This assessment serves as a foundational reference for expanding the BibleStudy design system. It documents:

- Current architecture and file organization
- Token definitions with code examples
- Semantic naming conventions
- Component patterns and reusability
- Developer interaction conventions
- Accessibility and theming support
- Design philosophy and visual language

The design system is mature, well-enforced via SwiftLint, and ready for systematic expansion while maintaining consistency with established patterns.

---

*Generated: January 2026*
*Version: Design System Assessment v1.0*
