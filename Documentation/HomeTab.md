# BibleStudy Home Tab: System Documentation

> **Purpose**: Technical documentation for the Home tab ("Forum") feature in the BibleStudy iOS app.

---

## Executive Summary

The Home tab uses a **Forum** design—a clean, centered layout inspired by Roman public gathering spaces. The interface features a prominent wisdom quote, minimal navigation pillars, and generous whitespace.

### Key Characteristics
- **Simple Time Greeting**: "Good morning/afternoon/evening" based on hour
- **Feature Gateway**: Primary navigation hub to app experiences
- **Personalized**: Displays user name and reading progress
- **Accessible**: Respects reduce motion and background state

---

## 1. Architecture Overview

### 1.1 View Hierarchy

```
MainTabView
└── SanctuaryHomeView (Tab Entry Point)
    ├── @State viewModel: SanctuaryViewModel
    ├── NavigationStack
    │   └── ForumHomeView
    │       ├── backgroundLayer
    │       ├── greetingSection
    │       ├── wisdomQuoteSection (hero)
    │       ├── forumDivider
    │       ├── featurePillars (3 primary)
    │       ├── secondaryFeatures (3 secondary)
    │       └── continueReadingPrompt
    └── SettingsView (fullScreenCover)
```

### 1.2 File Structure

```
Features/Home/
├── SanctuaryHomeView.swift          # Tab entry point
├── SanctuaryEnvironment.swift       # Environment key for settings action
│
├── ViewModels/
│   └── SanctuaryViewModel.swift     # Centralized state management
│
├── Models/
│   ├── AIFeature.swift              # Navigation enum for experiences
│   ├── MockModels.swift             # Mock data types
│   └── SanctuaryMockData.swift      # Mock data for previews
│
├── Views/
│   └── ForumHomeView.swift          # Main home view (Roman Forum design)
│
├── Components/
│   ├── Cards/
│   │   ├── CardStyle.swift          # Card styling configuration
│   │   ├── DailyVerseCard.swift
│   │   ├── AIInsightCard.swift
│   │   ├── PracticeCard.swift
│   │   ├── ReadingPlanCard.swift
│   │   └── StreakBadge.swift
│   │
│   ├── Chat/
│   │   └── ChatEntryButton.swift
│   │
│   ├── Discovery/
│   │   └── DiscoveryCarousel.swift
│   │
│   └── RomanBackground.swift
│
└── Theme/
    └── HomeHaptics.swift
```

---

## 2. Core Concepts

### 2.1 The "Forum" Design

The Forum is a clean, centered layout inspired by Roman public spaces:

| Element | Description |
|---------|-------------|
| **Wisdom Quote** | Central hero section with daily verse |
| **Feature Pillars** | 3 primary navigation buttons (Scripture, Reflect, Pray) |
| **Secondary Row** | 3 secondary features (Sermon, Compline, Breathe) |
| **Continue Reading** | Reading plan progress with CTA |

### 2.2 Time-Based Greeting

Simple greeting based on hour of day (not liturgical):

```swift
let hour = Calendar.current.component(.hour, from: Date())
switch hour {
case 5..<12:  return "Good morning, \(name)"
case 12..<17: return "Good afternoon, \(name)"
case 17..<21: return "Good evening, \(name)"
default:      return "Peace be with you, \(name)"
}
```

---

## 3. State Management

### 3.1 SanctuaryViewModel

Centralized state using iOS 17+ `@Observable` pattern:

```swift
@Observable
@MainActor
final class SanctuaryViewModel {
    // User Data (from services)
    var userName: String? { authService.userProfile?.displayName }
    var currentStreak: Int { progressService.currentStreak }

    // Lifecycle
    var scenePhase: ScenePhase = .active
    var reduceMotion: Bool = false
    var shouldAnimate: Bool { !isPaused }

    // Dependencies
    private let progressService: ProgressService
    private let authService: AuthService
}
```

### 3.2 Data Flow

```
Services (AuthService, ProgressService)
    ↓
SanctuaryViewModel (loads user data)
    ↓
SanctuaryHomeView (@State owner)
    ↓
ForumHomeView (@Environment)
    ↓
Components (Pillars, Cards, Quote)
```

### 3.3 Environment Integration

Settings action passed via custom environment key:

```swift
extension EnvironmentValues {
    var settingsAction: () -> Void { ... }
}

// Usage in child views
@Environment(\.settingsAction) private var openSettings
```

---

## 4. User Interface Layout

### 4.1 ForumHomeView Structure

```
┌─────────────────────────────────────────┐
│  Greeting Section                       │
│  [Date]              [Settings Gear]    │
│  Good morning, Friend                   │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │            "                      │  │
│  │  Your word is a lamp for my       │  │
│  │  feet, a light on my path.        │  │
│  │                                   │  │
│  │        PSALM 119:105              │  │
│  └───────────────────────────────────┘  │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────┐   ┌─────┐   ┌─────┐           │
│  │ 📖  │   │ 💬  │   │ 🙏  │           │
│  │SCRIP│   │REFL │   │PRAY │           │
│  └─────┘   └─────┘   └─────┘           │
│                                         │
│    🎤         🌙         💨            │
│  SERMON   COMPLINE   BREATHE           │
│                                         │
├─────────────────────────────────────────┤
│  CONTINUE YOUR JOURNEY                  │
│  Gospel of John                         │
│  Day 7 of 21                           │
│  ▓▓▓▓▓░░░░░░░░░░                       │
│  [Continue Reading →]                   │
└─────────────────────────────────────────┘
```

