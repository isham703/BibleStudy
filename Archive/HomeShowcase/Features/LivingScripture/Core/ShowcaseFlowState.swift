import SwiftUI

// MARK: - Showcase Flow Phase

enum ShowcaseFlowPhase {
    case entering
    case viewing
    case responding
    case transitioning
    case complete
}

// MARK: - Showcase Flow State

@Observable
class ShowcaseFlowState {
    var phase: ShowcaseFlowPhase = .entering
    var currentSceneIndex: Int = 0
    var userResponse: String = ""
    var textOpacity: Double = 0
    var breathePhase: CGFloat = 0
    var isVisible: Bool = false

    private var breatheTask: Task<Void, Never>?

    var scenes: [ShowcaseScene] {
        ShowcaseMockData.defaultScenes
    }

    var currentScene: ShowcaseScene {
        scenes[min(currentSceneIndex, scenes.count - 1)]
    }

    var isLastScene: Bool {
        currentSceneIndex >= scenes.count - 1
    }

    var sceneCount: Int {
        scenes.count
    }

    // MARK: - Lifecycle

    func onAppear() {
        startBreathing()
        withAnimation(.easeIn(duration: 2.0)) {
            isVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 1.5)) {
                self.textOpacity = 1
            }
        }
        phase = .viewing
    }

    func onDisappear() {
        breatheTask?.cancel()
        breatheTask = nil
    }

    // MARK: - Breathing Animation

    private func startBreathing() {
        breatheTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 4)) {
                    breathePhase = breathePhase == 0 ? 1 : 0
                }
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
        }
    }

    // MARK: - Scene Navigation

    func advanceScene() {
        guard !isLastScene else {
            phase = .complete
            return
        }

        phase = .transitioning

        // Fade out
        withAnimation(.easeOut(duration: 0.5)) {
            textOpacity = 0
        }

        // Advance after fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentSceneIndex += 1
            self.userResponse = ""

            // Fade in new scene
            withAnimation(.easeIn(duration: 1.0)) {
                self.textOpacity = 1
            }

            self.phase = self.isLastScene && self.currentScene.prompt == nil ? .complete : .viewing
        }
    }

    func reset() {
        currentSceneIndex = 0
        userResponse = ""
        textOpacity = 0
        phase = .entering
        isVisible = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.onAppear()
        }
    }
}
