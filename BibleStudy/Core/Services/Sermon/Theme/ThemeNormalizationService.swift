//
//  ThemeNormalizationService.swift
//  BibleStudy
//
//  Background actor for theme normalization work.
//  Main actor facade for UI access with lazy backfill support.
//

import Combine
import Foundation

// MARK: - Theme Normalization Actor

/// Background actor for theme normalization work
/// Performs CPU-intensive normalization and batch operations off main thread
actor ThemeNormalizationActor {
    private let repository = SermonRepository.shared

    // MARK: - Single Sermon Normalization

    /// Normalize themes from a study guide, preserving user overrides
    /// - Parameters:
    ///   - studyGuide: The sermon's study guide containing keyThemes
    ///   - existingOverrides: Current theme assignments to preserve user overrides
    /// - Returns: New theme assignments sorted by confidence
    func normalizeThemes(
        from studyGuide: SermonStudyGuide,
        existingOverrides: [SermonThemeAssignment]
    ) -> [SermonThemeAssignment] {
        let keyThemes = studyGuide.content.keyThemes
        guard !keyThemes.isEmpty else { return [] }

        var assignments: [NormalizedTheme: SermonThemeAssignment] = [:]

        // Preserve user overrides (both added and removed)
        for override in existingOverrides where override.overrideState != .auto {
            if let theme = NormalizedTheme(rawValue: override.theme) {
                assignments[theme] = override
            }
        }

        // Process AI-generated themes
        for (index, rawTheme) in keyThemes.enumerated() {
            let result = ThemeSynonymMapper.normalize(rawTheme)

            guard let theme = result.theme else {
                // Unmatched theme - skip for now
                continue
            }

            // Skip if user has removed this theme
            if let existing = assignments[theme],
               existing.overrideState == .userRemoved {
                continue
            }

            // Skip if user has already added this theme
            if let existing = assignments[theme],
               existing.overrideState == .userAdded {
                continue
            }

            // Calculate confidence with order bonus (earlier themes = higher priority)
            let orderBonus = max(0, 0.05 - Double(index) * 0.01)
            let confidence = min(1.0, result.confidence + orderBonus)

            // Merge source themes if this theme already exists from AI
            var sourceThemes = [rawTheme]
            if let existing = assignments[theme], existing.overrideState == .auto {
                sourceThemes = existing.sourceThemes + [rawTheme]
            }

            assignments[theme] = SermonThemeAssignment(
                sermonId: studyGuide.sermonId,
                theme: theme.rawValue,
                confidence: max(assignments[theme]?.confidence ?? 0, confidence),
                overrideState: .auto,
                sourceThemes: sourceThemes,
                matchType: result.matchType
            )
        }

        // Sort by confidence and take top 5 (excluding user_removed)
        return assignments.values
            .filter { $0.overrideState != .userRemoved }
            .sorted { $0.confidence > $1.confidence }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Batch Operations

    /// Batch rebuild themes for all sermons (background operation)
    /// - Parameters:
    ///   - userId: User ID to filter sermons
    ///   - batchSize: Number of sermons per batch
    ///   - onProgress: Progress callback (current, total)
    func rebuildAllThemes(
        userId: UUID,
        batchSize: Int = 20,
        onProgress: @escaping @Sendable (Int, Int) -> Void
    ) async throws {
        let sermons = try repository.fetchAllSermons(userId: userId, includeDeleted: false)
            .filter { $0.isComplete }

        let total = sermons.count
        var processed = 0

        // Process in batches
        for batchStart in stride(from: 0, to: sermons.count, by: batchSize) {
            try Task.checkCancellation()

            let batchEnd = min(batchStart + batchSize, sermons.count)
            let batch = Array(sermons[batchStart..<batchEnd])

            for sermon in batch {
                guard let studyGuide = try repository.fetchStudyGuide(sermonId: sermon.id) else {
                    processed += 1
                    continue
                }

                // Preserve existing overrides
                let existingOverrides = try repository.fetchThemeAssignments(sermonId: sermon.id)
                let assignments = normalizeThemes(from: studyGuide, existingOverrides: existingOverrides)

                try repository.saveThemeAssignments(sermonId: sermon.id, assignments: assignments)

                processed += 1
            }

            // Report progress
            onProgress(processed, total)

            // Yield to allow other work
            await Task.yield()
        }
    }

    /// Normalize themes for a single sermon
    func normalizeThemesForSermon(sermonId: UUID) async throws {
        guard let studyGuide = try repository.fetchStudyGuide(sermonId: sermonId) else {
            return
        }

        let existingOverrides = try repository.fetchThemeAssignments(sermonId: sermonId)
        let assignments = normalizeThemes(from: studyGuide, existingOverrides: existingOverrides)
        try repository.saveThemeAssignments(sermonId: sermonId, assignments: assignments)
    }
}

// MARK: - Theme Normalization Service

/// Main actor facade for UI access to theme normalization
@MainActor
final class ThemeNormalizationService: ObservableObject {
    static let shared = ThemeNormalizationService()

    private let actor = ThemeNormalizationActor()
    private let repository = SermonRepository.shared

    // MARK: - Published State

    @Published private(set) var isBackfilling = false
    @Published private(set) var backfillProgress: (current: Int, total: Int)?

    private var backfillTask: Task<Void, Error>?
    private var hasTriggeredBackfill = false

    // MARK: - Theme Queries

    /// Get visible themes for a sermon (from cache)
    func themes(for sermonId: UUID) -> [NormalizedTheme] {
        do {
            return try repository.fetchVisibleThemeAssignments(sermonId: sermonId)
                .compactMap { $0.normalizedTheme }
        } catch {
            print("Failed to fetch themes for sermon: \(error)")
            return []
        }
    }

    /// Get primary theme for a sermon
    func primaryTheme(for sermonId: UUID) -> NormalizedTheme? {
        themes(for: sermonId).first
    }

    /// Get full theme assignments for a sermon (for editing)
    func themeAssignments(for sermonId: UUID) -> [SermonThemeAssignment] {
        do {
            return try repository.fetchVisibleThemeAssignments(sermonId: sermonId)
        } catch {
            print("Failed to fetch theme assignments: \(error)")
            return []
        }
    }

    /// Check if a sermon has any themes assigned
    func hasThemes(sermonId: UUID) -> Bool {
        !themes(for: sermonId).isEmpty
    }

    // MARK: - Single Sermon Operations

    /// Normalize themes for a newly ready sermon
    func normalizeThemes(for sermonId: UUID) async {
        do {
            try await actor.normalizeThemesForSermon(sermonId: sermonId)
        } catch {
            print("Failed to normalize themes for sermon: \(error)")
        }
    }

    /// Add a user theme to a sermon
    func addUserTheme(_ theme: NormalizedTheme, to sermonId: UUID) {
        do {
            try repository.addUserTheme(sermonId: sermonId, theme: theme)
        } catch {
            print("Failed to add user theme: \(error)")
        }
    }

    /// Remove a theme from a sermon (marks as user_removed)
    func removeUserTheme(_ theme: NormalizedTheme, from sermonId: UUID) {
        do {
            try repository.removeUserTheme(sermonId: sermonId, theme: theme)
        } catch {
            print("Failed to remove user theme: \(error)")
        }
    }

    // MARK: - Lazy Backfill

    /// Trigger lazy backfill when user first selects Theme grouping
    func triggerBackfillIfNeeded(userId: UUID) {
        guard !hasTriggeredBackfill && backfillTask == nil else { return }
        hasTriggeredBackfill = true

        backfillTask = Task { [weak self] in
            guard let self else { return }

            await MainActor.run {
                self.isBackfilling = true
            }

            defer {
                Task { @MainActor [weak self] in
                    self?.isBackfilling = false
                    self?.backfillTask = nil
                }
            }

            do {
                try await actor.rebuildAllThemes(userId: userId) { [weak self] current, total in
                    Task { @MainActor [weak self] in
                        self?.backfillProgress = (current, total)
                    }
                }
            } catch {
                print("Theme backfill failed: \(error)")
            }
        }
    }

    /// Cancel any running backfill operation
    func cancelBackfill() {
        backfillTask?.cancel()
        backfillTask = nil
        isBackfilling = false
    }

    /// Reset backfill state (for testing)
    func resetBackfillState() {
        hasTriggeredBackfill = false
        backfillProgress = nil
    }
}
