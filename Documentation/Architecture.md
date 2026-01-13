# BibleStudy iOS App - Architecture Assessment Document

> **Purpose:** Foundational reference document for AI-assisted feature expansion
> **Version:** 1.0
> **Generated:** January 2026

---

## Executive Summary

BibleStudy is a contemplative iOS scripture reading and spiritual formation app built with SwiftUI. It combines traditional Bible study features (reading, highlighting, notes) with AI-powered spiritual experiences (prayer generation, insights, Q&A). The app follows a **Stoic-Existential Renaissance aesthetic** inspired by Roman architecture and classical design.

**Core Stack:**
- SwiftUI + iOS 17+ Observable macro
- GRDB (SQLite) for local Bible data
- Supabase for backend auth/sync
- OpenAI for AI features
- MVVM architecture with protocol-based services

---

## 1. Application Structure

### 1.1 Entry Point & Initialization

**File:** `BibleStudy/BibleStudyApp.swift`

```
App Launch Flow:
1. Initialize singleton services (BibleService, DataLoadingService, AuthService)
2. Create global AppState (@Observable)
3. Show first-launch overlay (data loading) if needed
4. Restore session (auth check via Supabase)
5. Present Onboarding OR MainTabView
6. Handle deep links (widget navigation)
```

**File:** `BibleStudy/App/Configuration.swift`

Centralized configuration with:
- Supabase credentials (from Info.plist)
- OpenAI API key and model selection
- Feature flags (devotional mode, language lens, topic search, AI cache)
- Database versioning (SQLite)
- UserDefaults keys
- App Groups for widget sharing

### 1.2 Directory Structure

```
BibleStudy/
├── BibleStudyApp.swift              # Entry point + AppState
├── App/
│   └── Configuration.swift          # Centralized config
├── Core/
│   ├── Database/
│   │   └── DatabaseStore.swift    # GRDB SQLite management
│   ├── Models/                      # Data models (Verse, Book, Highlight, etc.)
│   ├── Services/                    # Business logic layer (16+ services)
│   │   ├── Bible/                   # Scripture access
│   │   ├── AI/                      # OpenAI integration
│   │   ├── User/                    # Auth, biometrics, user content
│   │   └── Navigation/              # Deep linking
│   └── Networking/
│       └── SupabaseClient.swift     # Backend API
├── Features/                        # UI layer (MVVM)
│   ├── MainTabView.swift            # Root navigation
│   ├── Auth/                        # Authentication flow
│   ├── Bible/                       # Scripture reading
│   ├── Home/                        # Sanctuary variants
│   ├── Experiences/                 # Prayer, Compline, Breathe
│   ├── Ask/                         # AI Q&A chat
│   ├── Settings/                    # App configuration
│   └── Study/                       # Highlights, notes, collections
├── UI/
│   ├── Components/                  # Reusable views
│   └── Theme/                       # Design system (Theme.swift, Typography.swift, Colors.swift)
└── Resources/                       # Assets, bundled databases
```

---

## 2. Architecture Patterns

### 2.1 MVVM with Observable State

The app uses **MVVM** with Swift's `@Observable` macro (iOS 17+):

```swift
@Observable
@MainActor
final class BibleReaderViewModel {
    // Dependencies (injected)
    private let bibleService: BibleService
    private let userContentService: UserContentService
    private let aiService: AIServiceProtocol

    // Published state
    var currentLocation: BibleLocation
    var chapter: Chapter?
    var isLoading: Bool = false
    var error: Error?
}
```

**Key ViewModels:**
- `BibleReaderViewModel` - Scripture reading state
- `BibleInsightViewModel` - AI insights for verses
- `AuthViewModel` - Authentication flow
- `HomeTabViewModel` - Home screen state
- `SettingsViewModel` - Preferences management

### 2.2 Singleton Services

Services use singleton pattern with lazy initialization:

```swift
final class BibleService {
    static let shared = BibleService()
    private init() { loadTranslationPreference() }
}
```

### 2.3 Protocol-Based Design

Services conform to protocols for testability:

```swift
@MainActor
protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws -> String
}

protocol AIServiceProtocol {
    func generateQuickInsight(...) async throws -> QuickInsightOutput
    func generateExplanation(...) async throws -> ExplanationOutput
    func generatePrayer(...) async throws -> PrayerGenerationOutput
}
```

### 2.4 Environment-Based Injection

Views receive dependencies via SwiftUI Environment:

```swift
struct BibleReaderView: View {
    @Environment(AppState.self) private var appState
    @Environment(BibleService.self) private var bibleService
}

// Provided at parent level:
BibleTabView()
    .environment(AppState())
    .environment(BibleService.shared)
```

---

## 3. Data Layer

