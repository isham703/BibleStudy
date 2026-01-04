import SwiftUI

// MARK: - Prayer Flow Phase

enum PrayerFlowPhase: Equatable {
    case input
    case generating
    case displaying
}

// MARK: - Prayer Flow State
// Observable state manager for the prayer generation flow

@Observable
final class PrayerFlowState {
    // MARK: - Core State

    var phase: PrayerFlowPhase = .input
    var inputText: String = ""
    var selectedTradition: PrayerTradition = .psalmicLament
    var generatedPrayer: MockPrayer?

    // MARK: - Word-by-Word Reveal

    var revealedWordCount: Int = 0
    var isRevealComplete: Bool = false
    private var revealTask: Task<Void, Never>?
    private var generationTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    // MARK: - Toast State

    var showToast: Bool = false
    var toastMessage: String = ""

    // MARK: - Generation Duration

    /// Different variations can have different generation times
    var generationDuration: TimeInterval = 3.0

    // MARK: - Computed Properties

    var canGenerate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var totalWordCount: Int {
        generatedPrayer?.words.count ?? 0
    }

    // MARK: - Generation Actions

    func startGeneration(duration: TimeInterval = 3.0) {
        guard phase != .generating else { return } // Prevent double-start

        generationTask?.cancel()
        generationDuration = duration
        phase = .generating

        // Simulate AI generation
        generationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            completeGeneration()
        }
    }

    func completeGeneration() {
        generatedPrayer = MockPrayer.prayer(for: selectedTradition)
        phase = .displaying
    }

    func reset() {
        cancelReveal()
        generationTask?.cancel()
        generationTask = nil
        toastTask?.cancel()
        toastTask = nil
        phase = .input
        inputText = ""
        generatedPrayer = nil
        revealedWordCount = 0
        isRevealComplete = false
        showToast = false
    }

    // MARK: - Word-by-Word Reveal

    /// Start revealing words one at a time
    /// - Parameters:
    ///   - wordDelay: Time between words (default 0.7s = 0.3s fade + 0.4s hold)
    ///   - punctuationDelay: Extra delay after periods (default 0.6s)
    ///   - lineBreakDelay: Extra delay for line breaks (default 1.2s)
    func startWordReveal(
        wordDelay: TimeInterval = 0.7,
        punctuationDelay: TimeInterval = 0.6,
        lineBreakDelay: TimeInterval = 1.2
    ) {
        guard let prayer = generatedPrayer else { return }

        revealedWordCount = 0
        isRevealComplete = false

        let words = prayer.words

        revealTask = Task { @MainActor in
            for (index, word) in words.enumerated() {
                guard !Task.isCancelled else { return }

                // Reveal the word
                withAnimation(.easeInOut(duration: 0.3)) {
                    revealedWordCount = index + 1
                }

                // Determine delay based on punctuation
                var delay = wordDelay
                if word.hasSuffix(".") || word.hasSuffix("!") || word.hasSuffix("?") {
                    delay += punctuationDelay
                } else if word.hasSuffix(",") || word.hasSuffix(";") || word.hasSuffix(":") {
                    delay += 0.2
                }

                // Check if next word starts a new line (simplified heuristic)
                if index < words.count - 1 {
                    let currentWord = word.lowercased()
                    if currentWord.hasSuffix(".") || currentWord.hasSuffix("—") {
                        delay += lineBreakDelay - punctuationDelay
                    }
                }

                try? await Task.sleep(for: .seconds(delay))
            }

            // Final pause before marking complete
            try? await Task.sleep(for: .seconds(3.0))

            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                isRevealComplete = true
            }
        }
    }

    /// Skip to full reveal (tap anywhere to skip)
    func skipToFullReveal() {
        cancelReveal()
        withAnimation(.easeOut(duration: 0.3)) {
            revealedWordCount = totalWordCount
            isRevealComplete = true
        }
    }

    /// Cancel ongoing reveal animation
    func cancelReveal() {
        revealTask?.cancel()
        revealTask = nil
    }

    // MARK: - Toast Actions

    func showActionToast(_ action: String) {
        toastTask?.cancel() // Cancel any existing toast

        toastMessage = "\(action)"
        withAnimation(.spring(duration: 0.3)) {
            showToast = true
        }

        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.0))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
}