### 4.2 Feature Pillars (Primary)

| Pillar | Icon | Destination |
|--------|------|-------------|
| Scripture | `book.fill` | `BibleReaderView()` |
| Reflect | `text.quote` | `AskTabView()` |
| Pray | `hands.sparkles.fill` | `PrayersFromDeepView()` |

### 4.3 Secondary Features

| Feature | Icon | Destination |
|---------|------|-------------|
| Sermon | `mic.fill` | `SermonView()` |
| Compline | `moon.stars.fill` | `ComplineView()` |
| Breathe | `wind` | `BreatheView()` |

---

## 5. Component Details

### 5.1 Wisdom Quote Section (Hero)

Central quote display with decorative styling:
- Opening quotation mark (72pt serif)
- Quote text (28pt serif, centered)
- Reference (uppercase, tracked, AccentBronze)
- Subtle border and background

### 5.2 Forum Divider

Decorative separator with Roman column icon:
```swift
HStack(spacing: Theme.Spacing.lg) {
    Rectangle().fill(Color.appDivider).frame(width: 60, height: 1)
    Image(systemName: "building.columns")
    Rectangle().fill(Color.appDivider).frame(width: 60, height: 1)
}
```

### 5.3 Continue Reading Prompt

Reading plan progress section:
- "CONTINUE YOUR JOURNEY" label
- Plan name (e.g., "Gospel of John")
- Progress text (e.g., "Day 7 of 21")
- Progress bar with AccentBronze fill
- CTA button with capsule shape

---

## 6. Features & Navigation

### 6.1 AIFeature Enum

Defines all navigable experiences:

```swift
enum AIFeature: String, CaseIterable {
    case scriptureFindsYou = "Scripture Finds You"
    case theApprentice = "The Apprentice"
    case illuminate = "Illuminate"
    case theThread = "The Thread"
    case prayersFromDeep = "Prayers From the Deep"
    case memoryPalace = "Memory Palace"
    case compline = "Compline"
    case breathe = "Breathe"
    case sermonRecording = "Sermon Recording"
}
```

### 6.2 Currently Implemented Features

| Feature | Status |
|---------|--------|
| Prayers from the Deep | ✅ Implemented |
| Compline | ✅ Implemented |
| Breathe | ✅ Implemented |
| Sermon Recording | ✅ Implemented |
| Others | ⏳ Placeholder views |

---

## 7. Animation System

### 7.1 Entry Animations

Staggered reveal using `isAwakened` state:

```swift
// Animation cascade
Greeting:         delay 0.1s
Wisdom Quote:     delay 0.2s
Divider:          delay 0.4s
Primary Pillars:  delay 0.5-0.7s
Secondary:        delay 0.75-0.85s
Continue Reading: delay 0.8s
```

### 7.2 Animation Tokens

Uses design system tokens:
- `Theme.Animation.settle` - Initial awakening
- `Theme.Animation.slowFade` - Content reveals with delays

### 7.3 Accessibility

- Respects `accessibilityReduceMotion`
- Pauses animations when app backgrounded
- `shouldAnimate` computed property controls all motion

---

## 8. Color System

Uses design system Asset Catalog colors:

| Element | Color |
|---------|-------|
| Background | `Color.appBackground` |
| Surface | `Color.appSurface` |
| Primary Text | `Color("AppTextPrimary")` |
| Secondary Text | `Color("AppTextSecondary")` |
| Tertiary Text | `Color("TertiaryText")` |
| Accent | `Color("AccentBronze")` |
| Action | `Color("AppAccentAction")` |
| Divider | `Color.appDivider` |

### 8.1 Background Layers

```swift
ZStack {
    Color.appBackground                    // Base
    RadialGradient(AccentBronze, subtle)   // Central glow
    LinearGradient(vignette)               // Top/bottom vignette
}
```

---

## 9. Typography

Uses design system Typography tokens:

| Element | Token |
|---------|-------|
| Date label | `Typography.Command.meta` + tracking |
| Greeting | Serif 24pt regular |
| Quote | Serif 28pt regular |
| Reference | `Typography.Command.caption` + tracking |
| Pillar labels | `Typography.Command.meta` |
| CTA button | `Typography.Command.body` |

---

## 10. Technical Notes

### 10.1 Design System Compliance

The view uses proper design tokens with SwiftLint escape hatches for:
- Custom font sizes (24pt, 28pt, 72pt for quote display)
- Custom tracking values
- Custom frame sizes for decorative elements

### 10.2 Memory Management

- No timer-based updates (Forum is not time-aware)
- Scene phase awareness pauses animations when backgrounded
- Proper async/await for data loading

### 10.3 Performance

- `showsIndicators: false` on ScrollView for clean appearance
- Staggered animations prevent layout thrashing
- Background layers use simple gradients (no particles)

---

## 11. File Quick Reference

| File | Purpose |
|------|---------|
| `SanctuaryHomeView.swift` | Tab entry, state owner, lifecycle |
| `ForumHomeView.swift` | Main view with all sections |
| `SanctuaryViewModel.swift` | Centralized state management |
| `SanctuaryEnvironment.swift` | Settings action environment key |
| `AIFeature.swift` | Feature navigation enum |
| `CardStyle.swift` | Card styling configuration |

---

*Document updated: January 10, 2026*
