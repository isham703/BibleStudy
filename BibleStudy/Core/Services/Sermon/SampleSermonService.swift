//
//  SampleSermonService.swift
//  BibleStudy
//
//  Manages the bundled sample sermon for onboarding/demo purposes.
//  Sample is virtual (bundle-backed): never written to GRDB, never synced.
//

import Foundation

// MARK: - Sample Sermon Service

@MainActor
@Observable
final class SampleSermonService {
    // MARK: - Singleton

    static let shared = SampleSermonService()

    // MARK: - Sample Identity

    /// Stable UUID for sample sermon (deterministic across app launches)
    /// Generated from "sample.good_samaritan" namespace
    static let sampleSermonId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let sampleTranscriptId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let sampleStudyGuideId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    // MARK: - Bundle Resources

    private let transcriptFileName = "good_samaritan_transcript"
    private let studyGuideFileName = "good_samaritan_study_guide"

    // MARK: - Cached Content

    private var cachedTranscriptContent: String?
    private var cachedStudyGuideContent: StudyGuideContent?

    // MARK: - Initialization

    private init() {}

    // MARK: - Sample Identity Checks

    /// Check if a sermon ID is the sample
    func isSample(id: UUID) -> Bool {
        id == Self.sampleSermonId
    }

    /// Check if a sermon is the sample
    func isSample(_ sermon: Sermon) -> Bool {
        isSample(id: sermon.id)
    }

    // MARK: - Visibility Management (User-Scoped)

    /// Whether the sample should be shown for a given user
    func shouldShowSample(userId: UUID?) -> Bool {
        !UserDefaults.standard.bool(forKey: hideKey(for: userId))
    }

    /// Hide the sample for a given user (persists across launches)
    func hideSample(userId: UUID?) {
        UserDefaults.standard.set(true, forKey: hideKey(for: userId))
    }

    /// Unhide the sample for a given user (undo action)
    func unhideSample(userId: UUID?) {
        UserDefaults.standard.removeObject(forKey: hideKey(for: userId))
    }

    /// User-scoped UserDefaults key
    private func hideKey(for userId: UUID?) -> String {
        let userString = userId?.uuidString ?? "anonymous"
        return "sampleSermonHidden.\(userString)"
    }

    // MARK: - Sample Data Construction

    /// Construct the sample Sermon object (bundle-backed)
    func sampleSermon(userId: UUID?) -> Sermon {
        Sermon(
            id: Self.sampleSermonId,
            userId: userId ?? UUID(),
            title: "The Good Samaritan",
            speakerName: "Sample Sermon",
            recordedAt: Date(timeIntervalSince1970: 1704067200), // Jan 1, 2024
            durationSeconds: 720, // 12 minutes
            localAudioPath: nil,
            remoteAudioPath: nil,
            audioFileSize: nil,
            audioMimeType: nil,
            audioCodec: nil,
            audioBitrateKbps: nil,
            audioContentHash: nil,
            transcriptionStatus: .succeeded,
            transcriptionError: nil,
            studyGuideStatus: .succeeded,
            studyGuideError: nil,
            processingVersion: "sample",
            scriptureReferences: ["Luke 10:25-37"],
            createdAt: Date(timeIntervalSince1970: 1704067200),
            updatedAt: Date(timeIntervalSince1970: 1704067200),
            deletedAt: nil,
            needsSync: false,
            audioNeedsUpload: false
        )
    }

    /// Construct the sample SermonTranscript object (bundle-backed)
    func sampleTranscript(sermonId: UUID) -> SermonTranscript {
        SermonTranscript(
            id: Self.sampleTranscriptId,
            sermonId: sermonId,
            content: loadTranscriptContent(),
            language: "en",
            wordTimestamps: [], // Empty = static mode (no tap-to-seek)
            modelUsed: "sample",
            confidenceScore: 1.0,
            createdAt: Date(timeIntervalSince1970: 1704067200),
            updatedAt: Date(timeIntervalSince1970: 1704067200),
            needsSync: false
        )
    }

