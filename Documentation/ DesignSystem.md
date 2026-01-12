# BibleStudy Design System

> **Purpose**: Comprehensive reference for the BibleStudy iOS app's design system. Source of truth for tokens, patterns, and conventions.

---

## Executive Summary

The BibleStudy app uses a **Stoic-Existential Renaissance** design system with semantic tokens for spacing, typography, colors, animations, and opacity. The system prioritizes simplicity, accessibility, and ceremonial restraint.

**Migration Status**: ✅ **Phase 7 Complete** (January 2026)

- All legacy namespaces (`AppTheme.*`, `StoicTheme.*`) deleted
- Simplified to `Theme.*`, `Typography.*`, and Asset Catalog colors
- 96% token adoption rate across codebase

### Key Statistics

| Category | Count | Location |
|----------|-------|----------|
| Spacing tokens | 6 | `Theme.Spacing.*` |
| Radius tokens | 8 | `Theme.Radius.*` |
| Animation tokens | 4 | `Theme.Animation.*` |
| Opacity tokens | 12 | `Theme.Opacity.*` |
| Typography namespaces | 6 | Scripture, Command, Editorial, Label, Icon, Decorative |
| Asset Catalog colors | 12 | Backgrounds, Text, Accents, Feedback |
| SwiftLint rules | 40+ | `.swiftlint.yml` |

### Design Philosophy

**Stoic-Existential Renaissance** (Classical Self-Confrontation):

- "Serif for truth. Sans for command." - font signals mode
- Hairline strokes (1pt) over shadows for definition
- Cubic-eased motion only - NO spring animations
- Motion is ceremonial, restrained, almost invisible
- Generic naming (`Theme`, `Typography`) for flexibility

---

## 1. File Organization

### Theme Files (`BibleStudy/UI/Theme/`)

| File | Lines | Purpose |
|------|-------|---------|
| `Theme.swift` | ~280 | Design tokens: Spacing, Radius, Stroke, Animation, Opacity, Size, Reading, Toggle |
| `Typography.swift` | ~400 | Typography namespaces: Scripture, Command, Editorial, Label, Icon, Decorative |
| `TypographyModifiers.swift` | ~300 | View modifiers for correct-by-default typography |
| `Colors.swift` | ~100 | StateOverlay utilities, HighlightColor enum |
| `README.md` | ~175 | Quick reference guide |
| `DESIGN_SYSTEM_CONTRACT.md` | ~170 | Enforcement rules |

### Asset Catalog (`Assets.xcassets/Colors/`)

All colors defined in Asset Catalog with automatic dark/light mode support:

```
Colors/
├── AppBackground.colorset      # Main background
├── AppSurface.colorset         # Elevated surfaces (cards)
├── AppDivider.colorset         # Divider lines
├── AppTextPrimary.colorset     # Primary text
├── AppTextSecondary.colorset   # Secondary text
├── TertiaryText.colorset       # Tertiary text
├── AppAccentAction.colorset    # Primary accent (Imperial Purple)
├── AccentBronze.colorset       # Secondary accent (Bronze)
├── FeedbackError.colorset      # Error states
├── FeedbackWarning.colorset    # Warning states
├── FeedbackSuccess.colorset    # Success states
└── FeedbackInfo.colorset       # Info states
```

---

## 2. Spacing System

**Location**: `Theme.swift` - `Theme.Spacing`

| Token | Value | Use Case |
|-------|-------|----------|
| `.xs` | 6pt | Tight spacing |
| `.sm` | 10pt | Small gaps |
| `.md` | 16pt | Medium gaps (default) |
| `.lg` | 24pt | Large spacing |
| `.xl` | 32pt | Extra large |
| `.xxl` | 48pt | Section spacing |

**Usage**:
```swift
VStack(spacing: Theme.Spacing.md) {
    content
        .padding(Theme.Spacing.lg)
        .padding(.horizontal, Theme.Spacing.xl)
}
```

---

## 3. Corner Radius System

**Location**: `Theme.swift` - `Theme.Radius`

| Token | Value | Use Case |
|-------|-------|----------|
| `.xs` | 2pt | Indicator strips, progress bars |
| `.tag` | 6pt | Small badges/tags |
| `.input` | 8pt | Input fields, small controls |
| `.md` | 8pt | Context menus (alias) |
| `.button` | 10pt | CTA buttons |
| `.card` | 14pt | Cards, floating menus |
| `.xl` | 16pt | Large cards, overlays |
| `.sheet` | 20pt | Bottom sheets, modals |

**Usage**:
```swift
RoundedRectangle(cornerRadius: Theme.Radius.card)
    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
```

---

## 4. Stroke System

**Location**: `Theme.swift` - `Theme.Stroke`

| Token | Value | Use Case |
|-------|-------|----------|
| `.hairline` | 1pt | Subtle dividers, card borders |
| `.control` | 2pt | Control strokes (buttons, inputs) |