### 3.1 Persistence Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Persistence Strategy                      │
├─────────────────────────────────────────────────────────────┤
│  Local SQLite (GRDB)  ←  Main database (Bible content)      │
│         ↓                                                    │
│  UserDefaults         ←  Preferences & small state          │
│         ↓                                                    │
│  Supabase             ←  Remote sync (auth, profiles)       │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Database Manager

**File:** `Core/Database/DatabaseStore.swift`

- Manages SQLite via GRDB
- Bundled `BibleData.sqlite` copied to Documents on first launch
- Schema versioning for updates (current version: 3)
- FTS5 full-text search for verses

### 3.3 Data Models

**Bible Models** (`Core/Models/`):
| Model | Purpose |
|-------|---------|
| `Verse` | Individual verse with GRDB conformance |
| `Chapter` | Computed collection of verses |
| `Book` | Static reference data (66 books) |
| `Translation` | Available Bible versions |
| `BibleLocation` | Navigation state (book/chapter/verse) |
| `VerseRange` | Multi-verse selection |

**User Models:**
| Model | Purpose |
|-------|---------|
| `Highlight` | Verse highlights with 6 colors |
| `Note` | Annotations linked to verses |
| `SavedPrayer` | User-generated prayers |
| `UserProfile` | Auth user data |
| `ReadingSession` | Analytics tracking |

### 3.4 Repository Pattern

```
BibleService (High-level) → BibleRepository (Low-level) → GRDB Database
```

**BibleRepository** handles raw database operations:
- `getVerse()`, `getChapter()`, `getVerses()`
- `searchVerses()` (FTS5)
- `importVerses()` (JSON import)

**BibleService** adds business logic:
- LRU chapter cache (max 10 chapters)
- Smart prefetching of adjacent chapters
- Translation switching with entitlement checks
- Initialization/import on first launch

---

## 4. Services Layer

### 4.1 Service Overview

| Service | File | Purpose |
|---------|------|---------|
| **BibleService** | `Core/Services/Bible/BibleService.swift` | Scripture access + caching |
| **BibleRepository** | `Core/Services/Bible/BibleRepository.swift` | GRDB database operations |
| **AuthService** | `Core/Services/User/AuthService.swift` | Authentication management |
| **BiometricService** | `Core/Services/User/BiometricService.swift` | Face ID / Touch ID |
| **SupabaseManager** | `Core/Networking/SupabaseClient.swift` | Backend API client |
| **OpenAIProvider** | `Core/Services/AI/OpenAIProvider.swift` | AI implementation |
| **HapticService** | `Core/Services/HapticService.swift` | Haptic feedback patterns |
| **UserContentService** | `Core/Services/User/UserContentService.swift` | Highlights, notes, prayers |
| **SearchService** | `Core/Services/SearchService.swift` | FTS5 full-text search |
| **CrossRefService** | `Core/Services/CrossRefService.swift` | Cross-reference lookup |
| **LanguageService** | `Core/Services/LanguageService.swift` | Hebrew/Greek translation |
| **AudioService** | `Core/Services/AudioService.swift` | Audio playback |
| **AnalyticsService** | `Core/Services/AnalyticsService.swift` | Event tracking |

### 4.2 AI Services Architecture

**Protocol:** `Core/Services/AI/AIServiceProtocol.swift`

Defines capabilities:
- `generateQuickInsight()` - 1-2 sentence insights
- `generateExplanation()` - Detailed with reasoning points
- `generateInterpretation()` - Multiple perspectives
- `generateWhyLinked()` - Cross-reference explanations
- `generateTermExplanation()` - Hebrew/Greek word analysis
- `generatePrayer()` - Tradition-specific prayers
- `sendChatMessage()` - Ask tab Q&A
- `generateStory()` - Biblical narratives

**Implementation:** `Core/Services/AI/OpenAIProvider.swift`

- Models: gpt-4o-mini (default), gpt-4o (advanced/stories)
- Rate limiting: 20 req/min, 200 req/day
- Timeouts: 30s request, 60s resource
- Content moderation via OpenAI Moderation API
- Self-harm detection for crisis support

**Prompts:** `Core/Services/AI/PromptTemplates.swift`

Centralized prompt engineering with:
- 10+ system prompts for different AI tasks
- User prompt builder functions
- Grounding philosophy (citations, uncertainty indicators)
- Trust UX features (reasoning points, alternative views)

### 4.3 Authentication Flow

**AuthService** bridges Supabase auth to app:
- Email/password signup/signin
- Apple Sign In (OIDC nonce generation)
- Password reset via email
- Session restoration via biometrics

**BiometricService** manages quick sign-in:
- Keychain storage of refresh tokens
- Face ID / Touch ID authentication
- Secure credential storage/retrieval

---

## 5. Navigation Structure

