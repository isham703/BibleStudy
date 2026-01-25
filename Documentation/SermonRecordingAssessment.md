# Sermon Recording Feature - Comprehensive Assessment

## Executive Summary

The Sermon Recording feature is a **fully implemented, production-ready** system within the BibleStudy iOS app. It enables users to record or import audio sermons, automatically transcribe them via OpenAI's Whisper API, and generate AI-powered study guides with discussion questions, themes, scripture references, and reflection prompts.

**Key Statistics:**
- **13 Swift files** (~4,500+ lines of code)
- **6 UI phases** with animated transitions
- **4 core services** managing recording, transcription, processing, and sync
- **5 data models** with full GRDB and Supabase integration
- **19 error types** with user-friendly messages and recovery suggestions

---

## Table of Contents

1. [Feature Overview](#1-feature-overview)
2. [Architecture Summary](#2-architecture-summary)
3. [Data Models](#3-data-models)
4. [Service Layer](#4-service-layer)
5. [User Interface](#5-user-interface)
6. [Processing Pipeline](#6-processing-pipeline)
7. [User Journey](#7-user-journey)
8. [Technical Specifications](#8-technical-specifications)
9. [File Reference](#9-file-reference)
10. [Design System Integration](#10-design-system-integration)
11. [Detailed UI Implementation](#11-detailed-ui-implementation)
12. [Exact Code References](#12-exact-code-references)

---

## 1. Feature Overview

### Purpose

The Sermon Recording feature transforms audio sermons into structured study materials. Users can:

1. **Record** live sermons directly in the app with real-time waveform visualization
2. **Import** pre-recorded audio files (MP3, M4A, WAV)
3. **Transcribe** audio to text with word-level timestamps via Whisper API
4. **Generate** AI study guides with:
   - Summary and key themes
   - Sermon outline with timestamps
   - Notable quotes with context
   - Scripture references (mentioned and suggested)
   - Discussion questions by type (comprehension, interpretation, application, discussion)
   - Reflection prompts and application points
5. **Review** transcripts with audio-synced highlighting
6. **Bookmark** key moments with timestamps and notes

### Value Proposition

The feature bridges the gap between passive sermon listening and active Bible study, enabling users to:
- Capture sermons for personal review without note-taking during the service
- Navigate long recordings via searchable, timestamped transcripts
- Engage deeper with AI-generated study questions and prompts
- Build a personal library of analyzed sermons with scripture cross-references

---

## 2. Architecture Summary

### Design Patterns

| Pattern | Implementation | Purpose |
|---------|---------------|---------|
| **State Machine** | `SermonFlowState` | Manage UI phases and transitions |
| **MVVM** | `@Observable` classes with `@MainActor` | SwiftUI state management |
| **Offline-First** | GRDB local → Supabase sync | Reliable data persistence |
| **Actor** | `SermonProcessingQueue` | Thread-safe background processing |
| **Singleton Services** | Recording, Sync, Processing | Centralized resource management |
| **Protocol-Based DI** | `AIServiceProtocol` | Testable AI integration |

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SermonView (Container)                                    │  │
│  │  ├─ SermonInputPhase      (Record/Import)                │  │
│  │  ├─ SermonRecordingPhase  (Live Recording)               │  │
│  │  ├─ SermonProcessingPhase (Progress Display)             │  │
│  │  └─ SermonViewingPhase    (Results Display)              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     State Management                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SermonFlowState (@MainActor @Observable)                  │  │
│  │  • Phase transitions (input → recording → processing → viewing) │
│  │  • Recording control (start/pause/resume/stop)           │  │
│  │  • Progress tracking (0-100% across 5 steps)             │  │
│  │  • Error handling (19 error types with recovery)         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Service Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Recording       │  │ Transcription   │  │ Processing      │  │
│  │ Service         │  │ Service         │  │ Queue           │  │
│  │                 │  │                 │  │                 │  │
│  │ • AVAudioRec.   │  │ • Whisper API   │  │ • Job orchestr. │  │
│  │ • Chunking      │  │ • Multi-chunk   │  │ • Study guide   │  │
│  │ • Metering      │  │ • Timestamps    │  │ • Progress CB   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ SermonSyncService                                         │  │
│  │  • GRDB local cache ↔ Supabase sync                       │  │
│  │  • Audio upload to Supabase Storage                       │  │
│  │  • 2GB LRU audio cache with eviction                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Data Layer                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Local (GRDB)    │  │ Remote          │  │ Storage         │  │
│  │                 │  │ (Supabase DB)   │  │ (Supabase)      │  │
│  │ • sermons       │  │                 │  │                 │  │
│  │ • transcripts   │  │ • Mirror schema │  │ • Audio chunks  │  │
│  │ • study_guides  │  │ • RLS policies  │  │ • Signed URLs   │  │
│  │ • audio_chunks  │  │ • User isolation│  │ • User buckets  │  │
│  │ • bookmarks     │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Data Models

### 3.1 Sermon (Primary Record)

**File:** `Features/Sermon/Models/Sermon.swift`

The central model representing a recorded or imported sermon.

```swift
struct Sermon: Identifiable, Hashable, Sendable, FetchableRecord, PersistableRecord {
    // Identity
    let id: UUID
    let userId: UUID
    var title: String
    var speakerName: String?
    let recordedAt: Date
    var durationSeconds: Int

    // Audio Metadata
    var localAudioPath: String?      // Local file system path
    var remoteAudioPath: String?     // Supabase Storage path
    var audioFileSize: Int?          // Bytes
    var audioMimeType: String?       // "audio/m4a", "audio/mpeg"
    var audioCodec: String?          // "aac", "mp3"
    var audioBitrateKbps: Int?       // 32, 64, 128
    var audioContentHash: String?    // SHA-256 for integrity

    // Processing Status
    var transcriptionStatus: ProcessingStatus  // pending → running → succeeded/failed
    var transcriptionError: String?
    var studyGuideStatus: ProcessingStatus
    var studyGuideError: String?
    var processingVersion: String    // For future migration/reprocessing

    // Content
    var scriptureReferences: [String]  // Extracted Bible references

    // Sync Tracking
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?             // Soft delete timestamp
    var needsSync: Bool              // Pending remote sync
    var audioNeedsUpload: Bool       // Pending audio upload
}
```

**Computed Properties:**
- `isProcessing` - Either transcription or study guide is running
- `isComplete` - Both succeeded
- `hasError` - Either failed
- `displayTitle` - Title or fallback based on date
- `formattedDuration` - Human-readable "1:23:45"

**ProcessingStatus Enum:**
```swift
enum ProcessingStatus: String, Codable {
    case pending, running, succeeded, failed
}
```

### 3.2 SermonTranscript

**File:** `Features/Sermon/Models/SermonTranscript.swift`

Stores the complete transcription with word-level timing for audio sync.

```swift
struct SermonTranscript: Identifiable, Hashable, Sendable {
    let id: UUID
    let sermonId: UUID
    var content: String              // Full transcript text
    var language: String             // "en", etc.
    var wordTimestamps: [WordTimestamp]  // Per-word timing
    var modelUsed: String?           // "whisper-1"
    var confidenceScore: Double?     // 0.0-1.0

    // Sync
    let createdAt: Date
    var updatedAt: Date
    var needsSync: Bool
}
```

**WordTimestamp:**
```swift
struct WordTimestamp: Codable, Hashable, Sendable {
    let word: String
    let start: Double  // Seconds from audio start
    let end: Double
}
```

**Key Methods:**
- `wordIndex(at time: Double)` - Find word at playback position
- `segmentIndex(at time: Double)` - Find display segment at position
- `segments: [TranscriptDisplaySegment]` - ~12-second grouped segments for UI

**TranscriptDisplaySegment:**
```swift
struct TranscriptDisplaySegment: Identifiable {
    let id: Int                      // Segment index
    let text: String                 // Combined word text
    let startTime: Double
    let endTime: Double
    let wordRange: Range<Int>        // Index range in wordTimestamps
}
```

### 3.3 SermonStudyGuide

**File:** `Features/Sermon/Models/SermonStudyGuide.swift`

AI-generated study content based on the transcript.

```swift
struct SermonStudyGuide: Identifiable, Hashable, Sendable {
    let id: UUID
    let sermonId: UUID
    var content: StudyGuideContent   // The actual guide data
    var modelUsed: String?           // "gpt-4o"
    var promptVersion: String        // For versioned prompts
    var transcriptHash: String?      // Cache key to detect changes

    // Sync
    let createdAt: Date
    var updatedAt: Date
    var needsSync: Bool
}
```

**StudyGuideContent (JSON-encoded):**
```swift
struct StudyGuideContent: Codable, Hashable, Sendable {
    let title: String
    let summary: String
    let keyThemes: [String]

    // Navigation
    let outline: [OutlineSection]?
    let notableQuotes: [Quote]?

    // Scripture
    let bibleReferencesMentioned: [SermonVerseReference]  // Explicitly spoken
    let bibleReferencesSuggested: [SermonVerseReference]  // AI-inferred

    // Study Prompts
    let discussionQuestions: [StudyQuestion]
    let reflectionPrompts: [String]
    let applicationPoints: [String]

    // Diagnostics
    let confidenceNotes: [String]?
}
```

**Supporting Types:**

```swift
struct OutlineSection: Codable, Identifiable {
    let id: String
    let title: String
    let startSeconds: Double
    let endSeconds: Double
    let summary: String?
}

struct Quote: Codable, Identifiable {
    let id: String
    let text: String
    let timestampSeconds: Double
    let context: String?
}

struct SermonVerseReference: Codable, Identifiable {
    let id: String
    let reference: String         // "John 3:16"
    let bookId: Int?
    let chapter: Int?
    let verses: [Int]?
    let isMentioned: Bool         // false = AI-suggested
    let rationale: String?        // Why AI suggested this
    let timestampSeconds: Double? // When mentioned
}

struct StudyQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let type: QuestionType        // comprehension, interpretation, application, discussion
    let relatedVerses: [String]?
    let discussionHint: String?
}
```

### 3.4 SermonAudioChunk

**File:** `Features/Sermon/Models/SermonAudioChunk.swift`

Individual audio segments for Whisper API compliance and resumable uploads.

```swift
struct SermonAudioChunk: Identifiable, Hashable, Sendable {
    let id: UUID
    let sermonId: UUID
    let chunkIndex: Int              // 0, 1, 2, ...
    var startOffsetSeconds: Double   // Global timeline offset
    var durationSeconds: Double

    // Paths
    var localPath: String?           // ~/Documents/Sermons/{id}/chunk_000.m4a
    var remotePath: String?          // {userId}/{sermonId}/chunk_000.m4a

    // File Metadata
    var fileSize: Int?
    var contentHash: String?         // SHA-256

    // Upload Tracking
    var uploadStatus: ChunkUploadStatus  // pending → uploading → succeeded/failed
    var uploadError: String?
    var uploadProgress: Double       // 0.0 - 1.0

    // Transcription Tracking
    var transcriptionStatus: ProcessingStatus
    var transcriptionError: String?
    var transcriptSegment: TranscriptSegment?  // This chunk's transcript

    // UI
    var waveformSamples: [Float]?    // ~100 normalized values for visualization

    // Sync
    let createdAt: Date
    var updatedAt: Date
    var needsSync: Bool
}
```

**Computed Properties:**
- `endOffsetSeconds` - startOffsetSeconds + durationSeconds

### 3.5 SermonBookmark

**File:** `Features/Sermon/Models/SermonBookmark.swift`

User annotations at specific timestamps.

```swift
struct SermonBookmark: Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    let sermonId: UUID
    var timestampSeconds: Double     // Position in audio
    var note: String?
    var label: BookmarkLabel?
    var verseReference: VerseReferenceData?  // Linked scripture

    // Sync
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?             // Soft delete
    var needsSync: Bool
}
```

**BookmarkLabel:**
```swift
enum BookmarkLabel: String, Codable, CaseIterable {
    case keyPoint, question, highlight, note

    var icon: String       // SF Symbol name
    var displayName: String
    var color: Color
}
```

### 3.6 SermonError

**File:** `Features/Sermon/Models/SermonError.swift`

Comprehensive error handling with user-facing messages.

```swift
enum SermonError: Error, LocalizedError, Sendable {
    // Recording (4)
    case microphonePermissionDenied
    case recordingFailed(underlying: Error?)
    case recordingInterrupted
    case audioSessionFailed(underlying: Error?)

    // Import (4)
    case importFailed(underlying: Error?)
    case unsupportedAudioFormat(format: String)
    case fileTooLarge(sizeMB: Int, maxMB: Int)
    case fileNotFound

    // Processing (5)
    case transcriptionFailed(underlying: Error?)
    case transcriptionTimedOut
    case studyGuideGenerationFailed(underlying: Error?)
    case moderationFailed(underlying: Error?)
    case contentFlagged(reason: String)

    // Network (3)
    case uploadFailed(underlying: Error?)
    case downloadFailed(underlying: Error?)
    case networkUnavailable
    case syncFailed(underlying: Error?)

    // Storage (3)
    case storageFull
    case fileCorrupted
    case cacheError(underlying: Error?)

    // Database (2)
    case databaseError(underlying: Error?)
    case sermonNotFound
    case chunkNotFound

    // Auth (2)
    case notAuthenticated
    case authorizationFailed
}
```

**Properties:**

- `errorDescription` - User-friendly message
- `recoverySuggestion` - Actionable guidance
- `isRetryable` - Whether retry might succeed
- `shouldShowRetryButton` - UI hint

### 3.7 SermonStatus (Centralized Status Logic)

**File:** `Features/Sermon/Core/SermonStatus.swift`

Single source of truth for sermon display status, consolidating logic from multiple UI locations.

```swift
enum SermonStatus: Equatable, Sendable {
    case pending      // Not yet started processing
    case processing   // Transcription or study guide in progress
    case ready        // Both transcription and study guide succeeded
    case degraded     // Transcription OK, study guide failed (viewable + retry)
    case error        // Transcription failed (unrecoverable)
}
```

**Status Derivation Logic:**

| Condition | Status |
| --------- | ------ |
| `transcriptionStatus == .failed` | `.error` |
| `transcriptionStatus == .running` OR `studyGuideStatus == .running` | `.processing` |
| `transcriptionStatus == .pending` AND `studyGuideStatus == .pending` | `.pending` |
| `transcriptionStatus == .succeeded` AND `studyGuideStatus == .failed` | `.degraded` |
| `transcriptionStatus == .succeeded` AND `studyGuideStatus == .succeeded` | `.ready` |
| `transcriptionStatus == .succeeded` (other) | `.processing` |

**Computed Properties:**

- `isViewable` → `.ready` or `.degraded` (user can view transcript)
- `isProcessing` → `.processing`
- `canRetryStudyGuide` → `.degraded` (retry affordance)
- `displayText` → Human-readable status ("Ready", "Transcript Ready", etc.)
- `accessibilityLabel` → VoiceOver description

**Usage:**
```swift
// Extension on Sermon model
extension Sermon {
    var status: SermonStatus {
        SermonStatus.from(self)
    }
}

// In views
if sermon.status.isViewable {
    // Show transcript and study guide
}
```

### 3.8 SermonConfiguration (Centralized Constants)

**File:** `Features/Sermon/Core/SermonConfiguration.swift`

Centralizes hardcoded values scattered across the Sermon feature for maintainability.

```swift
enum SermonConfiguration {
    // Recording
    static let chunkDurationSeconds: TimeInterval = 10 * 60  // 10 minutes
    static let maxChunkFileSizeBytes: Int = 25 * 1024 * 1024 // 25 MB (Whisper limit)
    static let estimatedBytesPerMinute: Int = 240_000        // ~240 KB/min at 32kbps

    // Validation
    static let maxAudioDurationMinutes: Int = 30

    // Transcript
    static let segmentDurationSeconds: TimeInterval = 12.0

    // Cache
    static let maxCacheEntries: Int = 50

    // Timeouts
    static let processingTimeoutSeconds: TimeInterval = 30 * 60  // 30 minutes
}
```

**Benefits:**

- Single location to adjust thresholds
- Clear documentation of API constraints (Whisper 25MB limit)
- Easier testing with different values

---

## 4. Service Layer

### 4.1 SermonRecordingService

**File:** `Core/Services/Sermon/SermonRecordingService.swift`
**Lines:** ~515

Manages in-app audio recording with automatic chunking to stay under Whisper's 25MB limit.

**Singleton Pattern:**
```swift
@MainActor
@Observable
final class SermonRecordingService: NSObject, AVAudioRecorderDelegate {
    static let shared = SermonRecordingService()
}
```

**Recording Configuration:**
```swift
struct RecordingConfiguration {
    var chunkDurationMinutes: Int = 10      // Split every 10 minutes
    var sampleRate: Double = 16000          // 16kHz for speech
    var numberOfChannels: Int = 1           // Mono
    var bitRate: Int = 32000                // 32kbps
    var maxFileSizeMB: Int = 25             // Whisper API limit
}
```

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `requestMicrophonePermission()` | iOS 17+ async permission, with fallback |
| `startRecording(sermonId:configuration:)` | Initialize recorder, start metering |
| `pauseRecording()` | Pause without finalizing |
| `resumeRecording()` | Resume from pause |
| `stopRecording() -> [URL]` | Finalize all chunks, return file URLs |
| `cancelRecording()` | Delete all chunks and directory |
| `startMetering(onLevel:)` | Continuous audio level callbacks |

**Audio Level Metering:**
- Polls AVAudioRecorder every 0.1s
- Normalizes -60dB to 0dB → 0.0 to 1.0
- Emits via callback for waveform visualization

**Chunking Logic:**
- Creates new AVAudioRecorder when chunk duration exceeded
- Maintains array of chunk URLs
- Each chunk named `chunk_{index:03d}.m4a`

### 4.2 TranscriptionService

**File:** `Core/Services/Sermon/TranscriptionService.swift`
**Lines:** ~305

Interfaces with OpenAI's Whisper API for speech-to-text.

**Singleton Pattern:**
```swift
final class TranscriptionService {
    static let shared = TranscriptionService()
}
```

**Key Types:**

```swift
struct TranscriptionInput {
    let audioURL: URL
    let language: String?
    let prompt: String?      // Context for better accuracy
}

struct TranscriptionOutput {
    let text: String
    let language: String
    let duration: Double
    let segments: [TranscriptionSegment]
    let words: [WordTimestamp]  // Converted from segments
}
```

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `transcribe(input:onProgress:)` | Single file → Whisper API |
| `transcribeChunks(chunkURLs:onProgress:)` | Multi-file with offset merging |

**Whisper API Integration:**
- Endpoint: `POST https://api.openai.com/v1/audio/transcriptions`
- Model: `whisper-1`
- Response format: `verbose_json` (for timestamps)
- Timestamp granularity: `segment` (with word estimation)

**Multi-Chunk Processing:**
1. Process chunks sequentially
2. Use previous chunk's last text as prompt for context
3. Offset segment timestamps by cumulative duration
4. Merge all segments into single output

### 4.3 SermonProcessingQueue

**File:** `Core/Services/Sermon/SermonProcessingQueue.swift`
**Lines:** ~575

Actor-based background processing with job tracking and resumability.

**Actor Pattern (Thread-Safe):**
```swift
actor SermonProcessingQueue {
    static let shared = SermonProcessingQueue()
}
```

**Job Tracking:**
```swift
struct SermonProcessingJob {
    let sermonId: UUID
    var transcriptionStatus: ProcessingStatus
    var studyGuideStatus: ProcessingStatus
    var chunkStatuses: [ChunkStatus]
    var overallProgress: Double  // 0.0 - 1.0
}
```

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `enqueue(sermonId:)` | Add sermon to processing queue |
| `resumePendingJobs()` | On app launch, resume incomplete jobs |
| `registerProgressCallback(id:callback:)` | Subscribe to progress updates |
| `unregisterProgressCallback(id:)` | Unsubscribe |
| `getStatus(sermonId:)` | Poll current job state |

**Processing Steps (Private):**

1. **Upload Chunks** (0-20% progress)
   - Mark chunks for upload
   - SermonSyncService handles actual upload

2. **Transcription** (20-70% progress)
   - Transcribe each chunk via TranscriptionService
   - Merge with time offsets
   - Save to database
   - Update sermon.transcriptionStatus

3. **Study Guide Generation** (70-95% progress)
   - Extract Bible references via regex
   - Call OpenAIProvider.generateSermonStudyGuide()
   - Save to database
   - Update sermon.studyGuideStatus

4. **Completion** (95-100%)
   - Emit final progress callback
   - Process next queued job

**Regex Pattern for Bible References:**
```swift
let pattern = #"(?:\d\s+)?[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?\s+\d+:\d+(?:-\d+)?"#
// Matches: "John 3:16", "1 Corinthians 13:4-7", "2 Kings 5:10"
```

### 4.4 SermonSyncService

**File:** `Core/Services/Sermon/SermonSyncService.swift`
**Lines:** ~650

Offline-first data synchronization between local GRDB and Supabase.

**Singleton Pattern:**
```swift
final class SermonSyncService {
    static let shared = SermonSyncService()
}
```

**Key Responsibilities:**

| Area | Methods |
|------|---------|
| **Sermons** | `loadSermons()`, `saveSermon()`, `deleteSermon()` |
| **Transcripts** | `loadTranscript(sermonId:)`, `saveTranscript()` |
| **Study Guides** | `loadStudyGuide(sermonId:)`, `saveStudyGuide()` |
| **Bookmarks** | `getBookmarks(sermonId:)`, `addBookmark()`, `updateBookmark()`, `deleteBookmark()` |
| **Audio** | `uploadChunk()`, `downloadChunk()`, `getChunkURLs()` |
| **Sync** | `syncWithRemote()`, `pushLocalChanges()` |

**Audio Storage:**
- **Local path:** `~/Documents/Sermons/{sermonId}/chunk_{index:03d}.m4a`
- **Remote path:** `{userId}/{sermonId}/chunk_{index:03d}.m4a`
- **Signed URLs:** 1-hour expiration for playback

**Cache Management:**
- **Location:** `~/Library/Caches/SermonAudio/`
- **Max size:** 2GB
- **Eviction:** LRU (Least Recently Used)

**Sync Flow:**
1. Check network connectivity
2. Refresh JWT if needed
3. Fetch remote sermons for user
4. Merge with local (remote wins on conflict)
5. Push local changes where `needsSync = true`
6. Upload audio where `audioNeedsUpload = true`

### 4.5 Audio Session Ownership Model

**File:** `Core/Services/Audio/AudioService.swift`

The app uses a **stack-based audio session ownership model** to coordinate between Bible audio playback, sermon playback, and sermon recording.

**AudioSessionMode Enum:**

```swift
enum AudioSessionMode: Int, Comparable {
    case idle = 0           // No active audio
    case biblePlayback = 1  // Bible audio playback
    case sermonPlayback = 2 // Sermon audio playback
    case sermonRecording = 3 // Sermon recording (highest priority)
}
```

**Priority-Based Ownership:**

| Mode               | Priority | Category       | Options            |
| ------------------ | -------- | -------------- | ------------------ |
| `idle`             | 0        | -              | -                  |
| `biblePlayback`    | 1        | playback       | mixWithOthers      |
| `sermonPlayback`   | 2        | playback       | duckOthers         |
| `sermonRecording`  | 3        | playAndRecord  | allowBluetoothHFP  |

**Stack-Based Push/Pop API:**

```swift
// Claim audio session (pushes onto stack)
AudioService.shared.pushAudioSession(mode: .sermonRecording, owner: "SermonRecordingService")

// Release audio session (pops from stack, restores previous mode)
AudioService.shared.popAudioSession(owner: "SermonRecordingService")
```

**Key Behaviors:**

- Highest-priority mode on stack wins (recording > playback)
- Idempotent: same owner pushing same mode is no-op
- Pop restores previous mode automatically
- Handles interruptions (phone calls, Siri) via NotificationCenter

**Usage in Sermon Feature:**

| Component                | Mode                | When              |
| ------------------------ | ------------------- | ----------------- |
| `SermonRecordingService` | `.sermonRecording`  | During recording  |
| `SermonViewingViewModel` | `.sermonPlayback`   | During playback   |

---

## 5. User Interface

### 5.1 Phase Architecture

The UI follows a phase-based state machine with animated transitions.

```
┌─────────────────────────────────────────────────────────────┐
│                     SermonView (Container)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ SermonFlowState.phase                                  │  │
│  │  ├─ .input      → SermonInputPhase                    │  │
│  │  ├─ .recording  → SermonRecordingPhase                │  │
│  │  ├─ .importing  → (Import validation UI)              │  │
│  │  ├─ .processing → SermonProcessingPhase               │  │
│  │  ├─ .viewing    → SermonViewingPhase                  │  │
│  │  └─ .error      → Error alert with retry option       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  Additional Sheets:                                         │
│  └─ SermonLibraryView (Browse saved sermons)               │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 SermonFlowState

**File:** `Features/Sermon/Core/SermonFlowState.swift`
**Lines:** ~650

The central `@MainActor @Observable` class managing all UI state.

**Phase Enum:**
```swift
enum SermonFlowPhase: Equatable {
    case input
    case recording
    case importing
    case processing(ProcessingStep)
    case viewing
    case error(SermonError)
}
```

**ProcessingStep Enum:**
```swift
enum ProcessingStep: Equatable {
    case uploading(progress: Double)
    case transcribing(progress: Double, chunk: Int, total: Int)
    case moderating
    case analyzing
    case saving

    var overallProgress: Double {
        switch self {
        case .uploading(let p):     return 0.0 + (p * 0.20)
        case .transcribing(let p, _, _): return 0.20 + (p * 0.50)
        case .moderating:           return 0.75
        case .analyzing:            return 0.85
        case .saving:               return 0.95
        }
    }
}
```

**Published State:**
```swift
@Observable
final class SermonFlowState {
    var phase: SermonFlowPhase = .input
    var currentSermon: Sermon?
    var transcript: SermonTranscript?
    var studyGuide: SermonStudyGuide?
    var audioChunks: [SermonAudioChunk] = []
    var bookmarks: [SermonBookmark] = []

    // Recording state
    var isRecording = false
    var isPaused = false
    var recordingDuration: TimeInterval = 0
    var audioLevels: [Float] = []

    // Error state
    var error: SermonError?
    var showingError = false
}
```

**Key Methods:**
| Method | Action |
|--------|--------|
| `startRecording()` | Request mic, create sermon, begin recording |
| `pauseRecording()` | Pause audio capture |
| `resumeRecording()` | Resume from pause |
| `stopRecording()` | Finalize chunks, start processing |
| `cancelRecording()` | Discard all data |
| `importAudio(from:)` | Validate and process imported file |
| `addBookmark()` | Create timestamp annotation |
| `loadExistingSermon(sermon:)` | Load from library |
| `retry()` | Retry failed processing |
| `reset()` | Return to input phase |

### 5.3 Phase Views

#### SermonInputPhase
**Purpose:** Entry point for recording or importing

**UI Elements:**
- Illuminated microphone icon with pulsing glow
- Title input field (optional)
- Speaker name input field (optional)
- "Begin Recording" button (primary CTA)
- "Import Audio" button (secondary CTA)
- "My Sermons" button (opens library)

#### SermonRecordingPhase
**Purpose:** Live recording with visual feedback

**UI Elements:**
- Real-time waveform visualization (40 bars)
- Recording timer (HH:MM:SS)
- Pulsing red recording indicator
- Pause/Resume button
- Stop button
- "Bookmark Moment" button
- Current chunk indicator

#### SermonProcessingPhase
**Purpose:** Progress visualization during AI processing

**UI Elements:**
- Animated illuminated initial
- Overall progress bar (gold gradient fill, no shimmer per Theme doctrine)
- Current step label
- Step checklist:
  - ✓ Uploaded
  - ◉ Transcribing... (chunk 2 of 4)
  - ○ Analyzing
  - ○ Generating guide

#### SermonViewingPhase
**Purpose:** Display completed sermon with study materials

**UI Elements:**
- Header: Title, speaker, duration, date
- Audio player with waveform scrubber
- Play/pause, ±15s seek buttons
- Transcript view with:
  - Drop cap first letter
  - ~12-second segments
  - Current segment highlighting
  - Tap-to-seek functionality
- Collapsible study guide sections:
  - Summary & Key Themes
  - Sermon Outline (with timestamps)
  - Notable Quotes
  - Scripture References (mentioned vs suggested)
  - Discussion Questions (by type)
  - Reflection Prompts
  - Application Points
- Bookmark list
- Action buttons: Copy, Share, Export

### 5.4 SermonLibraryView

**Purpose:** Browse and manage saved sermons

**UI Elements:**
- Search bar (title, speaker)
- Sermon list with:
  - Title
  - Speaker name
  - Date
  - Duration
  - Processing status indicator
- Empty state message
- Loading indicator
- Selection callback to load sermon

---

## 6. Processing Pipeline

### 6.1 Recording Flow

```
User taps "Begin Recording"
          │
          ▼
┌─────────────────────────────┐
│ Request Microphone Permission│
└─────────────────────────────┘
          │ Granted
          ▼
┌─────────────────────────────┐
│ Create Sermon Record        │
│ (status: pending)           │
└─────────────────────────────┘
          │
          ▼
┌─────────────────────────────┐
│ Start AVAudioRecorder       │
│ (32kbps AAC mono @ 16kHz)   │
└─────────────────────────────┘
          │
          ▼
┌─────────────────────────────┐
│ Recording Loop              │
│ • Emit audio levels → UI    │
│ • Track duration            │
│ • Every 10 min → new chunk  │
└─────────────────────────────┘
          │ User stops
          ▼
┌─────────────────────────────┐
│ Finalize All Chunks         │
│ Return [URL]                │
└─────────────────────────────┘
```

### 6.2 Processing Pipeline

```
Recording Complete (or Import)
          │
          ▼
┌───────────────────────────────────────────┐
│ Step 1: Create Chunk Records (0-5%)       │
│ • Generate waveform samples               │
│ • Save chunks to database                 │
└───────────────────────────────────────────┘
          │
          ▼
┌───────────────────────────────────────────┐
│ Step 2: Upload to Supabase (5-20%)        │
│ • Upload each chunk to Storage            │
│ • Track progress per chunk                │
│ • Update remotePath on success            │
└───────────────────────────────────────────┘
          │
          ▼
┌───────────────────────────────────────────┐
│ Step 3: Transcribe via Whisper (20-70%)   │
│ • For each chunk:                         │
│   - POST to /v1/audio/transcriptions      │
│   - Use previous text as prompt           │
│   - Offset timestamps by chunk start      │
│ • Merge into single transcript            │
│ • Extract word-level timing               │
│ • Save transcript to database             │
└───────────────────────────────────────────┘
          │
          ▼
┌───────────────────────────────────────────┐
│ Step 4: Content Moderation (70-75%)       │
│ • Send transcript to moderation API       │
│ • Flag if inappropriate content detected  │
└───────────────────────────────────────────┘
          │
          ▼
┌───────────────────────────────────────────┐
│ Step 5: Generate Study Guide (75-95%)     │
│ • Extract Bible references (regex)        │
│ • Build prompt with transcript + metadata │
│ • Call GPT-4o for study guide             │
│ • Parse JSON response                     │
│ • Save study guide to database            │
└───────────────────────────────────────────┘
          │
          ▼
┌───────────────────────────────────────────┐
│ Step 6: Complete (95-100%)                │
│ • Update sermon status to succeeded       │
│ • Load transcript and study guide         │
│ • Transition to viewing phase             │
└───────────────────────────────────────────┘
```

---

## 7. User Journey

### 7.1 Primary Flow: Record New Sermon

1. **Open Sermon Tab**
   - User sees input phase with microphone icon

2. **Start Recording**
   - User enters optional title/speaker
   - Taps "Begin Recording"
   - Permission prompt (first time)

3. **Recording**
   - Live waveform displays audio levels
   - Timer counts up
   - User can pause/resume
   - User can add bookmarks

4. **Stop Recording**
   - User taps stop button
   - Recording finalizes

5. **Processing**
   - Progress bar fills
   - Step checklist updates
   - ~2-5 minutes typical

6. **Viewing**
   - Full transcript displayed
   - Audio player ready
   - Study guide sections available

### 7.2 Alternate Flow: Import Audio

1. **Tap "Import Audio"**
   - File picker opens

2. **Select File**
   - Supported: MP3, M4A, WAV
   - Max size validated
   - Duration extracted

3. **Processing**
   - Same pipeline as recording

### 7.3 Alternate Flow: Resume from Library

1. **Tap "My Sermons"**
   - Library sheet opens

2. **Select Sermon**
   - If complete: Jump to viewing
   - If processing: Show progress
   - If failed: Offer retry

---

## 8. Technical Specifications

### 8.1 API Constraints

| Constraint | Value | Impact |
|------------|-------|--------|
| Whisper file limit | 25 MB | 10-minute chunks at 32kbps |
| Whisper formats | mp3, mp4, m4a, wav, webm | Import validation |
| Whisper model | whisper-1 | Cost: ~$0.006/min |
| GPT model | gpt-4o | Study guide generation |
| Moderation | omni-moderation-latest | FREE |

### 8.2 Recording Settings

```swift
// Optimized for speech and API compliance
sampleRate: 16000       // 16 kHz (speech-optimized)
channels: 1             // Mono
bitRate: 32000          // 32 kbps
format: .m4a            // AAC codec
chunkDuration: 600      // 10 minutes
```

**File Size:** ~240 KB/minute → ~14 MB/hour

### 8.3 Database Schema

**Tables:**
- `sermons` - Core sermon records
- `sermon_transcripts` - Full transcriptions
- `sermon_study_guides` - AI-generated content
- `sermon_audio_chunks` - Chunk metadata and status
- `sermon_bookmarks` - User annotations

**FTS5 Index:**
- `sermon_transcripts_fts` - Full-text search on transcript content

### 8.4 Supabase Storage

**Bucket:** `sermons` (private)
- RLS: User can only access own files
- Path: `{userId}/{sermonId}/chunk_{index:03d}.m4a`
- Signed URLs: 1-hour expiry

### 8.5 Cost Estimates

| Component | Cost |
|-----------|------|
| Whisper (30 min sermon) | ~$0.18 |
| GPT-4o (study guide) | ~$0.03 |
| Moderation | FREE |
| **Total per sermon** | **~$0.21** |

---

## 9. File Reference

### Core Feature Files

| File | Path | Lines | Purpose |
|------|------|-------|---------|
| SermonView | `Features/Sermon/Views/SermonView.swift` | ~150 | Container with phase routing |
| SermonFlowState | `Features/Sermon/Core/SermonFlowState.swift` | ~650 | State machine |
| SermonStatus | `Features/Sermon/Core/SermonStatus.swift` | ~120 | Centralized status enum |
| SermonConfiguration | `Features/Sermon/Core/SermonConfiguration.swift` | ~30 | Centralized constants |
| SermonInputPhase | `Features/Sermon/Phases/SermonInputPhase.swift` | ~200 | Record/Import UI |
| SermonRecordingPhase | `Features/Sermon/Phases/SermonRecordingPhase.swift` | ~250 | Recording UI |
| SermonProcessingPhase | `Features/Sermon/Phases/SermonProcessingPhase.swift` | ~180 | Progress UI |
| SermonViewingPhase | `Features/Sermon/Phases/SermonViewingPhase.swift` | ~400 | Results UI |
| SermonLibraryView | `Features/Sermon/Views/SermonLibraryView.swift` | ~150 | Browse saved |

### Model Files

| File | Path | Lines | Purpose |
|------|------|-------|---------|
| Sermon | `Features/Sermon/Models/Sermon.swift` | ~250 | Core record |
| SermonTranscript | `Features/Sermon/Models/SermonTranscript.swift` | ~200 | Transcription |
| SermonStudyGuide | `Features/Sermon/Models/SermonStudyGuide.swift` | ~220 | AI content |
| SermonAudioChunk | `Features/Sermon/Models/SermonAudioChunk.swift` | ~180 | Chunk tracking |
| SermonBookmark | `Features/Sermon/Models/SermonBookmark.swift` | ~150 | Annotations |
| SermonError | `Features/Sermon/Models/SermonError.swift` | ~200 | Error types |

### Service Files

| File | Path | Lines | Purpose |
|------|------|-------|---------|
| SermonRecordingService | `Core/Services/Sermon/SermonRecordingService.swift` | ~515 | Audio recording |
| TranscriptionService | `Core/Services/Sermon/TranscriptionService.swift` | ~305 | Whisper API |
| SermonProcessingQueue | `Core/Services/Sermon/SermonProcessingQueue.swift` | ~575 | Job orchestration |
| SermonSyncService | `Core/Services/Sermon/SermonSyncService.swift` | ~650 | Data/audio sync |

### Utility Files

| File                   | Path                                                     | Purpose                        |
| ---------------------- | -------------------------------------------------------- | ------------------------------ |
| TranscriptSegmentCache | `Features/Sermon/Utilities/TranscriptSegmentCache.swift` | LRU cache for display segments |

### Related Files

| File | Path | Purpose |
|------|------|---------|
| AudioService | `Core/Services/Audio/AudioService.swift` | Stack-based audio session ownership |
| PromptTemplates | `Core/Services/AI/PromptTemplates.swift` | Study guide prompts |
| OpenAIProvider | `Core/Services/AI/OpenAIProvider.swift` | AI service |
| AIServiceProtocol | `Core/Services/AI/AIServiceProtocol.swift` | Protocol definition |
| DatabaseStore | `Core/Database/DatabaseStore.swift` | GRDB setup |
| SupabaseClient | `Core/Networking/SupabaseClient.swift` | Supabase integration |

---

## 10. Design System Integration

The Sermon Recording feature uses the app's unified design system defined in `UI/Theme/`:

### 10.1 Color System (Asset Catalog)

| Usage | Color Token |
|-------|-------------|
| Primary accent | `Color("AccentBronze")` |
| Background | `Color("AppBackground")` |
| Surface | `Color("AppSurface")` |
| Primary text | `Color.appTextPrimary` / `Color("AppTextPrimary")` |
| Secondary text | `Color.appTextSecondary` / `Color("AppTextSecondary")` |
| Dividers | `Color.appDivider` |

### 10.2 Typography Tokens

```swift
// Headers and labels
Typography.Scripture.heading  // Serif heading
Typography.Scripture.body     // Serif body text
Typography.Command.body       // UI command text
Typography.Command.caption    // Metadata, timestamps
```

### 10.3 Spacing & Layout Tokens

```swift
Theme.Spacing.sm   // 8pt
Theme.Spacing.md   // 16pt
Theme.Spacing.lg   // 24pt
Theme.Spacing.xl   // 32pt
Theme.Spacing.xxl  // 48pt

Theme.Radius.sm    // Small corners
Theme.Radius.md    // Standard corners
Theme.Radius.lg    // Large corners

Theme.Stroke.hairline  // Divider thickness
```

### 10.4 Opacity Tokens

```swift
Theme.Opacity.textPrimary      // 0.94 - Primary text
Theme.Opacity.textSecondary    // 0.75 - Secondary text
Theme.Opacity.focusStroke      // 0.60 - Focus rings, glows
Theme.Opacity.subtle           // 0.05 - Atmospheric backgrounds
```

### 10.5 Component Patterns

**Primary Buttons:**
```swift
.foregroundStyle(Color("AppBackground"))
.background(Color("AccentBronze"))
.clipShape(Capsule())
```

**Input Fields:**
```swift
.background(Color("AppSurface").opacity(Theme.Opacity.textSecondary))
.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
.overlay(RoundedRectangle(cornerRadius: Theme.Radius.md)
    .stroke(Color("AccentBronze").opacity(Theme.Opacity.focusStroke), lineWidth: 1))
```

**Cards/Sections:**
```swift
.background(Color("AppSurface"))
.clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
```

---

## 11. Detailed UI Implementation

### 11.1 SermonInputPhase Details

**File:** `Features/Sermon/Phases/SermonInputPhase.swift` (282 lines)

**Animation:**
- Illumination pulse: `withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true))`
- Outer glow scales: `1 + illuminationPhase * 0.1`

**Key Visual Elements:**
```swift
// Illuminated microphone icon
ZStack {
    // Outer glow (pulsing)
    Circle()
        .fill(RadialGradient(colors: [
            ManuscriptTheme.gold.opacity(0.3),
            ManuscriptTheme.gold.opacity(0.1),
            .clear
        ], center: .center, startRadius: 40, endRadius: 100))
        .frame(width: 200, height: 200)
        .scaleEffect(1 + illuminationPhase * 0.1)

    // Inner circle with border
    Circle()
        .fill(ManuscriptTheme.surface)
        .frame(width: 100, height: 100)
        .overlay(Circle().stroke(LinearGradient(...), lineWidth: 2))
        .shadow(color: ManuscriptTheme.gold.opacity(0.3), radius: 20)

    // Waveform icon
    Image(systemName: "waveform.circle.fill")
        .font(.system(size: 48))
        .foregroundStyle(LinearGradient(...))
}
```

**Divider Component (SermonDivider):**
- Gradient lines fading from center
- Diamond ornament (`Image(systemName: "diamond.fill")`)

### 11.2 SermonRecordingPhase Details

**File:** `Features/Sermon/Phases/SermonRecordingPhase.swift` (278 lines)

**Waveform Visualization (SermonWaveformView):**
```swift
struct SermonWaveformView: View {
    let audioLevels: [Float]
    let currentLevel: Float
    let isActive: Bool

    private let barCount = 40
    private let barWidth: CGFloat = 4
    private let spacing: CGFloat = 3

    // Uses Canvas for efficient rendering
    // Gold gradient per bar
    // Max height: size.height * 0.8
}
```

**Recording Indicator:**
- Red circle with pulse: `Circle().fill(Color.red).scaleEffect(1 + pulsePhase * 0.2)`
- Shadow glow: `.shadow(color: .red.opacity(0.6), radius: 8)`
- Animation: `.easeInOut(duration: 0.8).repeatForever(autoreverses: true)`

**Control Buttons:**
- Pause/Resume: 64pt circle, ManuscriptTheme.surface background
- Stop: 80pt gold gradient circle with white 24x24 square
- Cancel: 64pt circle with red X

### 11.3 SermonProcessingPhase Details

**File:** `Features/Sermon/Phases/SermonProcessingPhase.swift` (277 lines)

**Progress Bar (Theme Doctrine Compliant):**
```swift
// Track
RoundedRectangle(cornerRadius: 4)
    .fill(Color("AppSurface"))
    .overlay(RoundedRectangle(cornerRadius: 4)
        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline))

// Fill with gradient (no shimmer - banned by Theme.swift doctrine)
RoundedRectangle(cornerRadius: 4)
    .fill(LinearGradient(
        colors: [Color("AppAccentAction"), Color("AppAccentAction").opacity(0.7)],
        startPoint: .leading, endPoint: .trailing))
    .frame(width: geo.size.width * flowState.processingProgress)
    .animation(reduceMotion ? nil : Theme.Animation.settle, value: flowState.processingProgress)
```

**Motion Compliance:**

- NO shimmer gradients (banned by Theme.swift lines 16-20)
- Respects `@Environment(\.accessibilityReduceMotion)`
- All animations <400ms per doctrine

**Step Checklist (ProcessingStepRow):**
- Complete: Green checkmark circle
- Active: Gold ring with pulsing gold dot (pulse: `0.6s, repeatForever`)
- Pending: Faint gray ring

### 11.4 SermonViewingPhase Details

**File:** `Features/Sermon/Phases/SermonViewingPhase.swift` (1172 lines)

**Waveform Scrubber (SermonWaveformScrubber):**
- Uses custom `WaveformShape` for efficient bar rendering
- Playhead: 14pt gold circle (expands to 20pt when dragging)
- Gesture: `DragGesture(minimumDistance: 0)` for immediate response
- Mask technique for played portion highlight

**Transcript Display (TranscriptContentView):**
- First segment uses `DropCapText`:
  - Drop cap: Cinzel 52pt bold gold gradient, 52x52 frame
  - Remaining text: Cormorant 17pt with 8pt line spacing
- Subsequent segments: Cormorant 17pt, gold highlight when active
- Tap gesture seeks to segment start time

**Audio Player (SermonViewingViewModel):**
- Uses `AVQueuePlayer` for multi-chunk playback
- Time observer: 0.1s intervals (CMTime(seconds: 0.1, preferredTimescale: 600))
- Binary search for current segment index
- Playback speeds: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
- Audio session: `.playback` category, `.spokenAudio` mode

**Collapsible Sections (StudyGuideSection):**
- Chevron rotation: 180° when expanded
- Animation: `.easeInOut(duration: 0.3)`
- Transition: `.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity)`

**Flow Layout (SermonFlowLayout):**
- Custom `Layout` protocol implementation
- Used for scripture reference chips
- Wraps items to next row when exceeding container width

### 11.5 Haptic Feedback Integration

Throughout the UI, haptics provide tactile feedback:
```swift
HapticService.shared.success()        // Recording started, processing complete
HapticService.shared.mediumTap()      // Recording stopped
HapticService.shared.softTap()        // Play/pause, pause/resume
HapticService.shared.selectionChanged() // Seek, section expand, bookmark
HapticService.shared.lightTap()       // Segment tap
HapticService.shared.warning()        // Cancel, error
```

---

## 12. Exact Code References

### Key Line Numbers

| Component | File | Key Lines |
|-----------|------|-----------|
| Phase enum | SermonFlowState.swift | 10-29 |
| ProcessingStep progress | SermonFlowState.swift | 33-70 |
| startRecording() | SermonFlowState.swift | 159-226 |
| processRecording() | SermonFlowState.swift | 386-487 |
| RecordingConfiguration | SermonRecordingService.swift | 20-54 |
| startNewChunk() | SermonRecordingService.swift | 331-359 |
| levelMetering | SermonRecordingService.swift | 426-448 |
| segments computed | SermonTranscript.swift | 33-89 |
| StudyGuideContent | SermonStudyGuide.swift | 44-88 |
| QuestionType enum | SermonStudyGuide.swift | 144-167 |

### GRDB Column Mappings

**Sermon Columns (lines 158-183):**
```swift
enum Columns: String, ColumnExpression {
    case userId = "user_id"
    case speakerName = "speaker_name"
    case recordedAt = "recorded_at"
    case durationSeconds = "duration_seconds"
    case transcriptionStatus = "transcription_status"
    case studyGuideStatus = "study_guide_status"
    // ... (snake_case mapping)
}
```

**JSON Encoding:**
- `scriptureReferences`: JSON array stored as string
- `wordTimestamps`: JSON array stored as string
- `content` (StudyGuide): Full JSON object stored as string

---

## Summary

The Sermon Recording feature is a comprehensive, fully-implemented system that:

1. **Records or imports** audio sermons with intelligent chunking
2. **Transcribes** via Whisper API with word-level timing
3. **Generates** AI study guides with questions, themes, and scripture references
4. **Syncs** offline-first with Supabase
5. **Displays** interactive transcripts synced to audio playback

The architecture follows established patterns in the BibleStudy app (state machines, offline-first, Observable ViewModels) and is production-ready with comprehensive error handling, resumable processing, and user-friendly progress feedback.

**Design Language:** Uses the unified design system (`Theme.*`, `Typography.*`, Asset Catalog colors) with:

- Bronze accent via `Color("AccentBronze")`
- Typography tokens (`Typography.Scripture.*`, `Typography.Command.*`)
- Adaptive backgrounds (`Color("AppBackground")`, `Color("AppSurface")`)
- Theme-compliant animations (no shimmer, respects Reduce Motion)
- Consistent haptic feedback patterns
- Stack-based audio session ownership for recording/playback coordination

---

*Document updated: January 25, 2026*
