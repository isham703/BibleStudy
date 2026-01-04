import SwiftUI

// MARK: - Celebration Overlay
// A full-screen overlay for displaying celebration animations

struct CelebrationOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    let celebration: CelebrationType
    let content: () -> Content

    init(
        isPresented: Binding<Bool>,
        celebration: CelebrationType,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self._isPresented = isPresented
        self.celebration = celebration
        self.content = content
    }

    var body: some View {
        ZStack {
            content()

            if isPresented {
                // Dimmed background
                Color.black.opacity(AppTheme.Opacity.disabled)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss()
                    }

                // Celebration content
                celebration.view {
                    dismiss()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(AppTheme.Animation.spring, value: isPresented)
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                triggerHaptic()
            }
        }
    }

    private func triggerHaptic() {
        Task { @MainActor in
            switch celebration {
            case .correctAnswer:
                HapticService.shared.correctAnswer()
            case .wrongAnswer:
                HapticService.shared.wrongAnswer()
            case .firstVerseMastered:
                HapticService.shared.firstVerseMastered()
            case .streak(let count):
                HapticService.shared.streakMilestone(count: count)
            case .levelUp:
                HapticService.shared.levelUp()
            case .achievement:
                HapticService.shared.achievementUnlocked()
            case .userLevelUp:
                HapticService.shared.userLevelUp()
            }
        }
    }

    private func dismiss() {
        withAnimation {
            isPresented = false
        }
    }
}

// MARK: - Celebration Types
enum CelebrationType {
    case correctAnswer
    case wrongAnswer
    case firstVerseMastered
    case streak(Int)
    case levelUp(from: MasteryLevel, to: MasteryLevel)
    case achievement(Achievement)
    case userLevelUp(from: UserLevel, to: UserLevel)

    @ViewBuilder
    func view(onComplete: @escaping () -> Void) -> some View {
        switch self {
        case .correctAnswer:
            CelebrationCard {
                CorrectAnswerCelebration(onComplete: onComplete)
                    .frame(width: 200, height: 80)
            }

        case .wrongAnswer:
            CelebrationCard {
                WrongAnswerFeedback(onComplete: onComplete)
            }

        case .firstVerseMastered:
            CelebrationCard {
                FirstVerseMasteredCelebration(onComplete: onComplete)
            }

        case .streak(let count):
            CelebrationCard {
                StreakCelebration(streakCount: count, onComplete: onComplete)
            }

        case .levelUp(let from, let to):
            CelebrationCard {
                LevelUpCelebration(fromLevel: from, toLevel: to, onComplete: onComplete)
            }

        case .achievement(let achievement):
            CelebrationCard {
                AchievementCelebration(achievement: achievement, onComplete: onComplete)
            }

        case .userLevelUp(let from, let to):
            CelebrationCard {
                UserLevelUpCelebration(fromLevel: from, toLevel: to, onComplete: onComplete)
            }
        }
    }
}

// MARK: - Celebration Card
private struct CelebrationCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .fill(Color.surfaceBackground)
            )
            .shadow(AppTheme.Shadow.large)
    }
}

// MARK: - View Extension for Celebration
extension View {
    func celebrationOverlay(
        isPresented: Binding<Bool>,
        celebration: CelebrationType
    ) -> some View {
        CelebrationOverlay(isPresented: isPresented, celebration: celebration) {
            self
        }
    }
}

// MARK: - Inline Celebration Effect
// Smaller celebration that appears inline (not as overlay)

struct InlineCelebrationEffect: View {
    let type: InlineCelebrationType
    @Binding var isShowing: Bool

    var body: some View {
        Group {
            switch type {
            case .correctPulse:
                if isShowing {
                    NodePulse(color: .warmGold, maxScale: 2, ringCount: 2)
                        .frame(width: 20, height: 20)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                isShowing = false
                            }
                        }
                }

            case .incorrectShake:
                EmptyView() // Handled by modifier

            case .streakFlame:
                if isShowing {
                    Image(systemName: "flame.fill")
                        .font(Typography.UI.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .warmGold],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
}

enum InlineCelebrationType {
    case correctPulse
    case incorrectShake
    case streakFlame
}

// MARK: - Shake Effect Modifier
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

private struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(AppTheme.Animation.quick) {
                        shakeAmount = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        shakeAmount = 0
                    }
                }
            }
    }
}

// MARK: - Preview
#Preview("Celebration Overlay") {
    struct PreviewWrapper: View {
        @State private var showCorrect = false
        @State private var showMastered = false
        @State private var showStreak = false
        @State private var showLevelUp = false

        var body: some View {
            VStack(spacing: AppTheme.Spacing.xl) {
                Button("Show Correct Answer") {
                    showCorrect = true
                }

                Button("Show First Mastered") {
                    showMastered = true
                }

                Button("Show 7-Day Streak") {
                    showStreak = true
                }

                Button("Show Level Up") {
                    showLevelUp = true
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .celebrationOverlay(isPresented: $showCorrect, celebration: .correctAnswer)
            .celebrationOverlay(isPresented: $showMastered, celebration: .firstVerseMastered)
            .celebrationOverlay(isPresented: $showStreak, celebration: .streak(7))
            .celebrationOverlay(isPresented: $showLevelUp, celebration: .levelUp(from: .learning, to: .reviewing))
        }
    }

    return PreviewWrapper()
}
