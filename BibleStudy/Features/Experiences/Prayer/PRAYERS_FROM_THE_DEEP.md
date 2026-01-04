# Prayers from the Deep

## Overview

An AI prayer companion that transforms your raw emotions and situations into structured, beautiful prayers using the patterns of ancient traditions. You pour out your heart; the AI shapes it into sacred language—teaching you to pray by praying with you.

---

## Core Concept

**AI as Prayer Companion, Not Advice-Giver**

Rather than telling users what to do or how to feel, Prayers from the Deep meets them where they are emotionally and transforms their raw, unstructured thoughts into the sacred language of historic prayer traditions. The AI serves as a bridge between human emotion and divine conversation.

---

## Three-Phase Flow

### Phase 1: Input
**"Share what's on your heart"**

- Large breathing icon (`hands.sparkles.fill`) with subtle pulse animation
- Header: "What's on your heart?"
- Subtext: "Describe your situation, and I'll craft a prayer in the tradition of the Psalms."
- Multi-line text input with rose-colored border
- Placeholder: *"e.g., 'I'm anxious about my son who has drifted away...'"*
- Prayer tradition selector (horizontal chips)
- "Craft Prayer" button with sparkles icon

### Phase 2: Generating
**"Contemplative waiting"**

- Concentric breathing circles (3 rings pulsing outward)
- Central hands icon
- "Crafting your prayer..."
- Tradition-specific message (e.g., "Drawing from the well of the Psalms")
- ~3 second contemplative pause

### Phase 3: Prayer Display
**"Sacred text revealed"**

- Cross ornament at top
- Full prayer in elegant serif typography
- Centered text with generous line spacing (1.7x)
- Line-by-line reveal animation
- Decorative divider with diamond center
- Tradition attribution: "In the tradition of [Selected Tradition]"
- Action bar: Save | Share | New

---

## Prayer Traditions

| Tradition | Style | Structure |
|-----------|-------|-----------|
| **Psalmic Lament** | David's pattern | Cry → Trust → Praise |
| **Desert Fathers** | Sparse, contemplative | Repetitive, piercing brevity |
| **Celtic** | Nature imagery | Trinity invocations, creation themes |
| **Ignatian** | Imaginative | Conversational with God, sensory |

### Psalmic Lament Structure
The classic lament psalm follows this pattern:
1. **Address** - Direct invocation of God
2. **Complaint** - Honest expression of pain/struggle
3. **Trust** - Remembrance of God's faithfulness
4. **Petition** - Specific request
5. **Commitment** - Declaration of continued faith

---

## Example Prayer Output

**User Input:** *"I'm anxious about my son who has drifted away..."*

**Generated Prayer (Psalmic Lament):**

> O Lord, You who count the stars
> and call each one by name,
> surely You see my son
> wandering in distant places.
>
> My heart is heavy as stone in deep waters.
> I have cried until there are no more tears,
> yet still the ache remains,
> a wound that will not close.
>
> But I remember Your faithfulness—
> how You sought the lost sheep,
> how You waited for the prodigal,
> how Your arms never tire of reaching.
>
> So I will trust, even in this darkness.
> I will hope, even when hope seems foolish.
> For You are the God who brings
> dead things back to life.
>
> Watch over him, Lord.
> Where I cannot go, go with him.
> Where my voice cannot reach,
> let Your Spirit whisper love.
>
> *Amen.*

---

## Visual Design

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Sacred Navy | `#0a0d1a` | Primary background |
| Rose Accent | `#f43f5e` | Primary accent, buttons, highlights |
| Candlelight Glow | `#ffefd5` | Warm ambient glow |
| Gold Accent | `#d4a853` | Secondary accent, ornaments |

### Design Elements
- **Background:** Deep sacred blue-black with breathing rose glow
- **Typography:** Elegant serif for prayers, clean sans-serif for UI
- **Atmosphere:** Contemplative, intimate, sacred
- **Motion:** Breathing animations (4-second cycles), line-by-line reveals

---

## User Actions

| Action | Icon | Function |
|--------|------|----------|
| Save | `bookmark` | Save prayer to personal collection |
| Share | `square.and.arrow.up` | Share prayer with others |
| New | `arrow.counterclockwise` | Start over with new situation |

---

## State Management

```swift
@State private var inputText = ""
@State private var selectedTradition: PrayerTradition = .psalmicLament
@State private var breathePhase: CGFloat = 0  // Drives breathing animations

// Flow phases
enum PrayerFlowPhase {
    case input
    case generating
    case displaying
}
```

---

## Key Files

```
Features/Experiences/Prayer/
├── PrayersFromDeepView.swift          # Main entry point
├── Core/
│   └── PrayerFlowState.swift          # State management
├── Models/
│   └── PrayerModels.swift             # Traditions & mock prayers
├── Shared/
│   ├── DeepPrayerColors.swift         # Color palette
│   ├── DeepPrayerBackground.swift     # Breathing background
│   └── VariationPreviewCard.swift     # Showcase card
└── Variations/Balanced/
    ├── BalancedPrayerView.swift
    └── Components/
        ├── BalancedInputPhase.swift
        ├── BalancedGeneratingPhase.swift
        ├── BalancedDisplayPhase.swift
        └── BreathingCircleAnimation.swift
```

---

## What This Feature Demonstrates

1. **AI as Companion** - Walks alongside users rather than lecturing them
2. **Emotional Transformation** - Converts raw feelings into sacred structure
3. **Ancient Wisdom** - Connects modern struggles to historic prayer patterns
4. **Contemplative UX** - Breathing animations create space for reflection
5. **Personalized Learning** - Foundation for teaching users to pray in various traditions

---

## Future Enhancements

- [ ] Actual AI integration (currently uses mock prayers)
- [ ] Save prayers to personal collection
- [ ] Prayer history and favorites
- [ ] Custom tradition blending
- [ ] Audio playback of prayers
- [ ] Daily prayer suggestions based on mood
- [ ] Community sharing of anonymized prayer themes
