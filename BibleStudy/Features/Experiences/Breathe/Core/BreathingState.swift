import SwiftUI

// MARK: - Breathing State

/// Observable state manager for breathing exercises.
/// Uses Task-based timers following the PrayerFlowState pattern.
@Observable
@MainActor
final class BreathingState {
    // MARK: - Core State

    var selectedPattern: BreathingPattern = .sleep
    var isActive = false
    var currentPhase: BreathingPhase = .idle
    var breathScale: CGFloat = 0.7

    // MARK: - Progress State

    var phaseProgress: Double = 0
    var cycleProgress: Double = 0
    var cyclesCompleted = 0
    var totalTime: TimeInterval = 0

    // MARK: - Private Tasks

    private var sessionTask: Task<Void, Never>?
    private var timeTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Duration of the current phase in seconds.
    var currentPhaseDuration: Double {
        switch currentPhase {
        case .inhale: return selectedPattern.inhale
        case .hold1: return selectedPattern.hold1
        case .exhale: return selectedPattern.exhale
        case .hold2: return selectedPattern.hold2
        case .idle: return 0
        }
    }

    /// Human-readable remaining time in current phase.
    var phaseTimeRemaining: String {
        let remaining = (1 - phaseProgress) * currentPhaseDuration
        return String(format: "%.1fs", max(0, remaining))
    }

    /// Formatted total session time (m:ss).
    var formattedTotalTime: String {
        let minutes = Int(totalTime) / 60
        let seconds = Int(totalTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Session Control

    /// Toggles the breathing session on/off.
    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Starts the breathing session.
    func start() {
        guard !isActive else { return }

        isActive = true
        cycleProgress = 0
        phaseProgress = 0

        // Start time tracking
        timeTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                totalTime += 0.1
            }
        }

        // Start breathing cycle
        sessionTask = Task { @MainActor in
            await runPhase(.inhale)
        }
    }

    /// Stops the breathing session.
    func stop() {
        sessionTask?.cancel()
        sessionTask = nil
        timeTask?.cancel()
        timeTask = nil

        withAnimation(Theme.Animation.settle) {
            isActive = false
            currentPhase = .idle
            breathScale = 0.7
        }

        cycleProgress = 0
        phaseProgress = 0
    }

    /// Resets all state for a fresh session.
    func reset() {
        stop()
        cyclesCompleted = 0
        totalTime = 0
        selectedPattern = .sleep
    }

    /// Changes the selected pattern (only when not active).
    func selectPattern(_ pattern: BreathingPattern) {
        guard !isActive else { return }
        selectedPattern = pattern
        cyclesCompleted = 0
        totalTime = 0
    }

    // MARK: - Phase Execution

    /// Runs a single phase of the breathing cycle.
    private func runPhase(_ phase: BreathingPhase) async {
        guard isActive, !Task.isCancelled else { return }

        currentPhase = phase
        phaseProgress = 0

        let duration = currentPhaseDuration

        // Skip phases with zero duration
        if duration == 0 {
            await advanceToNextPhase()
            return
        }

        // Animate breath scale for inhale/exhale
        let targetScale = phase.scale
        if phase.shouldAnimate {
            withAnimation(.easeInOut(duration: duration)) {
                breathScale = targetScale
            }
        } else {
            breathScale = targetScale
        }

        // Light haptic at phase start
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Progress through the phase
        let startTime = Date()
        let stepInterval: TimeInterval = 0.05

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(stepInterval))
            guard !Task.isCancelled else { return }

            let elapsed = Date().timeIntervalSince(startTime)
            let progress = elapsed / duration

            // Update cycle progress
            let cycleOffset: Double
            switch phase {
            case .inhale: cycleOffset = 0
            case .hold1: cycleOffset = selectedPattern.inhale
            case .exhale: cycleOffset = selectedPattern.inhale + selectedPattern.hold1
            case .hold2: cycleOffset = selectedPattern.inhale + selectedPattern.hold1 + selectedPattern.exhale
            case .idle: cycleOffset = 0
            }

            cycleProgress = (cycleOffset + elapsed) / selectedPattern.totalCycle
            phaseProgress = min(1, progress)

            // Phase complete
            if progress >= 1 {
                await advanceToNextPhase()
                return
            }
        }
    }

    /// Advances to the next phase in the cycle.
    private func advanceToNextPhase() async {
        guard isActive, !Task.isCancelled else { return }

        switch currentPhase {
        case .inhale:
            await runPhase(.hold1)
        case .hold1:
            await runPhase(.exhale)
        case .exhale:
            await runPhase(.hold2)
        case .hold2:
            // Cycle complete
            cyclesCompleted += 1
            cycleProgress = 0
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await runPhase(.inhale)
        case .idle:
            break
        }
    }
}

// MARK: - Compline-Specific State

/// Simplified breathing state for Compline integration.
/// Always uses 4-7-8 pattern with no pattern selection.
@Observable
@MainActor
final class ComplineBreathingState {
    // MARK: - Core State

    var isActive = false
    var currentPhase: BreathingPhase = .idle
    var breathScale: CGFloat = 0.7
    var cyclesCompleted = 0

    private let pattern = BreathingPattern.complineSleep
    private var sessionTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var currentPhaseDuration: Double {
        switch currentPhase {
        case .inhale: return pattern.inhale
        case .hold1: return pattern.hold1
        case .exhale: return pattern.exhale
        case .hold2: return pattern.hold2
        case .idle: return 0
        }
    }

    // MARK: - Session Control

    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func start() {
        guard !isActive else { return }
        isActive = true

        sessionTask = Task { @MainActor in
            await runPhase(.inhale)
        }
    }

    func stop() {
        sessionTask?.cancel()
        sessionTask = nil

        withAnimation(Theme.Animation.settle) {
            isActive = false
            currentPhase = .idle
            breathScale = 0.7
        }
    }

    func reset() {
        stop()
        cyclesCompleted = 0
    }

    // MARK: - Phase Execution

    private func runPhase(_ phase: BreathingPhase) async {
        guard isActive, !Task.isCancelled else { return }

        currentPhase = phase
        let duration = currentPhaseDuration

        if duration == 0 {
            await advanceToNextPhase()
            return
        }

        let targetScale = phase.scale
        if phase.shouldAnimate {
            withAnimation(.easeInOut(duration: duration)) {
                breathScale = targetScale
            }
        } else {
            breathScale = targetScale
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        try? await Task.sleep(for: .seconds(duration))
        guard !Task.isCancelled else { return }

        await advanceToNextPhase()
    }

    private func advanceToNextPhase() async {
        guard isActive, !Task.isCancelled else { return }

        switch currentPhase {
        case .inhale:
            await runPhase(.hold1)
        case .hold1:
            await runPhase(.exhale)
        case .exhale:
            await runPhase(.hold2)
        case .hold2:
            cyclesCompleted += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            await runPhase(.inhale)
        case .idle:
            break
        }
    }
}
