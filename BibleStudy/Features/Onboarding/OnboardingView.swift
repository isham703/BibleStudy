import SwiftUI

// MARK: - Onboarding Flow State

private let analytics = AnalyticsService.shared

enum OnboardingStep {
    case valueProps      // Animated intro pages
    case nameEntry       // Collect user's name for personalization
    case goalQuiz        // Collect user preferences
    case personalization // Loading animation + mode assignment
}

// MARK: - Onboarding View
// Main onboarding coordinator managing the full flow

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentStep: OnboardingStep = .valueProps
    @State private var onboardingData = OnboardingData()

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            switch currentStep {
            case .valueProps:
                ValuePropsView(
                    onComplete: { advanceToNameEntry() },
                    onSkip: { skipToEnd() }
                )
                .transition(.opacity)

            case .nameEntry:
                NameEntryView(
                    userName: $onboardingData.userName,
                    onComplete: { advanceToQuiz() },
                    onSkip: { advanceToQuiz() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .goalQuiz:
                GoalQuizView(
                    onboardingData: $onboardingData,
                    onComplete: { advanceToPersonalization() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .personalization:
                PersonalizationView(
                    onboardingData: onboardingData,
                    onComplete: { completeOnboarding() }
                )
                .transition(.opacity)
            }
        }
        .animation(AppTheme.Animation.spring, value: currentStep)
    }

    private func advanceToNameEntry() {
        currentStep = .nameEntry
    }

    private func advanceToQuiz() {
        analytics.track(.onboardingQuizStarted)
        currentStep = .goalQuiz
    }

    private func advanceToPersonalization() {
        analytics.track(.onboardingQuizCompleted)
        currentStep = .personalization
    }

    private func skipToEnd() {
        // Skip quiz, use defaults
        analytics.trackOnboardingSkipped()
        onboardingData = OnboardingData(
            primaryFocus: "devotional",
            dailyTimeCommitment: "10",
            experienceLevel: "occasional"
        )
        completeOnboarding()
    }

    private func completeOnboarding() {
        // Track completion
        analytics.trackOnboardingCompleted(
            mode: onboardingData.recommendedMode.rawValue,
            dailyGoal: onboardingData.dailyGoalMinutes
        )

        // Save user name for personalized greeting
        if let userName = onboardingData.userName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !userName.isEmpty {
            UserDefaults.standard.set(userName, forKey: AppConfiguration.UserDefaultsKeys.userName)
        }

        // Apply settings to app state
        appState.applyOnboardingData(onboardingData)

        // Sync daily goal to ProgressService and mark onboarding completed in remote profile
        Task {
            try? await ProgressService.shared.setDailyGoal(minutes: onboardingData.dailyGoalMinutes)

            // Sync onboarding completion to remote profile (if authenticated)
            try? await AuthService.shared.markOnboardingCompleted()
        }

        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Value Props View
// Animated intro pages showcasing app features

struct ValuePropsView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Study the Bible with AI-powered insights",
            subtitle: "Understand scripture deeper.\nMemorize verses that stick.\nBuild a consistent habit.",
            animationType: .welcome
        ),
        OnboardingPage(
            title: "Read & Study",
            subtitle: "Highlight verses, take notes, and discover connections across scripture",
            animationType: .readStudy
        ),
        OnboardingPage(
            title: "Memorize",
            subtitle: "Build lasting memory pathways with spaced repetition",
            animationType: .memorize
        ),
        OnboardingPage(
            title: "Ask AI",
            subtitle: "Get thoughtful answers to your Bible questions",
            animationType: .askAI
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    onSkip()
                }
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
                .padding()
            }

            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                analytics.trackOnboardingStarted()
            }

            // Bottom section
            VStack(spacing: AppTheme.Spacing.lg) {
                // Page indicator
                OnboardingPageIndicator(
                    currentPage: currentPage,
                    pageCount: pages.count
                )

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation(AppTheme.Animation.spring) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(Typography.UI.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(Color.accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
            }
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let animationType: OnboardingAnimationType
}

enum OnboardingAnimationType {
    case welcome
    case readStudy
    case memorize
    case askAI

    @ViewBuilder
    var animationView: some View {
        switch self {
        case .welcome:
            WelcomeAnimation()
        case .readStudy:
            ReadStudyAnimation()
        case .memorize:
            MemorizeAnimation()
        case .askAI:
            AskAIAnimation()
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()

            // Animation
            page.animationType.animationView
                .frame(width: 250, height: 250)

            // Text content
            VStack(spacing: AppTheme.Spacing.md) {
                Text(page.title)
                    .font(Typography.Display.title1)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(Typography.UI.warmBody)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Onboarding Page Indicator
struct OnboardingPageIndicator: View {
    let currentPage: Int
    let pageCount: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.divineGold : Color.divineGold.opacity(AppTheme.Opacity.medium))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(AppTheme.Animation.spring, value: currentPage)
            }
        }
    }
}

// MARK: - Name Entry View
// Collects user's first name for personalized greeting

struct NameEntryView: View {
    @Binding var userName: String?
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var nameText: String = ""
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    onSkip()
                }
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
                .padding()
            }

            Spacer()

            // Content
            VStack(spacing: AppTheme.Spacing.xxl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentGold.opacity(AppTheme.Opacity.light))
                        .frame(width: 120, height: 120)

                    Image(systemName: "person.fill")
                        .font(.system(size: Typography.Scale.xxxl + 6))
                        .foregroundStyle(Color.accentGold)
                }

                // Title
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("What should we call you?")
                        .font(Typography.Display.title2)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)

                    Text("This helps personalize your experience")
                        .font(Typography.UI.warmBody)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                }

                // Name input field
                VStack(spacing: AppTheme.Spacing.sm) {
                    TextField("Your first name", text: $nameText)
                        .font(Typography.Display.headline)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)
                        .textContentType(.givenName)
                        .autocorrectionDisabled()
                        .focused($isNameFieldFocused)
                        .padding(AppTheme.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                .fill(Color.surfaceBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                .stroke(
                                    isNameFieldFocused ? Color.accentGold : Color.cardBorder,
                                    lineWidth: isNameFieldFocused ? 2 : 1
                                )
                        )
                        .padding(.horizontal, AppTheme.Spacing.xl)
                }
            }

            Spacer()

            // Continue button
            Button(action: {
                if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    userName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                onComplete()
            }) {
                Text("Continue")
                    .font(Typography.UI.buttonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(Color.accentGold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Onboarding") {
    OnboardingView()
}

#Preview("Name Entry") {
    NameEntryView(
        userName: .constant(nil),
        onComplete: {},
        onSkip: {}
    )
}
