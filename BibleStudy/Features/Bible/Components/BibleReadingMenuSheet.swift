import SwiftUI

// MARK: - Bible Reading Menu Sheet
// Dynamic height sheet with Bible palette styling
// Uses DynamicSheet for automatic height adjustment
// Supports morphing between menu, search, and settings views

struct BibleReadingMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(BibleService.self) private var bibleService
    @Environment(AppState.self) private var appState

    // Actions
    let onAudioTap: () -> Void
    let onNavigate: ((VerseRange) -> Void)?

    // View state
    @State private var currentView: MenuView = .menu

    // Search state
    @State private var query = ""
    @State private var results: [SearchService.SearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // Settings state
    @State private var showAdvanced = false
    @AppStorage(AppConfiguration.UserDefaultsKeys.usePagedReader) private var usePagedReader: Bool = false

    // Bible settings for insight toggles
    private var scholarSettings: BibleSettings { BibleSettings.shared }

    // Animation for transitions
    private let animation: Animation = .snappy(duration: 0.3, extraBounce: 0)

    enum MenuView {
        case menu
        case search
        case settings
        case insights
    }

    init(
        onAudioTap: @escaping () -> Void,
        onSettingsTap: @escaping () -> Void = {},
        onNavigate: ((VerseRange) -> Void)? = nil
    ) {
        self.onAudioTap = onAudioTap
        self.onNavigate = onNavigate
    }

    var body: some View {
        DynamicSheet(animation: animation) {
            ZStack {
                switch currentView {
                case .menu:
                    menuContent
                        .transition(.blurReplace(.downUp))

                case .search:
                    searchContent
                        .transition(.blurReplace(.upUp))

                case .settings:
                    settingsContent
                        .transition(.blurReplace(.upUp))

                case .insights:
                    insightsContent
                        .transition(.blurReplace(.upUp))
                }
            }
            .geometryGroup()
            .background(Color.appBackground)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Menu Content

    private var menuContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Header
            menuHeader

            // Menu Items
            VStack(spacing: AppTheme.Spacing.sm) {
                BibleMenuRow(
                    icon: "magnifyingglass",
                    iconColor: Color.scholarIndigo,
                    title: "Search",
                    subtitle: "Find verses and passages"
                ) {
                    withAnimation(animation) {
                        currentView = .search
                    }
                }

                menuDivider

                BibleMenuRow(
                    icon: "speaker.wave.2",
                    iconColor: Color.greekBlue,
                    title: "Listen",
                    subtitle: "Audio playback"
                ) {
                    dismiss()
                    onAudioTap()
                }

                menuDivider

                BibleMenuRow(
                    icon: "slider.horizontal.3",
                    iconColor: Color.theologyGreen,
                    title: "Display Settings",
                    subtitle: "Font, spacing, theme"
                ) {
                    withAnimation(animation) {
                        currentView = .settings
                    }
                }

                menuDivider

                BibleMenuRow(
                    icon: "sparkles",
                    iconColor: Color.divineGold,
                    title: "Insights",
                    subtitle: "Choose which insights to show"
                ) {
                    withAnimation(animation) {
                        currentView = .insights
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(AppTheme.Menu.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.xxl)
    }

    // MARK: - Menu Header

    private var menuHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Reading Options")
                    .font(CustomFonts.cormorantSemiBold(size: 22))
                    .foregroundStyle(Color.primaryText)

                Text("Customize your experience")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    // MARK: - Divider

    private var menuDivider: some View {
        Rectangle()
            .fill(AppTheme.Menu.divider)
            .frame(height: 1)
            .padding(.horizontal, AppTheme.Spacing.sm)
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Header
            subpageHeader(title: "Insights")

            // Insight toggles
            VStack(spacing: 0) {
                insightToggleRow(
                    icon: "person.2.fill",
                    color: .theologyGreen,
                    title: "Theology",
                    subtitle: "Doctrinal concepts and themes",
                    isEnabled: Binding(
                        get: { scholarSettings.showTheology },
                        set: { scholarSettings.showTheology = $0 }
                    )
                )

                insightDivider

                insightToggleRow(
                    icon: "questionmark.circle.fill",
                    color: .personalRose,
                    title: "Reflection",
                    subtitle: "Personal application prompts",
                    isEnabled: Binding(
                        get: { scholarSettings.showReflection },
                        set: { scholarSettings.showReflection = $0 }
                    )
                )

                insightDivider

                insightToggleRow(
                    icon: "link",
                    color: .connectionAmber,
                    title: "Connections",
                    subtitle: "Cross-references to other Scripture",
                    isEnabled: Binding(
                        get: { scholarSettings.showConnections },
                        set: { scholarSettings.showConnections = $0 }
                    )
                )

                insightDivider

                insightToggleRow(
                    icon: "textformat.abc",
                    color: .greekBlue,
                    title: "Greek",
                    subtitle: "Original language notes",
                    isEnabled: Binding(
                        get: { scholarSettings.showGreek },
                        set: { scholarSettings.showGreek = $0 }
                    )
                )
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(AppTheme.Menu.border, lineWidth: 1)
            )

            // Quick actions
            HStack(spacing: AppTheme.Spacing.md) {
                Button {
                    scholarSettings.enableAll()
                } label: {
                    Text("Enable All")
                        .font(Typography.UI.caption1.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(Color.scholarIndigo)

                Button {
                    scholarSettings.disableAll()
                } label: {
                    Text("Disable All")
                        .font(Typography.UI.caption1.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(Color.secondaryText)

                Spacer()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    private func insightToggleRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CustomFonts.cormorantSemiBold(size: 17))
                    .foregroundStyle(Color.primaryText)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: isEnabled)
                .labelsHidden()
                .tint(color)
        }
        .padding(.vertical, AppTheme.Spacing.sm)
        .opacity(isEnabled.wrappedValue ? 1.0 : 0.6)
    }

    private var insightDivider: some View {
        Rectangle()
            .fill(AppTheme.Menu.divider)
            .frame(height: 1)
            .padding(.horizontal, AppTheme.Spacing.sm)
    }

    // MARK: - Search Content

    private var searchContent: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Search Header
            subpageHeader(title: "Search Scripture")

            // Search Bar
            searchBar

            // Search Results
            searchResults
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Header
            subpageHeader(title: "Display Settings")

            // Scrollable settings
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
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
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    // MARK: - Subpage Header

    private func subpageHeader(title: String) -> some View {
        HStack {
            // Back button
            Button {
                withAnimation(animation) {
                    currentView = .menu
                    // Reset states
                    query = ""
                    results = []
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 15))
                }
                .foregroundStyle(Color.scholarIndigo)
            }

            Spacer()

            Text(title)
                .font(CustomFonts.cormorantSemiBold(size: 18))
                .foregroundStyle(Color.primaryText)

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    // MARK: - Theme Cards Section

    private var themeCardsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("APPEARANCE")
                .editorialLabel()
                .foregroundStyle(Color.scholarIndigo)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
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
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
    }

    // MARK: - Font Size Section

    private var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TEXT SIZE")
                .editorialLabel()
                .foregroundStyle(Color.scholarIndigo)

            HStack(spacing: AppTheme.Spacing.md) {
                Text("A")
                    .font(CustomFonts.cormorantRegular(size: 14))
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
                    .font(CustomFonts.cormorantRegular(size: 24))
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(AppTheme.Menu.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Reading Mode Section

    private var readingModeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("READING MODE")
                .editorialLabel()
                .foregroundStyle(Color.scholarIndigo)

            Picker("Reading Mode", selection: $usePagedReader) {
                Text("Scroll").tag(false)
                Text("Page").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(AppTheme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(AppTheme.Menu.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(animation) {
                    showAdvanced.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showAdvanced ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.scholarIndigo)

                    Text("ADVANCED")
                        .editorialLabel()
                        .foregroundStyle(Color.scholarIndigo)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if showAdvanced {
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
                            HStack(spacing: 4) {
                                Text(appState.lineSpacing.displayName)
                                    .font(.system(size: 14))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(Color.scholarIndigo)
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
                            HStack(spacing: 4) {
                                Text(appState.contentWidth.displayName)
                                    .font(.system(size: 14))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(Color.scholarIndigo)
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
                                .font(CustomFonts.cormorantSemiBold(size: 16))
                                .foregroundStyle(Color.primaryText)

                            Text("Show verses as continuous prose")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }
                    .tint(Color.scholarIndigo)
                    .disabled(usePagedReader)
                    .opacity(usePagedReader ? 0.5 : 1.0)
                    .padding(AppTheme.Spacing.md)
                }
                .background(Color.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .stroke(AppTheme.Menu.border, lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(AppTheme.Menu.divider)
            .frame(height: 1)
            .padding(.horizontal, AppTheme.Spacing.sm)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("PREVIEW")
                .editorialLabel()
                .foregroundStyle(Color.scholarIndigo)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                    Text("1")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.scholarIndigo)

                    Text("In the beginning God created the heaven and the earth.")
                        .readingVerse(size: appState.scriptureFontSize, font: appState.scriptureFont)
                        .foregroundStyle(Color.primaryText)
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(AppTheme.Menu.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.tertiaryText)

            TextField("John 3:16 or search words...", text: $query)
                .font(CustomFonts.cormorantRegular(size: 17))
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit {
                    performSearch(query)
                }
                .onChange(of: query) { _, newValue in
                    performSearch(newValue)
                }

            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.scholarIndigo.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var searchResults: some View {
        if isSearching {
            // Loading
            HStack(spacing: AppTheme.Spacing.sm) {
                ProgressView()
                    .tint(Color.scholarIndigo)
                Text("Searching...")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(height: 60)
        } else if query.isEmpty {
            // Hints
            searchHints
        } else if let ref = detectedReference {
            // Reference card
            referenceCard(ref)
        } else if !results.isEmpty {
            // Results
            resultsList
        } else {
            // No results
            Text("No results for \"\(query)\"")
                .font(.system(size: 14))
                .foregroundStyle(Color.tertiaryText)
                .frame(height: 60)
        }
    }

    private var searchHints: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("QUICK EXAMPLES")
                .editorialLabel()
                .foregroundStyle(Color.scholarIndigo)

            HStack(spacing: AppTheme.Spacing.sm) {
                hintChip("John 3:16")
                hintChip("love")
                hintChip("Rom 8")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hintChip(_ text: String) -> some View {
        Button {
            query = text
            performSearch(text)
        } label: {
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.scholarIndigo)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Color.scholarIndigo.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private func referenceCard(_ ref: ParsedReference) -> some View {
        Button {
            let range = VerseRange(
                bookId: ref.book.id,
                chapter: ref.chapter,
                verseStart: ref.verseStart ?? 1,
                verseEnd: ref.verseEnd ?? ref.verseStart ?? 1
            )
            onNavigate?(range)
            dismiss()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.scholarIndigo)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go to \(ref.displayText)")
                        .font(CustomFonts.cormorantSemiBold(size: 17))
                        .foregroundStyle(Color.primaryText)

                    Text("Jump to this reference")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.scholarIndigo)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.scholarIndigo.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        }
        .buttonStyle(.plain)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(results.prefix(5)) { result in
                    Button {
                        onNavigate?(result.verseRange)
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(result.verse.bookId <= 39 ? Color.greekBlue : Color.scholarIndigo)
                                .frame(width: 3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.verse.reference)
                                    .font(CustomFonts.cormorantSemiBold(size: 14))
                                    .foregroundStyle(Color.primaryText)

                                Text(result.highlightedSnippet)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.primaryText)
                                    .lineLimit(2)
                            }

                            Spacer()
                        }
                        .padding(AppTheme.Spacing.sm)
                        .background(Color.surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    }
                    .buttonStyle(.plain)
                }

                if results.count > 5 {
                    Text("+ \(results.count - 5) more results")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.tertiaryText)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Reference Detection

    private var detectedReference: ParsedReference? {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        if case .success(let ref) = ReferenceParser.parse(query) {
            return ref
        }
        return nil
    }

    // MARK: - Search Logic

    private func performSearch(_ query: String) {
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            isSearching = false
            return
        }

        // Don't search if it's just a reference
        if detectedReference != nil {
            results = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300)) // Debounce

            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await SearchService.shared.search(
                    query: query,
                    translationId: bibleService.currentTranslationId,
                    limit: 20
                )

                await MainActor.run {
                    results = searchResults
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    results = []
                    isSearching = false
                }
            }
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

// MARK: - Bible Menu Row

private struct BibleMenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticService.shared.lightTap()
            action()
        }) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(CustomFonts.cormorantSemiBold(size: 17))
                        .foregroundStyle(Color.primaryText)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.tertiaryText)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .padding(.horizontal, AppTheme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(isPressed ? AppTheme.Menu.buttonHover : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Bible Theme Card

private struct BibleThemeCard: View {
    let theme: AppThemeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                // Theme preview
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(theme.previewBackground)
                    .frame(width: 56, height: 36)
                    .overlay(
                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(theme.previewText)
                                .frame(width: 36, height: 2)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(theme.previewText.opacity(0.6))
                                .frame(width: 28, height: 2)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(
                                isSelected ? Color.scholarIndigo : AppTheme.Menu.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                // Theme name
                Text(theme.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? Color.scholarIndigo : Color.primaryText)

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.scholarIndigo)
                } else {
                    Circle()
                        .stroke(AppTheme.Menu.border, lineWidth: 1)
                        .frame(width: 14, height: 14)
                }
            }
            .padding(AppTheme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bible Font Size Slider

private struct BibleFontSizeSlider: View {
    @Binding var selectedSize: ScriptureFontSize

    private let sizes = ScriptureFontSize.allCases

    var body: some View {
        GeometryReader { geometry in
            let stepWidth = geometry.size.width / CGFloat(sizes.count - 1)
            let currentIndex = sizes.firstIndex(of: selectedSize) ?? 2

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.Menu.border)
                    .frame(height: 4)

                // Filled portion
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.scholarIndigo)
                    .frame(width: stepWidth * CGFloat(currentIndex), height: 4)

                // Thumb
                Circle()
                    .fill(Color.scholarIndigo)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.scholarIndigo.opacity(0.3), radius: 4)
                    .offset(x: stepWidth * CGFloat(currentIndex) - 10)
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
        .frame(height: 20)
    }
}

// MARK: - Bible Settings Row

private struct BibleSettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(title)
                .font(CustomFonts.cormorantSemiBold(size: 16))
                .foregroundStyle(Color.primaryText)

            Spacer()

            content
        }
        .padding(AppTheme.Spacing.md)
    }
}

// MARK: - Preview

#Preview("Bible Reading Menu") {
    struct PreviewContainer: View {
        @State private var showSheet = true

        var body: some View {
            Color.appBackground
                .ignoresSafeArea()
                .sheet(isPresented: $showSheet) {
                    BibleReadingMenuSheet(
                        onAudioTap: { print("Audio") },
                        onNavigate: { range in print("Navigate to \(range)") }
                    )
                    .environment(BibleService.shared)
                    .environment(AppState())
                }
        }
    }

    return PreviewContainer()
}
