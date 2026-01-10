# BibleStudy Home Tab: System Documentation

> **Purpose**: This document provides a comprehensive technical and UX assessment of the Home tab ("Sanctuary") feature in the BibleStudy iOS app. It serves as foundational documentation for future AI-assisted development and expansion of this feature.

---

## Executive Summary

The Home tab is branded as the **"Sanctuary"** — a time-aware spiritual experience that transforms throughout the day according to the **Liturgy of the Hours** (canonical hours). The interface automatically adapts its visual design, content, and animations to match five distinct liturgical periods: Dawn (Lauds), Meridian (Terce), Afternoon (Sext), Vespers, and Compline.

### Key Characteristics
- **Time-Aware Design**: UI automatically transforms based on current time
- **Liturgical Framework**: Based on traditional monastic prayer hours
- **Feature Gateway**: Primary navigation hub to app experiences
- **Personalized**: Displays user name, streak, and daily verse
- **Accessible**: Respects reduce motion and background state

---

## 1. Architecture Overview

### 1.1 View Hierarchy

```
MainTabView
└── SanctuaryHomeView (Tab Entry Point)
    ├── @State viewModel: SanctuaryViewModel
    ├── NavigationStack
    │   └── TimeAwareSanctuaryPage (Router)
    │       └── Conditional View Selection
    │           ├── DawnSanctuaryView      (5am-9am)
    │           ├── MeridianSanctuaryView  (9am-12pm)
    │           ├── AfternoonSanctuaryView (12pm-5pm)
    │           ├── VespersSanctuaryView   (5pm-9pm)
    │           └── ComplineSanctuaryView  (9pm-5am)
    ├── FloatingSanctuarySettings (fullScreenCover)
    └── TimePickerSheet (DEBUG only)
```

### 1.2 File Structure

```
Features/Home/
├── SanctuaryHomeView.swift          # Main tab entry point
├── SanctuaryEnvironment.swift       # Environment key for settings action
│
├── ViewModels/
│   └── SanctuaryViewModel.swift     # Centralized state management
│
├── Models/
│   ├── SanctuaryTimeOfDay.swift     # Core temporal model (5 liturgical hours)
│   ├── AIFeature.swift              # Navigation enum for experiences
│   ├── CardStyle.swift              # Card styling configuration
│   └── SanctuaryMockData.swift      # Mock data for previews
│
├── Views/
│   ├── TimeAware/
│   │   ├── TimeAwareSanctuaryPage.swift    # Router component
│   │   ├── DawnSanctuaryView.swift
│   │   ├── MeridianSanctuaryView.swift
│   │   ├── AfternoonSanctuaryView.swift
│   │   ├── VespersSanctuaryView.swift
│   │   └── ComplineSanctuaryView.swift
│   └── Alternatives/                # Legacy/showcase variants
│       ├── CandlelitSanctuaryPage.swift
│       └── ScholarsAtriumPage.swift
│
└── Components/
    ├── Cards/
    │   ├── HomeFeatureCard.swift    # Primary navigation card
    │   ├── CardStyle.swift          # Time-aware styling
    │   ├── DailyVerseCard.swift
    │   ├── AIInsightCard.swift
    │   ├── PracticeCard.swift
    │   ├── ReadingPlanCard.swift
    │   └── StreakBadge.swift
    │
    ├── Sections/
    │   ├── SanctuaryHeaderSection.swift   # Greeting + settings + streak
    │   └── SanctuaryVerseSection.swift    # Daily verse display
    │
    ├── Decorative/
    │   └── SanctuaryDivider.swift   # Time-aware separators
    │
    └── TimeOfDay/
        ├── DawnGlowBackground.swift
        ├── MeridianBackground.swift
        ├── AfternoonWindowBackground.swift
        ├── VespersBackground.swift
        └── (Starfield for Compline)
```

---

## 2. Core Concepts

### 2.1 The "Sanctuary" Concept

The Sanctuary is designed as a **sacred digital space** that reflects the ancient monastic tradition of praying at fixed hours throughout the day. Each time period creates a unique spiritual atmosphere:

