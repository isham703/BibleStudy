# Compline Feature Assessment

A comprehensive analysis of the Compline (Night Prayer) feature in the BibleStudy iOS app.

---

## 1. What is Compline?

**Compline** is a guided Night Prayer experience based on the ancient **Liturgy of the Hours** tradition—specifically the final prayer service of the day, historically prayed before sleep.

### How to Access

Compline is accessed from the **Home tab** (ForumHomeView) via the secondary features row. Users tap the "Compline" button (moon icon) to launch the guided prayer experience.

### Core Purpose

Help users close their day with:

- Intentional spiritual reflection
- Scripture meditation
- Personal examination of conscience
- Blessing before sleep

### Design Philosophy

> "Deep rest, sacred silence"

The feature embraces a **nocturnal, contemplative, candlelit serenity**—creating an atmosphere conducive to winding down, releasing the day's burdens, and preparing the mind and spirit for restful sleep.

---

## 2. ComplineView (The Guided Prayer Experience)

**File**: `BibleStudy/Features/Experiences/Compline/ComplineView.swift`

The Compline feature is a structured, 6-phase guided prayer journey designed to help users close their day with intentional spiritual practice.

### Access Point

From `ForumHomeView`, users tap the **Compline** secondary feature button to navigate to the ComplineView via NavigationLink.

---

## 3. The Six Phases of Compline

Each phase serves a specific spiritual purpose, guiding the user through a complete night prayer liturgy.

### Phase 1: The Opening

**Purpose**: Center the mind, transition from daily activities to prayerful state.

| Aspect | Detail |
| ------ | ------ |
| Visual | Breathing circle that expands and contracts on 4-second cycle |
| Instruction | "Begin by taking three slow breaths" |
| Interaction | User synchronizes their breathing with the animated circle |
| Prayer Response | "O God, come to my assistance. O Lord, make haste to help me." |
| Icon | `moon.stars.fill` |

**User Experience**: The breathing exercise serves as a physical and mental transition. By focusing on breath, users release the scattered thoughts of the day and prepare their hearts for prayer.

---

### Phase 2: Psalm 91 (Scripture)

**Purpose**: Ground the prayer in scripture about divine protection for the night.

| Aspect | Detail |
| ------ | ------ |
| Visual | Elegant scripture text display with contemplative typography |
| Instruction | "Let these words settle into your heart" |
| Interaction | User reads at their own pace, no time pressure |
| Icon | `book.fill` |

**Scripture Content**:

> You who dwell in the shelter of the Most High,
> who abide in the shadow of the Almighty,
> say to the Lord, "My refuge and fortress,
> my God in whom I trust."
>
> He will shelter you with his pinions,
> and under his wings you may take refuge.

**User Experience**: Psalm 91 is traditionally associated with night prayer because of its themes of protection and refuge. Users meditate on God's sheltering presence as they prepare for sleep.

---

### Phase 3: Examination (Self-Reflection)

**Purpose**: Conscious review of the day, gratitude practice, acknowledgment of struggles.

| Aspect | Detail |
| ------ | ------ |
| Visual | Guiding questions with optional text input area |
| Instruction | "Review your day with gentle honesty" |
| Interaction | Reflect internally; optionally write personal reflections |
| Icon | `eye.fill` |

**Guided Questions**:

1. "Where did you notice God's presence today?"
2. "Where did you resist grace?"
3. "What are you grateful for?"

**Optional Journaling**: Users can tap "Write a reflection" to expand a text input area where they can record their thoughts. This reflection is stored locally during the session.

**User Experience**: This phase invites honest self-examination without harsh judgment. The phrase "gentle honesty" sets the tone—users acknowledge both grace received and grace resisted, cultivating awareness and gratitude.

---

### Phase 4: Confession

**Purpose**: Spiritual cleansing before sleep, release of guilt and burden.

| Aspect | Detail |
| ------ | ------ |
| Visual | Traditional confession text in elegant typography |
| Instruction | "Release what burdens you" |
| Icon | `heart.fill` |

**Confession Text**:

> I confess to almighty God,
> and to you, my brothers and sisters,
> that I have sinned
> through my own fault,
> in my thoughts and in my words,
> in what I have done,
> and in what I have failed to do.

**Prayer Response** (Absolution):

> May almighty God have mercy on you,
> forgive you your sins,
> and bring you to everlasting life.

**User Experience**: This traditional liturgical confession acknowledges wrongdoing in thought, word, action, and omission. The absolution response provides assurance of forgiveness, allowing users to release guilt and rest peacefully.

---

### Phase 5: Nunc Dimittis (The Song of Simeon)

**Purpose**: Traditional night prayer canticle about departing in peace.

| Aspect | Detail |
| ------ | ------ |
| Visual | Canticle text display with contemplative styling |
| Instruction | "The Song of Simeon" |
| Interaction | User reads and meditates |
| Icon | `sparkles` |

