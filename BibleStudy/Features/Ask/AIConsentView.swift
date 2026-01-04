import SwiftUI

// MARK: - AI Consent View
// App Store compliance: Explicit consent for third-party AI data processing
// Reference: https://developer.apple.com/news/?id=ey6d8onl

struct AIConsentView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppConfiguration.UserDefaultsKeys.hasConsentedToAIProcessing)
    private var hasConsented: Bool = false

    let onConsent: () -> Void
    let onDecline: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
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
                .padding(AppTheme.Spacing.lg)
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
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "sparkles")
                .font(Typography.UI.largeTitle)
                .foregroundStyle(Color.scholarAccent)

            Text("Before You Begin")
                .font(Typography.Display.title2)
                .foregroundStyle(Color.primaryText)

            Text("To provide AI-powered Bible study assistance, we need your permission to process your questions.")
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    // MARK: - What We Collect

    private var whatWeCollectSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader(icon: "doc.text", title: "What We Send")

            bulletPoint("Your questions about the Bible")
            bulletPoint("Selected verse references for context")
            bulletPoint("Conversation history (for follow-up questions)")

            Text("We never send your personal information, notes, or highlights.")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .padding(.leading, AppTheme.Spacing.xl)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    // MARK: - How It's Used

    private var howItsUsedSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader(icon: "cpu", title: "How It's Processed")

            Text("Your questions are sent to OpenAI's servers to generate responses. OpenAI processes this data according to their **API Data Usage Policy**, which states that API data is not used to train their models.")
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
                .tint(Color.scholarAccent)
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    // MARK: - Your Control

    private var yourControlSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader(icon: "hand.raised", title: "Your Control")

            bulletPoint("You can withdraw consent anytime in Settings")
            bulletPoint("Declining will disable the AI assistant feature")
            bulletPoint("Your conversation history stays on your device")
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }

    // MARK: - Privacy Link

    private var privacyLinkSection: some View {
        HStack {
            Image(systemName: "lock.shield")
                .foregroundStyle(Color.tertiaryText)

            Text("Read our full **Privacy Policy**")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
                .tint(Color.scholarAccent)

            Spacer()
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Consent Buttons

    private var consentButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
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
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.appBackground)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.scholarAccent)
            Text(title)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(Color.scholarAccent)
                .frame(width: AppTheme.ComponentSize.dotSmall, height: AppTheme.ComponentSize.dotSmall)
                .padding(.top, AppTheme.Spacing.sm)

            Text(text)
                .font(Typography.UI.warmBody)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.leading, AppTheme.Spacing.sm)
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