| Period | Time Range | Liturgical Name | Spiritual Theme | Visual Aesthetic |
|--------|------------|-----------------|-----------------|------------------|
| **Dawn** | 5am - 9am | Lauds | Hope, awakening, praise | Aurora, cool lavender to warm coral |
| **Meridian** | 9am - 12pm | Terce | Clarity, focus, study | Illuminated scriptorium, golden light |
| **Afternoon** | 12pm - 5pm | Sext/None | Stillness, contemplation | Quiet library, soft amber |
| **Vespers** | 5pm - 9pm | Vespers | Gratitude, reflection | Twilight, emerging stars |
| **Compline** | 9pm - 5am | Compline | Rest, sacred silence | Candlelit night, starfield |

### 2.2 Time Detection

Time detection is automatic via `SanctuaryTimeOfDay.current`:

```swift
enum SanctuaryTimeOfDay: String, CaseIterable {
    case dawn, meridian, afternoon, vespers, compline

    static var current: SanctuaryTimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<9:   return .dawn
        case 9..<12:  return .meridian
        case 12..<17: return .afternoon
        case 17..<21: return .vespers
        default:      return .compline
        }
    }
}
```

The ViewModel updates every 60 seconds and animates transitions between periods.

---

## 3. State Management

### 3.1 SanctuaryViewModel

The central state container using iOS 17+ `@Observable` pattern:

```swift
@Observable
@MainActor
final class SanctuaryViewModel {
    // Time State
    var currentTime: SanctuaryTimeOfDay = .current
    var manualOverride: SanctuaryTimeOfDay?  // For testing
    var activeTime: SanctuaryTimeOfDay { manualOverride ?? currentTime }

    // User Data (from services)
    var userName: String?
    var currentStreak: Int

    // Lifecycle
    var scenePhase: ScenePhase = .active
    var reduceMotion: Bool = false
    var shouldAnimate: Bool { scenePhase == .active && !reduceMotion }

    // Dependencies
    private let progressService: ProgressService
    private let authService: AuthService
}
```

### 3.2 Data Flow

```
Services (AuthService, ProgressService)
    ↓
SanctuaryViewModel (loads user data, manages time)
    ↓
SanctuaryHomeView (@State owner)
    ↓
TimeAwareSanctuaryPage (routes to time-specific view)
    ↓
[Dawn|Meridian|Afternoon|Vespers|Compline]SanctuaryView
    ↓
Shared Components (Header, Verse, Cards)
```

### 3.3 Environment Integration

Settings action is passed via custom environment key:

```swift
extension EnvironmentValues {
    var settingsAction: () -> Void { ... }
}

// Usage in child views
@Environment(\.settingsAction) private var openSettings
```

---

## 4. User Interface Layout

### 4.1 Standard Page Structure

Each time-aware sanctuary view follows this layout:

```
┌─────────────────────────────────────────┐
│  SanctuaryHeaderSection                 │
│  [Greeting Text]     [Settings] [Streak]│
├─────────────────────────────────────────┤
│                                         │
│  SanctuaryVerseSection                  │
│  ─────── ☀ ───────                      │
│                                         │
│  "This is the day the Lord has made;    │
│   let us rejoice and be glad in it."    │
│                                         │
│           — Psalm 118:24                │
│  ─────── ☀ ───────                      │
│                                         │
├─────────────────────────────────────────┤
│  Primary CTA Card (Full Width)          │
│  ┌─────────────────────────────────────┐│
│  │  🙏 Prayers from the Deep           ││
│  │     Enter the sacred conversation   ││
│  └─────────────────────────────────────┘│
│                                         │
├─────────────────────────────────────────┤
│  Feature Grid (2x2)                     │
│  ┌─────────────┐  ┌─────────────┐       │
│  │  Feature 1  │  │  Feature 2  │       │
│  └─────────────┘  └─────────────┘       │
│  ┌─────────────┐  ┌─────────────┐       │
│  │  Feature 3  │  │  Feature 4  │       │
│  └─────────────┘  └─────────────┘       │
│                                         │
└─────────────────────────────────────────┘
```

### 4.2 Time-Specific Variations

**Afternoon**: Replaces standard verse section with a "Selah" breathing section featuring an animated breathing circle.

**Vespers**: Adds a "Compline hint" footer with "As night approaches..." and moon/stars iconography.

**Compline**: Adds a floating CandleFlame component at the bottom of the screen.

---

## 5. Component Details

### 5.1 SanctuaryHeaderSection

**Purpose**: Top navigation bar with personalized greeting

**Contents**:
- Time-aware greeting ("Good morning", "Good afternoon", "Good evening")
- User's name (if available)
- Settings gear button
- Streak badge with flame icon