### 5.1 Tab-Based Navigation

**File:** `Features/MainTabView.swift`

```
MainTabView
├── Home Tab → HomeTabView
├── Bible Tab → BibleTabView
├── Ask FAB → AskModalView (full-screen)
├── Mini Player → AudioPlayerView (above tab bar)
└── GlassTabBar → Floating glass tab bar
```

### 5.2 Feature Navigation

Each feature has its own NavigationStack:

**Bible Tab:**
```
BibleTabView
├── BibleHomeView (landing with search)
└── BibleReaderView
    ├── Book/Chapter picker
    ├── Reading menu (font/settings)
    ├── Context menu (highlight/share/study)
    └── Insight sheet (AI commentary)
```

**Home Tab:**
```
HomeTabView
└── ForumHomeView (Roman Forum design)
    ├── greetingSection (time-based greeting)
    ├── wisdomQuoteSection (hero daily verse)
    ├── forumDivider
    ├── featurePillars (Scripture, Reflect, Pray)
    ├── secondaryFeatures (Sermon, Compline, Breathe)
    └── continueReadingPrompt
```

### 5.3 Deep Linking

**File:** `Core/Services/Navigation/DeepLinkHandler.swift`

Handles:
- Widget deep links
- Routes to specific verses
- Settings navigation
- Search activation

---

## 6. Features & User Interactions

### 6.1 Bible Reader

**Files:**
- `Features/Bible/Views/BibleReaderView.swift`
- `Features/Bible/ViewModels/BibleReaderViewModel.swift`

**Capabilities:**
- Verse-by-verse scripture display
- Multi-verse selection (tap for single, long-press for range)
- Highlighting with 6 colors
- Notes attached to verses
- AI-generated insights
- Audio playback with verse highlighting
- Font/typography customization
- Chapter navigation

**User Interaction Pattern:**
1. Select book from picker → navigate to chapter
2. Tap verse to select → context menu appears
3. Long-press to start range selection → tap to extend
4. Choose action: copy, share, highlight, add note, view insights
5. Use toolbar for font settings, navigation

### 6.2 Prayer Generation

**Files:**
- `Features/Experiences/Prayer/PrayersFromDeepView.swift`
- `Features/Experiences/Prayer/Core/PrayerFlowState.swift`

**State Machine Phases:**
1. **Input** - Select category, enter prayer intention
2. **Generating** - AI crafts prayer (with animation)
3. **Displaying** - View prayer, copy/share/save

**Prayer Traditions:**
- Psalmic Lament
- Desert Fathers
- Celtic
- Ignatian

**Prayer Categories:**
- Gratitude, Guidance, Healing, Peace, Strength, Wisdom

### 6.3 Home (Forum Design)

**Files:**
- `Features/Home/HomeTabView.swift`
- `Features/Home/Views/ForumHomeView.swift`

**Design:** Roman Forum-inspired layout with centered wisdom quote and feature pillars.

**Layout:**
- Greeting section with time-based message
- Central wisdom quote (hero daily verse)
- 3 primary feature pillars (Scripture, Reflect, Pray)
- 3 secondary features (Sermon, Compline, Breathe)
- Continue reading prompt with progress

**Navigation Destinations:**
- Scripture → BibleReaderView
- Reflect → AskTabView
- Pray → PrayersFromDeepView
- Sermon → SermonView
- Compline → ComplineView
- Breathe → BreatheView

### 6.4 Ask (AI Q&A)

**Files:**
- `Features/Ask/AskTabView.swift`
- `Features/Ask/AskViewModel.swift`

**Capabilities:**
- Chat interface for Bible questions
- Streaming AI responses
- Follow-up suggestions
- Uncertainty level indicators
- Citation grounding

### 6.5 Other Experiences

**Compline** (`Features/Experiences/Compline/ComplineView.swift`):
- Structured evening prayer
- 5 sections: Opening, Psalm 91, Examination, Confession, Nunc Dimittis

**Breathe** (`Features/Experiences/Breathe/BreatheView.swift`):
- Guided breathing exercises
- Pattern selection
- Session tracking

### 6.6 Settings

**File:** `Features/Settings/FloatingSanctuarySettings.swift`

**Sections:**
- Reading preferences (font, size, spacing, theme)
- Account management
- Subscription status
- Developer tools (DEBUG only)

---

## 7. State Management

### 7.1 Global AppState

**File:** `BibleStudyApp.swift` (AppState class)

