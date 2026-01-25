import Foundation
import GRDB
import Auth
import WidgetKit
import UIKit

// MARK: - Reading Analytics Service
// Tracks reading sessions and computes analytics

@MainActor
@Observable
final class ReadingAnalyticsService {
    // MARK: - Singleton
    static let shared = ReadingAnalyticsService()

    // MARK: - Properties
    private let supabase = SupabaseManager.shared
    private let db = DatabaseStore.shared

    var currentSession: ReadingSession?
    var todaysSessions: [ReadingSession] = []
    var recentSessions: [ReadingSession] = []
    var stats: ReadingStats = ReadingStats()
    var dailyGoal: DailyGoal = .default
    var isLoading: Bool = false
    var error: Error?

    // Background/foreground tracking
    private var pausedAt: Date?
    private var accumulatedActiveTime: TimeInterval = 0
    private var sessionStartTime: Date?

    // Today's progress
    var todayMinutesRead: Int {
        todaysSessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    var todayChaptersRead: Int {
        Set(todaysSessions.map { "\($0.bookId):\($0.chapter)" }).count
    }

    var todayGoalProgress: Double {
        dailyGoal.progressForMinutes(todayMinutesRead)
    }

    var hasMetTodayGoal: Bool {
        dailyGoal.isMetForMinutes(todayMinutesRead)
    }

    // MARK: - Initialization
    private init() {
        loadDailyGoal()
        setupLifecycleObservers()
    }

    private func setupLifecycleObservers() {
        // Pause session when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pauseCurrentSession()
            }
        }

