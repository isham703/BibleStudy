import SwiftUI

// MARK: - Settings Section
// Display settings with theme, font size, reading mode, and advanced options
// Uses ReadingMenuState for view navigation

struct SettingsSection: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState
    @Bindable var state: ReadingMenuState
    @AppStorage(AppConfiguration.UserDefaultsKeys.usePagedReader) private var usePagedReader: Bool = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            subpageHeader(title: "Display Settings")

            // Scrollable settings
            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    // Theme Cards
                    themeCardsSection

                    // Font Size
                    fontSizeSection

                    // Reading Mode
                    readingModeSection

                    // Advanced Settings
                    advancedSection

                    // Preview
                    previewSection
                }
            }
            .frame(maxHeight: 380)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Subpage Header

    private func subpageHeader(title: String) -> some View {
        HStack {
            // Back button
            Button {
                state.navigateToMenu()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(Typography.Command.caption.weight(.semibold))
                    Text("Back")
                        .font(Typography.Command.subheadline)
                }
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }

            Spacer()

            Text(title)
                .font(Typography.Scripture.body.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    // swiftlint:disable:next hardcoded_swiftui_text_style
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    // MARK: - Theme Cards Section

    private var themeCardsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("APPEARANCE")
                .editorialLabel()
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(AppThemeMode.allCases, id: \.self) { theme in
                        BibleThemeCard(
                            theme: theme,
                            isSelected: appState.preferredTheme == theme
                        ) {
                            appState.preferredTheme = theme
                            saveTheme(theme)
                            HapticService.shared.lightTap()
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }

    // MARK: - Font Size Section

    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("TEXT SIZE")
                .editorialLabel()
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            HStack(spacing: Theme.Spacing.md) {
                Text("A")
                    .font(Typography.Scripture.footnote)
                    .foregroundStyle(Color.tertiaryText)

                BibleFontSizeSlider(
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
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Menu.border, lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    // MARK: - Reading Mode Section

    private var readingModeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("READING MODE")
                .editorialLabel()
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            Picker("Reading Mode", selection: $usePagedReader) {
                Text("Scroll").tag(false)
                Text("Page").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(Theme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Menu.border, lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(state.animation) {
                    state.showAdvanced.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: state.showAdvanced ? "chevron.down" : "chevron.right")
                        .font(Typography.Icon.xxs.weight(.bold))
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                    Text("ADVANCED")
                        .editorialLabel()
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if state.showAdvanced {
                VStack(spacing: 0) {
                    // Line Spacing
                    BibleSettingsRow(title: "Line Spacing") {
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
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(appState.lineSpacing.displayName)
                                    .font(Typography.Command.caption)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.Icon.xxs)
                            }
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        }
                    }

                    settingsDivider

                    // Content Width
                    BibleSettingsRow(title: "Content Width") {
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
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(appState.contentWidth.displayName)
                                    .font(Typography.Command.caption)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.Icon.xxs)
                            }
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        }
                    }

                    settingsDivider

                    // Paragraph Mode
                    Toggle(isOn: Binding(
                        get: { appState.paragraphMode },
                        set: { newValue in
                            appState.paragraphMode = newValue
                            saveParagraphMode(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Paragraph Mode")
                                .font(Typography.Scripture.body.weight(.semibold))
                                .foregroundStyle(Color.primaryText)

                            Text("Show verses as continuous prose")
                                .font(Typography.Command.meta)
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }
                    .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .disabled(usePagedReader)
                    .opacity(usePagedReader ? 0.5 : 1.0)
                    .padding(Theme.Spacing.md)
                }
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Theme.Menu.border, lineWidth: Theme.Stroke.hairline)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(Theme.Opacity.light))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.sm)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("PREVIEW")
                .editorialLabel()
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                    Text("1")
                        .font(Typography.Command.caption.weight(.bold))
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                    Text("In the beginning God created the heaven and the earth.")
                        .readingVerse(size: appState.scriptureFontSize, font: appState.scriptureFont)
                        .foregroundStyle(Color.primaryText)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Menu.border, lineWidth: Theme.Stroke.hairline)
            )
        }
    }

    // MARK: - Settings Persistence

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

#Preview {
    struct PreviewContainer: View {
        @State private var state = ReadingMenuState()

        var body: some View {
            SettingsSection(state: state)
                .environment(AppState())
                .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}
