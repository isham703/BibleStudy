import SwiftUI

// MARK: - Prayer Flow Phase

enum PrayerFlowPhase: Equatable {
    case input
    case generating
    case displaying
}

// MARK: - Prayer Flow State
// Observable state manager for the prayer generation flow
// @MainActor ensures all state mutations happen on main thread

@MainActor
@Observable
final class PrayerFlowState {
    // MARK: - Core State

    var phase: PrayerFlowPhase = .input
    var inputText: String = ""
    var selectedTradition: PrayerTradition = .psalmicLament
    var selectedCategory: PrayerCategory = .gratitude  // New: intention-based category
    var generatedPrayer: Prayer?

    // MARK: - Error State

    var error: PrayerGenerationError?
    var showCrisisModal: Bool = false

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

    /// Minimum generation time for UI animation
    var minimumGenerationDuration: TimeInterval = 2.0

    // MARK: - Retry Configuration

    /// Maximum retry attempts for transient failures
    private let maxRetries: Int = 3

    /// Base delay for exponential backoff (1s, 2s, 4s)
    private let baseRetryDelay: TimeInterval = 1.0

    // MARK: - Computed Properties

    var canGenerate: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var totalWordCount: Int {
        generatedPrayer?.words.count ?? 0
    }

    var hasError: Bool {
        error != nil && error?.isCrisis != true
    }

    // MARK: - Generation Actions

    /// Start generation using tradition (legacy)
    func startGeneration(duration: TimeInterval = 2.0) {
        guard phase != .generating else { return } // Prevent double-start

        generationTask?.cancel()
        minimumGenerationDuration = duration
        phase = .generating
        error = nil
        showCrisisModal = false

        generationTask = Task { @MainActor in
            let startTime = Date()

            do {
                // 1. Validate input
                let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedInput.isEmpty else {
                    throw PrayerGenerationError.inputEmpty
                }
                guard trimmedInput.count <= 500 else {
                    throw PrayerGenerationError.inputTooLong
                }

                // 2. Moderate content (FREE via OpenAI)
                let moderation = try await OpenAIProvider.shared.moderateContent(trimmedInput)

                // Check for self-harm first (trigger crisis modal)
                if moderation.selfHarmFlagged {
                    throw PrayerGenerationError.selfHarmDetected
                }

                // Check for other flagged content
                if moderation.flagged {
                    throw PrayerGenerationError.contentFlagged
                }

                // 3. Generate prayer
                let output = try await OpenAIProvider.shared.generatePrayer(
                    input: PrayerGenerationInput(
                        userContext: trimmedInput,
                        tradition: selectedTradition
                    )
                )

                // 4. Ensure minimum animation duration
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < minimumGenerationDuration {
                    try? await Task.sleep(for: .seconds(minimumGenerationDuration - elapsed))
                }

                guard !Task.isCancelled else { return }

                // 5. Create prayer model and display
                generatedPrayer = Prayer(
                    tradition: selectedTradition,
                    content: output.content,
                    amen: output.amen,
                    userContext: trimmedInput
                )
                phase = .displaying

            } catch let prayerError as PrayerGenerationError {
                guard !Task.isCancelled else { return }
                handleError(prayerError)

            } catch let aiError as AIServiceError {
                guard !Task.isCancelled else { return }
                // Map AI errors to prayer errors
                switch aiError {
                case .rateLimited:
                    handleError(.rateLimited)
                case .networkError(let underlying):
                    handleError(.networkError(underlying))
                case .moderationUnavailable:
                    // Neutral message - does NOT trigger crisis modal
                    handleError(.moderationUnavailable)
                default:
                    handleError(.generationFailed(aiError))
                }

            } catch {
                guard !Task.isCancelled else { return }
                handleError(.generationFailed(error))
            }
        }
    }