```swift
@Observable
final class AppState {
    // Theme
    var preferredTheme: AppThemeMode = .system
    var scriptureFontSize: ScriptureFontSize = .medium
    var lineSpacing: LineSpacing = .normal
    var paragraphMode: Bool = false

    // Typography
    var scriptureFont: ScriptureFont = .newYork
    var displayFont: DisplayFont = .system

    // App modes
    var appMode: AppMode = .devotion  // vs. study
    var homeVariant: HomeVariant = .liturgicalHours

    // User
    var isAuthenticated: Bool = false
    var userId: String?

    // Navigation
    var currentLocation: BibleLocation = .genesis1
    var hideTabBar: Bool = false
}
```

### 7.2 Persistence

- **UserDefaults** via `@AppStorage` for preferences
- **Codable** for complex types (BibleLocation)
- **didSet** observers for automatic persistence

---

## 8. Design System

### 8.1 Aesthetic

**Stoic-Existential Renaissance Theme:**
- Bronze accents (`Color("AccentBronze")`)
- Parchment backgrounds (`Color("AppBackground")`, `Color("AppSurface")`)
- Ornate typography (New York, Charter fonts)
- Sacred motion (subtle, respectful animations)

### 8.2 Theme Configuration

**Files:** `UI/Theme/Theme.swift`, `UI/Theme/Typography.swift`, `UI/Theme/Colors.swift`

- Light/Dark/System modes (Asset Catalog adaptive colors)
- Scripture font families (New York, Charter, Iowan, etc.)
- Typography tokens: `Typography.Scripture.*`, `Typography.Command.*`, `Typography.Body.*`
- Spacing tokens: `Theme.Spacing.*` (xs, sm, md, lg, xl, xxl)
- Radius tokens: `Theme.Radius.*`
- Animation tokens: `Theme.Animation.*`
- Opacity tokens: `Theme.Opacity.*`

### 8.3 Haptic Feedback

**File:** `Core/Services/HapticService.swift`

Comprehensive haptic patterns:
- Basic (light/medium/heavy taps)
- Celebrations (correct answer, streak milestone, level up)
- Sacred motion (page turn, verse selected)
- Color announcements (unique rhythm per highlight color)

---

## 9. Key Integration Points

### 9.1 For Adding New Features

1. **Create Feature Directory:**
   ```
   Features/NewFeature/
   ├── Views/
   ├── ViewModels/
   └── Components/
   ```

2. **Create ViewModel:**
   ```swift
   @Observable
   @MainActor
   final class NewFeatureViewModel {
       private let bibleService: BibleService
       private let aiService: AIServiceProtocol
       // ...
   }
   ```

3. **Add Navigation:**
   - Add to `MainTabView` if new tab
   - Or add to existing feature's NavigationStack
   - Or present as sheet/fullScreenCover

4. **Connect Services:**
   - Inject via Environment or pass to ViewModel
   - Use existing protocols for AI/Bible/User operations

### 9.2 For Adding AI Features

1. **Add Protocol Method:**
   ```swift
   // AIServiceProtocol.swift
   func generateNewFeature(input: NewFeatureInput) async throws -> NewFeatureOutput
   ```

2. **Implement in OpenAIProvider:**
   ```swift
   func generateNewFeature(...) async throws -> NewFeatureOutput {
       let prompt = PromptTemplates.newFeature(...)
       return try await callChatCompletion(...)
   }
   ```

3. **Add Prompt Template:**
   ```swift
   // PromptTemplates.swift
   static let systemPromptNewFeature = "..."
   static func newFeature(...) -> String { ... }
   ```

### 9.3 For Adding User Content

1. **Add DTO to SupabaseClient:**
   ```swift
   struct NewContentDTO: Codable { ... }
   func getNewContent() async throws -> [NewContentDTO]
   func createNewContent(...) async throws
   ```

2. **Add Local Model:**
   ```swift
   struct NewContent: Identifiable, FetchableRecord, PersistableRecord { ... }
   ```

3. **Add to UserContentService if user-generated**

---

## 10. File Reference Index

### Core Infrastructure
- `BibleStudyApp.swift` - Entry point, AppState
- `App/Configuration.swift` - Centralized config
- `Core/Database/DatabaseStore.swift` - GRDB management

### Services
- `Core/Services/Bible/BibleService.swift` - Scripture access
- `Core/Services/Bible/BibleRepository.swift` - Database ops
- `Core/Services/AI/AIServiceProtocol.swift` - AI protocol
- `Core/Services/AI/OpenAIProvider.swift` - AI implementation
- `Core/Services/AI/PromptTemplates.swift` - Prompt engineering
- `Core/Services/User/AuthService.swift` - Authentication
- `Core/Services/User/BiometricService.swift` - Biometrics
- `Core/Networking/SupabaseClient.swift` - Backend API
- `Core/Services/HapticService.swift` - Haptic feedback

