import SwiftUI

// MARK: - Goal Quiz View
// Collects user preferences to personalize the experience and assign Dual-Mode

private let analytics = AnalyticsService.shared

struct GoalQuizView: View {
    @Binding var onboardingData: OnboardingData
    let onComplete: () -> Void

    @State private var currentQuestion = 0
    @State private var animateIn = false

    private let questions: [QuizQuestion] = [
        QuizQuestion(
            title: "What's your primary focus?",
            options: [
                QuizOption(id: "devotional", title: "Daily devotional", subtitle: "5-10 min/day", icon: "heart.fill"),
                QuizOption(id: "study", title: "In-depth study", subtitle: "30+ min sessions", icon: "book.fill"),
                QuizOption(id: "memorize", title: "Scripture memorization", subtitle: "Build lasting memory", icon: "brain.head.profile"),
                QuizOption(id: "explore", title: "Just exploring", subtitle: "See what's here", icon: "sparkles")
            ]
        ),
        QuizQuestion(
            title: "How much time can you commit daily?",
            options: [
                QuizOption(id: "5", title: "5 minutes", subtitle: "Quick daily habit", icon: "clock"),
                QuizOption(id: "10", title: "10 minutes", subtitle: "Focused reading", icon: "clock.fill"),
                QuizOption(id: "15", title: "15 minutes", subtitle: "Deeper engagement", icon: "timer"),
                QuizOption(id: "30", title: "30+ minutes", subtitle: "Extended study", icon: "hourglass")
            ]
        ),
        QuizQuestion(
            title: "What's your Bible reading experience?",
            options: [
                QuizOption(id: "new", title: "New to the Bible", subtitle: "Just getting started", icon: "leaf"),
                QuizOption(id: "occasional", title: "Read occasionally", subtitle: "Some familiarity", icon: "book.closed"),
                QuizOption(id: "regular", title: "Read regularly", subtitle: "Consistent reader", icon: "books.vertical"),
                QuizOption(id: "extensive", title: "Studied extensively", subtitle: "Deep experience", icon: "graduationcap")
            ]
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(current: currentQuestion + 1, total: questions.count)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.lg)

                Spacer()

                // Question content
                if currentQuestion < questions.count {
                    QuestionView(
                        question: questions[currentQuestion],
                        selectedOption: bindingForQuestion(currentQuestion),
                        onSelect: { handleSelection($0) }
                    )
                    .id(currentQuestion)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }

                Spacer()

                // Back button (if not first question)
                if currentQuestion > 0 {
                    Button(action: goBack) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.secondaryText)
                    }
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
        }
        .onAppear {
            withAnimation(AppTheme.Animation.standard) {
                animateIn = true
            }
        }
    }

    private func bindingForQuestion(_ index: Int) -> Binding<String?> {
        switch index {
        case 0:
            return $onboardingData.primaryFocus
        case 1:
            return $onboardingData.dailyTimeCommitment
        case 2:
            return $onboardingData.experienceLevel
        default:
            return .constant(nil)
        }
    }

    private func handleSelection(_ optionId: String) {
        // Track quiz answer
        analytics.trackOnboardingQuizAnswer(question: currentQuestion + 1, answer: optionId)

        // Store selection
        switch currentQuestion {
        case 0:
            onboardingData.primaryFocus = optionId
        case 1:
            onboardingData.dailyTimeCommitment = optionId
        case 2:
            onboardingData.experienceLevel = optionId
        default:
            break
        }

        // Auto-advance after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentQuestion < questions.count - 1 {
                withAnimation(AppTheme.Animation.spring) {
                    currentQuestion += 1
                }
            } else {
                // Quiz complete
                onComplete()
            }
        }
    }

    private func goBack() {
        withAnimation(AppTheme.Animation.spring) {
            currentQuestion -= 1
        }
    }
}

// MARK: - Question View

struct QuestionView: View {
    let question: QuizQuestion
    @Binding var selectedOption: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Text(question.title)
                .font(Typography.Display.title2)
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(question.options) { option in
                    OptionButton(
                        option: option,
                        isSelected: selectedOption == option.id,
                        onTap: { onSelect(option.id) }
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
    }
}

// MARK: - Option Button

struct OptionButton: View {
    let option: QuizOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.scholarAccent : Color.surfaceBackground)
                        .frame(width: 44, height: 44)

                    Image(systemName: option.icon)
                        .font(Typography.UI.headline)
                        .foregroundStyle(isSelected ? .white : Color.secondaryText)
                }

                // Text
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(option.title)
                        .font(Typography.Display.headline)
                        .foregroundStyle(Color.primaryText)

                    Text(option.subtitle)
                        .font(Typography.UI.warmSubheadline)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.UI.title3)
                        .foregroundStyle(Color.scholarAccent)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(isSelected ? Color.scholarAccent.opacity(AppTheme.Opacity.subtle) : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(isSelected ? Color.scholarAccent : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppTheme.Animation.quick, value: isSelected)
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let current: Int
    let total: Int

    var progress: CGFloat {
        CGFloat(current) / CGFloat(total)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color.surfaceBackground)
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color.scholarAccent)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(AppTheme.Animation.spring, value: progress)
                }
            }
            .frame(height: 8)

            Text("Question \(current) of \(total)")
                .font(Typography.UI.warmSubheadline.monospacedDigit())
                .foregroundStyle(Color.tertiaryText)
        }
    }
}

// MARK: - Data Models

struct QuizQuestion: Identifiable {
    let id = UUID()
    let title: String
    let options: [QuizOption]
}

struct QuizOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Onboarding Data

struct OnboardingData {
    var userName: String?
    var primaryFocus: String?
    var dailyTimeCommitment: String?
    var experienceLevel: String?

    /// Determines the app mode based on quiz answers
    var recommendedMode: AppMode {
        // Study mode if in-depth study selected OR 30+ minutes OR extensive experience
        if primaryFocus == "study" ||
           dailyTimeCommitment == "30" ||
           experienceLevel == "extensive" {
            return .study
        }
        // Default to devotion mode for casual users
        return .devotion
    }

    /// Daily goal in minutes based on selection
    var dailyGoalMinutes: Int {
        switch dailyTimeCommitment {
        case "5": return 5
        case "10": return 10
        case "15": return 15
        case "30": return 30
        default: return 10
        }
    }

    /// Starting point recommendation based on experience
    var startingBook: String {
        switch experienceLevel {
        case "new": return "John"          // Gospel, accessible
        case "occasional": return "John"   // Familiar, engaging
        case "regular": return "Genesis"   // Start from beginning
        case "extensive": return "Genesis" // Full context
        default: return "John"
        }
    }
}

/// App mode determines home screen layout and emphasized features
enum AppMode: String, Codable {
    case devotion  // Daily verse + visual card, streaks, quick insights
    case study     // Reading plan progress, search, notes, Hebrew/Greek

    var displayName: String {
        switch self {
        case .devotion: return "Devotion Mode"
        case .study: return "Study Mode"
        }
    }

    var description: String {
        switch self {
        case .devotion:
            return "Daily verse, quick insights, and streak tracking"
        case .study:
            return "Reading plans, notes, and in-depth study tools"
        }
    }

    var icon: String {
        switch self {
        case .devotion: return "heart.fill"
        case .study: return "book.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    GoalQuizView(
        onboardingData: .constant(OnboardingData()),
        onComplete: {}
    )
}
