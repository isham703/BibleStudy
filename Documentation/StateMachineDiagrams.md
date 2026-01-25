# BibleStudy State Machine Diagrams

Comprehensive documentation of all state machines in the BibleStudy iOS app, visualized using Mermaid `stateDiagram-v2` syntax.

## Table of Contents

- [1. Phase-Based User Flows](#1-phase-based-user-flows)
  - [1.1 Prayer Flow](#11-prayer-flow)
  - [1.2 Sermon Recording Flow](#12-sermon-recording-flow)
  - [1.3 Breathing Experience](#13-breathing-experience)
  - [1.4 Compline Evening Prayer](#14-compline-evening-prayer)
  - [1.5 Authentication Flow](#15-authentication-flow)
  - [1.6 Onboarding Flow](#16-onboarding-flow)
- [2. Service-Level State Machines](#2-service-level-state-machines)
  - [2.1 Audio Playback & Session Ownership](#21-audio-playback--session-ownership)
  - [2.2 Circuit Breaker](#22-circuit-breaker)
  - [2.3 Data Loading](#23-data-loading)
  - [2.4 Subscription/Entitlements](#24-subscriptionentitlements)
  - [2.5 Notification Authorization](#25-notification-authorization)
- [3. UI Component States](#3-ui-component-states)
  - [3.1 Bible Reader Selection](#31-bible-reader-selection)
  - [3.2 Reading Menu Navigation](#32-reading-menu-navigation)
  - [3.3 Ask Chat](#33-ask-chat)
  - [3.4 Memorization](#34-memorization)

---

## 1. Phase-Based User Flows

### 1.1 Prayer Flow

**Purpose:** Manages the AI-powered prayer generation experience with crisis detection and word-by-word reveal animation.

**Source:** `Features/Experiences/Prayer/Core/PrayerFlowState.swift`
d
```mermaid
stateDiagram-v2
    [*] --> input

    input --> generating: startCategoryGeneration() [canGenerate && !quotaExceeded] / clearError()
    input --> PaywallShown: startCategoryGeneration() [quotaExceeded] / showPaywall()

    generating --> displaying: success / createPrayer(), recordPrayerGeneration()
    generating --> input: error [!isCrisis] / handleError(), setPhase(input)
    generating --> CrisisModal: error [isCrisis] / handleError(), showCrisisModal()

    CrisisModal --> input: dismissCrisisModal() / clearError()

    displaying --> input: reset() / cancelReveal(), clearState()

    state displaying {
        [*] --> revealing
        revealing --> revealed: skipToFullReveal() OR wordCount == totalWords
        revealed --> [*]
    }

    note right of generating
        Sequential execution (not substates):
        1. Validate input (2-500 chars)
        2. Moderate content (OpenAI)
        3. Generate prayer with retry
           - Retry logic: 1s, 2s, 4s delays
           - Max 3 attempts for transient errors
        4. Ensure 2s min animation duration
    end note
```

**Key Behaviors:**

- Crisis detection (self-harm) triggers hardcoded support resources modal
- Exponential backoff retry for transient failures (network, rate limit)
- Word-by-word reveal with punctuation-aware delays (0.7s base, +0.6s for periods)
- Quota tracking via `EntitlementService.recordPrayerGeneration()`

**Edge Cases:**

- Crisis modal prevents normal error dismissal flow
- Generation task is cancelled if view disappears
- Input validation (non-empty, <= 500 chars) happens before transition

---

### 1.2 Sermon Recording Flow

**Purpose:** Manages sermon recording, import, multi-step processing pipeline, and viewing.

**Source:** `Features/Sermon/Core/SermonFlowState.swift`

```mermaid
stateDiagram-v2
    [*] --> input

    input --> recording: startRecording() [authenticated && hasPermission] / createSermon(), startMetering()
    input --> importing: importAudio() [authenticated] / validateFile()
    input --> error: startRecording() [!hasPermission] / microphonePermissionDenied

    recording --> processing: stopRecording() / stopMetering(), processRecording()
    recording --> input: cancelRecording() / cleanup()

    state recording {
        [*] --> active
        active --> paused: pauseRecording() / softTap()
        paused --> active: resumeRecording() / softTap()
    }

    importing --> processing: fileValid / copyToLocal(), createChunk()
    importing --> error: invalidFile / fileTooLarge OR unsupportedFormat

    state processing {
        [*] --> uploading
        uploading --> transcribing: progress >= 0.2 / uploadChunk()
        transcribing --> moderating: progress >= 0.7
        moderating --> analyzing: progress >= 0.75
        analyzing --> saving: progress >= 0.95
        saving --> [*]: complete

        note right of transcribing
            Chunk-based: (chunk X of Y)
            Progress streaming via AsyncStream
        end note
    }

    processing --> viewing: allStepsComplete / loadSermonData(), success()
    processing --> error: anyStepFails / handleError()

    error --> input: dismissError() / clearError()
    error --> processing: retry() [hasLocalChunks] / processRecording()

    viewing --> input: reset() / cancelAllTasks(), clearState()

    note right of processing
        30-minute timeout
        500ms polling interval
    end note
```

**Key Behaviors:**

- 10-minute audio chunks for large recordings
- Progress streaming via `AsyncStream` with 500ms polling
- Waveform samples generated per chunk (100 samples)
- Audio level metering during recording (100 samples buffer)

**Edge Cases:**

- Processing timeout after 30 minutes triggers error
- Local chunks preserved for retry on network failure
- Session refresh before authenticated operations

---

### 1.3 Breathing Experience

**Purpose:** Manages cyclic breathing exercises with configurable patterns and visual/haptic feedback.

**Source:** `Features/Experiences/Breathe/Core/BreathingState.swift`

```mermaid
stateDiagram-v2
    [*] --> idle

    idle --> inhale: start() [!isActive] / setActive(true), startTimeTracking()

    state BreathingCycle {
        [*] --> inhale
        inhale --> hold1: duration elapsed / lightHaptic()
        hold1 --> exhale: duration elapsed
        exhale --> hold2: duration elapsed / lightHaptic()
        hold2 --> inhale: duration elapsed / cyclesCompleted++, successHaptic()

        note right of inhale
            breathScale: 0.7 → 1.0
            Animated easeInOut
        end note

        note right of exhale
            breathScale: 1.0 → 0.6
            Animated easeInOut
        end note

        note right of hold1
            breathScale: 1.0 (static)
            No animation
        end note

        note right of hold2
            breathScale: 0.6 (static)
            No animation
        end note
    }

    inhale --> idle: stop() / cancelTasks(), animate(scale: 0.7)
    hold1 --> idle: stop() / cancelTasks(), animate(scale: 0.7)
    exhale --> idle: stop() / cancelTasks(), animate(scale: 0.7)
    hold2 --> idle: stop() / cancelTasks(), animate(scale: 0.7)

    note left of idle
        Patterns:
        - Calm: 4-0-4-0
        - Box: 4-4-4-4
        - Sleep: 4-7-8-0
    end note
```

**Key Behaviors:**

- Pattern selection only allowed when `!isActive`
- Zero-duration phases are skipped automatically
- Cycle progress calculated as `(phaseOffset + elapsed) / totalCycle`
- Time tracking runs independently at 100ms intervals

**Edge Cases:**

- ComplineBreathingState variant uses fixed 4-7-8 pattern
- Tasks cancelled immediately on `stop()` to prevent zombie animations

---

### 1.4 Compline Evening Prayer

**Purpose:** Guides users through the traditional evening prayer liturgy with sequential sections.

**Source:** `Features/Experiences/Compline/ComplineView.swift`

```mermaid
stateDiagram-v2
    [*] --> opening

    opening --> psalm: nextSection() / slideTransition(), softTap()
    psalm --> examination: nextSection() / slideTransition()
    examination --> confession: nextSection() / slideTransition()
    confession --> canticle: nextSection() / slideTransition()
    canticle --> blessing: nextSection() / slideTransition()
    blessing --> complete: "Amen" tapped / setComplete(true)

    psalm --> opening: previousSection() [section > 0]
    examination --> psalm: previousSection()
    confession --> examination: previousSection()
    canticle --> confession: previousSection()
    blessing --> canticle: previousSection()

    complete --> [*]: dismiss

    state examination {
        [*] --> reflectionClosed
        reflectionClosed --> reflectionOpen: toggleReflection() / settleAnimation()
        reflectionOpen --> reflectionClosed: toggleReflection()
    }

    state opening {
        [*] --> breathingIntegrated
        note right of breathingIntegrated
            Embeds ComplineBreathingState
            Fixed 4-7-8 pattern
        end note
    }

    note right of complete
        Shows moon icon
        Final blessing display
    end note
```

**Key Behaviors:**

- Linear progression through 6 sections
- Back navigation allowed except from first section
- Examination section has optional text reflection input
- Opening section integrates `ComplineBreathingState`

**Edge Cases:**

- Keyboard dismissed on section transitions
- Section visibility animated on appear

---

### 1.5 Authentication Flow

**Purpose:** Manages sign-in, sign-up, password reset, email confirmation, and biometric enrollment.

**Source:** `Features/Auth/AuthViewModel.swift`

```mermaid
stateDiagram-v2
    [*] --> signIn

    state signIn {
        [*] --> formInput
        formInput --> loading: signIn() [canSubmit] / setLoading(true)
        formInput --> appleSignInLoading: appleSignIn() / handleAppleSignIn()
        loading --> biometricOptIn: success [biometricAvailable && !enrolled] / storeRefreshToken()
        loading --> authenticated: success [!biometricAvailable OR enrolled]
        loading --> formInput: failure / showError()
        appleSignInLoading --> biometricOptIn: success [biometricAvailable] / storeRefreshToken()
        appleSignInLoading --> authenticated: success [!biometricAvailable]
        appleSignInLoading --> formInput: failure / showError()
    }

    signIn --> signUp: toggleMode() / clearForm()
    signUp --> signIn: toggleMode() / clearForm()

    state signUp {
        [*] --> formInput
        formInput --> loading: signUp() [canSubmit] / setLoading(true)
        loading --> emailConfirmation: success / storeSubmittedEmail()
        loading --> formInput: failure / showError()
    }

    emailConfirmation --> signIn: changeEmail() / clearSubmittedEmail()
    emailConfirmation --> emailConfirmation: resendConfirmation()

    signIn --> resetPassword: forgotPassword() / showResetSheet()
    resetPassword --> signIn: dismiss OR success

    biometricOptIn --> authenticated: enableBiometrics() / storeCredentials()
    biometricOptIn --> authenticated: skipBiometrics() / clearRefreshToken()

    authenticated --> [*]

    state PasswordStrength {
        [*] --> blank
        blank --> rawPigment: score >= 1
        rawPigment --> groundPigment: score >= 2
        groundPigment --> gilded: score >= 3
        gilded --> illuminated: score > 4

        note right of illuminated
            Score factors:
            +1: length >= 8
            +1: length >= 12
            +1: upper + lower
            +1: has digit
            +1: has special
        end note
    }

    note right of biometricOptIn
        "Sacred Seal" icon animation
        Enable FaceID/TouchID
    end note

    note left of appleSignInLoading
        Bypasses password flow
        Uses Apple credentials
    end note
```

**Key Behaviors:**

- Biometric opt-in shown after successful sign-in if available
- Refresh token temporarily stored for biometric enrollment
- Password strength calculated in real-time with visual indicator
- Email confirmation allows resend without losing context

**Edge Cases:**

- Biometric sign-in with expired token falls back to password
- Form validation prevents submission with invalid data
- Apple Sign In bypasses password flow entirely

---

### 1.6 Onboarding Flow

**Purpose:** Collects user preferences to personalize the app experience with mode and goal recommendations.

**Source:** `Features/Onboarding/OnboardingView.swift`

```mermaid
stateDiagram-v2
    [*] --> valueProps

    state valueProps {
        [*] --> page0
        page0 --> page1: swipe
        page1 --> page2: swipe
        page2 --> page3: swipe
        page3 --> [*]: "Get Started"
    }

    valueProps --> nameEntry: "Get Started" OR lastPageReached / slideTransition()
    valueProps --> completed: "Skip" / setDefaults(), trackSkipped()

    nameEntry --> goalQuiz: "Continue" / storeName(), trackQuizStarted()

    state goalQuiz {
        [*] --> question1
        question1 --> question2: answerSelected [300ms delay] / trackAnswer()
        question2 --> question3: answerSelected [300ms delay] / trackAnswer()
        question3 --> [*]: answerSelected [300ms delay] / trackAnswer()

        question2 --> question1: back()
        question3 --> question2: back()
    }

    goalQuiz --> personalization: allAnswered / calculateMode()

    state personalization {
        [*] --> loading
        loading --> modeReveal: dataProcessed
        modeReveal --> [*]: animationComplete

        note right of loading
            "Preparing your experience..."
            Calculate recommendedMode
            Calculate dailyGoalMinutes
        end note
    }

    personalization --> completed: complete() / applyToAppState(), syncProfile()

    completed --> [*]: hasCompletedOnboarding = true

    note left of goalQuiz
        Q1: Primary focus (devotional/study/memorize/explore)
        Q2: Daily commitment (5/10/15/30 min)
        Q3: Experience level (new/occasional/regular/extensive)
    end note
```

**Key Behaviors:**

- Skip sets defaults: `{focus: "devotional", time: "10", level: "occasional"}`
- Mode recommendation: Study if `focus == "study"` OR `time == "30"` OR `level == "extensive"`
- Quiz answers auto-advance after 300ms selection delay
- Analytics tracked at each step

**Edge Cases:**

- Name entry is optional (can continue with empty)
- Back navigation within quiz (except Q1)
- Daily goal synced to `ProgressService` on completion

---

## 2. Service-Level State Machines

### 2.1 Audio Playback & Session Ownership

**Purpose:** Manages audio playback lifecycle with TTS generation, sleep timers, verse synchronization, and coordinated audio session ownership across multiple producers.

**Source:** `Core/Services/Audio/AudioService.swift`

```mermaid
stateDiagram-v2
    [*] --> idle

    idle --> loading: loadChapter() / createRequest()

    state loading {
        [*] --> checkingCache
        checkingCache --> generatingTTS: cacheMiss / startGeneration()
        checkingCache --> preparingPlayer: cacheHit / loadFromCache()
        generatingTTS --> preparingPlayer: generated / cacheAudio()

        note right of generatingTTS
            Quick-start: First 3 verses
            Background: Remaining verses
            Fallback: Edge TTS → Local TTS
        end note
    }

    loading --> ready: playerReady
    loading --> error: loadFailed / handleError()

    ready --> playing: play() / startPlayback()
    ready --> idle: stop() / cleanup()

    playing --> paused: pause() / pausePlayback()
    playing --> paused: interruption [shouldPause] / saveState()
    playing --> finished: reachedEnd
    playing --> paused: sleepTimerFired / pause(), postNotification()

    paused --> playing: play() / resumePlayback()
    paused --> playing: interruptionEnded [wasPlaying] / resumePlayback()
    paused --> idle: stop() / cleanup()

    finished --> playing: play() / seekToStart(), startPlayback()
    finished --> idle: stop() / cleanup()

    error --> idle: dismissError() / cleanup()
    error --> loading: retry() / loadChapter()

    state SleepTimer {
        [*] --> inactive
        inactive --> countdown: startTimer(minutes)
        inactive --> endOfChapter: startTimer(endOfChapter: true)
        countdown --> inactive: timerFired / pause()
        countdown --> inactive: cancelTimer()
        endOfChapter --> inactive: chapterEnded / pause()
        endOfChapter --> inactive: cancelTimer()
    }

    state AudioSessionOwnership {
        [*] --> idle_session
        idle_session --> biblePlayback: pushAudioSession(.biblePlayback) / configure(.playback, .spokenAudio)
        idle_session --> sermonPlayback: pushAudioSession(.sermonPlayback) / configure(.playback, .spokenAudio)
        idle_session --> sermonRecording: pushAudioSession(.sermonRecording) / configure(.playAndRecord)

        biblePlayback --> sermonPlayback: pushAudioSession(.sermonPlayback) [higher priority]
        biblePlayback --> sermonRecording: pushAudioSession(.sermonRecording) [highest priority]
        biblePlayback --> idle_session: popAudioSession() [stack empty] / deactivate()

        sermonPlayback --> sermonRecording: pushAudioSession(.sermonRecording) [highest priority]
        sermonPlayback --> biblePlayback: popAudioSession() [bible still claimed]
        sermonPlayback --> idle_session: popAudioSession() [stack empty] / deactivate()

        sermonRecording --> sermonPlayback: popAudioSession() [sermon playback claimed]
        sermonRecording --> biblePlayback: popAudioSession() [bible claimed]
        sermonRecording --> idle_session: popAudioSession() [stack empty] / deactivate()

        note right of sermonRecording
            Priority order:
            1. sermonRecording (highest)
            2. sermonPlayback
            3. biblePlayback
            4. idle (lowest)

            Stack-based: highest wins
            Idempotent reconfiguration
        end note
    }

    note right of playing
        Time observer: 0.25s intervals
        Boundary observer: verse transitions
        Posts: .audioVerseChanged
    end note
```

**Key Behaviors:**

- Progressive loading: start playback after first 3 verses
- TTS fallback chain: Edge neural TTS → Local AVSpeechSynthesizer
- Sleep timer modes: countdown (minutes) or end-of-chapter
- Verse boundary synchronization via `CMTime` observers
- **Stack-based audio session ownership**: Multiple producers can claim the session; highest priority mode wins
- **Idempotent reconfiguration**: Session only reconfigured when target mode differs from current

**Audio Session Modes (Priority Order):**

| Mode | Priority | Category | AVAudioSession.Mode | Options |
| ---- | -------- | -------- | ------------------- | ------- |
| `sermonRecording` | 3 (highest) | `.playAndRecord` | `.default` | `.defaultToSpeaker`, `.allowBluetoothHFP` |
| `sermonPlayback` | 2 | `.playback` | `.spokenAudio` | none |
| `biblePlayback` | 1 | `.playback` | `.spokenAudio` | none |
| `idle` | 0 (lowest) | - | - | Session deactivated |

**Edge Cases:**

- Audio session interruptions save/restore playback state
- Route changes (headphone unplug) trigger pause
- Invalid cache deleted and regenerated automatically
- Background task protection for TTS generation (10-30s window)
- **Session pop with empty stack**: Deactivates session with `.notifyOthersOnDeactivation`
- **Duplicate owner push**: Removes existing claim before adding new one

---

### 2.2 Circuit Breaker

**Purpose:** Prevents cascading failures during AI service outages by failing fast.

**Source:** `Core/Services/AI/CircuitBreaker.swift`

```mermaid
stateDiagram-v2
    [*] --> closed

    closed --> closed: recordSuccess() / consecutiveFailures = 0
    closed --> closed: recordFailure() [failures < threshold] / failures++
    closed --> open: recordFailure() [failures >= threshold] / failures++, logTripped()

    open --> open: shouldAllowRequest() [!timeoutElapsed] / return false
    open --> halfOpen: shouldAllowRequest() [timeoutElapsed && !trialInFlight] / trialInFlight = true

    halfOpen --> closed: recordSuccess() / failures = 0, trialInFlight = false, logRecovered()
    halfOpen --> open: recordFailure() / trialInFlight = false, logTrialFailed()
    halfOpen --> halfOpen: shouldAllowRequest() [trialInFlight] / return false

    note right of closed
        Normal operation
        Requests flow through
        Counting failures
    end note

    note right of open
        Fail fast mode
        No requests allowed
        Waiting for timeout
    end note

    note right of halfOpen
        Testing recovery
        Single trial request
        Others rejected
    end note
```

**Configuration:**

- `failureThreshold`: 5 consecutive failures
- `resetTimeout`: 60 seconds

**Key Behaviors:**

- Actor isolation ensures thread-safe state transitions
- Single trial request allowed in halfOpen (via `trialRequestInFlight` flag)
- `timeUntilRetry` computed property for UI feedback
- Manual `reset()` available for admin/testing

**Edge Cases:**

- Success in closed state resets failure count
- Failure in open state is no-op (already open)
- `CircuitBreakerError.circuitOpen(retryAfter:)` includes remaining timeout

---

### 2.3 Data Loading

**Purpose:** Manages app initialization data loading with progress tracking.

**Source:** `Core/Services/Bible/DataLoadingService.swift`

```mermaid
stateDiagram-v2
    [*] --> idle

    idle --> loading: initializeData() [!isDataReady] / updatePhase()

    state loading {
        [*] --> initializing
        initializing --> checkingBundledDB: progress = 0.3
        checkingBundledDB --> importingVerses: noBundledDB / loadSampleData()
        checkingBundledDB --> completed: hasBundledDB / copyDB()
        importingVerses --> importingCrossRefs: progress = 0.7
        importingCrossRefs --> importingTopics: progress = 0.9
        importingTopics --> [*]: progress = 1.0

        note right of importingVerses
            Batch size: 5000
            Yield every 10 batches
        end note
    }

    loading --> completed: allImportsSucceed / isDataReady = true
    loading --> failed: importError / captureError()

    idle --> idle: initializeData() [isDataReady] / skip

    note left of completed
        verseCount updated
        Ready for queries
    end note

    note left of failed
        Error message captured
        Non-critical imports can fail
    end note
```

**Key Behaviors:**

- Bundled database used if available (skip imports)
- Sample data fallback: kjv_sample.json, crossrefs_sample.json, topics_sample.json
- Batch processing with main thread yields every 10 batches
- Non-critical imports (cross-refs, topics) don't block completion

**Edge Cases:**

- Already loaded data skips re-initialization
- Progress description changes with each phase
- Error state captures localized description

---

### 2.4 Subscription/Entitlements

**Purpose:** Manages subscription tiers, feature gating, and paywall triggering.

**Sources:** `Core/Services/Purchase/PurchaseService.swift`, `Core/Services/Purchase/EntitlementService.swift`

```mermaid
stateDiagram-v2
    [*] --> free

    state SubscriptionTiers {
        [*] --> free
        free --> premium: purchase(premiumYearly) / verifyTransaction()
        free --> scholar: purchase(scholarYearly) / verifyTransaction()
        premium --> scholar: purchase(scholarYearly) / verifyTransaction()
        premium --> free: subscriptionExpired
        scholar --> free: subscriptionExpired
    }

    state DailyUsage {
        [*] --> tracking
        tracking --> tracking: recordUsage() [!limitReached] / increment()
        tracking --> paywallTriggered: recordUsage() [limitReached && !dismissed] / showPaywall()
        tracking --> tracking: dailyReset() / resetCounters()

        note right of tracking
            Tracked features:
            - aiInsightsUsedToday
            - notesUsedToday
            - prayersGeneratedToday
        end note
    }

    state PaywallTriggers {
        [*] --> monitoring
        monitoring --> shown: aiInsightsLimit / trigger = .aiInsightsLimit
        monitoring --> shown: prayerLimit / trigger = .prayerLimit
        monitoring --> shown: memorizationLimit / trigger = .memorizationLimit
        monitoring --> shown: translationLimit / trigger = .translationLimit
        monitoring --> shown: highlightLimit / trigger = .highlightLimit
        monitoring --> shown: noteLimit / trigger = .noteLimit
        monitoring --> shown: firstSession / trigger = .firstSession
        monitoring --> shown: manual / trigger = .manual
        shown --> dismissed: dismiss() / setDismissedFlag()
        dismissed --> monitoring: newSession
    }

    note right of free
        Limits:
        - AI Insights: 3/day
        - Memorization: 1 verse
        - Notes: 50/day
        - Prayers: 10/day
        - Translations: KJV only
    end note

    note right of premium
        Unlocks:
        - Unlimited insights
        - All translations
        - More prayers (100/day)
    end note

    note right of scholar
        All Premium +
        Hebrew/Greek
        Audio features
    end note
```

**Key Behaviors:**

- Transaction listener continuously monitors StoreKit updates
- JWS signature verification on purchases
- Daily usage resets at midnight UTC
- Paywall dismissal persists for session (per feature)

**Edge Cases:**

- Highlights now unlimited (changed from limited)
- `canAccess()` respects session dismissal flags
- Expired subscriptions detected via `expirationDate` check

---

### 2.5 Notification Authorization

**Purpose:** Manages notification permissions and scheduling following HIG guidelines.

**Source:** `Core/Services/Notification/NotificationService.swift`

```mermaid
stateDiagram-v2
    [*] --> notDetermined

    notDetermined --> authorized: requestAuthorization() [userGrants] / scheduleDefaults()
    notDetermined --> denied: requestAuthorization() [userDenies]
    notDetermined --> provisional: requestProvisional() [userGrants]

    authorized --> authorized: preferencesChanged / reschedule()
    authorized --> [*]

    denied --> authorized: openSettings() [userEnables]
    denied --> denied: requestAuthorization() / showSettingsLink()

    provisional --> authorized: userEngages / upgradePermission()
    provisional --> denied: userDismisses

    state NotificationScheduling {
        [*] --> idle
        idle --> dailyScheduled: enableDailyReminder() / scheduleDaily(time)
        idle --> streakScheduled: enableStreakReminder() / scheduleStreak()
        dailyScheduled --> idle: disableDailyReminder() / cancelDaily()
        streakScheduled --> idle: disableStreakReminder() / cancelStreak()

        note right of dailyScheduled
            Default: 8:00 AM
            Repeating calendar trigger
        end note

        note right of streakScheduled
            Fixed: 8:00 PM
            Repeating calendar trigger
        end note
    }

    note left of notDetermined
        HIG Compliance:
        Defer request until
        contextual moment
    end note

    note left of denied
        Show "Enable" button
        Deep-links to Settings
    end note
```

**Key Behaviors:**

- Permission request deferred until after first session
- Contextual messaging explains value before requesting
- Settings deep-link provided when denied
- Silent failure logging (errors don't crash)

**Edge Cases:**

- Foreground notification presentation handled via delegate
- `.notificationTapped` posted for navigation handling
- Achievement notifications are one-time (not repeating)

---

## 3. UI Component States

### 3.1 Bible Reader Selection

**Purpose:** Manages verse selection modes and context menu for Bible reader interactions.

**Source:** `Features/Bible/ViewModels/BibleReaderViewModel.swift`

```mermaid
stateDiagram-v2
    [*] --> none

    none --> single: selectVerse(v) / selectedVerses = [v]
    none --> range: startRangeSelection(v) / selectionMode = .range, selectedVerses = [v]

    single --> none: selectVerse(same) / selectedVerses = []
    single --> single: selectVerse(different) / selectedVerses = [v]
    single --> range: startRangeSelection(v) / selectionMode = .range

    range --> range: extendSelection(v) [v != anchor] / updateRange()
    range --> none: extendSelection(v) [v == anchor] / clearSelection()
    range --> none: clearSelection() / selectionMode = .none

    state ContextMenu {
        [*] --> hidden
        hidden --> visible: selectionMade / calculateBounds(), show()
        visible --> hidden: actionSelected / executeAction(), clearSelection()
        visible --> hidden: backgroundTap / clearSelection()
        visible --> hidden: menuDismissed

        note right of visible
            Position: MenuPositionCalculator
            Above or below selection
            isAppearing animation
        end note
    }

    state InlineInsight {
        [*] --> closed
        closed --> open: showInlineInsight() / createViewModel()
        open --> closed: hideInlineInsight() / clearViewModel()
    }

    note right of single
        Context menu appears
        Highlight actions available
    end note

    note right of range
        Multi-verse selection
        Computed VerseRange
    end note
```

**Key Behaviors:**

- Single tap toggles selection in single mode
- Long press initiates range selection mode
- Context menu positioned using `MenuPositionCalculator`
- Inline insight panel manages its own view model

**Edge Cases:**

- `existingHighlightColorForSelection` computed for UI display
- `lastHighlightAction` stored for undo capability
- Flash animation (`flashVerseId`) for search navigation

---

### 3.2 Reading Menu Navigation

**Purpose:** Manages reading menu sheet navigation between views.

**Source:** `Features/Bible/Views/ReadingMenu/ReadingMenuState.swift`

```mermaid
stateDiagram-v2
    [*] --> menu

    menu --> search: navigateToSearch() / animation(.snappy)
    menu --> settings: navigateToSettings() / animation(.snappy)
    menu --> insights: navigateToInsights() / animation(.snappy)

    search --> menu: navigateToMenu() / resetSearch(), animation(.snappy)
    settings --> menu: navigateToMenu() / animation(.snappy)
    insights --> menu: navigateToMenu() / animation(.snappy)

    state search {
        [*] --> idle
        idle --> searching: queryChanged [debounced] / createSearchTask()
        searching --> results: searchComplete / updateResults()
        searching --> idle: searchCancelled / cancelTask()
        results --> searching: queryChanged / cancelTask(), createSearchTask()
        results --> idle: clearQuery / resetSearch()
    }

    state settings {
        [*] --> collapsed
        collapsed --> expanded: showAdvanced() / animate()
        expanded --> collapsed: hideAdvanced() / animate()
    }

    note right of menu
        Main menu view
        Navigation hub
    end note

    note right of search
        Debounced search
        Cancellable task
    end note
```

**Key Behaviors:**

- All navigation uses `.snappy(duration: 0.3, extraBounce: 0)` animation
- Search reset on returning to menu
- Search task is cancellable (stored as `searchTask`)
- Advanced settings toggle in settings view

**Edge Cases:**

- Query changes cancel in-flight search and start new
- `isSearching` flag tracks loading state

---

### 3.3 Ask Chat

**Purpose:** Manages AI chat with input validation, moderation, guardrails, and uncertainty tracking.

**Source:** `Features/Ask/AskViewModel.swift`

```mermaid
stateDiagram-v2
    [*] --> empty

    empty --> inputReady: focusInput

    state inputReady {
        [*] --> validating
        validating --> valid: validate() [length 2-2000 && !blocked]
        validating --> tooShort: validate() [length < 2]
        validating --> tooLong: validate() [length > 2000]
        validating --> rateLimited: validate() [recentMessage]
        validating --> blocked: validate() [violations >= 3]
    }

    inputReady --> sending: send() [valid] / addUserMessage()

    state sending {
        [*] --> moderating
        moderating --> generating: clean / buildHistory(), callAI()
        moderating --> crisisResponse: selfHarmDetected / addCrisisResponse()
        moderating --> refusalResponse: flagged / recordViolation(), addRefusal()
        generating --> outputModeration: responseReceived
        outputModeration --> displaying: clean OR hasScriptureCitations
        outputModeration --> displaying: flagged [hasCitations && !selfHarm] / logExemption()
        outputModeration --> safeOutput: flagged [!hasCitations || selfHarm] / replaceWithSafe()
        safeOutput --> displaying
    }

    sending --> inputReady: success / updateThread(), showFollowUps()
    sending --> inputReady: error / handleError(), restoreInput()

    crisisResponse --> inputReady: displayed
    refusalResponse --> inputReady: displayed / checkBlocked()

    state ChatModes {
        [*] --> general
        general --> verseAnchored: setAnchor(range) / loadVerseText()
        verseAnchored --> general: clearAnchor()
    }

    state UncertaintyDisplay {
        [*] --> none
        none --> low: setUncertainty(.low)
        none --> medium: setUncertainty(.medium)
        none --> high: setUncertainty(.high)
        low --> none: newMessage
        medium --> none: newMessage
        high --> none: newMessage

        note right of medium
            "Interpretations vary"
            Badge shown
        end note

        note right of high
            "Significant debate exists"
            Badge shown
        end note
    }

    note left of blocked
        3 violations in 30 min
        30-minute cooldown
        Stored in UserDefaults
    end note
```

**Key Behaviors:**

- Input moderation via FREE OpenAI Moderation API
- Crisis detection triggers hardcoded support response
- Citation validation filters hallucinated references
- Uncertainty downgrade if citations missing but verses mentioned

**Edge Cases:**

- Scripture study exemption: flagged output allowed if has valid citations (self-harm NEVER exempted)
- Violation tracking with 30-minute rolling window
- Follow-up suggestions generated by AI
- Token budget management via conversation windowing

---

### 3.4 Memorization

**Purpose:** Manages verse memorization with SM-2 spaced repetition, hint progression, and mastery tracking.

**Sources:** `Core/Services/Study/MemorizationService.swift`, `Features/Memorize/MemorizeView.swift`

```mermaid
stateDiagram-v2
    [*] --> learning

    state MasteryLevels {
        [*] --> learning
        learning --> reviewing: reps >= 2 && accuracy >= 0.7
        reviewing --> mastered: reps >= 5 && accuracy >= 0.9 && interval >= 21
        mastered --> reviewing: qualityDrop [quality < 3]
        reviewing --> learning: qualityDrop [quality < 3]

        note right of learning
            Frequent review
            Short intervals
        end note

        note right of reviewing
            Spaced review
            SM-2 intervals
        end note

        note right of mastered
            Infrequent review
            Long intervals
        end note
    }

    state PracticeSession {
        [*] --> showPrompt
        showPrompt --> hintLevel0: startPractice()
        hintLevel0 --> hintLevel1: needMoreHint() / revealMore()
        hintLevel1 --> hintLevel2: needMoreHint() / revealMore()
        hintLevel2 --> hintLevel3: needMoreHint() / revealFull()
        hintLevel3 --> answerCheck: showAnswer() OR submitAnswer()

        state answerCheck {
            [*] --> checking
            checking --> correct: similarity >= 0.95
            checking --> almostCorrect: similarity >= 0.90
            checking --> partiallyCorrect: similarity >= 0.70
            checking --> incorrect: similarity < 0.70
        }

        correct --> rateQuality: showRating()
        almostCorrect --> rateQuality: showRating()
        partiallyCorrect --> rateQuality: showRating()
        incorrect --> rateQuality: showRating()

        rateQuality --> complete: selectQuality(q) / updateSM2(), awardXP()
    }

    state HintProgression {
        [*] --> level0
        level0: "I___ t__ b________"
        level1: "In__ th_ be________"
        level2: "In t___ the begi____"
        level3: "In the beginning"

        level0 --> level1: +1
        level1 --> level2: +1
        level2 --> level3: +1
        level3 --> level2: -1
        level2 --> level1: -1
        level1 --> level0: -1

        note left of level0
            First letter only
        end note

        note left of level1
            30% revealed
        end note

        note left of level2
            60% revealed
        end note

        note left of level3
            Full text
        end note
    }

    state ReviewQuality {
        q0: "Complete blackout"
        q1: "Incorrect but remembered"
        q2: "Incorrect, easy recall"
        q3: "Correct with difficulty"
        q4: "Correct with hesitation"
        q5: "Perfect recall"

        note right of q0
            Reset: interval = 1
            reps = 0
        end note

        note right of q5
            Optimal: interval *= easeFactor
            reps++
        end note
    }

    note left of complete
        Update nextReviewDate
        Award XP via ProgressService
        Check mastery level change
    end note
```

**Key Behaviors:**

- SM-2 algorithm for spaced repetition scheduling
- Hint levels 0-3 with progressive text reveal
- Answer similarity checked via string comparison
- XP awarded on completion via `ProgressService`

**Edge Cases:**

- Quality < 3 resets interval to 1 day, repetitions to 0
- Ease factor has minimum of 1.3
- Mastery level changes trigger celebration
- Due items computed from `nextReviewDate`

---

## Appendix: State Enum Reference

### Phase-Based Flows

| Component | Enum | Values |
| --------- | ---- | ------ |
| Prayer | `PrayerFlowPhase` | input, generating, displaying |
| Sermon | `SermonFlowPhase` | input, recording, importing, processing(ProcessingStep), viewing, error(SermonError) |
| Sermon Processing | `ProcessingStep` | uploading(Double), transcribing(Double, Int, Int), moderating, analyzing, saving |
| Sermon Status | `SermonStatus` | pending, processing, ready, degraded, error |
| Breathing | `BreathingPhase` | idle, inhale, hold1, exhale, hold2 |
| Auth | (implicit) | signIn, signUp, resetPassword, emailConfirmation, biometricOptIn |
| Auth Password | `PasswordIllumination` | blank, rawPigment, groundPigment, gilded, illuminated |
| Onboarding | `OnboardingStep` | valueProps, nameEntry, goalQuiz, personalization |

### Service-Level

| Component | Enum | Values |
| --------- | ---- | ------ |
| Audio | `PlaybackState` | idle, loading, ready, playing, paused, finished, error |
| Audio Session | `AudioSessionMode` | idle, biblePlayback, sermonPlayback, sermonRecording |
| Circuit Breaker | `State` | closed, open, halfOpen |
| Data Loading | `DataLoadingPhase` | idle, loading(String, Double), completed, failed(String) |
| Subscription | `SubscriptionTier` | free, premium, scholar |
| Notification | `UNAuthorizationStatus` | notDetermined, denied, authorized, provisional, ephemeral |

### UI Components

| Component | Enum | Values |
| --------- | ---- | ------ |
| Bible Reader | `BibleSelectionMode` | none, single, range |
| Reading Menu | `MenuView` | menu, search, settings, insights |
| Ask Chat | `ChatMode` | general, verseAnchored |
| Ask Validation | `InputValidation` | valid, tooShort, tooLong, rateLimited, blocked |
| Ask Response | `ResponseType` | answer, clarification, crisisSupport, refusalSafety |
| Ask Uncertainty | `UncertaintyLevel` | low, medium, high |
| Memorization | `MasteryLevel` | learning, reviewing, mastered |
| Memorization | `AnswerResult` | correct, almostCorrect(Double), partiallyCorrect(Double), incorrect |
| Memorization | `ReviewQuality` | 0-5 (completeBlackout to perfectRecall) |

---

*Generated for BibleStudy iOS App - Documentation of state machine architecture*
