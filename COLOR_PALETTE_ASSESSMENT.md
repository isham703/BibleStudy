# Color Palette Assessment

**Date**: January 3, 2026
**Context**: Scholar tab dark mode consolidation project

## Current State

### Asset Catalog Colors (Adaptive - Light/Dark Modes)

#### Surfaces
- ✅ `AppBackground` - Primary app background
- ✅ `SurfaceBackground` - Cards, elevated surfaces
- ✅ `ElevatedBackground` - Modals, sheets
- ✅ `CardBorder` - Card borders
- ✅ `Divider` - Separator lines
- ✅ `SelectedBackground` - Selected state backgrounds

#### Text
- ✅ `PrimaryText` - Main content text
- ✅ `SecondaryText` - Supporting text
- ✅ `TertiaryText` - Subtle text, placeholders
- ✅ `VerseNumber` - Scripture verse numbers

#### Brand/Accents
- ✅ `AccentIndigo` (scholarIndigo) - Primary accent
- ✅ `AccentBlue` - Secondary accent
- ✅ `AccentRose` - Tertiary accent

#### Scholar Supporting Colors
- ✅ `GreekBlue` - Annotations
- ✅ `TheologyGreen` - Doctrinal highlights
- ✅ `ConnectionAmber` - Cross-references
- ✅ `PersonalRose` - Reflective notes

#### Highlights (Verse Marking)
- ✅ `HighlightBlue`
- ✅ `HighlightGold`
- ✅ `HighlightGreen`
- ✅ `HighlightPurple`
- ✅ `HighlightRose`

#### Jewel Tones
- ✅ `Amethyst`
- ✅ `LapisLazuli`
- ✅ `Malachite`
- ✅ `Vermillion`

#### Semantic States
- ✅ `Error`
- ✅ `Warning`
- ✅ `Success`
- ✅ `Info`

### Hardcoded Colors (Non-Adaptive)

#### Still in Colors.swift (1244 lines)
- 🔴 **150+ hardcoded hex colors** that don't adapt to dark mode
- Gold family variations (divineGold, burnishedGold, illuminatedGold, etc.)
- Vellum/Parchment variants (freshVellum, agedParchment, monasteryStone)
- Ink colors (monasteryBlack, agedInk, sepiaInk)
- Liturgical hour palettes (Dawn, Meridian, Afternoon, Vespers, Compline)
- Sacred Threshold colors
- Showcase-specific colors

## Issues Identified

### 1. **Duplicate/Redundant Colors**

Many hardcoded colors serve similar purposes to asset catalog colors:

| Hardcoded Color | Asset Catalog Equivalent | Issue |
|----------------|---------------------------|-------|
| `vellumCream` | `AppBackground` (light) | Already migrated in this session |
| `scholarInk` | `PrimaryText` (light) | Already migrated in this session |
| `footnoteGray` | `TertiaryText` (light) | Already migrated in this session |
| `freshVellum` | `AppBackground` (light) | Duplicate definition |
| `monasteryBlack` | `PrimaryText` (light) | Duplicate definition |
| `monasteryStone` | `SurfaceBackground` (light) | Similar purpose |

### 2. **Missing Dark Mode Variants**

Asset catalog colors that exist but may need expansion:

| Need | Current Status |
|------|----------------|
| Pressed/Active states | ❌ Not in asset catalog |
| Disabled states | ❌ Not in asset catalog |
| Hover states (for Mac) | ❌ Not in asset catalog |
| Focus ring colors | ❌ Not in asset catalog |

### 3. **Feature-Specific Palettes**

Colors that are only used by specific features:

- **Liturgical Hours** (Dawn, Meridian, Afternoon, Vespers, Compline) - Only used by time-aware sanctuary views
- **Sacred Threshold** - Only used by one feature
- **Showcase colors** - Only used by DevTools

**Issue**: These are in global `Colors.swift` but should be in feature-specific files.