**Policy**: Prefer strokes over shadows for visual separation.

**Usage**:
```swift
Rectangle()
    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
```

---

## 5. Animation System

**Location**: `Theme.swift` - `Theme.Animation`

### Motion Doctrine

> "Ceremonial, restrained, almost invisible"

- ALL cubic easing - NO spring animations
- Banned: Confetti, fireworks, bouncy easing, shimmer gradients

### Animation Tokens

| Token | Duration | Easing | Use Case |
|-------|----------|--------|----------|
| `.fade` | 220ms | easeInOut | Tab switching, modal appearance |
| `.settle` | 260ms | easeOut | Content settling, card reveals |
| `.slowFade` | 420ms | easeInOut | "Begin" transitions, ritual moments |
| `.stagger(index:)` | 260ms + delay | easeOut | Sequential list reveals |

**Usage**:
```swift
withAnimation(Theme.Animation.fade) {
    showContent = true
}

.animation(Theme.Animation.settle, value: isSelected)

// Staggered reveals
ForEach(items.indices, id: \.self) { index in
    ItemView()
        .animation(Theme.Animation.stagger(index: index), value: isVisible)
}
```

### Canonical Ritual Transition

For "Begin" actions (Daily Office, Evening Examen, etc.):
1. Fade to near-black: 200ms easeOut
2. Content fade in: 240-360ms easeInOut
3. Subtle vertical drift: 2-4pt during fade in

```swift
withAnimation(Theme.Animation.slowFade) {
    showContent = true
}
```

---

## 6. Opacity System

**Location**: `Theme.swift` - `Theme.Opacity`

### Interaction States

| Token | Value | Use Case |
|-------|-------|----------|
| `.pressed` | 0.80 | Press feedback on buttons/controls |
| `.disabled` | 0.35 | Disabled controls and buttons |
| `.focusStroke` | 0.60 | Focus ring/stroke strength |
| `.selectionBackground` | 0.15 | Verse/text selection background |

### Text Hierarchy

| Token | Value | Use Case |
|-------|-------|----------|
| `.textPrimary` | 0.96 | Primary body text |
| `.textSecondary` | 0.75 | Secondary/supporting text |
| `.textTertiary` | 0.60 | Metadata, captions, timestamps |
| `.textDisabled` | 0.35 | Disabled text |

### Structural

| Token | Value | Use Case |
|-------|-------|----------|
| `.divider` | 0.12 | Divider lines, borders |
| `.overlay` | 0.10 | Modal overlays, scrims |
| `.subtle` | 0.05 | Atmospheric backgrounds |
| `.highlight` | 0.40 | Verse highlights |

**Usage**:
```swift
.opacity(Theme.Opacity.textSecondary)
.opacity(Theme.Opacity.pressed)

// State overlays (Colors.swift utilities)
Colors.StateOverlay.pressed(baseColor)
Colors.StateOverlay.selection(accentColor)
Colors.StateOverlay.disabled(baseColor)
```

---

## 7. Size System

**Location**: `Theme.swift` - `Theme.Size`

| Token | Value | Use Case |
|-------|-------|----------|
| `.minTapTarget` | 44pt | Minimum interactive element (Apple HIG) |
| `.iconSize` | 24pt | Standard icon size |
| `.iconSizeLarge` | 32pt | Large icon size |

---

## 8. Reading Layout

**Location**: `Theme.swift` - `Theme.Reading`

| Token | Value | Use Case |
|-------|-------|----------|
| `.maxWidth` | 500pt | Reading container max width (~55 chars) |
| `.horizontalPadding` | 20pt | Reading content margins |
| `.paragraphSpacing` | 12pt | Between paragraphs |
| `.sectionSpacing` | 24pt | Chapter/section breaks |
| `.verseSpacingMeditative` | 20pt | Slow reading mode |

**Usage**:
```swift
Text(scripture)
    .frame(maxWidth: Theme.Reading.maxWidth)
    .padding(.horizontal, Theme.Reading.horizontalPadding)
```

---

## 9. Typography System

**Location**: `Typography.swift`

### Philosophy

> "Serif for truth. Sans for command."

- **New York (Serif)** = Contemplation (scripture, readings, prompts)
- **SF Pro (Sans)** = Action (buttons, navigation, system)
- Font switching signals mode change to user

### Hard Rules

1. Buttons are ALWAYS Sans - no poetic button labels
2. Verse numbers are ALWAYS Sans (functional, not sacred)
3. ALL CAPS only for tiny tags with tracking
4. Emphasis: Italics (serif) for maxims, Weight (sans) for system
5. Reading blocks constrained to max width (~45-70 chars/line)

### Scripture Tokens (`Typography.Scripture.*`)

New York serif for contemplation.