### Features
- `Features/MainTabView.swift` - Root navigation
- `Features/Bible/Views/BibleReaderView.swift` - Scripture reader
- `Features/Bible/ViewModels/BibleReaderViewModel.swift` - Reader state
- `Features/Home/HomeTabView.swift` - Home screen
- `Features/Experiences/Prayer/PrayersFromDeepView.swift` - Prayer generation
- `Features/Auth/AuthView.swift` - Authentication UI
- `Features/Settings/FloatingSanctuarySettings.swift` - Settings UI
- `Features/Ask/AskTabView.swift` - AI Q&A

### Theme & Components
- `UI/Theme/Theme.swift` - Design system (spacing, radius, animation, opacity tokens)
- `UI/Theme/Typography.swift` - Typography tokens (Scripture, Command, Body, Icon)
- `UI/Theme/Colors.swift` - Color utilities (StateOverlay, HighlightColor)
- `UI/Components/` - Reusable UI components

---

## 11. Execution Paths & Data Flow (Deep Dive)

### 11.1 App Launch to Main Screen

**Complete Initialization Sequence:**

```
App Launch
  ↓
1. initializeApp() [BibleStudyApp.swift:174-194]
  ↓
2. DataLoadingService.initializeData()
   - Copies bundled BibleData.sqlite if needed
   - Runs database migrations
  ↓
3. BibleService.initialize() [BibleService.swift:81-111]
   - Sets up GRDB database queue
   - Loads translations metadata
   - Populates chapter cache
  ↓
4. WidgetService.syncWidgetData()
   - Syncs data to widget extension
  ↓
5. AudioCache.performMaintenance()
   - Prunes expired audio files
  ↓
6. checkExistingSession() [BibleStudyApp.swift:197-225]
   - Waits 300ms for Supabase SDK init
   - Checks for stored auth session
   - Loads user profile if authenticated
  ↓
7. Route to MainTabView OR OnboardingView
   - Based on hasCompletedOnboarding flag
```

### 11.2 Bible Reading Session Flow

**Book Selection → Verse Display:**

```
1. USER ACTION: Tap Bible tab
   File: MainTabView.swift (line 33-37)
   → Shows BibleTabView

2. BibleTabView renders BibleReaderView
   File: BibleReaderView.swift (line 71)
   → Task: initializeViewModel() (line 401-408)

3. BibleReaderViewModel initialization
   File: BibleReaderViewModel.swift (line 103-113)
   → Creates ViewModel with location (default: .genesis1)

4. Load Chapter Data
   File: BibleReaderViewModel.swift (line 116-129)

   loadChapter() flow:
   a. Set isLoading = true
   b. BibleService.getChapter(location:) (line 121)
   c. Check cache first (BibleService.swift line 186-190)
   d. If miss: BibleRepository.getChapter() (line 193)

5. Repository → Database
   File: BibleRepository.swift (line 35-44)

   DatabaseStore.read { db in
     Verse.filter(translationId == "kjv")
          .filter(bookId == location.bookId)
          .filter(chapter == location.chapter)
          .order(verse)
          .fetchAll(db)
   }

6. Cache Result
   File: BibleService.swift (line 215-222)
   → LRU eviction if cache full (maxCacheSize = 10)
   → Store in chapterCache dictionary

7. Prefetch Adjacent Chapters
   File: BibleService.swift (line 247-293)
   → Background Task after 100ms delay
   → Loads previous + next chapter into cache

8. Load User Content (Highlights/Notes)
   File: BibleReaderViewModel.swift (line 408-417)
   → UserContentService.getHighlights() for chapter
   → UserContentService.getNotes() for chapter

9. Render Verses
   File: BibleReaderView.swift (line 316-374)
   → For each verse: BibleVerseRow component
   → Apply highlight color, selection state
   → Staggered animation (0.02s delay per verse)
```

**Data Flow Layers:**

```
UI Layer (SwiftUI Views)
  ↓ @State, @Environment
BibleReaderView
  ↓ calls methods on
BibleReaderViewModel (@Observable)
  ↓ requests data from
BibleService (Singleton, @Observable, @MainActor)
  ↓ manages cache, delegates to
BibleRepository (Singleton, Database Operations)
  ↓ executes GRDB queries on
DatabaseStore (Singleton, DatabaseQueue)
  ↓ reads from
SQLite Database (Documents/BibleStudy.sqlite)
```

### 11.3 AI Feature Request Flow (Prayer Generation)

**Complete Trace from UI to AI Response:**

