import SwiftUI

// MARK: - AI Consent View
// App Store compliance: Explicit consent for third-party AI data processing
// Reference: https://developer.apple.com/news/?id=ey6d8onl

struct AIConsentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppConfiguration.UserDefaultsKeys.hasConsentedToAIProcessing)
    private var hasConsented: Bool = false

    let onConsent: () -> Void
    let onDecline: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    // Header
                    headerSection

                    // What we collect
                    whatWeCollectSection

                    // How it's used
                    howItsUsedSection

                    // Your control
                    yourControlSection

                    // Privacy link
                    privacyLinkSection
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle("AI Study Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDecline()
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                consentButtons
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "sparkles")
                .font(Typography.Command.largeTitle)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            Text("Before You Begin")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            Text("To provide AI-powered Bible study assistance, we need your permission to process your questions.")
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - What We Collect

    private var whatWeCollectSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(icon: "doc.text", title: "What We Send")

            bulletPoint("Your questions about the Bible")
            bulletPoint("Selected verse references for context")
            bulletPoint("Conversation history (for follow-up questions)")

            Text("We never send your personal information, notes, or highlights.")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
                .padding(.leading, Theme.Spacing.xl)
        }
        .padding(Theme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - How It's Used

    private var howItsUsedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(icon: "cpu", title: "How It's Processed")

            Text("Your questions are sent to OpenAI's servers to generate responses. OpenAI processes this data according to their **API Data Usage Policy**, which states that API data is not used to train their models.")
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
                .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
        }
        .padding(Theme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - Your Control

    private var yourControlSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(icon: "hand.raised", title: "Your Control")

            bulletPoint("You can withdraw consent anytime in Settings")
            bulletPoint("Declining will disable the AI assistant feature")
            bulletPoint("Your conversation history stays on your device")
        }
        .padding(Theme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - Privacy Link

    private var privacyLinkSection: some View {
        HStack {
            Image(systemName: "lock.shield")
                .foregroundStyle(Color.tertiaryText)

            Text("Read our full **Privacy Policy**")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.tertiaryText)
                .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            Spacer()
        }
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Consent Buttons

    private var consentButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                grantConsent()
            } label: {
                Text("I Agree")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)

            Button {
                onDecline()
                dismiss()
            } label: {
                Text("Not Now")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.appBackground)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            Text(title)
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 24, height: 24)
                .padding(.top, Theme.Spacing.sm)

            Text(text)
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.leading, Theme.Spacing.sm)
    }

    private func grantConsent() {
        hasConsented = true
        UserDefaults.standard.set(Date(), forKey: AppConfiguration.UserDefaultsKeys.aiConsentDate)
        onConsent()
        dismiss()
    }
}

// MARK: - AI Consent Manager

@Observable
@MainActor
final class AIConsentManager {
    static let shared = AIConsentManager()

    var hasConsented: Bool {
        UserDefaults.standard.bool(forKey: AppConfiguration.UserDefaultsKeys.hasConsentedToAIProcessing)
    }

    var consentDate: Date? {
        UserDefaults.standard.object(forKey: AppConfiguration.UserDefaultsKeys.aiConsentDate) as? Date
    }

    func revokeConsent() {
        UserDefaults.standard.set(false, forKey: AppConfiguration.UserDefaultsKeys.hasConsentedToAIProcessing)
        UserDefaults.standard.removeObject(forKey: AppConfiguration.UserDefaultsKeys.aiConsentDate)
    }

    func checkConsentRequired() -> Bool {
        !hasConsented
    }
}

// MARK: - View Modifier for Consent Check

struct AIConsentCheckModifier: ViewModifier {
    @State private var showConsentSheet = false
    @State private var hasCheckedConsent = false

    let onConsentGranted: () -> Void
    let onConsentDenied: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                checkConsent()
            }
            .sheet(isPresented: $showConsentSheet) {
                AIConsentView(
                    onConsent: {
                        onConsentGranted()
                    },
                    onDecline: {
                        onConsentDenied()
                    }
                )
                .interactiveDismissDisabled()
            }
    }

    private func checkConsent() {
        guard !hasCheckedConsent else { return }
        hasCheckedConsent = true

        if AIConsentManager.shared.checkConsentRequired() {
            showConsentSheet = true
        }
    }
}

extension View {
    func requiresAIConsent(
        onGranted: @escaping () -> Void = {},
        onDenied: @escaping () -> Void = {}
    ) -> some View {
        modifier(AIConsentCheckModifier(
            onConsentGranted: onGranted,
            onConsentDenied: onDenied
        ))
    }
}

// MARK: - Preview

#Preview("AI Consent") {
    AIConsentView(
        onConsent: { print("Consented") },
        onDecline: { print("Declined") }
    )
}