**Time-Aware Styling**:
| Period | Font | Weight | Animation Direction |
|--------|------|--------|---------------------|
| Dawn | CormorantGaramond | Regular | Upward (-10) |
| Meridian | CormorantGaramond | Regular | Horizontal (-15) |
| Afternoon | CormorantGaramond | Regular | Downward (+10) |
| Vespers | CormorantGaramond | Light | Downward (+8) |
| Compline | CormorantGaramond | Light (15pt) | Downward (+8) |

### 5.2 SanctuaryVerseSection

**Purpose**: Display daily verse with decorative framing

**Contents**:
- Top decorative divider (time-specific design)
- Optional decorative icon (Vespers shows incense flame)
- Verse text (CormorantGaramond-Italic, 24-26pt)
- Reference (Cinzel-Regular, 11pt, 4pt letter spacing)
- Bottom decorative divider

**Default Verses by Time**:
- Dawn: Psalm 118:24 (rejoicing)
- Meridian: John 8:12 (light of the world)
- Afternoon: Psalm 46:10 (be still)
- Vespers: Psalm 141:2 (prayer as incense)
- Compline: Psalm 119:105 (lamp to feet)

### 5.3 HomeFeatureCard

**Purpose**: Primary navigation component to app experiences

**Features**:
- Two initializers: AIFeature-based or custom action
- Time-aware styling via CardStyle factory
- Press animations (scale 0.98, brightness adjustment)
- Gradient border overlays
- Haptic feedback (varies by time)

**Card Variants**:
- `isPrimary: true` - Full-width, larger, emphasized
- `isPrimary: false` - Grid item, smaller, secondary

### 5.4 SanctuaryDivider

**Time-Specific Designs**:
- **Dawn**: Aurora gradient lines with sun.max icon
- **Meridian**: Gilded gradient with sun icon (golden)
- **Afternoon**: Simple leaf-centered divider
- **Vespers**: Sparkle-centered with amber lines
- **Compline**: Ornamental manuscript style in candleAmber

### 5.5 Background Components

Each time period has a unique animated background:

| Component | Key Elements |
|-----------|--------------|
| **DawnGlowBackground** | Aurora gradient, horizon glow, soft light rays, rising sun orb, mist wisps, floating particles |
| **MeridianBackground** | Parchment texture, golden diagonal light beams, ambient sun glow, sparkle motes, gilded frame corners |
| **AfternoonWindowBackground** | Paper texture, 3 diagonal light beams (opposite direction), dust motes drifting |
| **VespersBackground** | Sunset gradient, setting sun, sparse starfield (8-12 stars), twilight particles |
| **Compline (Starfield)** | Deep void, full starfield, candle glow, minimal visibility |

---

## 6. Features & Navigation

### 6.1 AIFeature Enum