    /// Start generation using category (new intention-based)
    func startCategoryGeneration(duration: TimeInterval = 2.0) {
        guard phase != .generating else { return }

        // Check daily quota before starting (triggers paywall if limit reached)
        // Only checks - doesn't record. Recording happens after successful generation.
        guard EntitlementManager.shared.canGeneratePrayer else {
            print("🙏 Prayer: Daily limit reached, triggering paywall")
            EntitlementManager.shared.showPaywall(trigger: .prayerLimit)
            return
        }

        generationTask?.cancel()
        minimumGenerationDuration = duration
        phase = .generating
        error = nil
        showCrisisModal = false

        generationTask = Task { @MainActor in
            let startTime = Date()

            do {
                // 1. Validate input
                let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedInput.isEmpty else {
                    throw PrayerGenerationError.inputEmpty
                }
                guard trimmedInput.count <= 500 else {
                    throw PrayerGenerationError.inputTooLong
                }

                print("🙏 Prayer: Starting moderation...")

                // 2. Moderate content (FREE via OpenAI)
                let moderation = try await OpenAIProvider.shared.moderateContent(trimmedInput)

                print("🙏 Prayer: Moderation complete, flagged=\(moderation.flagged)")

                if moderation.selfHarmFlagged {
                    throw PrayerGenerationError.selfHarmDetected
                }

                if moderation.flagged {
                    throw PrayerGenerationError.contentFlagged
                }

                print("🙏 Prayer: Starting generation for category=\(selectedCategory.rawValue)...")

                // 3. Generate prayer WITH RETRY for transient failures
                var lastError: Error?
                var output: PrayerGenerationOutput?

                for attempt in 1...maxRetries {
                    do {
                        output = try await OpenAIProvider.shared.generatePrayer(
                            input: PrayerGenerationInput(
                                userContext: trimmedInput,
                                category: selectedCategory
                            )
                        )
                        print("🙏 Prayer: Success on attempt \(attempt)!")
                        break

                    } catch let error as AIServiceError {
                        lastError = error

                        // Determine if we should retry based on error type
                        let shouldRetry: Bool = {
                            switch error {
                            case .rateLimited, .modelUnavailable, .networkError:
                                return attempt < maxRetries
                            case .notConfigured, .invalidResponse, .contentFiltered, .quotaExceeded, .moderationUnavailable:
                                return false
                            case .circuitOpen:
                                return false  // Circuit breaker open, don't retry
                            }
                        }()

                        if shouldRetry {
                            let delay = baseRetryDelay * pow(2.0, Double(attempt - 1))
                            print("🙏 Prayer: Attempt \(attempt) failed (\(error)), retrying in \(delay)s...")
                            try? await Task.sleep(for: .seconds(delay))
                        } else {
                            throw error
                        }
                    }
                }

                guard let finalOutput = output else {
                    throw lastError ?? AIServiceError.modelUnavailable
                }

                print("🙏 Prayer: Generation complete!")

                // 4. Ensure minimum animation duration
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < minimumGenerationDuration {
                    try? await Task.sleep(for: .seconds(minimumGenerationDuration - elapsed))
                }

                guard !Task.isCancelled else { return }

                // 5. Create prayer model with category
                generatedPrayer = Prayer(
                    category: selectedCategory,
                    content: finalOutput.content,
                    amen: finalOutput.amen,
                    userContext: trimmedInput
                )
                phase = .displaying

                // 6. Record successful generation for quota tracking
                EntitlementManager.shared.recordPrayerGeneration()
                print("🙏 Prayer: Quota recorded, remaining=\(EntitlementManager.shared.remainingPrayers)")

            } catch let prayerError as PrayerGenerationError {
                guard !Task.isCancelled else { return }
                print("🙏 Prayer ERROR (PrayerGenerationError): \(prayerError)")
                handleError(prayerError)

            } catch let aiError as AIServiceError {
                guard !Task.isCancelled else { return }
                print("🙏 Prayer ERROR (AIServiceError): \(aiError)")
                switch aiError {
                case .rateLimited:
                    handleError(.rateLimited)
                case .networkError(let underlying):
                    handleError(.networkError(underlying))
                case .moderationUnavailable:
                    // Neutral message - does NOT trigger crisis modal
                    handleError(.moderationUnavailable)
                case .circuitOpen:
                    // Circuit breaker tripped - service temporarily unavailable
                    handleError(.generationFailed(aiError))
                default:
                    handleError(.generationFailed(aiError))
                }

            } catch {
                guard !Task.isCancelled else { return }
                print("🙏 Prayer ERROR (other): \(error)")
                handleError(.generationFailed(error))
            }
        }
    }

    private func handleError(_ prayerError: PrayerGenerationError) {
        if prayerError.isCrisis {
            showCrisisModal = true
            error = prayerError
        } else {
            error = prayerError
        }
        phase = .input
    }

    func clearError() {
        error = nil
    }

    func dismissCrisisModal() {
        showCrisisModal = false
        // Keep the error cleared but don't reset input
        error = nil
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
        error = nil
        showCrisisModal = false
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
                withAnimation(Theme.Animation.settle) {
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
            withAnimation(Theme.Animation.slowFade) {
                isRevealComplete = true
            }
        }
    }

    /// Skip to full reveal (tap anywhere to skip)
    func skipToFullReveal() {
        cancelReveal()
        withAnimation(Theme.Animation.settle) {
            revealedWordCount = totalWordCount
            isRevealComplete = true
        }
    }

    /// Cancel ongoing reveal animation
    func cancelReveal() {
        revealTask?.cancel()
        revealTask = nil
    }

    /// Cancel all ongoing tasks (generation, reveal, toast)
    /// Called when view disappears or app goes to background
    func cancelAllTasks() {
        generationTask?.cancel()
        generationTask = nil
        revealTask?.cancel()
        revealTask = nil
        toastTask?.cancel()
        toastTask = nil

        // Reset to input phase if we were generating
        if phase == .generating {
            phase = .input
        }
    }

    // MARK: - Toast Actions

    func showActionToast(_ action: String) {
        toastTask?.cancel() // Cancel any existing toast

        toastMessage = "\(action)"
        withAnimation(Theme.Animation.settle) {
            showToast = true
        }

        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.0))
            guard !Task.isCancelled else { return }
            withAnimation(Theme.Animation.settle) {
                showToast = false
            }
        }
    }
}
