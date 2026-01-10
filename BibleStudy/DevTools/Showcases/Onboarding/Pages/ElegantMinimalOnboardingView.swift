import SwiftUI

// MARK: - Elegant Minimal Onboarding View
// Clean typography-focused design with generous whitespace
// Premium, understated elegance that lets content breathe

struct ElegantMinimalOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showContent = false
    @State private var emailText = ""
    @State private var isEmailFocused = false

    private let pages = ElegantMinimalPage.allPages

    var body: some View {
        ZStack {
            // Clean background
            Color(hex: "FAFAFA")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Main scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if currentPage < pages.count {
                            // Onboarding pages
                            pageContent(for: pages[currentPage])
                        } else {
                            // Sign up form
                            signUpForm
                        }
                    }
                }

                // Bottom navigation
                bottomNavigation
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                showContent = true
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                if currentPage > 0 {
                    withAnimation(Theme.Animation.settle) {
                        currentPage -= 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: currentPage == 0 ? "xmark" : "arrow.left")
                    .font(Typography.Icon.md)
                    .foregroundStyle(Color.surfaceRaised)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Progress indicator
            if currentPage < pages.count {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Rectangle()
                            .fill(index <= currentPage ? Color.surfaceRaised : Color.lightGray)
                            .frame(width: index == currentPage ? 24 : 8, height: 2)
                            .animation(Theme.Animation.settle, value: currentPage)
                    }
                }
            }

            Spacer()

            // Skip button (hidden when on last page or signup)
            Button {
                withAnimation(Theme.Animation.settle) {
                    currentPage = pages.count
                }
            } label: {
                Text("Skip")
                    .font(Typography.Command.callout)
                    .foregroundStyle(Color(hex: "666666"))
            }
            .opacity(currentPage < pages.count - 1 ? 1 : 0)
            .frame(width: 44)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, 8)
        .frame(height: 60)
    }

    // MARK: - Page Content
    @ViewBuilder
    private func pageContent(for page: ElegantMinimalPage) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            // Large typography hero
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Accent line
                Rectangle()
                    .fill(Color.accentIndigo)
                    .frame(width: 40, height: 3)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -20)

                // Main headline
                Text(page.headline)
                    .font(Typography.Scripture.display.weight(.light))
                    .foregroundStyle(Color.surfaceRaised)
                    .lineSpacing(8)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                // Supporting text
                Text(page.supportingText)
                    .font(Typography.Icon.base)
                    .foregroundStyle(Color(hex: "666666"))
                    .lineSpacing(6)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 15)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.xxl)

            Spacer()
                .frame(height: 60)

            // Feature list
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                    featureRow(feature, index: index)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(
                            Theme.Animation.slowFade.delay(Double(index) * 0.1),
                            value: showContent
                        )
                }
            }
            .padding(.horizontal, Theme.Spacing.xxl)

            Spacer()
                .frame(minHeight: 100)
        }
    }

    // MARK: - Feature Row
    private func featureRow(_ feature: ElegantFeature, index: Int) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.lg) {
            // Number indicator
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.accentIndigo)
                .frame(width: 24)

            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(feature.title)
                    .font(Typography.Command.callout.weight(.semibold))
                    .foregroundStyle(Color.surfaceRaised)

                Text(feature.description)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color(hex: "888888"))
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Sign Up Form
    private var signUpForm: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Rectangle()
                        .fill(Color.accentIndigo)
                        .frame(width: 40, height: 3)

                    Text("Begin your\njourney")
                        .font(Typography.Scripture.display.weight(.light))
                        .foregroundStyle(Color.surfaceRaised)
                        .lineSpacing(8)

                    Text("Create an account to personalize your study experience.")
                        .font(Typography.Command.callout)
                        .foregroundStyle(Color(hex: "666666"))
                }

                // Email field
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Email")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color(hex: "888888"))
                        .textCase(.uppercase)
                        .tracking(1)

                    TextField("your@email.com", text: $emailText)
                        .font(Typography.Icon.base.weight(.regular))
                        .foregroundStyle(Color.surfaceRaised)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.vertical, Theme.Spacing.md)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(isEmailFocused ? Color.accentIndigo : Color.lightGray)
                                .frame(height: isEmailFocused ? 2 : 1)
                        }
                        .onTapGesture {
                            isEmailFocused = true
                        }
                }

                // Continue with email button
                Button {
                    // Continue action
                } label: {
                    Text("Continue")
                        .font(Typography.Command.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                }

                // Divider
                HStack(spacing: Theme.Spacing.lg) {
                    Rectangle()
                        .fill(Color.lightGray)
                        .frame(height: 1)

                    Text("or")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color(hex: "888888"))

                    Rectangle()
                        .fill(Color.lightGray)
                        .frame(height: 1)
                }

                // Social sign in
                VStack(spacing: Theme.Spacing.md) {
                    socialButton(
                        icon: "apple.logo",
                        text: "Continue with Apple",
                        style: .dark
                    )

                    socialButton(
                        icon: "g.circle.fill",
                        text: "Continue with Google",
                        style: .light
                    )
                }

                // Terms
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color(hex: "AAAAAA"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Theme.Spacing.xxl)

            Spacer()
        }
    }

    // MARK: - Social Button
    private enum SocialButtonStyle {
        case dark, light
    }

    private func socialButton(icon: String, text: String, style: SocialButtonStyle) -> some View {
        Button {
            // Social sign in action
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(Typography.Icon.base)

                Text(text)
                    .font(Typography.Icon.md)
            }
            .foregroundStyle(style == .dark ? .white : Color.surfaceRaised)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(style == .dark ? Color.surfaceRaised : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.lightGray, lineWidth: style == .light ? 1 : 0)
            )
        }
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        VStack(spacing: 0) {
            // Subtle divider
            Rectangle()
                .fill(Color(hex: "F0F0F0"))
                .frame(height: 1)

            HStack {
                if currentPage < pages.count {
                    // Page navigation
                    Button {
                        withAnimation(Theme.Animation.settle) {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Text(currentPage == pages.count - 1 ? "Create Account" : "Next")
                                .font(Typography.Command.callout.weight(.semibold))

                            Image(systemName: "arrow.right")
                                .font(Typography.Command.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.xxl)
                        .frame(height: 48)
                        .background(Color.surfaceRaised)
                    }

                    Spacer()

                    // Sign in link
                    Button {
                        // Navigate to sign in
                    } label: {
                        Text("Sign In")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color(hex: "666666"))
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Color(hex: "FAFAFA"))
    }
}

// MARK: - Elegant Minimal Page Model
struct ElegantMinimalPage: Identifiable {
    let id = UUID()
    let headline: String
    let supportingText: String
    let features: [ElegantFeature]

    static let allPages: [ElegantMinimalPage] = [
        ElegantMinimalPage(
            headline: "Scripture,\nreimagined",
            supportingText: "A thoughtfully designed experience for deeper understanding.",
            features: [
                ElegantFeature(
                    title: "Intelligent Study Tools",
                    description: "AI-powered analysis that surfaces insights without overwhelming you."
                ),
                ElegantFeature(
                    title: "Beautiful Reading",
                    description: "Typography and layouts designed for extended, comfortable reading."
                ),
                ElegantFeature(
                    title: "Personal Library",
                    description: "Your notes, highlights, and discoveries in one elegant space."
                )
            ]
        ),
        ElegantMinimalPage(
            headline: "Ask, and you\nshall receive",
            supportingText: "Your questions deserve thoughtful, nuanced answers.",
            features: [
                ElegantFeature(
                    title: "Conversational AI",
                    description: "Ask questions in natural language and receive scholarly responses."
                ),
                ElegantFeature(
                    title: "Historical Context",
                    description: "Understand the world in which these texts were written."
                ),
                ElegantFeature(
                    title: "Cross-References",
                    description: "Discover connections across the entire biblical canon."
                )
            ]
        ),
        ElegantMinimalPage(
            headline: "Your study,\nyour way",
            supportingText: "Personalized features that adapt to how you learn.",
            features: [
                ElegantFeature(
                    title: "Reading Plans",
                    description: "Structured journeys through Scripture at your own pace."
                ),
                ElegantFeature(
                    title: "Memory Tools",
                    description: "Techniques to help you internalize what you read."
                ),
                ElegantFeature(
                    title: "Sync Everywhere",
                    description: "Your progress follows you across all your devices."
                )
            ]
        )
    ]
}

// MARK: - Elegant Feature Model
struct ElegantFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

// MARK: - Preview
#Preview {
    ElegantMinimalOnboardingView()
}