| Token | Size | Use Case |
|-------|------|----------|
| `.display` | 34pt semibold | Hero titles ("Evening Examen") |
| `.title` | 28pt semibold | Screen/session titles |
| `.heading` | 22pt semibold | Section headers |
| `.prompt` | 24pt regular | Examination questions |
| `.body` | 17pt regular | Scripture reading |
| `.quote` | 17pt italic | Maxims, quotations |
| `.footnote` | 13pt regular | Footnotes, references |

**View Modifiers**:
```swift
Text("Evening Examen").scriptureDisplay()
Text("Section").scriptureHeading()
Text(verse.text).scriptureBody()
Text("Maxim").scriptureQuote()
```

### Command Tokens (`Typography.Command.*`)

SF Pro sans for action.

| Token | Size | Use Case |
|-------|------|----------|
| `.cta` | 17pt semibold | Primary buttons |
| `.body` | 17pt regular | Short instructions |
| `.label` | 15pt medium | Field labels, chips |
| `.meta` | 13pt medium | Dates, tags, verse numbers |
| `.caption` | 12pt regular | Hints, helper text |
| `.errorTitle` | 15pt semibold | Error titles |
| `.errorBody` | 13pt regular | Error guidance |
| `.largeTitle` | 34pt bold | Large navigation titles |
| `.title1` | 28pt bold | Primary titles |
| `.title2` | 22pt bold | Secondary titles |
| `.title3` | 20pt semibold | Tertiary titles |
| `.headline` | 17pt semibold | Section headlines |
| `.subheadline` | 15pt regular | Supporting text |
| `.callout` | 16pt regular | Callout text |

**View Modifiers**:
```swift
Text("Begin").commandCTA()
Text("Instructions").commandBody()
Text("Label").commandLabel()
Text("12 Jan 2026").commandMeta()
```

### Editorial Tokens (`Typography.Editorial.*`)

Tracked uppercase for section headers.

| Token | Size | Tracking | Use Case |
|-------|------|----------|----------|
| `.sectionHeader` | 11pt bold | 2.5px | Section headers |
| `.label` | 10pt bold | 2.0px | Editorial labels |
| `.labelSmall` | 9pt bold | - | Small editorial labels |

**Usage**:
```swift
Text("LESSON")
    .font(Typography.Editorial.sectionHeader)
    .tracking(Typography.Editorial.sectionTracking)
    .textCase(.uppercase)
```

### Label Tokens (`Typography.Label.*`)

Uppercase tags with tracking.

| Token | Size | Tracking | Use Case |
|-------|------|----------|----------|
| `.uppercase` | 12pt medium | 2.2px | Metadata tags, small labels |

**View Modifier**:
```swift
Text("NEW").uppercaseLabel()
```

### Icon Tokens (`Typography.Icon.*`)

SF Symbol sizing scale.

| Token | Size | Use Case |
|-------|------|----------|
| `.xxxs` | 8pt | Tiny badges |
| `.xxs` | 10pt | Small indicators |
| `.xs` | 12pt | Tiny indicators |
| `.sm` | 14pt | Small buttons |
| `.md` | 16pt | Standard icons |
| `.base` | 18pt | Default icons |
| `.lg` | 24pt | Large icons |
| `.xl` | 28pt | Feature icons |
| `.xxl` | 32pt | Extra large |
| `.hero` | 40pt | Hero icons |
| `.display` | 76pt | Onboarding |

**Usage**:
```swift
Image(systemName: "book")
    .font(Typography.Icon.lg)
```

### Decorative Tokens (`Typography.Decorative.*`)

Illuminated manuscript effects.

| Token | Size | Use Case |
|-------|------|----------|
| `.dropCap` | 72pt bold serif | Large illuminated first letter |
| `.dropCapCompact` | 52pt bold serif | Compact drop cap |

---

## 10. Color System

**Location**: Asset Catalog + `Colors.swift`

### Asset Catalog Colors

All colors use Asset Catalog with automatic dark/light mode support.

**Backgrounds**:
- `Color("AppBackground")` - Main background
- `Color("AppSurface")` - Elevated surfaces
- `Color("AppDivider")` - Divider lines

**Text**:
- `Color("AppTextPrimary")` - Primary text
- `Color("AppTextSecondary")` - Secondary text
- `Color("TertiaryText")` - Tertiary text

**Accents**:
- `Color("AppAccentAction")` - Primary accent (Imperial Purple)
- `Color("AccentBronze")` - Secondary accent (Bronze)

**Feedback**:
- `Color("FeedbackError")` - Error states
- `Color("FeedbackWarning")` - Warning states
- `Color("FeedbackSuccess")` - Success states
- `Color("FeedbackInfo")` - Info states

### State Overlays (`Colors.StateOverlay`)

Utilities for consistent interaction feedback:

