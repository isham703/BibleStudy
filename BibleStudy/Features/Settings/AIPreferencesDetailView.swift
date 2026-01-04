import SwiftUI

// MARK: - AI Preferences Detail View
// "Divine Intelligence" - AI feature configuration with illuminated manuscript aesthetics

struct AIPreferencesDetailView: View {
    @Environment(\.dismiss) private var dismiss

    // Bindings to parent settings
    @Binding var scholarModeEnabled: Bool
    @Binding var aiInsightsEnabled: Bool
    @Binding var voiceGuidanceEnabled: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    headerSection

                    // AI Features Section
                    IlluminatedSettingsCard(title: "AI Features", icon: "brain.head.profile") {
                        VStack(spacing: AppTheme.Spacing.md) {
                            // Scholar Mode
                            IlluminatedToggle(
                                isOn: $scholarModeEnabled,
                                label: "Scholar Mode",
                                description: "Advanced study tools and deeper insights",
                                icon: "book.closed.fill",
                                iconColor: .scholarAccent
                            )

                            SettingsDivider()

                            // AI Insights
                            IlluminatedToggle(
                                isOn: $aiInsightsEnabled,
                                label: "AI Insights",
                                description: "Contextual understanding and explanations",
                                icon: "lightbulb.fill",
                                iconColor: .scholarAccent
                            )

                            SettingsDivider()

                            // Voice Guidance
                            IlluminatedToggle(
                                isOn: $voiceGuidanceEnabled,
                                label: "Voice Guidance",
                                description: "Spoken insights and reflections",
                                icon: "waveform",
                                iconColor: .scholarAccent
                            )
                        }
                    }

                    // About AI Section
                    aboutAISection
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationTitle("AI Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // AI Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.scholarAccent.opacity(0.2),
                                Color.scholarAccent.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.scholarAccent, Color.scholarAccent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Divine Intelligence")
                .font(Typography.Display.title2)
                .foregroundStyle(Color.primaryText)

            Text("Customize your AI-powered study experience")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.md)
    }

    // MARK: - About AI Section

    private var aboutAISection: some View {
        IlluminatedSettingsCard(title: "About AI Features", icon: "info.circle.fill", showDivider: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                featureDescription(
                    title: "Scholar Mode",
                    description: "Unlock deeper theological insights, cross-references, and advanced study tools designed for serious Bible students."
                )

                SettingsDivider()

                featureDescription(
                    title: "AI Insights",
                    description: "Receive contextual explanations, historical background, and personalized reflections as you read Scripture."
                )

                SettingsDivider()

                featureDescription(
                    title: "Voice Guidance",
                    description: "Listen to AI-narrated insights and reflections, perfect for meditation or hands-free study."
                )
            }
        }
    }

    private func featureDescription(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(Typography.UI.bodyBold)
                .foregroundStyle(Color.primaryText)

            Text(description)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    AIPreferencesDetailView(
        scholarModeEnabled: .constant(true),
        aiInsightsEnabled: .constant(true),
        voiceGuidanceEnabled: .constant(false)
    )
}