```
1. USER INPUT: Enter prayer context
   File: PrayersFromDeepView.swift (line 218-223)
   → createPrayer() called
   → flowState.startCategoryGeneration()

2. State Transition to Generating Phase
   File: PrayerFlowState.swift
   → phase = .generating
   → Shows loading animation

3. AI Request Construction
   File: OpenAIProvider.swift (line 560-606)

   generatePrayer(input:) flow:
   a. Check rate limiter (line 561)
   b. Select prompt template (lines 567-586)
      - If category: PromptTemplates.prayerGenerationByCategory()
      - If tradition: PromptTemplates.prayerGeneration()
   c. Construct chat completion request

4. OpenAI API Call
   File: OpenAIProvider.swift (line 589-594, 724-777)

   callChatCompletion():
   a. Build request to api.openai.com/v1/chat/completions
   b. Headers: Authorization: Bearer {apiKey}
   c. Body: {model: "gpt-4o-mini", messages: [...], max_tokens: 500}
   d. URLSession.data(for: request)

5. Response Processing
   File: OpenAIProvider.swift (line 595-605)

   a. Strip markdown code fences (line 597)
   b. JSONDecoder.decode(PrayerGenerationOutput.self)
   c. Return {content: "...", amen: "..."}

6. Error Handling & Moderation
   File: OpenAIProvider.swift (line 644-720)

   moderateContent() (FREE Moderation API):
   a. Check for self-harm/crisis keywords
   b. If flagged: throw PrayerGenerationError.selfHarmDetected
   c. Triggers CrisisHelpModal

7. Display Result
   File: PrayersFromDeepView.swift (line 41-49)
   → flowState.phase = .displaying
   → Shows PrayerDisplayPhase component

8. Save Prayer (Optional)
   → PrayerService.savePrayer(prayer)
   → UserContentService → SupabaseManager
   → Insert into saved_prayers table
```

---

## 12. Detailed Pattern Analysis

### 12.1 MVVM Implementation

**View Layer:**
- SwiftUI Views (e.g., `BibleReaderView.swift`)
- Minimal logic, delegates to ViewModel
- Uses `@State`, `@Environment`, `@Observable` for reactivity

**ViewModel Layer:**
- Uses Swift 5.9's `@Observable` macro (NOT `ObservableObject`)
- Example pattern:

```swift
@Observable
@MainActor
final class BibleReaderViewModel {
    // Data state
    var currentLocation: BibleLocation
    var chapter: Chapter?

    // Loading state
    var isLoading: Bool = false
    var error: Error?

    // Selection state
    var selectedVerses: Set<Int> = []
    var selectionMode: BibleSelectionMode = .none

    // UI state
    var showContextMenu: Bool = false
    var showInlineInsight: Bool = false
}
```

**Key Deviation:**
- ViewModels are often initialized IN the View with `@State`, not injected
- Example: `@State private var viewModel: BibleReaderViewModel?`

### 12.2 Repository Pattern

**Implementation:**

```swift
final class BibleRepository: @unchecked Sendable {
    static let shared = BibleRepository()

    func getChapter(bookId: Int, chapter: Int, translationId: String) throws -> [Verse] {
        try database.read { db in
            try Verse
                .filter(Verse.Columns.translationId == translationId)
                .filter(Verse.Columns.bookId == bookId)
                .filter(Verse.Columns.chapter == chapter)
                .order(Verse.Columns.verse)
                .fetchAll(db)
        }
    }
}
```

**Service Layer Above Repository:**
- `BibleService` adds caching, prefetching, business logic
- Delegates raw DB access to `BibleRepository`

### 12.3 Singleton Pattern

**All Singleton Services:**

```swift
BibleService.shared
BibleRepository.shared
DatabaseStore.shared
SupabaseManager.shared
AuthService.shared
UserContentService.shared
AudioService.shared
OpenAIProvider.shared
HapticService.shared
ToastService.shared
```

**Pattern:**
```swift
static let shared = ServiceName()
private init() {}
```

### 12.4 Strategy Pattern (AI Providers)

**Protocol:**
```swift
protocol AIServiceProtocol {
    func generateQuickInsight(...) async throws -> QuickInsightOutput
    func generateExplanation(...) async throws -> ExplanationOutput
    func generatePrayer(...) async throws -> PrayerGenerationOutput
    var isAvailable: Bool { get }
}
```

**Usage:**
```swift
// BibleReaderViewModel.swift
private let aiService: AIServiceProtocol

// Injected as OpenAIProvider.shared by default, mockable for tests
init(aiService: AIServiceProtocol? = nil) {
    self.aiService = aiService ?? OpenAIProvider.shared
}
```

### 12.5 Observer Pattern

**SwiftUI `@Observable`:**
- Replaces Combine `@Published`
- Automatic dependency tracking

**NotificationCenter (Traditional):**
```swift
// BibleReaderView.swift
.onReceive(NotificationCenter.default.publisher(for: .audioVerseChanged)) { notification in
    guard let verse = notification.userInfo?["verse"] as? Int else { return }
    currentPlayingVerse = verse
}
```

**Pattern Choice:**
- `@Observable` for data binding (reactive UI)
- `NotificationCenter` for cross-component events (navigation, deep links)

