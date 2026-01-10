import SwiftUI

// MARK: - Immersive Cards Onboarding View
// Feature cards with glass morphism and depth
// Interactive, engaging experience with micro-animations

struct ImmersiveCardsOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeature: Int? = nil
    @State private var showContent = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showSignUp = false

    private let features = ImmersiveFeature.allFeatures

    var body: some View {
        ZStack {
            // Animated gradient background
            animatedBackground

            VStack(spacing: 0) {
                // Header
                header

                // Scrollable feature cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Theme.Spacing.xxl) {
                        // Hero section
                        heroSection

                        // Feature cards
                        featureCardsSection

                        // CTA section
                        ctaSection
                    }
                    .padding(.bottom, 100)
                }
            }

            // Bottom gradient fade
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color(hex: "0a0f1e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                showContent = true
            }
        }
        .sheet(isPresented: $showSignUp) {
            signUpSheet
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "0a0f1e"), location: 0),
                    .init(color: Color(hex: "0f1629"), location: 0.5),
                    .init(color: Color(hex: "0a0f1e"), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Floating orbs
            GeometryReader { geo in
                // Blue orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.vibrantBlue.opacity(Theme.Opacity.lightMedium),
                                Color.vibrantBlue.opacity(Theme.Opacity.overlay),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: 100)
                    .blur(radius: 60)

                // Teal orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.cinematicTeal.opacity(Theme.Opacity.subtle),
                                Color.cinematicTeal.opacity(Theme.Opacity.faint),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 300)
                    .blur(radius: 40)

                // Indigo orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentIndigo.opacity(Theme.Opacity.quarter),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 350, height: 350)
                    .offset(x: geo.size.width / 2 - 175, y: geo.size.height / 2)
                    .blur(radius: 50)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(Typography.Icon.base)
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Logo placeholder
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "book.closed.fill")
                    .font(Typography.Icon.base)
                    .foregroundStyle(Color.vibrantBlue)

                Text("Bible Study")
                    .font(Typography.Command.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                showSignUp = true
            } label: {
                Text("Sign In")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
            }
            .frame(width: 60)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, 60)
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Tagline
            Text("Study Smarter")
                .font(Typography.Command.caption.weight(.semibold))
                .foregroundStyle(Color.vibrantBlue)
                .textCase(.uppercase)
                .tracking(2)
                .opacity(showContent ? 1 : 0)

            // Main headline
            Text("Your AI-Powered\nBible Companion")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            // Subtitle
            Text("Discover deeper understanding through intelligent study tools, contextual insights, and personalized learning.")
                .font(Typography.Command.callout)
                .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Theme.Spacing.xl)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Feature Cards Section
    private var featureCardsSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                ImmersiveFeatureCard(
                    feature: feature,
                    isExpanded: selectedFeature == index,
                    delay: Double(index) * 0.15
                )
                .onTapGesture {
                    withAnimation(Theme.Animation.settle) {
                        if selectedFeature == index {
                            selectedFeature = nil
                        } else {
                            selectedFeature = index
                        }
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(
                    Theme.Animation.slowFade.delay(Double(index) * 0.1 + 0.3),
                    value: showContent
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - CTA Section
    private var ctaSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Primary CTA
            Button {
                showSignUp = true
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Start Your Journey")
                        .font(Typography.Command.headline)

                    Image(systemName: "arrow.right")
                        .font(Typography.Command.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.vibrantBlue, Color.vibrantBlue.opacity(Theme.Opacity.pressed)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .shadow(color: Color.vibrantBlue.opacity(Theme.Opacity.lightMedium), radius: 20, y: 10)
            }

            // Trust indicators
            HStack(spacing: Theme.Spacing.xl) {
                trustBadge(icon: "lock.shield.fill", text: "Private")
                trustBadge(icon: "star.fill", text: "4.9 Rating")
                trustBadge(icon: "arrow.down.circle.fill", text: "Free")
            }
            .opacity(Theme.Opacity.tertiary)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.xxl)
    }

    private func trustBadge(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.Command.caption)
            Text(text)
                .font(Typography.Icon.xs)
        }
        .foregroundStyle(.white)
    }

    // MARK: - Sign Up Sheet
    private var signUpSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0f1e")
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xxl) {
                    Spacer()
                        .frame(height: Theme.Spacing.xl)

                    // Header
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(Typography.Icon.hero)
                            .foregroundStyle(Color.vibrantBlue)

                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Join thousands studying Scripture with AI")
                            .font(Typography.Command.callout)
                            .foregroundStyle(.white.opacity(Theme.Opacity.tertiary))
                    }

                    // Sign up options
                    VStack(spacing: Theme.Spacing.md) {
                        signUpButton(
                            icon: "apple.logo",
                            text: "Continue with Apple",
                            background: .white,
                            foreground: .black
                        )

                        signUpButton(
                            icon: "envelope.fill",
                            text: "Continue with Email",
                            background: Color(hex: "1a1f36"),
                            foreground: .white
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(.white.opacity(Theme.Opacity.light))
                            .frame(height: 1)
                        Text("or")
                            .font(Typography.Command.caption)
                            .foregroundStyle(.white.opacity(Theme.Opacity.lightMedium))
                        Rectangle()
                            .fill(.white.opacity(Theme.Opacity.light))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, Theme.Spacing.xxl)

                    // Sign in link
                    Button {
                        // Navigate to sign in
                    } label: {
                        Text("Already have an account? **Sign In**")
                            .font(Typography.Command.subheadline)
                            .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
                    }

                    Spacer()

                    // Terms
                    Text("By continuing, you agree to our Terms and Privacy Policy")
                        .font(Typography.Command.caption)
                        .foregroundStyle(.white.opacity(Theme.Opacity.lightMedium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xxl)
                        .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSignUp = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Typography.Icon.lg)
                            .foregroundStyle(.white.opacity(Theme.Opacity.medium))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func signUpButton(
        icon: String,
        text: String,
        background: Color,
        foreground: Color
    ) -> some View {
        Button {
            // Sign up action
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(Typography.Icon.base)
                Text(text)
                    .font(Typography.Command.callout.weight(.semibold))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }
}

// MARK: - Immersive Feature Card
struct ImmersiveFeatureCard: View {
    let feature: ImmersiveFeature
    let isExpanded: Bool
    let delay: Double

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.lg) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(feature.accentColor.opacity(Theme.Opacity.light))
                        .frame(width: 48, height: 48)

                    Image(systemName: feature.iconName)
                        .font(Typography.Command.title3)
                        .foregroundStyle(feature.accentColor)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                        .font(Typography.Icon.base.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(feature.subtitle)
                        .font(Typography.Command.caption)
                        .foregroundStyle(.white.opacity(Theme.Opacity.tertiary))
                }

                Spacer()

                // Expand indicator
                Image(systemName: "chevron.down")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(.white.opacity(Theme.Opacity.lightMedium))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text(feature.description)
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(.white.opacity(Theme.Opacity.pressed))
                        .lineSpacing(4)

                    // Feature bullets
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        ForEach(feature.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(feature.accentColor)

                                Text(bullet)
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(.white.opacity(Theme.Opacity.heavy))
                            }
                        }
                    }
                }
                .padding(.top, Theme.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.xl)
        .background(
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(.ultraThinMaterial.opacity(Theme.Opacity.medium))

                // Gradient overlay
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(Theme.Opacity.overlay),
                                .white.opacity(Theme.Opacity.faint)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(Theme.Opacity.light),
                                .white.opacity(Theme.Opacity.faint)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: feature.accentColor.opacity(isExpanded ? 0.2 : 0), radius: 20, y: 10)
    }
}