    /// Construct the sample SermonStudyGuide object (bundle-backed)
    func sampleStudyGuide(sermonId: UUID) -> SermonStudyGuide {
        SermonStudyGuide(
            id: Self.sampleStudyGuideId,
            sermonId: sermonId,
            content: loadStudyGuideContent(),
            modelUsed: "sample",
            promptVersion: "sample",
            transcriptHash: nil,
            createdAt: Date(timeIntervalSince1970: 1704067200),
            updatedAt: Date(timeIntervalSince1970: 1704067200),
            needsSync: false
        )
    }

    // MARK: - Bundle Loading

    /// Load transcript content from bundle (cached)
    private func loadTranscriptContent() -> String {
        if let cached = cachedTranscriptContent {
            return cached
        }

        guard let url = Bundle.main.url(
            forResource: transcriptFileName,
            withExtension: "txt",
            subdirectory: "SermonSamples"
        ) else {
            print("[SampleSermonService] Failed to find transcript bundle resource")
            return sampleTranscriptFallback
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            cachedTranscriptContent = content
            return content
        } catch {
            print("[SampleSermonService] Failed to load transcript: \(error)")
            return sampleTranscriptFallback
        }
    }

    /// Load study guide content from bundle (cached)
    private func loadStudyGuideContent() -> StudyGuideContent {
        if let cached = cachedStudyGuideContent {
            return cached
        }

        guard let url = Bundle.main.url(
            forResource: studyGuideFileName,
            withExtension: "json",
            subdirectory: "SermonSamples"
        ) else {
            print("[SampleSermonService] Failed to find study guide bundle resource")
            return sampleStudyGuideFallback
        }

        do {
            let data = try Data(contentsOf: url)
            let content = try JSONDecoder().decode(StudyGuideContent.self, from: data)
            cachedStudyGuideContent = content
            return content
        } catch {
            print("[SampleSermonService] Failed to load study guide: \(error)")
            return sampleStudyGuideFallback
        }
    }

    // MARK: - Fallback Content

    /// Minimal fallback if bundle resources fail to load
    private var sampleTranscriptFallback: String {
        """
        Today we're looking at one of Jesus' most famous parables: the Good Samaritan. \
        This story challenges us to reconsider who our neighbor really is, and what it \
        means to love them as ourselves. The lawyer asked Jesus, "Who is my neighbor?" \
        But Jesus flipped the question: "Who proved to be a neighbor to the man in need?"
        """
    }

    private var sampleStudyGuideFallback: StudyGuideContent {
        StudyGuideContent(
            title: "The Good Samaritan",
            summary: "Jesus uses the parable of the Good Samaritan to redefine what it means to be a neighbor.",
            keyThemes: ["Compassion", "Neighborly Love", "Action over Words"],
            sermonType: .expository,
            centralThesis: "True discipleship means showing mercy to all people.",
            bibleReferencesMentioned: [
                SermonVerseReference(
                    reference: "Luke 10:25-37",
                    bookId: 42,
                    chapter: 10,
                    verseStart: 25,
                    verseEnd: 37,
                    isMentioned: true,
                    rationale: "The primary passage"
                )
            ],
            discussionQuestions: [
                StudyQuestion(
                    question: "Who are the 'Samaritans' in your life?",
                    type: .application
                )
            ],
            reflectionPrompts: [
                "When was the last time you went out of your way to help someone?"
            ],
            applicationPoints: [
                "Look for opportunities to show kindness this week."
            ]
        )
    }
}

// MARK: - Sample Metadata

extension SampleSermonService {
    /// Display metadata for the sample card
    var sampleTitle: String { "The Good Samaritan" }
    var sampleDuration: String { "12:00" }
    var sampleScriptureRange: String { "Luke 10:25-37" }
    var sampleDescription: String { "Explore what sermon analysis looks like" }
}
