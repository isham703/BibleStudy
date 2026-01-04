import SwiftUI

// MARK: - Living Scripture Flow State
// Observable state manager for the immersive narrative experience

@Observable
final class LivingScriptureFlowState {
    // MARK: - Core State

    var currentSceneIndex: Int = 0
    var userResponse: String = ""
    var isVisible: Bool = false
    var textOpacity: Double = 0
    var breathePhase: CGFloat = 0

    // MARK: - Story Selection

    let storyType: StoryData.StoryType

    init(storyType: StoryData.StoryType = .prodigalSon) {
        self.storyType = storyType
    }

    // MARK: - Animation Tasks

    private var breatheTask: Task<Void, Never>?
    private var fadeTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var scenes: [LivingScriptureScene] {
        switch storyType {
        case .prodigalSon:
            return StoryData.prodigalSon
        case .petersDenial:
            return StoryData.petersDenial
        case .burningBush:
            return StoryData.burningBush
        }
    }

    var storyTitle: String {
        switch storyType {
        case .prodigalSon:
            return "The Prodigal Son"
        case .petersDenial:
            return "Peter's Denial"
        case .burningBush:
            return "The Burning Bush"
        }
    }

    var finalMessage: (title: String, subtitle: String) {
        StoryData.finalMessage(for: storyType)
    }

    var currentScene: LivingScriptureScene {
        scenes[min(currentSceneIndex, scenes.count - 1)]
    }

    var isAtFinalScene: Bool {
        currentScene.isFinalScene
    }

    var progress: Double {
        Double(currentSceneIndex) / Double(max(scenes.count - 1, 1))
    }

    // MARK: - Actions

    func startExperience() {
        isVisible = true
        startBreathingAnimation()

        // Fade in text
        fadeTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 1.5)) {
                textOpacity = 1
            }
        }
    }

    func advanceScene() {
        guard currentSceneIndex < scenes.count - 1 else { return }

        // Fade out current scene
        fadeTask?.cancel()
        fadeTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 0
            }

            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }

            currentSceneIndex += 1
            userResponse = ""

            // Fade in new scene
            withAnimation(.easeIn(duration: 1.0)) {
                textOpacity = 1
            }
        }
    }

    func reset() {
        fadeTask?.cancel()
        fadeTask = nil
        breatheTask?.cancel()
        breatheTask = nil

        currentSceneIndex = 0
        userResponse = ""
        textOpacity = 0
        breathePhase = 0
        isVisible = false
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        breatheTask?.cancel()
        breatheTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 4)) {
                    breathePhase = 1
                }
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 4)) {
                    breathePhase = 0
                }
                try? await Task.sleep(for: .seconds(4))
            }
        }
    }

    deinit {
        breatheTask?.cancel()
        fadeTask?.cancel()
    }
}