Defines all navigable experiences from the Home tab:

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
}
```

### 6.2 Time-Based Feature Surfacing

Different features are emphasized at different times:

| Time | Primary CTA | Grid Features |
|------|-------------|---------------|
| Dawn | Prayers from the Deep | PrayersFromDeep, MemoryPalace, ScriptureFindsYou, TheApprentice |
| Meridian | The Apprentice | ScriptureFindsYou, TheApprentice, PrayersFromDeep, MemoryPalace |
| Afternoon | Prayers from the Deep | Similar to Dawn |
| Vespers | Compline | PrayersFromDeep, Compline, Breathe, MemoryPalace |
| Compline | Compline | Compline, Breathe, PrayersFromDeep, MemoryPalace |

### 6.3 Currently Implemented Features

Based on navigation destinations:
- ✅ Prayers from the Deep
- ✅ Compline
- ✅ Breathe
- ⏳ Others show placeholder views

---

## 7. Animation System

### 7.1 Animation Direction by Time

```swift
enum AnimationDirection {
    case upward    // Dawn - rising, hopeful
    case horizontal // Meridian - precise, scholarly
    case settling  // Afternoon - calm, grounding
    case downward  // Vespers - winding down
    case breathing // Compline - very slow, meditative
}
```

### 7.2 Animation Speed

| Speed | Duration | Breathing Duration |
|-------|----------|-------------------|
| quick | 0.3s | - |
| medium | 0.5s | 2.0s |
| mediumSlow | 0.7s | 3.0s |
| slow | 1.0s | 4.0s |
| verySlow | 1.5s | 5.0s |

### 7.3 Entry Animation Pattern

All sanctuary views use staggered entry animations:

```swift
// Typical animation cascade
Header:     delay 0.2s, offset varies by time direction
Settings:   delay 0.3s
Streak:     delay 0.4s
Divider:    delay 0.4s
Verse:      delay 0.6s
Primary:    delay 0.8s-1.0s
Grid cards: delay 1.2s-1.7s (sequential)
```

### 7.4 Accessibility

- Respects `accessibilityReduceMotion`
- Disables particle effects when motion reduced
- Pauses animations when app backgrounded

---

## 8. Color System

### 8.1 Light Mode (Dawn, Meridian, Afternoon)

| Property | Dawn | Meridian | Afternoon |
|----------|------|----------|-----------|
| Background | dawnSkyGradient | meridianBackgroundGradient | afternoonBaseGradient |
| Card BG | frost + material | linen + material | ivory + material |
| Text | dawnSlate | sepia | espresso |
| Accent | dawnAccent (lavender) | meridianGilded (gold) | afternoonAmber |

### 8.2 Dark Mode (Vespers, Compline)

| Property | Vespers | Compline |
|----------|---------|----------|
| Background | vespersSunsetGradient | nightVoid + starfield |
| Card BG | white @ 5-6% opacity | white @ 5% opacity |
| Text | vespersText | starlight (pale) |
| Accent | vespersAmber | candleAmber |

### 8.3 Streak Badge Colors

| Days | Color |
|------|-------|
| 0-6 | Orange |
| 7-29 | divineGold |
| 30-99 | illuminatedGold |
| 100+ | goldLeafShimmer |

---

## 9. User Interactions

### 9.1 Primary Interactions

1. **Tap Feature Card** → Navigate to experience
2. **Tap Settings Gear** → Open settings sheet
3. **Tap Streak Badge** → (Currently visual only)
4. **Scroll** → Browse full page content

### 9.2 Haptic Feedback

| Time Period | Haptic Style |
|-------------|--------------|
| Dawn/Meridian/Afternoon | Rigid (sharp, scholarly) |
| Vespers | Soft (gentle) |
| Compline | Light (minimal, peaceful) |

### 9.3 Press States

Cards respond to touch with:
- Scale: 1.0 → 0.98
- Brightness: Varies by time (0.95-1.0)
- Shadow: Reduced on press

---

## 10. Technical Implementation Notes

### 10.1 Memory Management

- Task-based timer (no Timer memory leaks)
- Proper cancellation in `cleanup()`
- Scene phase awareness stops animations when backgrounded

### 10.2 Performance Considerations

- Background particle systems disabled when `reduceMotion` enabled
- View identity via `.id(viewModel.activeTime)` forces clean recreation on time change
- Transitions use opacity + scale for smooth performance

### 10.3 Debug Features

In DEBUG builds only:
- Time picker overlay showing current period
- Lock icon indicates manual override
- Sheet to select any time period for testing

---

## 11. Key Design Decisions

1. **Liturgical Hours Framework**: Provides theological depth and daily rhythm
2. **Automatic Time Detection**: Zero-configuration user experience
3. **Shared Components**: Header and verse sections reused across all variants
4. **Factory Pattern for Styles**: CardStyle.forTime() enables clean time-aware styling
5. **Environment-Based Actions**: Settings action passed via environment, not props
6. **Observable + MainActor**: Modern Swift concurrency for thread safety
7. **Task-Based Timers**: Prevents memory leaks from traditional Timer usage

---

## 12. Future Expansion Considerations

### 12.1 Current Placeholders

The following AIFeature destinations show placeholder views:
- Scripture Finds You
- The Apprentice
- Illuminate
- The Thread
- Memory Palace

### 12.2 Existing Alternative Variants

Located in `Views/Alternatives/`:
- **CandlelitSanctuaryPage**: Unified dark-mode aesthetic
- **ScholarsAtriumPage**: Academic/scholarly aesthetic

These could be offered as user preference options or special modes.

### 12.3 Component Extensibility

- `HomeFeatureCard` supports custom actions beyond AIFeature navigation
- `SanctuaryTimeOfDay` enum easily extended with new properties
- Background components are modular and swappable

---

## Appendix A: File Quick Reference

| File | Purpose |
|------|---------|
| `SanctuaryHomeView.swift` | Tab entry, state owner, lifecycle |
| `TimeAwareSanctuaryPage.swift` | Time-based view router |
| `SanctuaryViewModel.swift` | Centralized state management |
| `SanctuaryTimeOfDay.swift` | Liturgical hours model |
| `AIFeature.swift` | Experience navigation enum |
| `CardStyle.swift` | Time-aware card styling |
| `HomeFeatureCard.swift` | Navigation card component |
| `SanctuaryHeaderSection.swift` | Header with greeting/settings |
| `SanctuaryVerseSection.swift` | Daily verse display |
| `SanctuaryDivider.swift` | Decorative separators |

---

## Appendix B: Color Tokens

Key semantic colors used throughout:
- `dawnAccent`, `dawnSlate`, `dawnSkyGradient`
- `meridianGilded`, `meridianParchment`, `meridianIllumination`
- `afternoonAmber`, `afternoonSage`, `afternoonIvory`
- `vespersAmber`, `vespersText`, `vespersSunsetGradient`
- `candleAmber`, `starlight`, `nightVoid`
- `divineGold`, `illuminatedGold`, `goldLeafShimmer`

---

## 13. Architectural Patterns

### 13.1 Factory Pattern (CardStyle)

The CardStyle struct uses a static factory method to create fully-configured style objects:

```swift
static func forTime(_ time: SanctuaryTimeOfDay, isPrimary: Bool) -> CardStyle {
    switch time {
    case .dawn: return dawnStyle(isPrimary: isPrimary)
    case .meridian: return meridianStyle(isPrimary: isPrimary)
    // ...
    }
}
```

**Benefits**: Eliminates conditional styling logic in views, enables easy testing and style previews.

### 13.2 Composition Over Inheritance

The codebase uses pure struct composition rather than class hierarchies:
- Shared components (Header, Verse, Divider) are injected with time-of-day enum
- Views composed from reusable pieces, not extended from base classes
- Each time-specific view uses the same building blocks with different configuration

### 13.3 Enum-Driven Architecture

`SanctuaryTimeOfDay` serves as the **single source of truth** for all time variation:
- Contains colors, fonts, animations, content, liturgical names
- Single place to add new time periods or modify existing ones
- 359 lines covering all temporal logic

### 13.4 Facade Pattern (ViewModel)

The ViewModel acts as a facade over the service layer:

```swift
var userName: String? {
    authService.userProfile?.displayName
}