**Scripture Content** (Luke 2:29-32):

> Lord, now you let your servant go in peace;
> your word has been fulfilled.
>
> My own eyes have seen the salvation
> which you have prepared
> in the sight of every people:
>
> A light to reveal you to the nations
> and the glory of your people Israel.

**User Experience**: The Nunc Dimittis has been sung at Compline for centuries. Simeon's words upon seeing the Christ child speak of completion, fulfillment, and peaceful departure. At night, these words express trust in God and readiness for rest.

---

### Phase 6: Blessing

**Purpose**: Final blessing and commissioning for restful sleep.

| Aspect | Detail |
| ------ | ------ |
| Visual | Animated flickering candle with warm amber glow |
| Instruction | "Receive this blessing for the night" |
| Button Text | "Amen" (instead of "Continue") |
| Icon | `hands.sparkles.fill` |

**Prayer Response**:

> May the Lord Almighty grant you
> a peaceful night
> and a perfect end.
>
> Amen.

**User Experience**: The candle visualization creates a warm, intimate atmosphere. The blessing is traditional to Compline, invoking both peaceful rest and, in its deeper meaning, a "perfect end"—a good death, the ultimate night's sleep.

---

### Completion Screen

**Purpose**: Celebrate completion and send user to rest with final blessing.

| Aspect | Detail |
| ------ | ------ |
| Visual | Moon surrounded by softly twinkling stars, celestial glow |
| Message | "Rest now in peace" |
| Subtitle | "The prayer of Compline is complete. May you sleep in God's protection." |
| Final Blessing | Numbers 6:24: "May the Lord bless you and keep you" |
| Button | "Good Night" |

**User Experience**: The completion screen provides closure. The celestial imagery (moon and stars) reinforces the nighttime theme. Tapping "Good Night" dismisses the view and returns the user to the app or allows them to close the app for sleep.

---

## 4. User Journey Flow

```
USER OPENS APP (9pm-5am)
        │
        ▼
┌─────────────────────────────────────┐
│     ComplineSanctuaryView (Hub)     │
│                                     │
│  • Starfield night sky background   │
│  • "Good evening, [Name]"           │
│  • Tonight's verse (Psalm 119:105)  │
│  • Primary CTA: Compline card       │
│  • Secondary feature grid           │
│  • Floating candle flame            │
└─────────────────────────────────────┘
        │
        │ User taps "Compline" card
        ▼
┌─────────────────────────────────────┐
│   ComplineView (Full-Screen)        │
│                                     │
│  • Progress dots (6 phases)         │
│  • Current time displayed           │
│  • Night sky background             │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  PHASE 1: The Opening               │
│  • Breathing circle animation       │
│  • User syncs breath                │
│  • Prayer response displayed        │
│  • Tap "Continue"                   │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  PHASE 2: Psalm 91                  │
│  • Scripture about protection       │
│  • User reads and contemplates      │
│  • Tap "Continue"                   │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  PHASE 3: Examination               │
│  • Three guided questions           │
│  • Optional: Write reflection       │
│  • User reflects on day             │
│  • Tap "Continue"                   │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  PHASE 4: Confession                │
│  • Traditional confession text      │
│  • Absolution response              │
│  • Release of burdens               │
│  • Tap "Continue"                   │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  PHASE 5: Nunc Dimittis             │
│  • Song of Simeon (Luke 2:29-32)    │
│  • "Let your servant go in peace"   │
│  • Tap "Continue"                   │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  PHASE 6: Blessing                  │
│  • Candle flame visualization       │
│  • Final night blessing             │
│  • Tap "Amen"                       │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  COMPLETION SCREEN                  │
│                                     │
│  • Moon and stars visual            │
│  • "Rest now in peace"              │
│  • Numbers 6:24 blessing            │
│  • Tap "Good Night" → Exit          │
└─────────────────────────────────────┘
```

---

## 5. Design & Atmosphere

### Color System (Asset Catalog)

| Purpose | Token | Description |
| ------- | ----- | ----------- |
| Background | `Color("AppBackground")` | Deep night background |
| Primary Text | `.white` | High contrast for night mode |
| Secondary Text | `.white.opacity(Theme.Opacity.textSecondary)` | Softer, less prominent |
| Accent | `Color("AppAccentAction")` | Indigo accent for icons and highlights |
| Disabled/Muted | `.white.opacity(Theme.Opacity.disabled)` | Time display, subtle labels |

### Typography Tokens

| Usage | Token | Style |
| ----- | ----- | ----- |
| Headers/Titles | `Typography.Scripture.title` | Elegant serif with liturgical gravitas |
| Body/Instructions | `Typography.Scripture.footnote` | Contemplative, readable serif |
| Labels | `Typography.Editorial.label` | Section headers with tracking |
| Time Display | `Typography.Command.meta.monospaced()` | Functional, minimal |
| Captions | `Typography.Command.caption` | Subtitle text |

