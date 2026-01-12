# Design System Enforcement Contract

Rules for working with the BibleStudy design system. Source files: `Theme.swift`, `Typography.swift`, `Colors.swift`.

## Enforcement Summary

| Category | Forbidden | Allowed |
|----------|-----------|---------|
| Colors | `Color(red:)`, `UIColor(red:)` | `Color("AppTextPrimary")`, `Color("AppSurface")` |
| Typography | `.font(.system(size:))`, `.font(.title)` | `Typography.Scripture.*`, `Typography.Command.*` |
| Spacing | Hardcoded `.padding(16)` | `Theme.Spacing.md` |
| Corner Radius | `.cornerRadius(12)` | `Theme.Radius.card` |
| Animation | `.easeInOut(duration: 0.3)` | `Theme.Animation.fade` |
| Opacity | `.opacity(0.5)` | `Theme.Opacity.textSecondary` |

## Detailed Rules

### Colors

**Forbidden:**
```swift
Color(red: 0.5, green: 0.5, blue: 0.5)
Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
UIColor(red: 1.0, green: 0, blue: 0, alpha: 1)
```

**Allowed:**
```swift
Color("AppTextPrimary")
Color("AppSurface")
Color("AppAccentAction")
Color("FeedbackError")
```

### Typography

**Forbidden:**
```swift
.font(.system(size: 14))
.font(.system(size: 16, weight: .bold))
.font(.title)
.font(.headline)
```

**Allowed:**
```swift
.font(Typography.Scripture.body)
.font(Typography.Scripture.heading)
.font(Typography.Command.cta)
.font(Typography.Command.label)

// View modifiers
Text("Title").scriptureHeading()
Text("Begin").commandCTA()
Text("LESSON").uppercaseLabel()
```

### Spacing

**Forbidden:**
```swift
.padding(8)
.padding(16)
.padding(.horizontal, 24)
VStack(spacing: 12) { }
```

**Allowed:**
```swift
.padding(Theme.Spacing.sm)
.padding(.horizontal, Theme.Spacing.lg)
VStack(spacing: Theme.Spacing.md) { }
```

### Corner Radius

**Forbidden:**
```swift
.cornerRadius(8)
.clipShape(RoundedRectangle(cornerRadius: 12))
```

**Allowed:**
```swift
.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))
.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
RoundedRectangle(cornerRadius: Theme.Radius.button)
```

### Animations

**Forbidden:**
```swift
.animation(.easeInOut(duration: 0.3), value: state)
withAnimation(.spring()) { }
```

**Allowed:**
```swift
.animation(Theme.Animation.fade, value: state)
withAnimation(Theme.Animation.settle) { }
withAnimation(Theme.Animation.slowFade) { }
```

**Motion Doctrine:** Ceremonial, restrained, almost invisible. NO spring animations, NO bounce, NO confetti.

### Opacity

**Forbidden:**
```swift
.opacity(0.5)
.opacity(0.8)
```

**Allowed:**
```swift
.opacity(Theme.Opacity.textSecondary)
.opacity(Theme.Opacity.pressed)
.opacity(Theme.Opacity.divider)
```

## Escape Hatch

When you have a legitimate reason to use a hardcoded value:

```swift
// swiftlint:disable:next hardcoded_padding_single
// Reason: Pixel-perfect alignment for third-party component
.padding(13)
```

**Valid reasons:**
- Third-party component integration
- Accessibility edge cases
- Pixel-perfect alignment outside token scale

**Invalid reasons:**
- "It looks better" (add a new token instead)
- "I didn't know about the token" (see README.md)

## Adding New Tokens

1. Check if an existing token works
2. Propose new token in `Theme.swift` or `Typography.swift`
3. Update `README.md`
4. Get design review approval

## Token Reference

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
| Colors | Colors.swift | `Color("AssetName")` |
| State Overlays | Colors.swift | `Colors.StateOverlay.*` |
