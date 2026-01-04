# SanctuaryTheme vs AppTheme Analysis

**Date**: January 3, 2026
**Issue**: Major duplication between SanctuaryTheme.swift and AppTheme.swift

## Current Usage

**SanctuaryTheme.swift** (in `/Core/Theme/`)
- Used by: 18 files in Features/Home
- Used by: 4 files in DevTools/Showcases
- **Problem**: Located in Core but only used by one feature + dev tools

**AppTheme.swift** (in `/UI/Theme/`)
- Used by: Entire app (Read, Ask, Prayer, Scholar, etc.)
- **Status**: Main theme system

## Duplication Analysis

### Identical Properties ⚠️

Both have the same values for:
- `Spacing.xxs` through `Spacing.xxxl` (100% match)
- `CornerRadius.xs, small, card, large, sheet` (100% match)
- `Animation.quick, standard, reverent, luminous, contemplative, sacredSpring, unfurl, shimmer, pulse` (100% match)
- `Opacity.subtle, light, quarter, medium, half, strong, high` (~90% match)
- `Shadow.subtle, small, medium, large, dramatic` (~90% match)

### Unique to SanctuaryTheme

**Spacing:**
- `huge: 64` (AppTheme only goes to `xxxl: 48`)

**CornerRadius:**
- `pill: 100` (AppTheme doesn't have this)

**Animation:**
- `cinematic` (AppTheme doesn't have this exact one)
- `float` (for chat pill)
- `gradientRotation` (linear 8s)

**Component Sizes (entirely unique):**
```swift
enum Size {
    static let cardMinHeight: CGFloat = 120
    static let cardMaxWidth: CGFloat = 400
    static let heroHeight: CGFloat = 380
    static let metricPillHeight: CGFloat = 72
    static let touchTarget: CGFloat = 44
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 24
    static let iconLarge: CGFloat = 32
    static let streakBadgeWidth: CGFloat = 60
}
```

**View Modifiers (unique):**
- `staggeredEntrance(index:isVisible:delay:)`
- `pressEffect(isPressed:)`
- `glassCard()`
- `accessibleAnimation(_:value:)`

**Haptics (entirely unique):**
- `HomeShowcaseHaptics` enum with sanctuary-specific haptics

### Unique to AppTheme

**Many more properties:**
- Border widths
- Blur radii
- Component sizes (button, icon, indicator, etc.)
- Opacity values
- Scale effects
- More animation curves
- Shadow styles (structured)
- Menu theme

## Professional Assessment

### Current State: 🔴 **Anti-Pattern**

This is a **code duplication anti-pattern**:
1. Two theme systems with 90% overlap
2. Confusing which to use
3. Maintenance burden (update both)
4. Values can drift apart
5. No clear ownership

### Root Cause

SanctuaryTheme was likely created for early Home page prototyping before AppTheme matured. It was never cleaned up after AppTheme became the standard.

## Recommended Solution

### Option A: **Delete SanctuaryTheme** ✅ (Recommended)

**Approach:**
1. Add missing values to AppTheme:
   - `Spacing.huge`
   - `CornerRadius.pill`
   - `Animation.cinematic`, `float`, `gradientRotation`
   - Move `Size` enum to AppTheme
2. Migrate all 18 Home files to use AppTheme
3. Delete SanctuaryTheme.swift
4. Keep SanctuaryTypography.swift (typography is feature-specific, that's valid)

**Pros:**
- ✅ Single source of truth
- ✅ Less confusion
- ✅ Easier maintenance
- ✅ AppTheme becomes comprehensive

**Cons:**
- ⚠️ Need to update 18 files
- ⚠️ 30 minutes of work

### Option B: Keep as Feature-Specific Theme

**Approach:**
1. Move to `Features/Home/Theme/SanctuaryTheme.swift`
2. Remove all duplicates, keep only unique values
3. Make it extend/reference AppTheme for common values

**Pros:**
- ✅ Feature isolation
- ✅ Less file changes

**Cons:**
- ❌ Still have two theme systems
- ❌ Confusing architecture
- ❌ Easy to re-duplicate values

### Option C: Do Nothing

**Approach:** Leave it as-is

**Pros:**
- ✅ No work required

**Cons:**
- ❌ Technical debt remains
- ❌ Confusing for developers
- ❌ Maintenance burden
- ❌ Not professional

## Recommendation

**Go with Option A: Delete SanctuaryTheme and consolidate to AppTheme**

This follows iOS best practices:
- Single theme system (like Apple's design tokens)
- Clear ownership
- Easy to find values
- Feature-specific values (like Home page sizes) are OK in the main theme

**Migration Plan:**
1. Add missing values to AppTheme (5 minutes)
2. Find/replace `SanctuaryTheme` → `AppTheme` in 18 files (15 minutes)
3. Test build (5 minutes)
4. Delete SanctuaryTheme.swift
5. Keep SanctuaryTypography.swift (typography is legitimately feature-specific)

**Total effort:** ~30 minutes
**Benefit:** Eliminated major technical debt, cleaner architecture

## What About SanctuaryTypography?

**Keep it!** Typography is feature-specific and valid:
- Contains custom fonts (Cinzel, CormorantGaramond)
- Home-specific type scales (Minimalist, Dashboard, Narrative, Candlelit, Scholar, Threshold)
- Text style modifiers unique to Home variants

Typography being feature-specific is a legitimate pattern (like UIKit's Dynamic Type per-feature).

## Next Steps

If you approve Option A, I can:
1. Execute the migration
2. Delete SanctuaryTheme.swift
3. Verify build succeeds
4. Document the consolidation