### Animation Tokens

| Element | Behavior |
| ------- | -------- |
| Breathing Circle | `Theme.Animation.slowFade.repeatForever(autoreverses: true)` - Scale 1.0 to 1.05 |
| Phase Transitions | `Theme.Animation.slowFade` with opacity and offset |
| Progress Dots | Fill animation as user advances through phases |
| Entry Animation | `Theme.Animation.slowFade` for initial visibility |

### Accessibility

| Feature | Implementation |
| ------- | -------------- |
| Reduce Motion | Disables starfield twinkling and candle flicker when enabled |
| Dark Mode | Always uses dark color scheme (`.preferredColorScheme(.dark)`) |
| Text Size | Uses relative font sizes that scale with system settings |

### Audio

Currently **none**—the experience is designed for silent contemplation. This is a potential expansion area.

---

## 6. Related Features

From the Home tab (ForumHomeView), users can access these related experiences alongside Compline:

| Feature | Description | Access |
| ------- | ----------- | ------ |
| Prayers from Deep | AI-generated personalized prayers | Primary feature pillar (Pray) |
| Breathe | Guided breathing exercises | Secondary feature button |
| Sermon | Record and transcribe sermons | Secondary feature button |

These features share the contemplative design aesthetic and are accessed from the same Home screen.

---

## 7. Technical Architecture

### Key Files

| File | Path | Purpose |
| ---- | ---- | ------- |
| ComplineView | `Features/Experiences/Compline/ComplineView.swift` | Main 6-phase guided prayer experience |
| ComplineBreathePhase | `Features/Experiences/Compline/Components/ComplineBreathePhase.swift` | Breathing animation component |
| AIFeature | `Features/Home/Models/AIFeature.swift` | Navigation enum (includes `.compline` case) |

### State Management (ComplineView)

```swift
@State private var currentSection = 0       // Current phase (0-5)
@State private var breathePhase: CGFloat = 0 // Breathing animation phase
@State private var candleFlicker: CGFloat = 0 // Candle animation phase
@State private var showingReflection = false // Reflection text field visible
@State private var reflectionText = ""       // User's written reflection
@State private var isComplete = false        // Prayer completed
@State private var isVisible = false         // Fade-in animation state
```

### Data Model

```swift
struct ComplineSection {
    let type: ComplineSectionType    // .opening, .psalm, .examination, etc.
    let title: String                // "The Opening", "Psalm 91", etc.
    let instruction: String          // Brief guidance text
    let content: String?             // Main content (scripture, questions)
    let response: String?            // Prayer response text
    let icon: String                 // SF Symbol name
}

enum ComplineSectionType {
    case opening
    case psalm
    case examination
    case confession
    case canticle
    case blessing
}
```

### Navigation Flow

1. User on `ForumHomeView` (Home tab)
2. Taps **Compline** secondary feature button
3. `NavigationLink` pushes `ComplineView`
4. User progresses through 6 phases via `nextSection()` function
5. After phase 6, `isComplete = true` shows completion screen
6. "Good Night" button calls `dismiss()` to pop back

---

## 8. Expansion Opportunities

The following areas represent potential directions for feature expansion:

### Audio Integration

- Ambient soundscapes (wind, rain, fireplace)
- Spoken prayers (text-to-speech or recorded)
- Gentle background music

### Persistence & History

- Save reflection text to user's journal
- Track Compline completion streaks
- View past reflections by date

### Customization

- Allow users to select different psalms
- Customizable examination questions
- Adjustable phase durations
- Skip/include specific phases

### Integration

- Sleep tracking integration (Apple Health)
- Scheduled notifications at user's preferred Compline time
- Widget for quick access to "Start Compline"

### Social Features

- Multi-user prayer sessions (pray together remotely)
- Share reflections with spiritual director or trusted friend
- Community prayer intentions

### Extended Content

- Rotating psalm selections based on liturgical calendar
- Seasonal variations (Advent, Lent, Easter)
- Saint feast day integrations

---

## 9. Summary

**Compline** is a thoughtfully designed guided Night Prayer experience that:

1. **Accessible anytime** from the Home tab's secondary features (Compline button)
2. **Creates atmosphere** through dark colors, indigo accents, and contemplative typography
3. **Guides users** through 6 traditional liturgical phases: Opening, Psalm, Examination, Confession, Canticle, Blessing
4. **Encourages reflection** through optional journaling during the Examination phase
5. **Provides closure** with a completion screen and "Good Night" dismissal
6. **Uses design system** tokens (`Theme.*`, `Typography.*`, Asset Catalog colors) for consistency

The feature balances **ancient tradition** (Liturgy of the Hours structure, traditional prayers) with **modern UX** (breathing animations, progressive disclosure, optional interactions) to create a meaningful end-of-day spiritual practice.

---

*Document updated: January 10, 2026*
