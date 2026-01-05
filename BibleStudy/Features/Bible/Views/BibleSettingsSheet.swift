import SwiftUI

// MARK: - Scholar Settings Sheet
// Settings sheet for Scholar tab - insight types, Greek level, behavior

struct BibleSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = BibleSettings.shared
    @State private var showAboutSheet = false
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Insight Types Section
                    insightTypesSection

                    // Greek Annotations Section
                    greekSection

                    // Behavior Section
                    behaviorSection

                    // About Section
                    aboutSection

                    // Reset Section
                    resetSection
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xl)
            }
            .background(Color.appBackground)
            .navigationTitle("Scholar Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Typography.UI.body.weight(.medium))
                    .foregroundStyle(Color.scholarIndigo)
                }
            }
        }
        .sheet(isPresented: $showAboutSheet) {
            BibleAboutSheet()
        }
        .confirmationDialog(
            "Reset Reading Position",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to John 1", role: .destructive) {
                settings.resetReadingPosition()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset your reading position to John Chapter 1.")
        }
    }

    // MARK: - Insight Types Section

    private var insightTypesSection: some View {
        IlluminatedSettingsCard(title: "Insight Types", icon: "sparkles") {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Choose which insights appear when you long-press a verse.")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, AppTheme.Spacing.xs)

                // Theology
                insightTypeRow(
                    icon: "person.2.fill",
                    color: .theologyGreen,
                    title: "Theology",
                    subtitle: "Doctrinal concepts and themes",
                    isEnabled: $settings.showTheology
                )

                SettingsDivider()

                // Reflection
                insightTypeRow(
                    icon: "questionmark.circle.fill",
                    color: .personalRose,
                    title: "Reflection",
                    subtitle: "Personal application prompts",
                    isEnabled: $settings.showReflection
                )

                SettingsDivider()

                // Connections
                insightTypeRow(
                    icon: "link",
                    color: .connectionAmber,
                    title: "Connections",
                    subtitle: "Cross-references to other Scripture",
                    isEnabled: $settings.showConnections
                )

                SettingsDivider()

                // Greek
                insightTypeRow(
                    icon: "textformat.abc",
                    color: .greekBlue,
                    title: "Greek",
                    subtitle: "Original language notes",
                    isEnabled: $settings.showGreek
                )

                // Quick actions
                HStack(spacing: AppTheme.Spacing.md) {
                    Button {
                        settings.enableAll()
                    } label: {
                        Text("Enable All")
                            .font(Typography.UI.caption1.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.scholarIndigo)

                    Button {
                        settings.disableAll()
                    } label: {
                        Text("Disable All")
                            .font(Typography.UI.caption1.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.secondaryText)

                    Spacer()
                }
                .padding(.top, AppTheme.Spacing.sm)
            }
        }
    }

    private func insightTypeRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        IlluminatedSettingsRow(
            icon: icon,
            iconColor: color,
            title: title,
            subtitle: subtitle
        ) {
            Toggle("", isOn: isEnabled)
                .labelsHidden()
                .tint(color)
        }
        .opacity(isEnabled.wrappedValue ? 1.0 : 0.6)
    }

    // MARK: - Greek Section

    private var greekSection: some View {
        IlluminatedSettingsCard(title: "Greek Annotations", icon: "character.book.closed") {
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Control the depth of Greek language annotations.")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, AppTheme.Spacing.xs)

                IlluminatedSettingsRow(
                    icon: "textformat.abc",
                    iconColor: .greekBlue,
                    title: "Annotation Level",
                    subtitle: settings.greekLevel.description
                ) {
                    Picker("", selection: $settings.greekLevel) {
                        ForEach(BibleGreekLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.greekBlue)
                }

                if settings.greekLevel == .off && settings.showGreek {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "info.circle")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.info)

                        Text("Greek insights are enabled but annotations are off. You'll see Greek insights in the sheet but no inline annotations.")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppTheme.Spacing.xs)
                }
            }
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        IlluminatedSettingsCard(title: "Behavior", icon: "slider.horizontal.3") {
            VStack(spacing: AppTheme.Spacing.md) {
                IlluminatedSettingsRow(
                    icon: "eye",
                    iconColor: .scholarIndigo,
                    title: "Auto-Reveal",
                    subtitle: "Show insight indicators as you scroll"
                ) {
                    Toggle("", isOn: $settings.autoReveal)
                        .labelsHidden()
                        .tint(Color.scholarIndigo)
                }

                if !settings.autoReveal {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "info.circle")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.info)

                        Text("Long-press any verse to access insights")
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        IlluminatedSettingsCard(title: "About", icon: "info.circle") {
            VStack(spacing: AppTheme.Spacing.md) {
                Button {
                    showAboutSheet = true
                } label: {
                    IlluminatedSettingsRow(
                        icon: "wand.and.stars",
                        iconColor: .divineGold,
                        title: "How It Works",
                        subtitle: "Learn about AI-generated insights"
                    ) {
                        Image(systemName: "chevron.right")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.tertiaryText)
                    }
                }
                .buttonStyle(.plain)

                SettingsDivider()

                // Attribution note
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.success)

                    Text("Insights are pre-generated and reviewed. No data is sent during use.")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        IlluminatedSettingsCard(title: "Data", icon: "arrow.counterclockwise", showDivider: false) {
            Button {
                showResetConfirmation = true
            } label: {
                IlluminatedSettingsRow(
                    icon: "bookmark.slash",
                    iconColor: .warning,
                    title: "Reset Reading Position",
                    subtitle: "Return to John Chapter 1"
                ) {
                    Image(systemName: "chevron.right")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Scholar About Sheet

struct BibleAboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.divineGold)

                        Text("AI-Powered Insights")
                            .font(CustomFonts.cormorantSemiBold(size: 28))
                            .foregroundStyle(Color.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppTheme.Spacing.xl)

                    // Content sections
                    aboutSection(
                        title: "How It Works",
                        content: "Scholar insights are generated using advanced AI language models trained on biblical scholarship. Each insight is pre-generated and bundled with the app, so no internet connection or API calls are needed during use."
                    )

                    aboutSection(
                        title: "Types of Insights",
                        content: """
                        • **Theology**: Doctrinal themes and concepts explained in context
                        • **Reflection**: Personal application questions for deeper study
                        • **Greek**: Original language analysis with Strong's references
                        • **Connections**: Cross-references to related Scripture passages
                        """
                    )

                    aboutSection(
                        title: "Quality & Review",
                        content: "All insights undergo review before being included. While AI-generated, they're checked for theological accuracy and relevance. Interpretive insights are clearly marked."
                    )

                    aboutSection(
                        title: "Privacy",
                        content: "Your reading activity and preferences stay on your device. No data is collected or transmitted when using Scholar features."
                    )

                    // Attribution
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("ATTRIBUTION")
                            .font(Typography.UI.caption2.weight(.semibold))
                            .tracking(1.5)
                            .foregroundStyle(Color.tertiaryText)

                        Text("Bible text: King James Version (Public Domain)\nGreek data: STEP Bible (CC BY 4.0)\nCross-references: Open Bible (CC BY 4.0)")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .padding(.top, AppTheme.Spacing.md)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationTitle("About Scholar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Typography.UI.body.weight(.medium))
                    .foregroundStyle(Color.scholarIndigo)
                }
            }
        }
    }

    private func aboutSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title.uppercased())
                .font(Typography.UI.caption2.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(Color.scholarIndigo)

            Text(LocalizedStringKey(content))
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)
                .lineSpacing(4)
        }
    }
}

// MARK: - Preview

#Preview("Scholar Settings") {
    BibleSettingsSheet()
}

#Preview("Scholar About") {
    BibleAboutSheet()
}
