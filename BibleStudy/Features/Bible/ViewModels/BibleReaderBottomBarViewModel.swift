import SwiftUI

// MARK: - Bible Reader Bottom Bar ViewModel
// State manager for bottom navigation bar in Bible reader
// Tracks audio playback state and highlight/note counts

@Observable
@MainActor
final class BibleReaderBottomBarViewModel {

    // MARK: - State

    private(set) var isAudioPlaying: Bool = false
    private(set) var highlightCount: Int = 0
    private(set) var noteCount: Int = 0

    // MARK: - Computed Properties

    var totalNotesCount: Int {
        highlightCount + noteCount
    }

    // MARK: - Dependencies

    private let audioService: AudioService
    private let userContentService: UserContentService
    private var audioObserver: NSObjectProtocol?

    // MARK: - Initialization

    init() {
        self.audioService = AudioService.shared
        self.userContentService = UserContentService.shared
    }

    // MARK: - Public API

    /// Update highlight and note counts for the current chapter
    func updateCounts(bookId: Int, chapter: Int) {
        let highlights = userContentService.getHighlights(for: chapter, bookId: bookId)
        highlightCount = highlights.count

        let notes = userContentService.getNotes(for: chapter, bookId: bookId)
        noteCount = notes.count
    }

    /// Start observing audio playback state
    /// Call this when the view appears
    func startObservingAudio() {
        // Initial state
        isAudioPlaying = audioService.isPlaying

        // Observe changes via notification (store token for proper cleanup)
        audioObserver = NotificationCenter.default.addObserver(
            forName: .audioPlaybackStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isAudioPlaying = self.audioService.isPlaying
            }
        }
    }

    /// Stop observing audio playback state
    /// Call this when the view disappears
    func stopObservingAudio() {
        if let observer = audioObserver {
            NotificationCenter.default.removeObserver(observer)
            audioObserver = nil
        }
    }
}