---

## 13. Service Dependencies & Interactions

### 13.1 Dependency Graph

```
App Launch
  ↓
DatabaseStore (foundational)
  ↓
BibleRepository (depends on DatabaseStore)
  ↓
BibleService (depends on BibleRepository)
  ↓
ViewModels (depend on BibleService)
  ↓
Views (depend on ViewModels)

Parallel Initialization:
- SupabaseManager (independent)
- AuthService (depends on SupabaseManager)
- UserContentService (depends on SupabaseManager + DatabaseStore)
- AudioService (independent)
- OpenAIProvider (independent)
```

### 13.2 Service Call Examples

**Create Highlight:**
```
User taps color →
BibleReaderViewModel.createHighlight(color:) →
  UserContentService.createHighlight(for:color:) →
    EntitlementService.recordHighlightUsage() [paywall check] →
    DatabaseStore.write { ... } [local cache] →
    SupabaseManager.createHighlight() [remote sync]
```

**Generate AI Insight:**
```
User taps "Study" →
BibleReaderViewModel.openInlineInsight() →
  BibleInsightViewModel.loadExplanation() →
    OpenAIProvider.generateExplanation() →
      RateLimiter.checkLimit() →
      URLSession → OpenAI API →
      AIResponseCache.store() [cache for offline]
```

### 13.3 Initialization Order

**Sequential (Critical Path):**
1. `DatabaseStore.setup()` - MUST complete first
2. `BibleService.initialize()` - Loads translations
3. `WidgetService.syncWidgetData()` - Non-blocking
4. `AuthService` checks session - Async, doesn't block UI

**Parallel (Independent):**
- `AudioCache.performMaintenance()` - Background cleanup
- `SupabaseManager` init - Only needed for authenticated features
- `EntitlementService` - Lazy initialization on first paywall trigger

---

## 14. State Management Deep Dive

### 14.1 AppState Propagation

**Definition Location:** `BibleStudyApp.swift` lines 229-435

**Propagation:**
```swift
// BibleStudyApp.swift
MainTabView()
    .environment(appState)  // Injected at root

// Any child view can access:
@Environment(AppState.self) private var appState
```

**Persistence:**
```swift
// Property observers save on change:
var scriptureFontSize: ScriptureFontSize = .medium {
    didSet {
        UserDefaults.standard.set(scriptureFontSize.rawValue, forKey: "preferredFontSize")
    }
}
```

### 14.2 Persistence at Each Layer

| Layer | Mechanism | Use Case | Lifetime |
|-------|-----------|----------|----------|
| In-Memory | `@State` | Ephemeral UI state | View lifecycle |
| App-Wide | `AppState` | User preferences | App session + persisted |
| Local Cache | GRDB SQLite | Highlights, Notes | Permanent, synced |
| Cloud | Supabase | User data | Cross-device |

### 14.3 Highlight Creation Flow (Complete)

```
1. UI: User selects verse
   → @State selectedVerses updated

2. ViewModel: User picks color
   → BibleReaderViewModel.createHighlight()

3. Service: Create model
   → UserContentService.createHighlight()

4. Local DB: Save to cache
   → DatabaseStore.write { Highlight.save() }

5. Cloud: Sync to Supabase
   → SupabaseManager.createHighlight()

6. Update UI: Reload highlights
   → ViewModel.loadUserContent()
   → chapterHighlights array updated
   → SwiftUI re-renders (automatic via @Observable)
```

---

## 15. AI Integration Details

### 15.1 Rate Limiting

**Actor-based Implementation:**
```swift
actor RateLimiter {
    private let maxRequests: Int = 20  // per minute
    private var requestTimestamps: [Date] = []

    func checkLimit() async throws {
        let now = Date()
        let windowStart = now.addingTimeInterval(-60)
        requestTimestamps = requestTimestamps.filter { $0 > windowStart }

        if requestTimestamps.count >= maxRequests {
            throw AIServiceError.rateLimited
        }
        requestTimestamps.append(now)
    }
}
```

### 15.2 AI Response Cache

**Database Schema:**
```sql
CREATE TABLE ai_cache (
    id INTEGER PRIMARY KEY,
    cache_key TEXT UNIQUE,
    book_id INTEGER,
    chapter INTEGER,
    verse_start INTEGER,
    verse_end INTEGER,
    mode TEXT,
    prompt_hash TEXT,
    response TEXT,
    model_used TEXT,
    created_at DATETIME,
    expires_at DATETIME
)
```

**Cache Strategy:**
- **Key**: `hash(verseRange + mode + promptHash)`
- **TTL**: 30 days (configurable)
- **Eviction**: Manual cleanup on app launch
- **Purpose**: Offline support + cost reduction

### 15.3 Error Handling Strategy