var currentStreak: Int {
    progressService.currentStreak
}
```

**Benefits**: Child views don't need direct service dependencies; single source of truth remains in services.

### 13.5 Task-Based Concurrency

Time updates use Swift Concurrency Tasks instead of timers:

```swift
timeUpdateTask = Task { [weak self] in
    while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(60))
        // Update time...
    }
}
```

**Advantages**: Automatic cancellation on view disappear, no memory leaks from strong references.

---

## 14. Design Philosophy

### 14.1 Animation Direction Semantics

Animation directions are spiritually meaningful:
- **Upward** (Dawn): Awakening, rising energy, hope
- **Horizontal** (Meridian): Focused, scholarly, precise scanning
- **Settling** (Afternoon): Contemplation, grounding, rest
- **Downward** (Vespers): Winding down, gentle descent
- **Breathing** (Compline): Deep rest, meditation, very slow pulse

### 14.2 Color Psychology

Colors reinforce spiritual mood:
- **Cool → Warm** (Dawn): Hope emerging from darkness
- **Warm parchment** (Meridian): Scholarly, focused study
- **Neutral cream** (Afternoon): Peaceful, contemplative
- **Twilight indigo** (Vespers): Transition, reflection
- **Deep night** (Compline): Rest, sacred silence

### 14.3 Material Effect Strategy

- **Light modes** (Dawn, Meridian, Afternoon): Use `.ultraThinMaterial` for glassmorphism
- **Dark modes** (Vespers, Compline): Use pure color opacity for candle-glow aesthetic
- Consistent pattern across Header, Cards, Streak badge

### 14.4 Typography Weight Progression

Typography lightens as the day progresses:
- **Dawn/Meridian/Afternoon**: `CormorantGaramond-Regular` at 17pt
- **Vespers**: `CormorantGaramond-Light` at 17pt
- **Compline**: `CormorantGaramond-Light` at 15pt (smallest, most meditative)

---

## 15. Unique Time-Period Elements

### 15.1 Afternoon's Selah Section

The only sanctuary view with a custom middle section:
- Breathing circle animation (5-second cycle)
- "SELAH" typography in Cinzel font with extreme tracking
- "Take a moment. Breathe." prompt
- Replaces standard verse section

### 15.2 Vespers' Compline Hint

Forward-looking transition prompt:
- "As night approaches..." text
- "Compline awaits" with moon.stars icon
- Appears at 2.0s delay
- Creates anticipation for night prayer

### 15.3 Compline's Floating Candle

Bottom-anchored meditative element:
- `CandleFlame()` component with breathing animation (4s cycle)
- Subtle flicker (120ms intervals, ±1.5px horizontal offset)
- Ignores safe area on bottom edge
- 120px content spacing accounts for candle

### 15.4 Dawn's Aurora Particles

Atmospheric particle system:
- Color index based on vertical position
- Cooler at top (lavender), warmer at bottom (peach)
- Upward float with horizontal drift
- 20 particles with randomized properties

---

## 16. Critical Files by Priority

### Tier 1: Core Architecture (Must Read First)

| File | Lines | Purpose |
|------|-------|---------|
| `SanctuaryTimeOfDay.swift` | 359 | Central liturgical hours model |
| `SanctuaryViewModel.swift` | 125 | State management, timer, lifecycle |
| `TimeAwareSanctuaryPage.swift` | 254 | Router, transitions, debug tools |
| `SanctuaryHomeView.swift` | 46 | Tab entry, settings, environment setup |

### Tier 2: Component System (Read for UI Understanding)

| File | Lines | Purpose |
|------|-------|---------|
| `HomeFeatureCard.swift` | ~177 | Primary navigation card component |
| `CardStyle.swift` | 203 | Time-aware styling factory |
| `AIFeature.swift` | 193 | Feature catalog, navigation, time surfacing |
| `SanctuaryHeaderSection.swift` | ~184 | Header with greeting, settings, streak |

### Tier 3: Time-Specific Views (Reference Implementations)

| File | Purpose |
|------|---------|
| `DawnSanctuaryView.swift` | Aurora aesthetic reference |
| `ComplineSanctuaryView.swift` | Most unique (starfield, candle) |
| `AfternoonSanctuaryView.swift` | Selah breathing section |
| `VespersSanctuaryView.swift` | Compline hint footer |

### Tier 4: Visual Polish (Backgrounds & Decorations)

| File | Purpose |
|------|---------|
| `DawnGlowBackground.swift` | Complex aurora with particles |
| `MeridianBackground.swift` | Golden light rays, motes |
| `SanctuaryDivider.swift` | 5 unique divider designs |
| `CandleFlame.swift` | Breathing flame animation |

---

## 17. Data Flow Diagrams

### 17.1 Service to View Flow

```
ProgressService.loadProgress()
    ↓