### 4. **Inconsistent Naming**

Multiple naming conventions:

- Poetic names: `divineGold`, `illuminatedGold`, `moonlitParchment`
- Descriptive names: `freshVellum`, `agedParchment`
- Semantic names: `primaryText`, `surfaceBackground`
- Location names: `candlelitStone`, `chapelShadow`

## Recommendations

### Phase 1: Clean Up Redundancies (Immediate)

1. **Remove migrated colors** from Colors.swift:
   - ✅ `vellumCream` - migrated to `Color.appBackground`
   - ✅ `scholarInk` - migrated to `Color.primaryText`
   - ✅ `footnoteGray` - migrated to `Color.tertiaryText`
   - ✅ `scholarIndigoSubtle` - can use `scholarIndigo.opacity(0.1)`

2. **Add deprecation warnings** for colors with asset catalog equivalents:
   ```swift
   @available(*, deprecated, message: "Use Color.appBackground instead")
   static let freshVellum = Color(hex: "FBF7F0")
   ```

### Phase 2: Expand Asset Catalog (Recommended)

Add missing adaptive states:

```
Colors/States/
├── PressedBackground.colorset (for touch feedback)
├── DisabledBackground.colorset
├── DisabledText.colorset
├── FocusRing.colorset (for keyboard nav)
├── HoverBackground.colorset (for Mac)
└── PlaceholderText.colorset
```

### Phase 3: Move Feature-Specific Colors (Optional)

Relocate feature-specific palettes:

```
Features/Home/Theme/
├── LiturgicalColors.swift (Dawn, Meridian, Vespers, etc.)
└── SacredThresholdColors.swift

Features/Experiences/Theme/
└── ExperienceColors.swift
```

### Phase 4: Standardize Naming (Optional)

Pick one naming convention - recommendation:

- **Semantic** for UI states: `primaryText`, `surfaceBackground`
- **Descriptive** for theme-specific: `dawnSky`, `vespersPurple`
- **Brand** for accent colors: `scholarIndigo`, `greekBlue`

## Missing Colors Assessment

### Colors We Don't Have (But Might Need)

1. **Interactive States**
   - ❌ Link color (hover/visited states)
   - ❌ Button secondary/tertiary variants
   - ❌ Destructive action color (separate from Error semantic)

2. **Reading Experience**
   - ✅ Have: verse highlighting (5 colors)
   - ❌ Missing: note/bookmark category colors beyond current set
   - ❌ Missing: cross-reference link colors

3. **Chart/Data Visualization**
   - ❌ Data series colors (if charts are used)
   - ❌ Progress indicator colors

4. **Accessibility**
   - ❌ High contrast mode variants
   - ❌ Reduced transparency mode support

### Colors We Have (But Might Not Need)

1. **150+ liturgical/time-aware colors** - Could be consolidated
2. **Multiple gold variants** (7 different golds) - Could use opacity/tint variations
3. **Duplicate background colors** - Many serve same purpose

## Summary

### Strengths ✅
- Excellent asset catalog structure with light/dark support
- Good semantic naming in asset catalog
- Comprehensive highlight colors for scripture marking
- All core UI colors are adaptive

### Weaknesses ❌
- Too many hardcoded colors (150+) that don't adapt
- Feature-specific colors in global file
- Redundant color definitions
- Missing common interactive states

### Priority Actions

1. **High Priority** - Add missing adaptive states to asset catalog:
   - Pressed/hover/disabled states
   - Placeholder text color

2. **Medium Priority** - Clean up Colors.swift:
   - Remove/deprecate migrated colors
   - Move feature-specific palettes

3. **Low Priority** - Naming standardization
   - Can be done gradually as code is touched

## Next Steps

1. Should we add the missing interactive state colors to the asset catalog?
2. Should we remove/deprecate the redundant hardcoded colors?
3. Should we move feature-specific color palettes to their respective features?