| Error Type | Handling | UI Fallback |
|------------|----------|-------------|
| Network | Throw `AIServiceError.networkError` | Show cached response if available |
| Rate Limit | Throw `AIServiceError.rateLimited` | Toast "Too many requests" |
| Content Moderation | Throw `PrayerGenerationError.selfHarmDetected` | Show CrisisHelpModal |
| Invalid JSON | Fallback to plain text | Display raw response |

---

## 16. Navigation System Details

### 16.1 Custom Tab Implementation

**Why No TabView:**
- Avoids SwiftUI's built-in tab limitations
- Custom tab bar with glassmorphism
- Preserves state between tabs (views stay mounted)

**Implementation:**
```swift
// MainTabView.swift
ZStack {
    HomeTabView()
        .opacity(selectedTab == .home ? 1 : 0)
        .blur(radius: selectedTab == .home ? 0 : 2)

    BibleTabView()
        .opacity(selectedTab == .bible ? 1 : 0)
        .blur(radius: selectedTab == .bible ? 0 : 2)
}
.safeAreaInset(edge: .bottom) {
    GlassTabBar(selectedTab: $selectedTab)
}
```

### 16.2 Deep Link Handling

**URL Scheme:** `biblestudy://`

**Supported Paths:**
```
biblestudy://verse?ref=John+3:16
biblestudy://search?q=love
biblestudy://auth/callback?code={authCode}
biblestudy://auth/error?error=otp_expired
```

**Flow:**
1. Deep link opened → `onOpenURL` triggered
2. `DeepLinkHandler.handle()` parses URL
3. Posts NotificationCenter event
4. `MainTabView` or `BibleReaderView` listens for event
5. Updates navigation state

### 16.3 Modal Presentation Patterns

| Type | Usage | Presentation |
|------|-------|--------------|
| Bottom Sheet | Reading menu | `.presentationDetents([.medium])` |
| Full-Screen Cover | Ask modal | `.fullScreenCover(isPresented:)` |
| Dynamic Sheet | Insight sheet | `.presentationDetents([.medium, .large])` |

---

## 17. Component Reusability

### 17.1 Key Shared Components

| Component | Location | Usage |
|-----------|----------|-------|
| `IlluminatedContextMenu` | `UI/Components/` | Verse selection menu |
| `AppToastView` | `UI/Components/` | Parchment-style toast |
| `FloatingParticles` | `UI/Components/` | Ambient animation |
| `IlluminatedChapterHeader` | `UI/Components/` | Ornate headers |
| `OrnamentalDivider` | `UI/Components/` | Decorative separators |
| `CandleFlame` | `UI/Components/` | Animated candle |

### 17.2 Composition Pattern

```swift
struct BibleVerseRow: View {
    let verse: Verse
    let isSelected: Bool
    let highlightColor: HighlightColor?
    let fontSize: ScriptureFontSize

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VerseNumberView(number: verse.verse, style: .superscript)

            Text(verse.text)
                .font(fontSize.swiftUIFont)
                .foregroundColor(highlightColor?.textColor ?? .primaryText)

            Spacer()
        }
        .padding(12)
        .background(highlightColor?.backgroundColor ?? Color.clear)
    }
}
```

### 17.3 Theme Integration

```swift
// Usage pattern - Design system tokens
Text("Hello")
    .font(Typography.Body.regular)
    .foregroundColor(Color("AppTextPrimary"))
    .padding(Theme.Spacing.md)

// Scripture text
Text(verseText)
    .font(Typography.Scripture.body)
    .foregroundColor(Color("AppTextPrimary"))

// Command/UI text
Text("Continue Reading")
    .font(Typography.Command.body)
    .foregroundColor(Color("AccentBronze"))
```

---

## Summary

BibleStudy is a mature SwiftUI application with:
- **Clear separation of concerns** (Services, ViewModels, Views)
- **Protocol-based testability** (AIServiceProtocol, AuthServiceProtocol)
- **Modern Swift patterns** (@Observable, async/await, MainActor)
- **Multi-layer persistence** (GRDB local, Supabase remote)
- **Rich AI integration** (insights, prayer, Q&A)
- **Contemplative UX** (Stoic-Roman aesthetic, classical design)

**For Feature Expansion:**
1. **New Feature**: Create ViewModel → Service → Repository (if data-backed)
2. **New AI Feature**: Implement in `AIServiceProtocol`, add to `OpenAIProvider`
3. **New Data Type**: Add migration to `DatabaseStore`, create model with GRDB
4. **New Screen**: Follow MVVM, inject `AppState` and required services
5. **Navigation**: Use NotificationCenter for cross-feature routing

The architecture supports extension through its modular feature structure and protocol-based service layer.

---

*Document updated: January 10, 2026*
