# Reading Tab Assessment: BibleStudy iOS App

> **Purpose**: This document provides a comprehensive technical assessment of the Reading tab for use by another AI system to understand the feature before expanding it.

---

## Executive Summary

The **Reading tab** (internally named "Bible" tab) is the primary scripture reading experience in the BibleStudy iOS app. It provides a sophisticated, scholar-oriented Bible reader with:

- Verse-level interaction and multi-verse selection
- 5-color semantic highlighting system with undo support
- AI-powered insights via OpenAI integration
- Full-text search with FTS5 and BM25 ranking
- Audio playback with verse-by-verse highlighting
- Extensive typography and theme customization
- Offline-first architecture with Supabase cloud sync

The feature follows modern SwiftUI architecture using `@Observable` with `@MainActor` for Swift 6 concurrency safety.

---

## 1. Navigation Architecture

### View Hierarchy

```text
MainTabView (GlassTabBar)
    └── BibleTabView (NavigationStack)
            ├── BibleHomeView (Landing Page)
            │       └── BibleReaderView (Main Reader)
            │               ├── BibleChapterHeader
            │               ├── BibleVerseRow (per verse)
            │               ├── BibleChapterFooter
            │               └── BibleContextMenuOverlay
            └── BibleBookPickerView (Sheet)
```

### Key Files

| File | Purpose |
| ---- | ------- |
| [BibleTabView.swift](BibleStudy/Features/Bible/Views/BibleTabView.swift) | Tab root with NavigationStack |
| [BibleHomeView.swift](BibleStudy/Features/Bible/Views/BibleHomeView.swift) | Landing/discovery page |
| [BibleReaderView.swift](BibleStudy/Features/Bible/Views/BibleReaderView.swift) | Core reading experience |
| [BibleReaderViewModel.swift](BibleStudy/Features/Bible/ViewModels/BibleReaderViewModel.swift) | State management hub |

### Navigation Flow

1. **BibleTabView** uses `NavigationStack` with `BibleLocation` as destination type
2. **BibleHomeView** shows hero section, continue reading card, quick access (Gospels), and browse all books button
3. **BibleReaderView** is pushed via `navigationPath.append(location)` when user selects a chapter
4. Reading position is persisted to `@AppStorage("scholarLastBookId")` and `@AppStorage("scholarLastChapter")`

---

## 2. Core Data Models

### BibleLocation (Navigation Coordinate)

```swift
struct BibleLocation: Codable, Hashable, Sendable {
    let bookId: Int      // 1-66 (Genesis to Revelation)
    let chapter: Int     // Chapter number
    var verse: Int?      // Optional specific verse

    // Navigation helpers
    func next(maxChapter: Int) -> BibleLocation?
    func previous() -> BibleLocation?

    // Presets
    static var genesis1: BibleLocation
    static var john1: BibleLocation
    static var psalm1: BibleLocation
}
```

