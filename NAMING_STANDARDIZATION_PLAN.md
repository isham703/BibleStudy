# Color Naming Standardization Plan - Phase 4

**Date**: January 3, 2026
**Context**: Standardizing color naming conventions in Colors.swift

## Current Naming Patterns

### 1. Poetic/Evocative Names (Inconsistent)
```swift
divineGold, illuminatedGold, burnishedGold, ancientGold
candlelitStone, chapelShadow
moonlitParchment, fadedMoonlight, starlight, moonMist
nightVoid, warmBurgundy, deepIndigo
```
**Issue**: Beautiful but inconsistent, unclear what they're used for

### 2. Material-Based Names (Clear)
```swift
freshVellum, agedParchment, monasteryStone
monasteryBlack, agedInk, sepiaInk
```
**Good**: Self-descriptive, material metaphor is clear

### 3. Jewel Family (Consistent)
```swift
vermillionJewel, lapisLazuliJewel, malachiteJewel, amethystJewel
```
**Good**: Consistent pattern, beautiful historical reference

### 4. Semantic/Functional Names (Best Practice)
```swift
showcaseBackground, showcaseSurface, showcaseCard
showcasePrimaryText, showcaseSecondaryText, showcaseTertiaryText
```
**Best**: Clear purpose, follows iOS conventions

### 5. Theme-Specific Prefixes (Organized)
```swift
// Dawn palette
dawnLavender, dawnPeriwinkle, dawnRosePink, dawnPeach

// Meridian palette
meridianParchment, meridianVellum, meridianIllumination

// Vespers palette
vespersIndigo, vespersAmber, vespersSky

// OLED theme
oledText, oledSecondaryText, oledElevated, oledSurface
```
**Good**: Prefix groups related colors together

## Proposed Naming Convention

Following Apple HIG and iOS best practices:

### Category 1: Core UI Semantic Colors ✅
**Pattern**: `{purpose}{Layer/Hierarchy}`
- Already in asset catalog: `primaryText`, `secondaryText`, `tertiaryText`
- Already in asset catalog: `appBackground`, `surfaceBackground`, `elevatedBackground`
- **Keep as-is**: These follow Apple conventions

### Category 2: Brand/Accent Colors ✅
**Pattern**: `{brandName}{Color}{Variant?}`
- `scholarIndigo`, `scholarIndigoLight`, `scholarIndigoDark`
- `greekBlue`, `theologyGreen`, `connectionAmber`, `personalRose`
- **Keep as-is**: Clear branding, good hierarchy

### Category 3: Theme Mode Colors ✅
**Pattern**: `{themeMode}{Purpose}`
- Light mode: `lightBackground`, `lightSurface`, `lightElevated`
- Dark mode: `darkBackground`, `darkSurface`, `darkElevated`
- Sepia mode: `sepiaBackground`, `sepiaSurface`, `sepiaText`
- OLED mode: `oledText`, `oledSecondaryText`, `oledElevated`
- **Keep as-is**: Follows established pattern

### Category 4: Time/Liturgical Palettes ✅
**Pattern**: `{timePeriod}{ColorDescriptor}`
- Dawn: `dawnLavender`, `dawnPeriwinkle`, `dawnRosePink`
- Meridian: `meridianParchment`, `meridianIllumination`, `meridianVermillion`
- Afternoon: `afternoonIvory`, `afternoonCream`, `afternoonHoney`
- Vespers: `vespersIndigo`, `vespersAmber`, `vespersSky`
- **Keep as-is**: Well-organized, poetic names fit liturgical context

### Category 5: Material Palette (Base Colors) ⚠️ CONSIDER RENAMING
**Current**: Poetic but inconsistent
```swift
divineGold → scholarGold? (to match scholarIndigo pattern)
illuminatedGold → goldHighlight?
burnishedGold → goldAccent?
ancientGold → goldDark?

candlelitStone → stoneVeryDark?
chapelShadow → stoneDark?
monasteryStone → stoneLight?

moonlitParchment → parchmentLight?
agedParchment → parchmentMedium?
freshVellum → parchmentFresh?
```

**Question**: Should we keep poetic names or standardize to descriptive?

### Category 6: Jewel Tones ✅
**Pattern**: `{jewelName}Jewel` or `{jewelName}`
- Current: `vermillionJewel`, `lapisLazuliJewel`, `malachiteJewel`, `amethystJewel`
- Also in asset catalog: `Amethyst`, `LapisLazuli`, `Malachite`, `Vermillion`
- **Keep as-is**: Beautiful, historically accurate, consistent

### Category 7: Feature-Specific Colors ✅
**Pattern**: `{featureName}{Purpose}`
- Showcase: `showcaseBackground`, `showcaseSurface`, `showcaseCard`
- Threshold: `thresholdGold`, `thresholdIndigo`, `thresholdPurple`
- **Keep as-is**: Clear feature association

## Decision Points

### Option A: Keep Poetic Names (Current)
**Pros**:
- Beautiful, aligns with app's spiritual/scholarly theme
- Names like `divineGold`, `candlelitStone`, `moonlitParchment` evoke the right feeling
- Already established in codebase

**Cons**:
- Less clear what each color is used for
- Harder for new developers to understand
- Doesn't follow Apple HIG conventions

### Option B: Standardize to Descriptive Names
**Pros**:
- Clear, predictable naming
- Follows iOS best practices
- Easier to maintain

**Cons**:
- Loses the beautiful, evocative quality
- `goldDark` is less inspiring than `ancientGold`
- May feel generic for a spiritual app

### Option C: Hybrid Approach (Recommended)
**Keep poetic names but add clarity through:**
1. **Better organization** (MARK comments)
2. **Doc comments** explaining purpose
3. **Consistent patterns within families**

Example:
```swift
// MARK: - Gold Palette (Brand Accent Family)
/// Divine Gold - Primary brand gold, hero elements
static let divineGold = Color(hex: "D4A853")

/// Burnished Gold - Pressed/active state
static let burnishedGold = Color(hex: "C9943D")

/// Illuminated Gold - Highlights, hover state
static let illuminatedGold = Color(hex: "E8C978")

/// Ancient Gold - Dark variant for dark mode
static let ancientGold = Color(hex: "8B6914")
```

## Recommendations

### High Priority
1. ✅ Keep semantic colors in asset catalog (primaryText, surfaceBackground, etc.)
2. ✅ Keep theme mode patterns (lightBackground, darkBackground, sepiaText, etc.)
3. ✅ Keep liturgical time palettes with current poetic names
4. ⚠️ Add comprehensive doc comments to ALL colors explaining their purpose

### Medium Priority
5. Consider: Should gold family align with scholar naming?
   - Option A: Rename `divineGold` → `scholarGold` (consistency with scholarIndigo)
   - Option B: Keep `divineGold` but document as "Scholar brand gold"

6. Consider: Material colors (stone/parchment families)
   - Option A: Keep poetic names (candlelitStone, moonlitParchment)
   - Option B: Standardize to descriptive (stoneDark, parchmentLight)

### Low Priority
7. Audit for unused colors - remove dead code
8. Group related colors with better MARK comments

## Questions for Decision

1. **Gold family**: Should we rename to match `scholarIndigo` pattern, or keep `divineGold`?
2. **Material palette**: Keep poetic names or standardize to descriptive?
3. **Doc comments**: Should every color have a /// comment explaining its use case?

## Next Steps

1. User decides on naming philosophy (Option A, B, or C)
2. Apply chosen pattern consistently
3. Add doc comments to all colors
4. Update any references if names change
