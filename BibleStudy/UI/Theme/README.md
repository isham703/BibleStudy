# BibleStudy Design System

Centralized design tokens for consistent UI across the app. All values are enforced by SwiftLint custom rules.

## Quick Reference

### Spacing (`AppTheme.Spacing.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.xxs` | 2pt | Micro gaps, tight layouts |
| `.xs` | 4pt | Icon gaps, inline spacing |
| `.sm` | 8pt | Component internal padding |
| `.md` | 12pt | Default spacing |
| `.lg` | 16pt | Section spacing |
| `.xl` | 24pt | Major sections |
| `.xxl` | 32pt | Screen margins |
| `.xxxl` | 48pt | Hero spacing |

### Corner Radius (`AppTheme.CornerRadius.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.small` / `.sm` | 4pt | Chips, small badges |
| `.medium` / `.md` | 8pt | Buttons, inputs |
| `.large` / `.lg` | 12pt | Cards |
| `.xl` | 16pt | Large cards |
| `.card` | 12pt | Standard cards |
| `.sheet` | 20pt | Bottom sheets |

### Typography

**Display Text** (`Typography.Display.*`) — Serif headlines for premium feel
| Token | Size | Weight | Design | Use Case |
|-------|------|--------|--------|----------|
| `.largeTitle` | 34pt | Medium | Serif | Hero headlines |
| `.title1` | 28pt | Medium | Serif | Onboarding titles |
| `.title2` | 22pt | Medium | Serif | Feature headers |
| `.title3` | 20pt | Medium | Serif | Card titles |
| `.headline` | 17pt | Semibold | Serif | Section headers |

**UI Text** (`Typography.UI.*`)
- `.largeTitle` - Screen titles
- `.title1`, `.title2`, `.title3` - Section headers
- `.headline` - Emphasized text
- `.body` - Default reading text
- `.callout` - Secondary content
- `.subheadline` - Supporting text
- `.footnote` - Small annotations
- `.caption1`, `.caption2` - Labels, metadata
- `.buttonLabel` - Button text (Rounded design)
- `.chipLabel` - Chip/tag text (Rounded design)
- `.tabLabel` - Tab bar labels (Rounded design)

**Warm Variants** (`Typography.UI.*`) — Rounded design for welcoming contexts
| Token | Size | Weight | Use Case |
|-------|------|--------|----------|
| `.warmBody` | 17pt | Regular | Welcoming messages, onboarding subtitles |
| `.warmHeadline` | 17pt | Semibold | Friendly section headers |
| `.warmSubheadline` | 15pt | Regular | Supportive text, empty states |

**Scripture Text** (`Typography.Scripture.*`)
- `.body` - Verse text
- `.title` - Book/chapter titles
- `.verseNumber` - Verse numbers
- `.chapterNumber` - Chapter numbers
- `.quote` - Block quotes

### Animation (`AppTheme.Animation.*`)

| Token | Description |
|-------|-------------|
| `.quick` | 0.15s ease - micro interactions |
| `.standard` | 0.25s ease - default |
| `.slow` | 0.4s ease - emphasis |
| `.spring` | Spring animation - bouncy |
| `.celebrationBounce` | Bouncy celebration |
| `.celebrationSettle` | Settle after bounce |

**Reduced Motion Support:**
```swift
// Skip animation when Reduce Motion enabled
.animation(AppTheme.Animation.reduced(.spring), value: state)

// Use subtle fade as fallback
.animation(AppTheme.Animation.accessible(.spring), value: state)

// View extension
.reducedMotionAnimation(.spring, value: state)
.accessibleAnimation(.spring, value: state)
```

### Opacity (`AppTheme.Opacity.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.faint` | 0.08 | Very subtle backgrounds |
| `.subtle` | 0.1 | Subtle backgrounds |
| `.light` | 0.15 | Light highlights |
| `.lightMedium` | 0.2 | Light to medium |
| `.medium` | 0.3 | Standard opacity |
| `.disabled` | 0.4 | Disabled states |
| `.heavy` | 0.5 | Emphasized |
| `.strong` | 0.6 | Strong visibility |
| `.overlay` | 0.7 | Overlays |
| `.pressed` | 0.8 | Pressed states |
| `.high` | 0.9 | Very visible |
| `.nearOpaque` | 0.95 | Almost fully visible |

### Scale (`AppTheme.Scale.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.small` | 0.7 | Smaller scale |
| `.reduced` | 0.8 | Reduced size |
| `.pressed` | 0.95 | Button pressed |
| `.subtle` | 0.98 | Subtle pressed |
| `.enlarged` | 1.2 | Slightly enlarged |
| `.pulse` | 1.5 | Pulse animation max |

### Shadows (`AppTheme.Shadow.*`)

| Token | Use Case |
|-------|----------|
| `.small` | Subtle elevation |
| `.medium` | Cards, elevated surfaces |
| `.large` | Modals, prominent elements |

```swift
// Using shadow extension
.shadow(AppTheme.Shadow.medium)
```

### Icon Sizes (`AppTheme.IconSize.*`)

| Token | Value |
|-------|-------|
| `.small` | 16pt |
| `.medium` | 20pt |
| `.large` | 24pt |
| `.xl` | 32pt |
| `.xxl` | 48pt |
| `.celebration` | 36pt |

### Icon Containers (`AppTheme.IconContainer.*`)

| Token | Value |
|-------|-------|
| `.small` | 24pt |
| `.medium` | 32pt |
| `.large` | 44pt |
| `.xl` | 56pt |

### Border (`AppTheme.Border.*`)

| Token | Value |
|-------|-------|
| `.hairline` | 0.5pt |
| `.thin` | 1pt |
| `.medium` | 1.5pt |
| `.regular` | 2pt |
| `.thick` | 3pt |
| `.heavy` | 4pt |

### Touch Targets (`AppTheme.TouchTarget.*`)

| Token | Value |
|-------|-------|
| `.minimum` | 44pt (Apple HIG) |
| `.comfortable` | 48pt |
| `.large` | 56pt |

### Component Sizes (`AppTheme.ComponentSize.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.dot` | 4pt | Tiny dots |
| `.dotSmall` | 6pt | Small dots |
| `.indicator` | 8pt | Status indicators |
| `.badge` | 20pt | Small badges |
| `.icon` | 24pt | Standard icons |
| `.avatar` | 40pt | User avatars |
| `.thumbnail` | 64pt | Thumbnails |
| `.preview` | 120pt | Preview cards |

### Colors

Use semantic colors from `Colors.swift`:

**Text:** `Color.primaryText`, `.secondaryText`, `.tertiaryText`

**Backgrounds:** `Color.appBackground`, `.surfaceBackground`, `.elevatedBackground`

**Accents:** `Color.accentGold`, `.accentBlue`, `.accentRose`

**Highlights:** `Color.highlightBlue`, `.highlightGold`, `.highlightGreen`, `.highlightPurple`, `.highlightRose`

**Status:** `Color.success`, `.warning`, `.error`, `.info`

## Escape Hatch

If you must use a hardcoded value:
```swift
// swiftlint:disable:next hardcoded_padding_single
// Reason: Pixel-perfect alignment for external component
.padding(13)
```