```swift
Colors.StateOverlay.pressed(baseColor)        // 0.80 opacity
Colors.StateOverlay.selection(accentColor)    // 0.15 opacity
Colors.StateOverlay.focusStroke(accentColor)  // 0.60 opacity
Colors.StateOverlay.disabled(baseColor)       // 0.35 opacity
```

### Highlight Colors (`HighlightColor`)

Verse annotation colors:

| Case | Color | Use Case |
|------|-------|----------|
| `.blue` | FeedbackInfo | Original language annotations |
| `.green` | FeedbackSuccess | Doctrinal study notes |
| `.amber` | FeedbackWarning | Cross-references |
| `.rose` | AccentBronze | Reflective questions |
| `.purple` | AppAccentAction | General/spiritual |

---

## 11. Toggle Sizing

**Location**: `Theme.swift` - `Theme.Toggle`

Custom sizing for GoldToggleStyle:

| Token | Value |
|-------|-------|
| `.trackWidth` | 51pt |
| `.trackHeight` | 31pt |
| `.thumbSize` | 27pt |
| `.thumbOffset` | 10pt |

---

## 12. SwiftLint Enforcement

**Location**: `.swiftlint.yml`

### Forbidden Patterns

| Category | Forbidden | Allowed |
|----------|-----------|---------|
| Colors | `Color(red:)`, `UIColor(red:)` | `Color("AppTextPrimary")` |
| Typography | `.font(.system(size:))`, `.font(.title)` | `Typography.Scripture.*` |
| Spacing | `.padding(16)` | `Theme.Spacing.md` |
| Corner Radius | `.cornerRadius(12)` | `Theme.Radius.card` |
| Animation | `.spring()`, `.easeInOut(duration:)` | `Theme.Animation.fade` |
| Opacity | `.opacity(0.5)` | `Theme.Opacity.textSecondary` |

### Escape Hatch

For justified exceptions:

```swift
// swiftlint:disable:next hardcoded_padding_single
// Reason: Pixel-perfect alignment for third-party component
.padding(13)
```

**Valid Reasons**:
- Third-party component integration
- Accessibility edge cases
- Pixel-perfect alignment outside token scale

---

## 13. Token Reference

| System | File | Namespace |
|--------|------|-----------|
| Spacing | Theme.swift | `Theme.Spacing.*` |
| Radius | Theme.swift | `Theme.Radius.*` |
| Stroke | Theme.swift | `Theme.Stroke.*` |
| Animation | Theme.swift | `Theme.Animation.*` |
| Size | Theme.swift | `Theme.Size.*` |
| Opacity | Theme.swift | `Theme.Opacity.*` |
| Reading | Theme.swift | `Theme.Reading.*` |
| Toggle | Theme.swift | `Theme.Toggle.*` |
| Scripture | Typography.swift | `Typography.Scripture.*` |
| Command | Typography.swift | `Typography.Command.*` |
| Editorial | Typography.swift | `Typography.Editorial.*` |
| Label | Typography.swift | `Typography.Label.*` |
| Icon | Typography.swift | `Typography.Icon.*` |
| Decorative | Typography.swift | `Typography.Decorative.*` |
| Colors | Asset Catalog | `Color("AssetName")` |
| State Overlays | Colors.swift | `Colors.StateOverlay.*` |

---

## 14. View Modifiers Reference

### Typography Modifiers

```swift
// Scripture
Text("Title").scriptureDisplay()
Text("Section").scriptureHeading()
Text("Question").scripturePrompt()
Text(verse).scriptureBody()
Text("Maxim").scriptureQuote()
Text("Ref").scriptureFootnote()

// Command
Text("Begin").commandCTA()
Text("Info").commandBody()
Text("Label").commandLabel()
Text("Date").commandMeta()
Text("Hint").commandCaption()
Text("Error").commandErrorTitle()

// Labels
Text("NEW").uppercaseLabel()
```

### Reading Layout Modifiers

```swift
// TypographyModifiers.swift
Text(verse.text)
    .readingVerse(size: fontSize, font: fontFamily)

Text("\(verse.verse)")
    .readingVerseNumber()
    .foregroundStyle(Color("TertiaryText"))
```

---

## 15. Accessibility

### WCAG Compliance

All text/background combinations meet WCAG AA standards (4.5:1 for text, 3:1 for large text 18pt+).

### Reduce Motion Support

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : Theme.Animation.fade) {
    // ...
}
```

### Dynamic Type

All typography scales with iOS accessibility settings. Test at largest accessibility size (AX5).

### Tap Targets

Minimum tap target: 44pt (`Theme.Size.minTapTarget`)

---

## Document Changelog

| Date | Version | Changes |
|------|---------|---------|
| Jan 2026 | 2.0 | Complete rewrite for Phase 7 completion |

---

*Generated: January 2026*
*Version: Design System v2.0 (Post-Phase 7)*
