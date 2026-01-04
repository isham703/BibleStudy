//
//  ThemesSettingsSheet.swift
//  BibleStudy
//
//  Apple Books-style theme-first settings sheet
//  Theme cards first, quick controls, advanced collapsed
//

import SwiftUI

// MARK: - Themes & Settings Sheet

struct ThemesSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // User preferences
    @AppStorage(AppConfiguration.UserDefaultsKeys.usePagedReader) private var usePagedReader: Bool = false

    // Advanced section expansion
    @State private var showAdvanced: Bool = false

    var body: some View {
        @Bindable var state = appState

        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Theme Cards (Primary)
                    themeSection

                    // Text Size Slider
                    textSizeSection

                    // Reading Mode
                    readingModeSection

                    // Advanced (Collapsed)
                    advancedSection

                    // Preview
                    previewSection
                }
                .padding()
            }
            .background(appState.preferredTheme.customBackground ?? Color.appBackground)
            .navigationTitle("Themes & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(appState.preferredTheme.accentColor)
                }
            }
        }
        .preferredColorScheme(appState.preferredTheme.baseColorScheme)
        .animation(AppTheme.Animation.standard, value: appState.preferredTheme)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("APPEARANCE")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(AppThemeMode.allCases, id: \.self) { theme in
                        ThemeCard(
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
            }
        }
    }

    // MARK: - Text Size Section

    private var textSizeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TEXT SIZE")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            VStack(spacing: AppTheme.Spacing.md) {
                // Slider with A labels
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
            }
            .padding()
            .background(appState.preferredTheme.customSurface ?? Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }

    // MARK: - Reading Mode Section

    private var readingModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("READING MODE")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            VStack(spacing: 0) {
                // Scroll vs Page picker
                Picker("Reading Mode", selection: $usePagedReader) {
                    Text("Scroll").tag(false)
                    Text("Page").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
            }
            .background(appState.preferredTheme.customSurface ?? Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(AppTheme.Animation.standard) {
                    showAdvanced.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showAdvanced ? "chevron.down" : "chevron.right")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)

                    Text("ADVANCED")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if showAdvanced {
                VStack(spacing: 0) {
                    // Line Spacing
                    SettingsRow(
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
                            HStack {
                                Text(appState.lineSpacing.displayName)
                                    .foregroundStyle(Color.accentGold)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.UI.caption2)
                                    .foregroundStyle(Color.accentGold)
                            }
                        }
                    }

                    Divider().padding(.leading)

                    // Content Width
                    SettingsRow(
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
                            HStack {
                                Text(appState.contentWidth.displayName)
                                    .foregroundStyle(Color.accentGold)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.UI.caption2)
                                    .foregroundStyle(Color.accentGold)
                            }
                        }
                    }

                    Divider().padding(.leading)

                    // Paragraph Mode
                    Toggle(isOn: Binding(
                        get: { appState.paragraphMode },
                        set: { newValue in
                            appState.paragraphMode = newValue
                            saveParagraphMode(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text("Paragraph Mode")
                                .font(Typography.UI.body)
                                .foregroundStyle(Color.primaryText)

                            Text("Show verses as continuous prose")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }
                    .tint(Color.accentGold)
                    .disabled(usePagedReader)
                    .opacity(usePagedReader ? 0.5 : 1.0)
                    .padding()

                }
                .background(appState.preferredTheme.customSurface ?? Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("PREVIEW")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                    Text("1")
                        .font(Typography.Scripture.verseNumber)
                        .foregroundStyle(appState.preferredTheme.customSecondaryTextColor ?? Color.verseNumber)

                    Text("In the beginning God created the heaven and the earth.")
                        .font(Typography.Scripture.bodyWithSize(appState.scriptureFontSize))
                        .lineSpacing(appState.lineSpacing.value)
                        .foregroundStyle(appState.preferredTheme.customTextColor ?? Color.primaryText)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(appState.preferredTheme.customBackground ?? Color.surfaceBackground)
            )
        }
    }

    // MARK: - Persistence

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

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: AppThemeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                // Theme preview
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(theme.previewBackground)
                    .frame(width: 60, height: 40)
                    .overlay(
                        VStack(spacing: AppTheme.Spacing.xxs) {
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .fill(theme.previewText)
                                .frame(width: 40, height: AppTheme.Divider.thick)
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .fill(theme.previewText.opacity(AppTheme.Opacity.strong))
                                .frame(width: 30, height: AppTheme.Divider.thick)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(isSelected ? Color.accentGold : Color.cardBorder, lineWidth: isSelected ? AppTheme.Border.regular : AppTheme.Border.thin)
                    )

                // Theme name
                Text(theme.displayName)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(isSelected ? Color.accentGold : Color.primaryText)

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.accentGold)
                } else {
                    Circle()
                        .stroke(Color.cardBorder, lineWidth: AppTheme.Border.thin)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(AppTheme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Font Size Slider

struct FontSizeSlider: View {
    @Binding var selectedSize: ScriptureFontSize

    private let sizes = ScriptureFontSize.allCases

    var body: some View {
        GeometryReader { geometry in
            let stepWidth = geometry.size.width / CGFloat(sizes.count - 1)
            let currentIndex = sizes.firstIndex(of: selectedSize) ?? 2

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.cardBorder)
                    .frame(height: AppTheme.Divider.thick)

                // Filled portion
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.accentGold)
                    .frame(width: stepWidth * CGFloat(currentIndex), height: AppTheme.Divider.thick)

                // Thumb
                Circle()
                    .fill(Color.accentGold)
                    .frame(width: 24, height: 24)
                    .shadow(AppTheme.Shadow.small)
                    .offset(x: stepWidth * CGFloat(currentIndex) - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newIndex = Int(round(value.location.x / stepWidth))
                                let clampedIndex = max(0, min(sizes.count - 1, newIndex))
                                if sizes[clampedIndex] != selectedSize {
                                    selectedSize = sizes[clampedIndex]
                                    HapticService.shared.lightTap()
                                }
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let title: String
    let value: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(title)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)

            Spacer()

            content
        }
        .padding()
    }
}

// MARK: - Theme Extensions

extension AppThemeMode {
    var previewBackground: Color {
        switch self {
        case .system: return Color(.systemBackground)
        case .light: return Color.lightBackground
        case .dark: return Color.darkBackground
        case .sepia: return Color.sepiaBackground
        case .oled: return Color.oledBackground
        }
    }

    var previewText: Color {
        switch self {
        case .system: return Color.primary
        case .light: return Color.monasteryBlack
        case .dark: return Color.moonlitParchment
        case .sepia: return Color.sepiaText
        case .oled: return Color.oledText
        }
    }
}

// MARK: - Preview

#Preview("Themes & Settings Sheet") {
    Color.appBackground
        .sheet(isPresented: .constant(true)) {
            ThemesSettingsSheet()
                .environment(AppState())
        }
}
