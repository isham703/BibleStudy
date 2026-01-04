import SwiftUI

// MARK: - Reading Section View
// Reading preferences with expandable appearance settings

struct ReadingSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(AppState.self) private var appState

    @State private var showClearCacheConfirmation = false
    @State private var isAppearanceExpanded = false
    @State private var showAdvanced = false

    // Staggered animation delays
    @State private var revealPhase: Int = 0

    // User preferences
    @AppStorage(AppConfiguration.UserDefaultsKeys.usePagedReader) private var usePagedReader: Bool = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Reading Settings Card with Expandable Appearance
            IlluminatedSettingsCard(title: "Reading", icon: "book.fill") {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Expandable Reading Appearance Section
                    readingAppearanceSection

                    SettingsDivider()

                    // Translation selector
                    translationRow

                    SettingsDivider()

                    // Devotional mode toggle
                    IlluminatedToggle(
                        isOn: $viewModel.devotionalModeEnabled,
                        label: "Devotional Mode",
                        description: "Larger text with generous spacing for meditation",
                        icon: "sparkles",
                        iconColor: .scholarAccent
                    )
                }
            }

            // Audio Cache Section
            IlluminatedSettingsCard(title: "Audio", icon: "speaker.wave.2.fill") {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Cache size picker
                    audioCacheLimitRow

                    SettingsDivider()

                    // Current cache usage
                    audioCacheUsageRow

                    SettingsDivider()

                    // Clear cache button
                    clearCacheRow
                }
            }
            .alert("Clear Audio Cache?", isPresented: $showClearCacheConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    viewModel.clearAudioCache()
                }
            } message: {
                Text("This will delete all cached audio files. They will be regenerated when you play chapters again.")
            }
        }
    }

    // MARK: - Expandable Reading Appearance Section

    private var readingAppearanceSection: some View {
        VStack(spacing: 0) {
            // Expandable Header
            appearanceHeader

            // Expanded Content with Staggered Reveal
            if isAppearanceExpanded {
                VStack(spacing: AppTheme.Spacing.lg) {
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
                .padding(.top, AppTheme.Spacing.lg)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Appearance Header

    private var appearanceHeader: some View {
        Button {
            withAnimation(AppTheme.Animation.sacredSpring) {
                isAppearanceExpanded.toggle()
            }

            if isAppearanceExpanded {
                // Staggered reveal animation
                triggerStaggeredReveal()
            } else {
                revealPhase = 0
                showAdvanced = false
            }

            HapticService.shared.lightTap()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon with subtle glow when expanded
                ZStack {
                    if isAppearanceExpanded {
                        Circle()
                            .fill(Color.scholarAccent.opacity(AppTheme.Opacity.light))
                            .frame(width: 36, height: 36)
                            .blur(radius: AppTheme.Blur.light)
                    }

                    Image(systemName: "paintpalette.fill")
                        .font(Typography.UI.iconSm.weight(.medium))
                        .foregroundStyle(Color.scholarAccent)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                                .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle + 0.02))
                        )
                }

                // Label
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Theme & Text Size")
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.primaryText)

                    Text(isAppearanceExpanded ? "Customize your reading experience" : currentThemeSummary)
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                        .animation(.none, value: isAppearanceExpanded)
                }

                Spacer()

                // Rotating chevron
                Image(systemName: "chevron.right")
                    .font(Typography.UI.iconXxxs.weight(.semibold))
                    .foregroundStyle(isAppearanceExpanded ? Color.scholarAccent : Color.tertiaryText)
                    .rotationEffect(.degrees(isAppearanceExpanded ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Theme and Text Size")
        .accessibilityHint(isAppearanceExpanded ? "Collapse settings" : "Expand settings")
    }

    private var currentThemeSummary: String {
        "\(appState.preferredTheme.displayName) \u{2022} \(appState.scriptureFontSize.displayName)"
    }

    // MARK: - Theme Selection Section

    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("APPEARANCE")
                .font(Typography.UI.caption2)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color.secondaryText.opacity(AppTheme.Opacity.pressed))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(AppThemeMode.allCases, id: \.self) { theme in
                        InlineThemeCard(
                            theme: theme,
                            isSelected: appState.preferredTheme == theme
                        ) {
                            appState.preferredTheme = theme
                            saveTheme(theme)
                            HapticService.shared.lightTap()
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
                .padding(.horizontal, AppTheme.Spacing.xxs)
            }
        }
    }

    // MARK: - Font Size Section

    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TEXT SIZE")
                .font(Typography.UI.caption2)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color.secondaryText.opacity(AppTheme.Opacity.pressed))

            HStack(spacing: AppTheme.Spacing.md) {
                Text("A")
                    .font(Typography.Scripture.body(size: 14))
                    .foregroundStyle(Color.secondaryText)

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
                    .font(Typography.Scripture.body(size: 24))
                    .foregroundStyle(Color.secondaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(Color.appBackground.opacity(AppTheme.Opacity.heavy))
            )
        }
    }

    // MARK: - Reading Mode Section

    private var readingModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("READING MODE")
                .font(Typography.UI.caption2)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color.secondaryText.opacity(AppTheme.Opacity.pressed))

            Picker("Reading Mode", selection: $usePagedReader) {
                Text("Scroll").tag(false)
                Text("Page").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Advanced Options Section

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(AppTheme.Animation.standard) {
                    showAdvanced.toggle()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: showAdvanced ? "chevron.down" : "chevron.right")
                        .font(Typography.UI.iconXxs.weight(.semibold))
                        .foregroundStyle(Color.secondaryText.opacity(AppTheme.Opacity.strong))

                    Text("ADVANCED")
                        .font(Typography.UI.caption2)
                        .fontWeight(.medium)
                        .tracking(1.5)
                        .foregroundStyle(Color.secondaryText.opacity(AppTheme.Opacity.pressed))

                    Spacer()
                }
            }
            .buttonStyle(.plain)

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
                            HStack(spacing: AppTheme.Spacing.xxs) {
                                Text(appState.lineSpacing.displayName)
                                    .foregroundStyle(Color.scholarAccent)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.UI.iconXxs)
                                    .foregroundStyle(Color.scholarAccent.opacity(AppTheme.Opacity.overlay))
                            }
                        }
                    }

                    Divider()
                        .padding(.leading, AppTheme.Spacing.md)

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
                            HStack(spacing: AppTheme.Spacing.xxs) {
                                Text(appState.contentWidth.displayName)
                                    .foregroundStyle(Color.scholarAccent)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.UI.iconXxs)
                                    .foregroundStyle(Color.scholarAccent.opacity(AppTheme.Opacity.overlay))
                            }
                        }
                    }

                    Divider()
                        .padding(.leading, AppTheme.Spacing.md)

                    // Paragraph Mode
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text("Paragraph Mode")
                                .font(Typography.UI.subheadline)
                                .foregroundStyle(Color.primaryText)

                            Text("Show verses as continuous prose")
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.secondaryText)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { appState.paragraphMode },
                            set: { newValue in
                                appState.paragraphMode = newValue
                                saveParagraphMode(newValue)
                            }
                        ))
                        .tint(Color.scholarAccent)
                        .labelsHidden()
                    }
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .disabled(usePagedReader)
                    .opacity(usePagedReader ? AppTheme.Opacity.heavy : 1.0)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.appBackground.opacity(AppTheme.Opacity.heavy))
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
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.primaryText)

            Spacer()

            content()
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("PREVIEW")
                .font(Typography.UI.caption2)
                .fontWeight(.medium)
                .tracking(1.5)
                .foregroundStyle(Color.secondaryText.opacity(AppTheme.Opacity.pressed))

            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                Text("1")
                    .font(Typography.Scripture.verseNumber)
                    .foregroundStyle(appState.preferredTheme.customSecondaryTextColor ?? Color.verseNumber)

                Text("In the beginning God created the heaven and the earth.")
                    .font(Typography.Scripture.bodyWithSize(appState.scriptureFontSize))
                    .lineSpacing(appState.lineSpacing.value)
                    .foregroundStyle(appState.preferredTheme.customTextColor ?? Color.primaryText)
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(appState.preferredTheme.customBackground ?? Color.appBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(Color.cardBorder.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
                    )
            )
        }
        .animation(AppTheme.Animation.quick, value: appState.preferredTheme)
        .animation(AppTheme.Animation.quick, value: appState.scriptureFontSize)
    }

    // MARK: - Staggered Animation

    private func triggerStaggeredReveal() {
        let baseDelay: Double = 0.06

        for phase in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay * Double(phase)) {
                withAnimation(AppTheme.Animation.standard) {
                    revealPhase = phase
                }
            }
        }
    }

    // MARK: - Translation Row

    private var translationRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            Image(systemName: "book.closed.fill")
                .font(Typography.UI.iconSm.weight(.medium))
                .foregroundStyle(Color.scholarAccent)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                        .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle + 0.02))
                )

            // Label
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Translation")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                if !viewModel.isPremiumOrHigher {
                    Text("Upgrade to access all translations")
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.tertiaryText)
                }
            }

            Spacer()

            // Current translation badge
            HStack(spacing: AppTheme.Spacing.xxs) {
                Text("KJV")
                    .font(Typography.UI.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                if !viewModel.isPremiumOrHigher {
                    Image(systemName: "lock.fill")
                        .font(Typography.UI.iconXxxs)
                        .foregroundStyle(.white.opacity(AppTheme.Opacity.pressed))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(Color.scholarAccent)
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !viewModel.isPremiumOrHigher {
                viewModel.showUpgradePaywall()
            }
            // TODO: Navigate to translation picker when premium
        }
    }

    // MARK: - Audio Cache Rows

    private var audioCacheLimitRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            Image(systemName: "internaldrive.fill")
                .font(Typography.UI.iconSm.weight(.medium))
                .foregroundStyle(Color.scholarAccent)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                        .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle + 0.02))
                )

            // Label
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Cache Limit")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                Text("Maximum storage for cached audio")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            // Picker
            Menu {
                ForEach(viewModel.audioCacheSizeOptions, id: \.mb) { option in
                    Button {
                        viewModel.audioCacheLimitMB = option.mb
                    } label: {
                        HStack {
                            Text(option.label)
                            if viewModel.audioCacheLimitMB == option.mb {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Text(viewModel.audioCacheSizeOptions.first { $0.mb == viewModel.audioCacheLimitMB }?.label ?? "\(viewModel.audioCacheLimitMB) MB")
                        .font(Typography.UI.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.scholarAccent)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(Typography.UI.iconXxxs)
                        .foregroundStyle(Color.scholarAccent.opacity(AppTheme.Opacity.pressed))
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(
                    Capsule()
                        .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle))
                )
            }
        }
    }

    private var audioCacheUsageRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            Image(systemName: "chart.pie.fill")
                .font(Typography.UI.iconSm.weight(.medium))
                .foregroundStyle(Color.secondaryText)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                        .fill(Color.secondaryText.opacity(AppTheme.Opacity.subtle + 0.02))
                )

            // Label
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Current Usage")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                Text("Audio files are cached for 30 days")
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            // Size badge
            Text(viewModel.audioCacheSize)
                .font(Typography.UI.caption1.monospacedDigit())
                .fontWeight(.medium)
                .foregroundStyle(Color.secondaryText)
        }
    }

    private var clearCacheRow: some View {
        Button {
            showClearCacheConfirmation = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                Image(systemName: "trash.fill")
                    .font(Typography.UI.iconSm.weight(.medium))
                    .foregroundStyle(Color.error)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                            .fill(Color.error.opacity(AppTheme.Opacity.subtle + 0.02))
                    )

                // Label
                Text("Clear Audio Cache")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.UI.iconXxxs)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .buttonStyle(.plain)
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

// MARK: - Inline Theme Card
// Compact theme card for inline settings display

struct InlineThemeCard: View {
    let theme: AppThemeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs) {
                // Theme preview swatch
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(theme.previewBackground)
                        .frame(width: 52, height: 36)
                        .overlay(
                            VStack(spacing: AppTheme.Spacing.xs) {
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
                                    .fill(theme.previewText)
                                    .frame(width: 32, height: 3)
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xs)
                                    .fill(theme.previewText.opacity(AppTheme.Opacity.strong))
                                    .frame(width: 24, height: 3)
                            }
                        )

                    // Selection ring
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(Color.scholarAccent, lineWidth: AppTheme.Border.regular)
                            .frame(width: 52, height: 36)
                    }
                }
                .shadow(
                    color: isSelected ? Color.scholarAccent.opacity(AppTheme.Opacity.medium) : .clear,
                    radius: 4
                )

                // Theme name
                Text(theme.displayName)
                    .font(Typography.UI.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.scholarAccent : Color.secondaryText)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
            .padding(.horizontal, AppTheme.Spacing.xxs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("Reading Section") {
    ScrollView {
        ReadingSectionView(viewModel: SettingsViewModel())
            .padding()
            .environment(AppState())
    }
    .background(Color.appBackground)
}