progress: UserProgress? (observable)
    ↓
SanctuaryViewModel.currentStreak (computed)
    ↓
SanctuaryHeaderSection(currentStreak: viewModel.currentStreak)
```

### 17.2 Time Change Propagation

```
SanctuaryTimeOfDay.current (static var)
    ↓
Task { /* check every 60s */ }
    ↓
SanctuaryViewModel.currentTime (observable)
    ↓
TimeAwareSanctuaryPage.sanctuaryView(for:)
    ↓
.id(viewModel.activeTime) // Forces new view
```

### 17.3 Settings Action Flow

```
SanctuaryHomeView.onSettingsTapped { showSettings = true }
    ↓
.environment(\.settingsAction, action)
    ↓
@Environment(\.settingsAction) in child component
    ↓
Button(action: settingsAction)
```

---

## 18. Code Quality Observations

### 18.1 Strengths

1. **DRY Principle**: Successfully eliminated duplicate implementations across 5 time views
2. **Type Safety**: Enums for styles, times, directions prevent invalid states
3. **Semantic Naming**: Colors like `.dawnAccent`, `.candleAmber` convey meaning
4. **Accessibility First**: Reduce motion support throughout
5. **Proper Lifecycle**: Task cancellation, scene phase awareness
6. **Extensive Previews**: Every component has SwiftUI previews

### 18.2 Architecture Excellence

1. **Spiritual Authenticity**: Liturgical hours reflected in every detail
2. **Progressive Disclosure**: Primary CTA → Grid creates clear hierarchy
3. **Atmospheric Coherence**: Background, cards, dividers all reinforce time mood
4. **Tactile Refinement**: Time-aware haptics enhance spiritual experience

---

*Document generated: January 7, 2026*
*For use in AI-assisted feature expansion*
