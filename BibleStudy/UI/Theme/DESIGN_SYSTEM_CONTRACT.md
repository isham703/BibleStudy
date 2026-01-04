# Design System Enforcement Contract

This document defines what is forbidden, allowed, and how to request exceptions when working with the BibleStudy design system.

## Enforcement Summary

| Category | Forbidden | Allowed | Escape Hatch |
|----------|-----------|---------|--------------|
| Colors | `Color(red:)`, `Color(.sRGB, red:)`, `UIColor(red:)` | `Color.primaryText`, `Color.accentGold`, etc. | `// swiftlint:disable:next` + justification |
| Typography | `.font(.system(size:))`, `.font(.custom(_, size:))`, `.font(.title2)` | `Typography.UI.*`, `Typography.Scripture.*` | Same |
| Spacing | Any hardcoded numeric `.padding()` or `spacing:` | `AppTheme.Spacing.*` | Same |
| Corner Radius | `.cornerRadius(N)`, `RoundedRectangle(cornerRadius: N)` | `AppTheme.CornerRadius.*` | Same |
| Animation | `.easeIn/Out(duration:)`, `.spring(response:)` | `AppTheme.Animation.*` | Same |

## Detailed Rules

### Colors

**Forbidden:**
```swift
// Direct RGB construction
Color(red: 0.5, green: 0.5, blue: 0.5)
Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
Color(white: 0.8)
UIColor(red: 1.0, green: 0, blue: 0, alpha: 1)
```

**Allowed:**
```swift
// Semantic colors from asset catalog
Color.primaryText
Color.secondaryText
Color.accentGold
Color.surfaceBackground
Color.highlightBlue
```

### Typography

**Forbidden:**
```swift
// Hardcoded font sizes
.font(.system(size: 14))
.font(.system(size: 16, weight: .bold))
.font(.custom("CustomFont", size: 18))
Font.system(size: 20)

// SwiftUI built-in text styles
.font(.title)
.font(.title2)
.font(.headline)
.font(.body)
```

**Allowed:**
```swift
// Typography tokens
.font(Typography.UI.body)
.font(Typography.UI.headline)
.font(Typography.UI.title1)
.font(Typography.UI.warmBody)              // Rounded for welcoming contexts
.font(Typography.Display.title1)           // Serif for premium headlines
.font(Typography.Display.headline)         // Serif for section headers
.font(Typography.Scripture.body(size: fontSize))
.font(Typography.Language.hebrew)
```

### Spacing

**Forbidden:**
```swift
// ANY hardcoded numeric value, including micro values
.padding(0)
.padding(2)
.padding(8)
.padding(16)
.padding(.horizontal, 24)
.padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
VStack(spacing: 12) { }
HStack(alignment: .center, spacing: 8) { }
```

**Allowed:**
```swift
// Spacing tokens
.padding(AppTheme.Spacing.sm)
.padding(.horizontal, AppTheme.Spacing.lg)
VStack(spacing: AppTheme.Spacing.md) { }
HStack(alignment: .center, spacing: AppTheme.Spacing.xs) { }
```

### Corner Radius

**Forbidden:**
```swift
// Hardcoded corner radius values
.cornerRadius(8)
.clipShape(RoundedRectangle(cornerRadius: 12))
RoundedRectangle(cornerRadius: 16)
```

**Allowed:**
```swift
// Corner radius tokens
.clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
```

### Animations

**Forbidden:**
```swift
// Hardcoded animation durations
.animation(.easeInOut(duration: 0.3), value: state)
withAnimation(.easeOut(duration: 0.2)) { }
withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { }
Animation.easeIn(duration: 0.15)
```

**Allowed:**
```swift
// Animation tokens
.animation(AppTheme.Animation.standard, value: state)
withAnimation(AppTheme.Animation.quick) { }
withAnimation(AppTheme.Animation.spring) { }
```

## Escape Hatch Pattern

When you have a legitimate reason to use a hardcoded value, use this pattern:

```swift
// swiftlint:disable:next hardcoded_padding_single
// Reason: Pixel-perfect alignment required for third-party component integration
.padding(13)
```

**Valid reasons for exceptions:**
- Third-party component integration with specific requirements
- Accessibility edge cases requiring precise adjustments
- Pixel-perfect alignment that doesn't fit the token scale
- Temporary prototyping (must be converted before merge)

**Invalid reasons:**
- "It looks better this way" (add a new token instead)
- "I didn't know about the token" (see README.md)
- "It's faster" (the lint warning is the point)

## Adding New Tokens

If you need a value that doesn't exist in the token system:

1. Check if an existing token is close enough
2. If not, propose a new token in `AppTheme.swift` or `Typography.swift`
3. Update `README.md` with the new token
4. Get design review approval
5. Use the new token instead of a hardcoded value

## Questions?

- Token reference: See [README.md](README.md)
- SwiftLint config: See `/.swiftlint.yml`
- Design system source: See `AppTheme.swift`, `Typography.swift`, `Colors.swift`