// MARK: - Immersive Feature Model
struct ImmersiveFeature: Identifiable {
    let id = UUID()
    let iconName: String
    let title: String
    let subtitle: String
    let description: String
    let bullets: [String]
    let accentColor: Color

    static let allFeatures: [ImmersiveFeature] = [
        ImmersiveFeature(
            iconName: "brain.head.profile",
            title: "AI Scripture Analysis",
            subtitle: "Intelligent insights at your fingertips",
            description: "Our AI understands biblical context, historical background, and theological nuance to provide meaningful insights.",
            bullets: [
                "Contextual commentary on any passage",
                "Cross-reference suggestions",
                "Original language insights"
            ],
            accentColor: Color.vibrantBlue
        ),
        ImmersiveFeature(
            iconName: "text.book.closed.fill",
            title: "Multiple Translations",
            subtitle: "Compare and understand",
            description: "Access dozens of translations side-by-side. See how different scholars have interpreted the same passages.",
            bullets: [
                "15+ Bible translations",
                "Parallel reading view",
                "Greek & Hebrew originals"
            ],
            accentColor: Color.cinematicTeal
        ),
        ImmersiveFeature(
            iconName: "sparkles",
            title: "Ask Anything",
            subtitle: "Your personal Bible scholar",
            description: "Have questions? Ask in plain language and receive thoughtful, well-researched answers instantly.",
            bullets: [
                "Natural language queries",
                "Citation-backed responses",
                "Follow-up conversations"
            ],
            accentColor: Color.accentIndigo
        ),
        ImmersiveFeature(
            iconName: "bookmark.fill",
            title: "Personal Library",
            subtitle: "Your study, organized",
            description: "Save notes, highlights, and collections. Your personal study materials sync across all devices.",
            bullets: [
                "Highlights with categories",
                "Personal notes & reflections",
                "Custom reading plans"
            ],
            accentColor: Color.amberOrange
        )
    ]
}

// MARK: - Preview
#Preview {
    ImmersiveCardsOnboardingView()
}
