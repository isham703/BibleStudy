import SwiftUI

// MARK: - Reading Appearance Section
// Expandable theme, font size, reading mode, and advanced options

struct ReadingAppearanceSection: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(AppState.self) private var appState

    @Binding var isExpanded: Bool
    @Binding var showAdvanced: Bool
    @Binding var revealPhase: Int
    @Binding var usePagedReader: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Expandable Header
            appearanceHeader

            // Expanded Content with Staggered Reveal
            if isExpanded {
                VStack(spacing: Theme.Spacing.lg) {
                    // Theme Selection
                    themeSelectionSection
                        .opacity(revealPhase >= 1 ? 1 : 0)
                        .offset(y: revealPhase >= 1 ? 0 : 8)

                    // Font Size Slider
                    fontSizeSection
                        .opacity(revealPhase >= 2 ? 1 : 0)
                        .offset(y: revealPhase >= 2 ? 0 : 8)

                    // Reading Mode
                    readingModeSection
                        .opacity(revealPhase >= 3 ? 1 : 0)
                        .offset(y: revealPhase >= 3 ? 0 : 8)

                    // Advanced Options (Nested Expandable)
                    advancedOptionsSection
                        .opacity(revealPhase >= 4 ? 1 : 0)
                        .offset(y: revealPhase >= 4 ? 0 : 8)

                    // Live Preview
                    previewSection
                        .opacity(revealPhase >= 5 ? 1 : 0)
                        .offset(y: revealPhase >= 5 ? 0 : 8)
                }
                .padding(.top, Theme.Spacing.lg)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Appearance Header

    private var appearanceHeader: some View {
        Button {
            withAnimation(Theme.Animation.settle) {
                isExpanded.toggle()
            }

            if isExpanded {
                triggerStaggeredReveal()
            } else {
                revealPhase = 0
                showAdvanced = false
            }

            HapticService.shared.lightTap()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Icon with subtle glow when expanded
                ZStack {
                    if isExpanded {
                        Circle()
                            .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                            .frame(width: 36, height: 36)
                            .blur(radius: 4)
                    }

                    Image(systemName: "paintpalette.fill")
                        .font(Typography.Icon.sm.weight(.medium))
                        .foregroundStyle(Color("AppAccentAction"))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.input + 2)
                                .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle + 0.02))
                        )
                }

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    Text("Theme & Text Size")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(isExpanded ? "Customize your reading experience" : currentThemeSummary)
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color("TertiaryText"))
                        .animation(.none, value: isExpanded)
                }

                Spacer()

                // Rotating chevron
                Image(systemName: "chevron.right")
                    .font(Typography.Icon.xxxs.weight(.semibold))
                    .foregroundStyle(isExpanded ? Color("AppAccentAction") : Color("TertiaryText"))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Theme and Text Size")
        .accessibilityHint(isExpanded ? "Collapse settings" : "Expand settings")
    }

    private var currentThemeSummary: String {
        "\(appState.preferredTheme.displayName) \u{2022} \(appState.scriptureFontSize.displayName)"
    }

    // MARK: - Theme Selection Section

    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("APPEARANCE")
                .font(Typography.Command.meta)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))

            // Uses ThemePicker - flat design, no shadows per design system
            ThemePicker(
                selectedTheme: Binding(
                    get: { appState.preferredTheme },
                    set: { newTheme in
                        appState.preferredTheme = newTheme
                        saveTheme(newTheme)
                    }
                )
            )
        }
    }

    // MARK: - Font Size Section

    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("TEXT SIZE")
                .font(Typography.Command.meta)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))

            HStack(spacing: Theme.Spacing.md) {
                Text("A")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color("AppTextSecondary"))

                FontSizeSlider(
                    selectedSize: Binding(
                        get: { appState.scriptureFontSize },
                        set: { newSize in
                            appState.scriptureFontSize = newSize
                            saveFontSize(newSize)
                        }
                    )
                )

                Text("A")
                    .font(Typography.Scripture.prompt)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appBackground.opacity(Theme.Opacity.textSecondary))
            )
        }
    }

    // MARK: - Reading Mode Section

    private var readingModeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("READING MODE")
                .font(Typography.Command.meta)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))

            Picker("Reading Mode", selection: $usePagedReader) {
                Text("Scroll").tag(false)
                Text("Page").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Advanced Options Section

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(Theme.Animation.settle) {
                    showAdvanced.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: showAdvanced ? "chevron.down" : "chevron.right")
                        .font(Typography.Icon.xxs.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.textPrimary))

                    Text("ADVANCED")
                        .font(Typography.Command.meta)
                        .fontWeight(.medium)
                        .tracking(1.5)
                        .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Advanced options")
            .accessibilityHint(showAdvanced ? "Collapse advanced options" : "Expand advanced options")

            if showAdvanced {
                VStack(spacing: 0) {
                    // Line Spacing
                    advancedRow(
                        title: "Line Spacing",
                        value: appState.lineSpacing.displayName
                    ) {
                        Menu {
                            ForEach(LineSpacing.allCases, id: \.self) { spacing in
                                Button {
                                    appState.lineSpacing = spacing
                                    saveLineSpacing(spacing)
                                } label: {
                                    HStack {
                                        Text(spacing.displayName)
                                        if appState.lineSpacing == spacing {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text(appState.lineSpacing.displayName)
                                    .foregroundStyle(Color("AppAccentAction"))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.Icon.xxs)
                                    .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.overlay))
                            }
                        }
                    }

                    Divider()
                        .padding(.leading, Theme.Spacing.md)

                    // Content Width
                    advancedRow(
                        title: "Content Width",
                        value: appState.contentWidth.displayName
                    ) {
                        Menu {
                            ForEach(ContentWidth.allCases, id: \.self) { width in
                                Button {
                                    appState.contentWidth = width
                                    saveContentWidth(width)
                                } label: {
                                    HStack {
                                        Text(width.displayName)
                                        if appState.contentWidth == width {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 2) {
                                Text(appState.contentWidth.displayName)
                                    .foregroundStyle(Color("AppAccentAction"))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.Icon.xxs)
                                    .foregroundStyle(Color("AppAccentAction").opacity(Theme.Opacity.overlay))
                            }
                        }
                    }

                    Divider()
                        .padding(.leading, Theme.Spacing.md)

                    // Paragraph Mode
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Paragraph Mode")
                                .font(Typography.Command.subheadline)
                                .foregroundStyle(Color("AppTextPrimary"))

                            Text("Show verses as continuous prose")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { appState.paragraphMode },
                            set: { newValue in
                                appState.paragraphMode = newValue
                                saveParagraphMode(newValue)
                            }
                        ))
                        .tint(Color("AppAccentAction"))
                        .labelsHidden()
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.md)
                    .disabled(usePagedReader)
                    .opacity(usePagedReader ? Theme.Opacity.textSecondary : 1.0)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Paragraph Mode")
                    .accessibilityValue(appState.paragraphMode ? "On" : "Off")
                    .accessibilityHint(usePagedReader ? "Not available in page mode" : "Show verses as continuous prose")
                }
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(Color.appBackground.opacity(Theme.Opacity.textSecondary))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func advancedRow<Content: View>(
        title: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title)
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextPrimary"))

            Spacer()

            content()
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("PREVIEW")
                .font(Typography.Command.meta)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color("AppTextSecondary").opacity(Theme.Opacity.pressed))

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                Text("1")
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("AppTextSecondary"))

                Text("In the beginning God created the heaven and the earth.")
                    .font(Typography.Scripture.bodyWithSize(CGFloat(appState.scriptureFontSize.rawValue)))
                    .lineSpacing(appState.lineSpacing.value)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.appBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Color.appDivider.opacity(Theme.Opacity.textSecondary), lineWidth: Theme.Stroke.hairline)
                    )
            )
        }
        .animation(Theme.Animation.fade, value: appState.preferredTheme)
        .animation(Theme.Animation.fade, value: appState.scriptureFontSize)
    }

    // MARK: - Staggered Animation

    private func triggerStaggeredReveal() {
        let baseDelay: Double = 0.06

        for phase in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay * Double(phase)) {
                withAnimation(Theme.Animation.settle) {
                    revealPhase = phase
                }
            }
        }
    }

    // MARK: - Persistence Helpers

    private func saveFontSize(_ size: ScriptureFontSize) {
        UserDefaults.standard.set(size.rawValue, forKey: AppConfiguration.UserDefaultsKeys.preferredFontSize)
    }

    private func saveTheme(_ theme: AppThemeMode) {
        UserDefaults.standard.set(theme.rawValue, forKey: AppConfiguration.UserDefaultsKeys.preferredTheme)
    }

    private func saveLineSpacing(_ spacing: LineSpacing) {
        UserDefaults.standard.set(spacing.rawValue, forKey: AppConfiguration.UserDefaultsKeys.preferredLineSpacing)
    }

    private func saveContentWidth(_ width: ContentWidth) {
        UserDefaults.standard.set(width.rawValue, forKey: AppConfiguration.UserDefaultsKeys.preferredContentWidth)
    }

    private func saveParagraphMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: AppConfiguration.UserDefaultsKeys.paragraphMode)
    }
}

// MARK: - Preview

#Preview("Reading Appearance Section") {
    ScrollView {
        ReadingAppearanceSection(
            viewModel: SettingsViewModel(),
            isExpanded: .constant(true),
            showAdvanced: .constant(false),
            revealPhase: .constant(5),
            usePagedReader: .constant(false)
        )
        .padding()
        .environment(AppState())
    }
    .background(Color.appBackground)
}
