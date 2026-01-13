# BibleStudy Design System

Stoic-Existential Renaissance design tokens. All values in `Theme.swift`, `Typography.swift`, and `Colors.swift`.

## Quick Reference

### Spacing (`Theme.Spacing.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.xs` | 6pt | Tight spacing |
| `.sm` | 10pt | Small gaps |
| `.md` | 16pt | Medium gaps (default) |
| `.lg` | 24pt | Large spacing |
| `.xl` | 32pt | Extra large |
| `.xxl` | 48pt | Section spacing |

### Corner Radius (`Theme.Radius.*`)

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

### Stroke (`Theme.Stroke.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.hairline` | 1pt | Subtle dividers, card borders |
| `.control` | 2pt | Control strokes (buttons, inputs) |

### Animation (`Theme.Animation.*`)

Motion is ceremonial, restrained, almost invisible. ALL cubic easing, NO spring animations.

| Token | Duration | Use Case |
|-------|----------|----------|
| `.fade` | 220ms easeInOut | Tab switching, modal appearance |
| `.settle` | 260ms easeOut | Content settling, card reveals |
| `.slowFade` | 420ms easeInOut | "Begin" transitions, ritual moments |
| `.stagger(index:)` | 260ms + delay | Sequential list reveals |

**Banned:** Confetti, fireworks, spring animations, bouncy easing, shimmer gradients.

### Opacity (`Theme.Opacity.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.pressed` | 0.80 | Button press feedback |
| `.disabled` | 0.35 | Disabled controls |
| `.focusStroke` | 0.60 | Focus rings |
| `.selectionBackground` | 0.15 | Verse/text selection |
| `.textPrimary` | 0.96 | Primary body text |
| `.textSecondary` | 0.75 | Supporting text |
| `.textTertiary` | 0.60 | Metadata, captions |
| `.textDisabled` | 0.35 | Disabled text |
| `.divider` | 0.12 | Divider lines, borders |
| `.overlay` | 0.10 | Modal overlays, scrims |
| `.subtle` | 0.05 | Atmospheric backgrounds |
| `.highlight` | 0.40 | Verse highlights |

### Reading Layout (`Theme.Reading.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.maxWidth` | 500pt | Reading container max width (~55 chars) |
| `.horizontalPadding` | 20pt | Reading content margins |
| `.paragraphSpacing` | 12pt | Between paragraphs |
| `.sectionSpacing` | 24pt | Chapter/section breaks |
| `.verseSpacingMeditative` | 20pt | Slow reading mode |

### Size (`Theme.Size.*`)

| Token | Value | Use Case |
|-------|-------|----------|
| `.minTapTarget` | 44pt | Minimum interactive element (Apple HIG) |
| `.iconSize` | 24pt | Standard icon size |
| `.iconSizeLarge` | 32pt | Large icon size |

### Typography

**Philosophy:** "Serif for truth. Sans for command."

**Scripture Tokens** (`Typography.Scripture.*`) — New York serif for contemplation
| Token | Size | Use Case |
|-------|------|----------|
| `.display` | 34pt semibold | Hero titles |
| `.title` | 28pt semibold | Screen titles |
| `.heading` | 22pt semibold | Section headers |
| `.prompt` | 24pt regular | Examination questions |
| `.body` | 17pt regular | Scripture reading |
| `.quote` | 17pt italic | Maxims, quotations |
| `.footnote` | 13pt regular | Footnotes, references |

**Command Tokens** (`Typography.Command.*`) — SF Pro sans for action
| Token | Size | Use Case |
|-------|------|----------|
| `.cta` | 17pt semibold | Primary buttons |
| `.body` | 17pt regular | Short instructions |
| `.label` | 15pt medium | Field labels, chips |
| `.meta` | 13pt medium | Dates, tags, verse numbers |
| `.caption` | 12pt regular | Hints, helper text |
| `.errorTitle` | 15pt semibold | Error titles |
| `.errorBody` | 13pt regular | Error guidance |

**Editorial Tokens** (`Typography.Editorial.*`) — Tracked uppercase
| Token | Size | Tracking | Use Case |
|-------|------|----------|----------|
| `.sectionHeader` | 11pt bold | 2.5px | Section headers |
| `.label` | 10pt bold | 2.0px | Editorial labels |

**Label Tokens** (`Typography.Label.*`) — Uppercase tags
| Token | Size | Tracking | Use Case |
|-------|------|----------|----------|
| `.uppercase` | 12pt medium | 2.2px | Metadata tags, small labels |

**Icon Tokens** (`Typography.Icon.*`) — SF Symbol sizing
| Token | Size | Use Case |
|-------|------|----------|
| `.xs` | 12pt | Tiny indicators |
| `.sm` | 14pt | Small buttons |
| `.md` | 16pt | Standard icons |
| `.lg` | 24pt | Large icons |
| `.xl` | 28pt | Feature icons |
| `.hero` | 40pt | Hero icons |
| `.display` | 76pt | Onboarding |

**Decorative Tokens** (`Typography.Decorative.*`) — Stoic-Roman aesthetic
| Token | Size | Use Case |
|-------|------|----------|
| `.dropCap` | 72pt bold serif | Large decorative first letter |
| `.dropCapCompact` | 52pt bold serif | Compact drop cap |

### Colors

All colors in Asset Catalog with automatic dark/light mode support.

**Backgrounds:** `Color("AppBackground")`, `Color("AppSurface")`, `Color("AppDivider")`

**Text:** `Color("AppTextPrimary")`, `Color("AppTextSecondary")`, `Color("TertiaryText")`

**Accents:** `Color("AppAccentAction")`, `Color("AccentBronze")`

**Feedback:** `Color("FeedbackError")`, `Color("FeedbackWarning")`, `Color("FeedbackSuccess")`, `Color("FeedbackInfo")`

**State Overlays:** `Colors.StateOverlay.pressed(_:)`, `.selection(_:)`, `.focusStroke(_:)`, `.disabled(_:)`

## View Modifiers

Typography helpers for correct-by-default application:

```swift
Text("Title").scriptureHeading()
Text("Begin").commandCTA()
Text("LESSON").uppercaseLabel()
Text(verse.text).readingVerse(size: fontSize, font: fontFamily)
```

## Escape Hatch

If you must use a hardcoded value:
```swift
// swiftlint:disable:next hardcoded_padding_single
// Reason: Pixel-perfect alignment for external component
.padding(13)
```