        // Resume session when app returns to foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.resumeCurrentSession()
            }
        }

        // Save session on app termination to prevent data loss
        // CRITICAL: Must be synchronous - async Task may not complete before termination
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // We're on .main queue, so we can use assumeIsolated to run synchronously
            MainActor.assumeIsolated {
                self?.saveSessionOnTerminate()
            }
        }
    }

    // MARK: - Session Management

    func startSession(bookId: Int, chapter: Int, translationId: String = "kjv") {
        guard let userId = supabase.currentUser?.id else { return }

        // End any existing session
        if currentSession != nil {
            endCurrentSession()
        }

        currentSession = ReadingSession(
            userId: userId,
            bookId: bookId,
            chapter: chapter,
            translationId: translationId
        )

        // Reset background tracking state for new session
        accumulatedActiveTime = 0
        pausedAt = nil
        sessionStartTime = Date()
    }

    func recordVerseRead(_ verse: Int) {
        currentSession?.recordVerseRead(verse)
    }

    func updateSessionLocation(bookId: Int, chapter: Int) {
        guard let session = currentSession else { return }

        // If chapter changed, save current session and start new one
        if session.bookId != bookId || session.chapter != chapter {
            endCurrentSession()
            startSession(bookId: bookId, chapter: chapter, translationId: session.translationId)
        }
    }

    // MARK: - Background/Foreground Handling

    /// Pause session timer when app goes to background
    private func pauseCurrentSession() {
        guard currentSession != nil, pausedAt == nil else { return }

        // Record when we paused
        pausedAt = Date()

        // Accumulate active time from session start (or last resume) until now
        if let startTime = sessionStartTime {
            accumulatedActiveTime += Date().timeIntervalSince(startTime)
        }

        print("ReadingAnalyticsService: Session paused, accumulated \(Int(accumulatedActiveTime))s of active time")
    }

    /// Resume session timer when app returns to foreground
    private func resumeCurrentSession() {
        guard currentSession != nil, pausedAt != nil else { return }

        // Reset the start time to now (accumulated time is preserved)
        sessionStartTime = Date()
        pausedAt = nil

        print("ReadingAnalyticsService: Session resumed")
    }

    /// Save partial session on app termination to prevent data loss
    private func saveSessionOnTerminate() {
        guard var session = currentSession else { return }

        // Calculate final active time
        var finalActiveTime = accumulatedActiveTime
        if pausedAt == nil, let startTime = sessionStartTime {
            // App is still active, add time since last start
            finalActiveTime += Date().timeIntervalSince(startTime)
        }

        // Cap at 2 hours max
        session.durationSeconds = min(Int(finalActiveTime), 7200)
        session.endedAt = Date()

        // Synchronously save to prevent data loss on termination
        guard let dbQueue = db.dbQueue else { return }

        do {
            try saveSessionToCache(session, dbQueue: dbQueue)
            print("ReadingAnalyticsService: Session saved on terminate (\(session.durationSeconds)s)")
        } catch {
            print("ReadingAnalyticsService: Failed to save session on terminate - \(error)")
        }

        currentSession = nil
    }

    func endCurrentSession() {
        guard var session = currentSession else { return }

        // Calculate final active time (excluding background time)
        var finalActiveTime = accumulatedActiveTime
        if pausedAt == nil, let startTime = sessionStartTime {
            // App is still active, add time since last start/resume
            finalActiveTime += Date().timeIntervalSince(startTime)
        }

        // Set duration using accumulated active time (capped at 2 hours)
        session.endedAt = Date()
        session.durationSeconds = min(Int(finalActiveTime), 7200)

        print("ReadingAnalyticsService: Session ended with \(session.durationSeconds)s of active reading time")

        // Reset tracking state
        accumulatedActiveTime = 0
        pausedAt = nil
        sessionStartTime = nil

        // Save to database
        Task {
            do {
                try await saveSession(session)
                todaysSessions.append(session)

                // Sync reading progress to widget
                WidgetService.shared.updateReadingProgress(todayGoalProgress)
            } catch {
                self.error = error
            }
        }

        currentSession = nil
    }

    // MARK: - Persistence

    private nonisolated func saveSessionToCache(_ session: ReadingSession, dbQueue: DatabaseQueue) throws {
        try dbQueue.write { db in
            try session.save(db)
        }
    }

    private func saveSession(_ session: ReadingSession) async throws {
        guard let dbQueue = db.dbQueue else {
            throw DatabaseError.notInitialized
        }

        try saveSessionToCache(session, dbQueue: dbQueue)
    }

    // MARK: - Loading

    func loadSessions() async {
        guard let userId = supabase.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await loadFromCache(userId: userId)
            calculateStats()
        } catch {
            self.error = error
        }
    }

    private nonisolated func fetchSessionsFromCache(userId: UUID, dbQueue: DatabaseQueue) throws -> [ReadingSession] {
        try dbQueue.read { db in
            try ReadingSession
                .filter(ReadingSession.Columns.userId == userId.uuidString)
                .order(ReadingSession.Columns.startedAt.desc)
                .limit(100)
                .fetchAll(db)
        }
    }

    private nonisolated func fetchTodaysSessionsFromCache(userId: UUID, dbQueue: DatabaseQueue) throws -> [ReadingSession] {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        return try dbQueue.read { db in
            try ReadingSession
                .filter(ReadingSession.Columns.userId == userId.uuidString)
                .filter(ReadingSession.Columns.startedAt >= startOfDay)
                .order(ReadingSession.Columns.startedAt.desc)
                .fetchAll(db)
        }
    }

    private func loadFromCache(userId: UUID) async throws {
        guard let dbQueue = db.dbQueue else { return }

        recentSessions = try fetchSessionsFromCache(userId: userId, dbQueue: dbQueue)
        todaysSessions = try fetchTodaysSessionsFromCache(userId: userId, dbQueue: dbQueue)
    }

    // MARK: - Statistics

    private func calculateStats() {
        var newStats = ReadingStats()

        newStats.totalSessions = recentSessions.count
        newStats.totalMinutesRead = recentSessions.reduce(0) { $0 + $1.durationSeconds } / 60
        newStats.totalVersesRead = recentSessions.reduce(0) { $0 + $1.versesRead.count }

        // Chapters by book
        for session in recentSessions {
            if newStats.chaptersByBook[session.bookId] == nil {
                newStats.chaptersByBook[session.bookId] = []
            }
            newStats.chaptersByBook[session.bookId]?.insert(session.chapter)
        }

        newStats.totalChaptersRead = newStats.chaptersByBook.values.reduce(0) { $0 + $1.count }

        // Average session time
        if newStats.totalSessions > 0 {
            newStats.averageSessionMinutes = Double(newStats.totalMinutesRead) / Double(newStats.totalSessions)
        }

        // Calculate streak
        calculateStreak(&newStats)

        stats = newStats
    }

    private func calculateStreak(_ stats: inout ReadingStats) {
        let calendar = Calendar.current

        // Get unique days with sessions
        var sessionDays: Set<Date> = []
        for session in recentSessions {
            let day = calendar.startOfDay(for: session.startedAt)
            sessionDays.insert(day)
        }

        guard !sessionDays.isEmpty else {
            stats.currentStreak = 0
            stats.longestStreak = 0
            return
        }

        // Sort days
        let sortedDays = sessionDays.sorted(by: >)

        // Calculate current streak (starting from today or yesterday)
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let checkDate = sortedDays.first == today ? today : (sortedDays.first == yesterday ? yesterday : nil)

        if let startDate = checkDate {
            var dateToCheck = startDate
            while sessionDays.contains(dateToCheck) {
                currentStreak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: dateToCheck) else { break }
                dateToCheck = previousDay
            }
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 0
        var lastDate: Date?

        for day in sortedDays.reversed() {
            if let last = lastDate {
                let expectedNext = calendar.date(byAdding: .day, value: 1, to: last)!
                if day == expectedNext {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            lastDate = day
        }
        longestStreak = max(longestStreak, tempStreak)

        stats.currentStreak = currentStreak
        stats.longestStreak = longestStreak
    }

    // MARK: - Daily Goal

    func setDailyGoal(_ goal: DailyGoal) {
        dailyGoal = goal
        saveDailyGoal()
    }

    private func loadDailyGoal() {
        if let data = UserDefaults.standard.data(forKey: "dailyReadingGoal"),
           let goal = try? JSONDecoder().decode(DailyGoal.self, from: data) {
            dailyGoal = goal
        }
    }

    private func saveDailyGoal() {
        if let data = try? JSONEncoder().encode(dailyGoal) {
            UserDefaults.standard.set(data, forKey: "dailyReadingGoal")
        }
    }

    // MARK: - Helpers

    func getReadingHistory(for bookId: Int) -> [ReadingSession] {
        recentSessions.filter { $0.bookId == bookId }
    }

    func getChaptersRead(for bookId: Int) -> Set<Int> {
        stats.chaptersByBook[bookId] ?? []
    }

    func hasReadChapter(bookId: Int, chapter: Int) -> Bool {
        stats.chaptersByBook[bookId]?.contains(chapter) ?? false
    }

    /// Get formatted "last read" text for a book
    func lastReadText(for bookId: Int) -> String? {
        guard let lastSession = recentSessions.first(where: { $0.bookId == bookId }) else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastSession.startedAt, relativeTo: Date())
    }
}
