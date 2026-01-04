import SwiftUI

// MARK: - Achievement Celebration Modifier
// Observes achievement unlock notifications and displays celebration

struct AchievementCelebrationModifier: ViewModifier {
    @State private var showCelebration = false
    @State private var currentAchievement: Achievement?

    func body(content: Content) -> some View {
        content
            .celebrationOverlay(
                isPresented: $showCelebration,
                celebration: .achievement(currentAchievement ?? placeholderAchievement)
            )
            .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
                if let achievement = notification.userInfo?["achievement"] as? Achievement {
                    currentAchievement = achievement
                    withAnimation {
                        showCelebration = true
                    }
                }
            }
    }

    private var placeholderAchievement: Achievement {
        Achievement(
            id: "placeholder",
            title: "Achievement",
            description: "Description",
            icon: "star.fill",
            category: .milestones,
            xpReward: 0,
            isSecret: false,
            requiredProgress: 1
        )
    }
}

// MARK: - User Level Up Celebration Modifier
// Observes user level up notifications and displays celebration

struct UserLevelUpCelebrationModifier: ViewModifier {
    @State private var showCelebration = false
    @State private var fromLevel: UserLevel = .novice
    @State private var toLevel: UserLevel = .apprentice

    func body(content: Content) -> some View {
        content
            .celebrationOverlay(
                isPresented: $showCelebration,
                celebration: .userLevelUp(from: fromLevel, to: toLevel)
            )
            .onReceive(NotificationCenter.default.publisher(for: .userLeveledUp)) { notification in
                if let newLevel = notification.userInfo?["level"] as? UserLevel,
                   let oldLevel = notification.userInfo?["previousLevel"] as? UserLevel {
                    fromLevel = oldLevel
                    toLevel = newLevel
                    withAnimation {
                        showCelebration = true
                    }
                }
            }
    }
}

// MARK: - All Celebrations Modifier
// Combines all celebration modifiers for easy use

struct AllCelebrationsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(AchievementCelebrationModifier())
            .modifier(UserLevelUpCelebrationModifier())
    }
}

// MARK: - View Extensions

extension View {
    /// Adds achievement celebration overlay that responds to unlock notifications
    func withAchievementCelebrations() -> some View {
        modifier(AchievementCelebrationModifier())
    }

    /// Adds level up celebration overlay that responds to level up notifications
    func withLevelUpCelebrations() -> some View {
        modifier(UserLevelUpCelebrationModifier())
    }

    /// Adds all celebration overlays for achievements, level ups, etc.
    func withAllCelebrations() -> some View {
        modifier(AllCelebrationsModifier())
    }
}