**Location**: [Verse.swift:190-240](BibleStudy/Core/Models/Bible/Verse.swift#L190-L240)

### Verse

```swift
struct Verse: Identifiable, Hashable, Sendable {
    let translationId: String
    let bookId: Int
    let chapter: Int
    let verse: Int
    let text: String

    var reference: String      // "John 3:16"
    var shortReference: String // "Jn 3:16"
    var fullReference: String  // "John 3:16 (KJV)"
}
```

**Location**: [Verse.swift:7-51](BibleStudy/Core/Models/Bible/Verse.swift#L7-L51)

### Chapter

```swift
struct Chapter: Identifiable, Sendable, Equatable {
    let translationId: String
    let bookId: Int
    let chapter: Int
    let verses: [Verse]

    func verse(at number: Int) -> Verse?
    func verses(from start: Int, to end: Int) -> [Verse]
}
```

**Location**: [Verse.swift:137-185](BibleStudy/Core/Models/Bible/Verse.swift#L137-L185)

### Highlight

```swift
struct Highlight: Identifiable, FetchableRecord, PersistableRecord {
    let id: UUID
    let userId: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let color: HighlightColor    // blue, green, amber, rose, purple
    var category: HighlightCategory
    var needsSync: Bool          // Offline sync flag
    var deletedAt: Date?         // Soft delete
}
```

**Location**: [Highlight.swift](BibleStudy/Core/Models/User/Highlight.swift)

### Note

```swift
struct Note: Identifiable, FetchableRecord, PersistableRecord {
    let id: UUID
    let bookId: Int
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    var content: String          // Max 50KB
    var template: NoteTemplate   // freeform, observation, application
    var linkedNoteIds: [UUID]    // Cross-references
    var needsSync: Bool
}
```

**Location**: [Note.swift](BibleStudy/Core/Models/User/Note.swift)

---

## 3. State Management Architecture

### BibleReaderViewModel

The central state manager for the reading experience:

```swift
@Observable @MainActor
final class BibleReaderViewModel {
    // Dependencies
    private let bibleService: BibleService
    private let userContentService: UserContentService
    private let aiService: AIServiceProtocol
    private let highlightIndexCache = HighlightIndexCache()

    // Core State
    var currentLocation: BibleLocation
    var chapter: Chapter?
    var isLoading: Bool = false
    var error: Error?

    // Selection State
    var selectedVerses: Set<Int> = []
    var selectionMode: BibleSelectionMode = .none  // .none, .single, .range

    // Context Menu State
    var showContextMenu: Bool = false
    var selectionBounds: CGRect = .zero
    var containerBounds: CGRect = .zero

    // User Content
    var chapterHighlights: [Highlight] = []
    var chapterNotes: [Note] = []

    // Navigation
    var canGoBack: Bool = false
    var canGoForward: Bool = false
}
```

**Location**: [BibleReaderViewModel.swift:8-47](BibleStudy/Features/Bible/ViewModels/BibleReaderViewModel.swift#L8-L47)

### Selection Modes

```swift
enum BibleSelectionMode {
    case none    // No selection active
    case single  // One verse selected (tap toggles)
    case range   // Multiple contiguous verses (long-press initiates)
}
```

**Location**: [BibleReaderViewModel.swift:484-488](BibleStudy/Features/Bible/ViewModels/BibleReaderViewModel.swift#L484-L488)

### Key ViewModel Methods

| Method | Purpose |
| ------ | ------- |
| `loadChapter()` | Fetch chapter from BibleService, update navigation state |
| `selectVerse(_:)` | Toggle single verse selection |
| `extendSelection(to:)` | Extend selection to create a range |
| `startRangeSelection(from:)` | Initiate range mode from long-press |
| `clearSelection()` | Reset all selection state |
| `createHighlight(color:)` | Create highlight for current selection |
| `quickHighlight(color:)` | Replace existing highlight with new color |
| `removeHighlightForSelection()` | Delete highlight |
| `undoLastHighlight()` | Undo create/delete via stored action |
| `copySelectedVerses()` | Copy to clipboard with reference |
| `getShareText()` | Format text for share sheet |
| `navigateToVerse(_:)` | Navigate from search results |
| `playAudio()` | Start audio playback for chapter |

---

## 4. Service Layer Architecture

```text
┌─────────────────────────────────────────┐
│       BibleReaderViewModel              │
│  (Orchestrates reading experience)      │
└──────────┬──────────────────────────────┘
           │
    ┌──────┴──────┬──────────────┬──────────────┬──────────────┐
    │             │              │              │              │
    ▼             ▼              ▼              ▼              ▼
┌────────┐  ┌───────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Bible  │  │UserContent│  │ AI       │  │Highlight │  │ Audio    │
│Service │  │Service    │  │Service   │  │IndexCache│  │ Service  │
└────────┘  └───────────┘  └──────────┘  └──────────┘  └──────────┘
    │             │              │                          │
    ▼             ▼              ▼                          ▼
┌────────────────────────────────────────────────────────────────┐
│  BibleRepository (GRDB)  |  Supabase  |  OpenAI  |  TTS/Cache  │
└────────────────────────────────────────────────────────────────┘
```

### BibleService

- **Purpose**: High-level Bible data access with caching
- **Caching**: LRU cache of 10 most recent chapters
- **Prefetching**: Adjacent chapters loaded in background (100ms delay)
- **Translation**: Multi-translation support via `currentTranslationId`

**Key Methods**:

```swift
func getChapter(location: BibleLocation) async throws -> Chapter
func setTranslation(_ translationId: String) -> Bool
```

**Location**: [BibleService.swift](BibleStudy/Core/Services/Bible/BibleService.swift)

### UserContentService

- **Purpose**: Highlights and notes management with sync
- **Architecture**: Offline-first (local SQLite + Supabase sync)
- **Sync Strategy**: `needsSync` flag for pending changes, soft deletes via `deletedAt`

**Key Methods**:

```swift
func createHighlight(for range: VerseRange, color: HighlightColor) async throws
func deleteHighlight(_ highlight: Highlight) async throws
func getHighlights(for chapter: Int, bookId: Int) -> [Highlight]
func syncWithRemote() async throws
```

**Location**: [UserContentService.swift](BibleStudy/Core/Services/User/UserContentService.swift)

### HighlightIndexCache

- **Purpose**: O(1) per-verse highlight color lookup
- **Implementation**: Builds dictionary from chapter highlights
- **Invalidation**: Called on highlight create/delete

```swift
func getIndex(for chapter: Int, bookId: Int, highlights: [Highlight]) -> HighlightIndex
func invalidate(chapter: Int, bookId: Int)
```

**Location**: [HighlightIndexCache.swift](BibleStudy/Core/Services/User/HighlightIndexCache.swift)

### SearchService (FTS5)

- **Purpose**: Full-text scripture search
- **Implementation**: FTS5 virtual table with Porter stemming
- **Ranking**: BM25 algorithm for relevance
- **Features**: Phrase queries, boolean operators, snippet generation

**Location**: [SearchService.swift](BibleStudy/Core/Services/Bible/SearchService.swift)

---

## 5. User Interface Components

### BibleHomeView (Landing Page)

**Sections**:

1. **Hero Section** - Book cover visual with translation info
2. **Continue Reading Card** - Resume from `@AppStorage` position
3. **Quick Access** - Gospel shortcuts (Matthew, Mark, Luke, John)
4. **Browse All Books** - Opens `BibleBookPickerView` sheet
5. **About Section** - Feature explanation with interaction hints

**Location**: [BibleHomeView.swift](BibleStudy/Features/Bible/Views/BibleHomeView.swift)

### BibleReaderView (Main Reader)

**Layout**:

```text
ScrollView
├── BibleChapterHeader (book name, chapter number)
├── BibleEditorialDivider
├── VStack of BibleVerseRow (or ParagraphModeView)
└── BibleChapterFooter (next chapter invitation)
```

**Key Features**:

- Tap to dismiss selection
- Context menu overlay for selected verses
- Audio verse highlighting via NotificationCenter
- Search flash animation for navigated verses

**Location**: [BibleReaderView.swift](BibleStudy/Features/Bible/Views/BibleReaderView.swift)

### BibleVerseRow

**Visual States**:

| State | Background | Border |
| ----- | ---------- | ------ |
| Selected | Indigo 0.08 | Indigo 0.3 (1.5pt) |
| In Range | Indigo 0.08 | Indigo 0.2 |
| Highlighted | Color 0.15 | Clear |
| Spoken (Audio) | Accent 0.15 | Clear |
| Default | Clear | Clear |

**Interactions**:

- `onTap`: Toggle verse selection
- `onLongPress`: Start range selection + open insight sheet
- `onBoundsChange`: Report geometry for context menu positioning

**Location**: [BibleVerseRow.swift](BibleStudy/Features/Bible/Views/Reader/Components/BibleVerseRow.swift)

### BibleContextMenuOverlay

**Structure**:

```text
┌─────────────────────────────────┐
│  Copy  Share  Note     Study   │  ← Action Row
├─────────────────────────────────┤
│  🔵 🟢 🟡 🔴 🟣    ✕            │  ← Highlight Row
└─────────────────────────────────┘
         ▼ (arrow pointing to verse)
```

**Positioning**: Uses `MenuPositionCalculator` to avoid clipping and keyboard overlap

**Location**: [BibleContextMenuOverlay.swift](BibleStudy/Features/Bible/Views/Reader/Components/BibleContextMenuOverlay.swift)

---

## 6. Highlight System

### Color Semantic Meaning

| Color | Name | Purpose |
| ----- | ---- | ------- |
| Blue | Greek Blue | Original language annotations |
| Green | Theology Green | Doctrinal notes |
| Amber | Connection Amber | Cross-references |
| Rose | Personal Rose | Reflective questions |
| Purple | Amethyst | General/spiritual |

### Highlight Flow

```text
User taps color dot
    → BibleContextMenuOverlay.onHighlight(color)
    → BibleReaderViewModel.quickHighlight(color:)
        → Remove existing highlight if present
        → UserContentService.createHighlight(for:color:)
            → Save to local SQLite
            → Sync to Supabase
        → HighlightIndexCache.invalidate()
        → loadUserContent()
        → Store undo action
        → Show toast with undo button
    → clearSelection()
```

### Undo System

```swift
struct BibleHighlightUndoAction {
    let highlight: Highlight
    let type: ActionType  // .created, .deleted, .modified
}
```

Toast displays for 4 seconds with undo button. Tapping undo calls `undoLastHighlight()` which reverses the action.

---

## 7. Reading Menu System

**Entry**: Three-line button in toolbar → `showReadingMenu = true`

### Menu Sections

| Section | Purpose |
| ------- | ------- |
| **Search** | FTS5 full-text search with reference detection |
| **Listen** | Audio playback controls |
| **Display** | Font size, theme, line spacing settings |
| **Insights** | Toggle insight types (Theology, Reflection, etc.) |

### Settings Options

| Setting | Options | Storage |
| ------- | ------- | ------- |
| Theme | Light, Dark, System | `AppState.preferredTheme` |
| Text Size | 5-step slider | `AppState.scriptureFontSize` |
| Reading Mode | Scroll, Page | `@AppStorage` |
| Line Spacing | Normal, Comfortable, Spacious | `AppState.lineSpacing` |
| Content Width | Narrow, Standard, Wide | `AppState.contentWidth` |
| Paragraph Mode | On/Off | `AppState.paragraphMode` |

**Location**:

- [BibleReadingMenuSheet.swift](BibleStudy/Features/Bible/Components/BibleReadingMenuSheet.swift)
- [SettingsSection.swift](BibleStudy/Features/Bible/Views/ReadingMenu/Sections/SettingsSection.swift)

---

## 8. AI Insights System

### Architecture

```text
BibleReaderViewModel.openInlineInsight()
    → Create BibleInsightViewModel(verseRange:)
    → loadExplanation()
        → EntitlementService.canUseAIInsights
        → AIResponseCache check
        → OpenAIProvider.generateExplanation(input:)
        → Parse structured ExplanationOutput
        → Cache response
```

### Four-Tab Insight Sheet

| Tab | Content |
| --- | ------- |
| **Insight** | AI explanation (Explain/Understand/Views modes) |
| **Context** | Surrounding verses + cross-references |
| **Compare** | Translation comparison view |
| **Language** | Hebrew/Greek morphology analysis |

### Entitlement Gating

- Free tier: 3 AI insights per day
- Premium: Unlimited
- Scholar tier: Full language analysis

**Location**:

- [BibleInsightViewModel.swift](BibleStudy/Features/Bible/ViewModels/BibleInsightViewModel.swift)
- [AIServiceProtocol.swift](BibleStudy/Core/Services/AI/AIServiceProtocol.swift)

---

## 9. Audio Integration

### Audio Flow

```text
BibleReaderViewModel.playAudio()
    → createAudioChapter() → AudioChapter(location:bookName:translation:verses:)
    → AudioService.shared.loadChapter(audioChapter)
        → Check cache for HLS manifest
        → Generate TTS if not cached (Edge TTS → Local fallback)
        → Create AVMutableComposition with verse boundaries
    → AudioService.shared.play()
        → Setup boundary time observers
        → Post .audioVerseChanged notifications
```

### Verse Highlighting During Playback

1. `AudioService` posts `NotificationCenter` notification with verse number
2. `BibleReaderView` receives via `.onReceive(NotificationCenter.default.publisher(for: .audioVerseChanged))`
3. Updates `currentPlayingVerse` state
4. `BibleVerseRow` shows "spoken verse" styling when `isSpokenVerse == true`

**Location**: [AudioService.swift](BibleStudy/Core/Services/Audio/AudioService.swift)

---

## 10. Book & Chapter Selection

### BibleBookPickerView

**Two-Phase Navigation**:

1. **Phase 1: Book Selection**
   - Testament toggle (Old/New)
   - Search by book name/abbreviation
   - Grid layout with book initials
   - Organized by category (Pentateuch, Historical, etc.)

2. **Phase 2: Chapter Selection**
   - Book header card
   - Chapter grid (adaptive columns)
   - Confirm button with location preview

### BibleChapterSelector (Toolbar)

- Pill-shaped button showing current reference
- Tapping opens `BibleBookPickerView` sheet

**Location**:

- [BibleBookPickerView.swift](BibleStudy/Features/Bible/Components/BibleBookPickerView.swift)
- [BibleChapterSelector.swift](BibleStudy/Features/Bible/Components/BibleChapterSelector.swift)

---

## 11. Data Flow Summary

### Chapter Loading Pipeline

```text
User navigates to chapter
    → BibleReaderViewModel.loadChapter(at: location)
        → currentLocation = location
        → clearSelection()
        → loadChapter()
            → isLoading = true
            → BibleService.getChapter(location:)
                → Check LRU cache
                → If miss: BibleRepository.getChapter() via GRDB
                → Prefetch adjacent chapters (background)
            → chapter = result
            → updateNavigationState() → canGoBack, canGoForward
            → loadUserContent() → chapterHighlights, chapterNotes
            → isLoading = false
```

### User Content Sync Pipeline

```text
Highlight created
    → UserContentService.createHighlight()
        → EntitlementService.recordHighlightUsage()
        → Create Highlight with needsSync=true
        → saveHighlightToDB() via GRDB
        → Add to in-memory array
        → supabase.createHighlight()
            → If success: needsSync=false
            → If fail: remains needsSync=true for later sync
```

---

## 12. Performance Optimizations

| Optimization | Implementation |
| ------------ | -------------- |
| **LRU Chapter Cache** | 10-chapter capacity in BibleService |
| **Prefetching** | Adjacent chapters loaded after 100ms delay |
| **Highlight Index** | O(1) per-verse color lookup via cache |
| **FTS5 Search** | BM25 ranking for fast relevance scoring |
| **Translation Cache** | Cache key includes translationId |
| **Audio Cache** | HLS manifests and segments cached locally |

---

## 13. File Structure

```text
BibleStudy/Features/Bible/
├── Views/
│   ├── BibleTabView.swift          # Tab root
│   ├── BibleHomeView.swift         # Landing page
│   ├── BibleReaderView.swift       # Main reader
│   ├── BibleLensContainer.swift    # AI insight margins
│   ├── BibleInsightSheet.swift     # Full insight sheet
│   ├── Reader/Components/
│   │   ├── BibleChapterHeader.swift
│   │   ├── BibleChapterFooter.swift
│   │   ├── BibleVerseRow.swift
│   │   └── BibleContextMenuOverlay.swift
│   └── ReadingMenu/
│       ├── ReadingMenuState.swift
│       └── Sections/
├── Components/
│   ├── BibleBookPickerView.swift
│   ├── BibleChapterSelector.swift
│   ├── BibleReadingMenuSheet.swift
│   └── BibleContextMenu.swift
├── ViewModels/
│   ├── BibleReaderViewModel.swift
│   └── BibleInsightViewModel.swift
└── Models/
    └── BiblePreferences.swift
```

---

## 14. Integration Points

### Tab Bar Integration

- Tab enum value: `.bible`
- Tab bar hidden when in reader: `appState.hideTabBar = true`
- Golden flash animation on tab switch

### Deep Link Handling

- `biblestudy://verse/John%203:16` → Parse → Post notification → Select Bible tab → Navigate

### Entitlement System

- AI insights gated by `EntitlementService.canUseAIInsights`
- Some translations require premium
- Usage tracked with `recordAIInsightUsage()`

### Cloud Sync

- Highlights sync via Supabase
- Notes sync with content validation (50KB limit)
- `needsSync` flag for offline queue
- `deletedAt` for soft deletes

---

## 15. Key User Interactions Summary

| Interaction | Result |
| ----------- | ------ |
| Tap verse | Toggle selection, show context menu |
| Long press verse | Start range selection, open insight sheet |
| Tap in background | Clear selection, dismiss menu |
| Tap highlight color | Apply/change highlight |
| Tap "Study" | Open AI insight sheet |
| Swipe chapter footer | Navigate to next chapter |
| Toolbar three-line button | Open reading menu |
| Search field | FTS5 search with reference detection |
| Chapter selector | Open book/chapter picker |
| Prev/Next chevrons | Navigate chapters |

---

## 16. Critical Files for Feature Expansion

When expanding the Reading tab, these files are essential to understand:

1. **[BibleReaderViewModel.swift](BibleStudy/Features/Bible/ViewModels/BibleReaderViewModel.swift)** - State management hub
2. **[BibleReaderView.swift](BibleStudy/Features/Bible/Views/BibleReaderView.swift)** - UI orchestration
3. **[BibleVerseRow.swift](BibleStudy/Features/Bible/Views/Reader/Components/BibleVerseRow.swift)** - Verse interaction
4. **[UserContentService.swift](BibleStudy/Core/Services/User/UserContentService.swift)** - Highlight/note persistence
5. **[BibleService.swift](BibleStudy/Core/Services/Bible/BibleService.swift)** - Bible data access
6. **[BibleInsightViewModel.swift](BibleStudy/Features/Bible/ViewModels/BibleInsightViewModel.swift)** - AI integration
7. **[Theme.swift](BibleStudy/UI/Theme/Theme.swift)** & **[Typography.swift](BibleStudy/UI/Theme/Typography.swift)** - Design system tokens
8. **[Verse.swift](BibleStudy/Core/Models/Bible/Verse.swift)** - Core data models

---

## Document Purpose

This assessment serves as a **foundational reference** for understanding the Reading tab's architecture, components, data flow, and user interactions. It is intended to provide another AI system with complete context for planning feature expansions or modifications to the Bible reading experience.

**Key takeaways for expansion**:

- The feature uses modern SwiftUI with `@Observable` pattern
- All state flows through `BibleReaderViewModel`
- User content follows offline-first sync strategy
- AI features are entitlement-gated
- Performance is optimized via multi-layer caching
- The codebase follows consistent naming (`Bible*` prefix) and organization patterns

---

*Document verified: January 10, 2026*
