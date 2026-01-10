import SwiftUI

// MARK: - Floating Sanctuary Settings
/// A bold, innovative settings design featuring elevated floating cards
/// with ambient gold glow effects, contextual groupings, and a floating
/// quick-access navigation bar.

struct FloatingSanctuarySettings: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = SettingsViewModel()

    @State private var activeSection: SanctuarySection = .reading
    @State private var showQuickNav = true

    // Confirmation dialogs
    @State private var showSignOutConfirmation = false
    @State private var showClearCacheConfirmation = false

    // Reading mode preference
    @AppStorage(AppConfiguration.UserDefaultsKeys.usePagedReader) private var usePagedReader: Bool = false

    // User preferences (using @AppStorage for automatic persistence + SwiftUI integration)
    @AppStorage(AppConfiguration.UserDefaultsKeys.devotionalModeEnabled) private var devotionalModeEnabled: Bool = false
    // Note: scholarModeEnabled, voiceGuidanceEnabled, aiInsightsEnabled removed - features not wired
    @AppStorage(AppConfiguration.UserDefaultsKeys.hapticFeedbackEnabled) private var hapticFeedbackEnabled: Bool = true
    @AppStorage(AppConfiguration.UserDefaultsKeys.cloudSyncEnabled) private var cloudSyncEnabled: Bool = false

    // Entry animation state
    @State private var appeared = false
    @State private var headerAppeared = false

    var body: some View {
        NavigationStack {
            // Full settings view with all sections
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    headerSection

                    // Reading Section
                    readingSection

                    // Subscription Section
                    subscriptionSection

                    // Account Section
                    accountSection

                    // More Section
                    moreSection

                    // Footer
                    footerSection
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.Spacing.lg)
                // swiftlint:disable:next hardcoded_padding_edge
                .padding(.bottom, 120)
            }
            .background(ambientBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Typography.Command.body.weight(.medium))
                            .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    }
                }
            }
        }
        .preferredColorScheme(appState.colorScheme)
        .task {
            await viewModel.loadInitialData()
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(trigger: viewModel.paywallTrigger)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { @MainActor in
                    await viewModel.signOut()
                    // Update AppState to trigger navigation to AuthView
                    appState.isAuthenticated = false
                    appState.userId = nil
                    // Dismiss settings sheet so navigation takes effect
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .confirmationDialog("Clear Audio Cache", isPresented: $showClearCacheConfirmation, titleVisibility: .visible) {
            Button("Clear Cache", role: .destructive) {
                viewModel.clearAudioCache()
                HapticService.shared.success()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all downloaded audio files. They will be re-downloaded when needed.")
        }
    }

    // MARK: - Section Anchor

    private func sectionAnchor(_ section: SanctuarySection) -> some View {
        Color.clear
            .frame(height: Theme.Stroke.hairline)
            .id(section)
    }

    // MARK: - Computed Properties

    private var userInitials: String {
        guard let name = viewModel.displayName, !name.isEmpty else {
            return "G"
        }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return first + last
        } else {
            return String(name.prefix(2))
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            Colors.Surface.background(for: ThemeMode.current(from: colorScheme))
                .ignoresSafeArea()

            // Subtle ambient glow based on active section
            RadialGradient(
                colors: [
                    Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Golden dust motes with subtle glow
            FloatingSanctuaryParticles()
                .opacity(Theme.Opacity.secondary)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Profile avatar with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Text(userInitials)
                            .font(Typography.Scripture.title)
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.primary), Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: Theme.Stroke.control
                            )
                    }
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text(viewModel.displayName ?? "Guest")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                Text(viewModel.tierDisplayName)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                    )
            }
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Reading Section

    private var readingSection: some View {
        FloatingSectionCard(
            title: "Reading Experience",
            icon: "book.fill",
            accentColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Font Size with Discrete Slider
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "textformat.size")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            .frame(width: 32)

                        Text("Text Size")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                        Spacer()

                        Text(appState.scriptureFontSize.displayName)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    }

                    HStack(spacing: Theme.Spacing.md) {
                        Text("A")
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))

                        FontSizeSlider(
                            selectedSize: Binding(
                                get: { appState.scriptureFontSize },
                                set: { newSize in
                                    appState.scriptureFontSize = newSize
                                    UserDefaults.standard.set(newSize.rawValue, forKey: AppConfiguration.UserDefaultsKeys.preferredFontSize)
                                }
                            )
                        )

                        Text("A")
                            .font(Typography.Scripture.body)
                            .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                    }

                    // Preview text
                    Text("In the beginning was the Word...")
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                        .padding(.top, Theme.Spacing.xs)
                }
                .padding(Theme.Spacing.lg)

                FloatingDivider()

                // Theme Selection
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            .frame(width: 32)

                        Text("Theme")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(AppThemeOption.allCases) { theme in
                            ThemePill(
                                theme: theme,
                                isSelected: AppThemeOption(from: appState.preferredTheme) == theme
                            ) {
                                withAnimation(Theme.Animation.settle) {
                                    appState.preferredTheme = theme.toAppThemeMode
                                    UserDefaults.standard.set(theme.rawValue, forKey: AppConfiguration.UserDefaultsKeys.preferredTheme)
                                }
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)

                FloatingDivider()

                // Reading Mode Picker
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "book.pages")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            .frame(width: 32)

                        Text("Reading Mode")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                    }

                    Picker("Reading Mode", selection: $usePagedReader) {
                        Text("Scroll").tag(false)
                        Text("Page").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(Theme.Spacing.lg)

                FloatingDivider()

                // Audio Cache Section
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            .frame(width: 32)

                        Text("Audio Cache")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                        Spacer()

                        Text(viewModel.audioCacheSize)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    }

                    // Cache limit picker
                    HStack {
                        Text("Cache Limit")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                        Spacer()

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
                            HStack(spacing: 2) {
                                Text("\(viewModel.audioCacheLimitMB) MB")
                                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.overlay))
                            }
                        }
                    }

                    // Clear cache button
                    Button {
                        showClearCacheConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(Typography.Command.caption)
                            Text("Clear Cache")
                                .font(Typography.Command.caption)
                        }
                        .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.card)
                                .stroke(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary), lineWidth: Theme.Stroke.hairline)
                        )
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        FloatingSectionCard(
            title: "Subscription",
            icon: "crown.fill",
            accentColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Tier Status Card
                tierStatusCard
                    .padding(Theme.Spacing.lg)

                if viewModel.isPremiumOrHigher {
                    // Premium/Scholar user content
                    premiumSubscriptionContent
                } else {
                    // Free user content
                    freeSubscriptionContent
                }
            }
        }
    }

    private var tierStatusCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Tier icon with glow for premium
            ZStack {
                if viewModel.isPremiumOrHigher {
                    Circle()
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium))
                        .blur(radius: 8)
                        .frame(width: 48, height: 48)
                }

                Image(systemName: viewModel.tierIcon)
                    .font(Typography.Command.body.weight(.medium))
                    .foregroundStyle(viewModel.isPremiumOrHigher ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(viewModel.isPremiumOrHigher
                                ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
                                : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text(viewModel.tierDisplayName)
                        .font(Typography.Command.cta)
                        .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                    if viewModel.isScholar {
                        Text("BEST VALUE")
                            .font(Typography.Command.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.sm - 2)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))))
                    }
                }

                Text(viewModel.tierDescription)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }

            Spacer()

            if !viewModel.isPremiumOrHigher {
                Button {
                    viewModel.showUpgradePaywall()
                } label: {
                    Text("Upgrade")
                        .font(Typography.Command.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Capsule().fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))))
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(viewModel.isPremiumOrHigher
                    ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint)
                    : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    viewModel.isPremiumOrHigher
                        ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium)
                        : Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary),
                    lineWidth: Theme.Stroke.hairline
                )
        )
    }

    private var freeSubscriptionContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            FloatingDivider()

            // Usage Statistics
            VStack(spacing: Theme.Spacing.md) {
                usageRow(
                    title: "AI Insights",
                    used: viewModel.aiInsightsUsed,
                    total: viewModel.aiInsightsTotal,
                    icon: "sparkles"
                )

                usageRow(
                    title: "Highlights",
                    used: viewModel.highlightsUsed,
                    total: viewModel.highlightsTotal,
                    icon: "highlighter"
                )

                usageRow(
                    title: "Notes",
                    used: viewModel.notesUsed,
                    total: viewModel.notesTotal,
                    icon: "note.text"
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)

            // Feature preview
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Unlock with Premium:")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    featurePreviewRow(icon: "text.book.closed", text: "All Bible translations")
                    featurePreviewRow(icon: "sparkles", text: "Unlimited AI insights")
                    featurePreviewRow(icon: "note.text", text: "Unlimited notes")
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            // Restore purchases
            restorePurchasesButton
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
        }
    }

    private func usageRow(title: String, used: Int, total: Int, icon: String) -> some View {
        // Clamp total to prevent layout issues with large/invalid values
        let safeTotal = max(0, min(total, 10))
        let safeUsed = max(0, min(used, safeTotal))

        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 20)

            Text(title)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

            Spacer()

            // Usage dots - use Array to avoid ForEach range issues
            if safeTotal > 0 {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(Array(0..<safeTotal), id: \.self) { index in
                        Circle()
                            .fill(index < safeUsed ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                            .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                    }
                }
            }

            Text("\(safeUsed)/\(safeTotal)")
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
        }
    }

    private func featurePreviewRow(icon: String, text: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 20)

            Text(text)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
        }
    }

    private var premiumSubscriptionContent: some View {
        VStack(spacing: Theme.Spacing.md) {
            FloatingDivider()

            // Benefits summary
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Your benefits:")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    .padding(.horizontal, Theme.Spacing.lg)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.xs) {
                    benefitBadge(icon: "checkmark.circle.fill", text: "All translations")
                    benefitBadge(icon: "checkmark.circle.fill", text: "Unlimited AI")
                    benefitBadge(icon: "checkmark.circle.fill", text: "Unlimited notes")
                    if viewModel.isScholar {
                        benefitBadge(icon: "checkmark.circle.fill", text: "Hebrew & Greek")
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }

            FloatingDivider()

            // Renewal info
            if let renewalDate = viewModel.formattedRenewalDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                    Text("Renews \(renewalDate)")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }

            // Manage subscription button
            Button {
                Task { await viewModel.manageSubscription() }
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                        .font(Typography.Command.caption)
                    Text("Manage Subscription")
                        .font(Typography.Command.caption)
                }
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary), lineWidth: Theme.Stroke.hairline)
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)

            // Restore purchases
            restorePurchasesButton
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
        }
    }

    private func benefitBadge(icon: String, text: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Semantic.success(for: ThemeMode.current(from: colorScheme)))

            Text(text)
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
        }
    }

    private var restorePurchasesButton: some View {
        Button {
            Task { await viewModel.restorePurchases() }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                if viewModel.isRestoringPurchases {
                    ProgressView()
                        // swiftlint:disable:next hardcoded_scale_effect
                        .scaleEffect(0.8)
                        .tint(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .font(Typography.Command.caption)
                }
                Text("Restore Purchases")
                    .font(Typography.Command.caption)
            }
            .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
        }
        .disabled(viewModel.isRestoringPurchases)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        FloatingSectionCard(
            title: "Account & Sync",
            icon: "person.crop.circle.fill",
            accentColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        ) {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isAuthenticated {
                    // Authenticated user content
                    NavigationLink {
                        AccountDetailView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                                    .frame(width: 44, height: 44)

                                Text(userInitials)
                                    .font(Typography.Command.cta)
                                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.displayName ?? "Bible Student")
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                                if let email = viewModel.email {
                                    Text(email)
                                        .font(Typography.Command.caption)
                                        .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(Typography.Command.caption.weight(.semibold))
                                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                        }
                        .padding(Theme.Spacing.lg)
                    }
                    .buttonStyle(.plain)

                    FloatingDivider()

                    FloatingToggleRow(
                        title: "Cloud Sync",
                        subtitle: "Sync highlights and notes across devices",
                        icon: "icloud.fill",
                        isOn: $cloudSyncEnabled
                    )

                    FloatingDivider()

                    // Sign Out
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(Typography.Command.body)
                                .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign Out")
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Colors.Semantic.error(for: ThemeMode.current(from: colorScheme)))

                                Text(viewModel.email ?? "")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                            }

                            Spacer()
                        }
                        .padding(Theme.Spacing.lg)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Sign in prompt
                    NavigationLink {
                        AuthView()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
                                    .frame(width: 52, height: 52)

                                Image(systemName: "person.circle")
                                    .font(Typography.Command.cta.weight(.light))
                                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sign In")
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                                Text("Sync highlights and notes across devices")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(Typography.Command.caption.weight(.semibold))
                                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                        }
                        .padding(Theme.Spacing.lg)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - More Section

    private var moreSection: some View {
        FloatingSectionCard(
            title: "Notifications & More",
            icon: "bell.fill",
            accentColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme))
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Notifications section
                if viewModel.notificationsAuthorized {
                    FloatingToggleRow(
                        title: "Daily Reminder",
                        subtitle: "Reading reminders and updates",
                        icon: "bell.badge.fill",
                        isOn: $viewModel.dailyReminderEnabled
                    )

                    FloatingDivider()

                    // Time picker row
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "clock.fill")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                            .frame(width: 32)

                        Text("Reminder Time")
                            .font(Typography.Command.body)
                            .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                        Spacer()

                        DatePicker("", selection: $viewModel.dailyReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    }
                    .padding(Theme.Spacing.lg)
                    .opacity(viewModel.dailyReminderEnabled ? 1.0 : Theme.Opacity.primary)
                    .disabled(!viewModel.dailyReminderEnabled)

                    FloatingDivider()

                    FloatingToggleRow(
                        title: "Streak Protection",
                        subtitle: "Extra reminders to maintain your streak",
                        icon: "flame.fill",
                        isOn: $viewModel.streakReminderEnabled
                    )
                } else {
                    // Notification permission prompt
                    Button {
                        Task { await viewModel.requestNotificationPermission() }
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "bell.badge.fill")
                                .font(Typography.Command.body)
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Notifications")
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                                Text("Get reading reminders and updates")
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
                            }

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .font(Typography.Command.body)
                                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        }
                        .padding(Theme.Spacing.lg)
                    }
                    .buttonStyle(.plain)
                }

                FloatingDivider()

                FloatingToggleRow(
                    title: "Haptic Feedback",
                    subtitle: "Tactile response for interactions",
                    icon: "hand.tap.fill",
                    isOn: $hapticFeedbackEnabled
                )

                FloatingDivider()

                // About row with dynamic version
                FloatingNavigationRow(
                    title: "About",
                    subtitle: "Version \(AppConfiguration.App.version) • Build \(AppConfiguration.App.build)",
                    icon: "info.circle.fill",
                    action: {
                        // TODO: Navigate to about screen
                    }
                )
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Rectangle()
                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.secondary))
                .frame(width: 40, height: Theme.Stroke.hairline)

            Text("Bible Study • Floating Sanctuary")
                .font(Typography.Command.caption)
                .foregroundStyle(Colors.Surface.textTertiary(for: ThemeMode.current(from: colorScheme)))
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Floating Quick Navigation

    private var floatingQuickNav: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(SanctuarySection.allCases) { section in
                Button {
                    // swiftlint:disable:next hardcoded_animation_spring hardcoded_with_animation
                    withAnimation(Theme.Animation.settle) {
                        activeSection = section
                    }
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: section.icon)
                            .font(Typography.Command.body.weight(.medium))

                        Text(section.shortTitle)
                            .font(Typography.Command.caption.weight(.medium))
                    }
                    .foregroundStyle(activeSection == section ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
                    .frame(width: 56, height: 50)
                    .background {
                        if activeSection == section {
                            RoundedRectangle(cornerRadius: Theme.Radius.card)
                                .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.light))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        // swiftlint:disable:next hardcoded_line_width
                        .strokeBorder(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium), lineWidth: 0.5)
                }
        }
        .shadow(color: .black.opacity(Theme.Opacity.disabled), radius: 20, y: 10)
        .padding(.bottom, Theme.Spacing.xl)
    }
}

// MARK: - Sanctuary Section

enum SanctuarySection: String, CaseIterable, Identifiable {
    case reading, subscription, account, more

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .reading: return "book.fill"
        case .subscription: return "crown.fill"
        case .account: return "person.fill"
        case .more: return "ellipsis"
        }
    }

    var shortTitle: String {
        switch self {
        case .reading: return "Read"
        case .subscription: return "Plan"
        case .account: return "Account"
        case .more: return "More"
        }
    }

}

// MARK: - Theme Pill

struct ThemePill: View {
    let theme: AppThemeOption
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.xs + 2) {
                Circle()
                    .fill(theme.previewColor)
                    .frame(width: 24 + 8, height: 24 + 8)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium),
                                lineWidth: isSelected ? Theme.Stroke.control : Theme.Stroke.hairline
                            )
                    }

                Text(theme.name)
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.faint))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Theme Option

enum AppThemeOption: String, CaseIterable, Identifiable {
    case system, light, dark, sepia, oled

    var id: String { rawValue }

    var name: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        case .oled: return "OLED"
        }
    }

    var previewColor: Color {
        switch self {
        case .system: return Colors.Semantic.accentSeal(for: .dark)  // Bronze as neutral
        case .light: return Colors.Surface.background(for: .light)   // Light parchment
        case .dark: return Colors.Surface.background(for: .dark)     // Near-black
        case .sepia: return Color.sepiaPreview  // Sepia preview (Phase 8 feature)
        case .oled: return Color.oledPreview   // Pure black (Phase 8 feature)
        }
    }

    // MARK: - Conversion to AppThemeMode

    var toAppThemeMode: AppThemeMode {
        switch self {
        case .system: return .system
        case .light: return .light
        case .dark: return .dark
        case .sepia: return .sepia
        case .oled: return .oled
        }
    }

    init(from mode: AppThemeMode) {
        switch mode {
        case .system: self = .system
        case .light: self = .light
        case .dark: self = .dark
        case .sepia: self = .sepia
        case .oled: self = .oled
        }
    }
}

// MARK: - Section Reveal Modifier
/// Staggered reveal animation for settings sections with "manuscript unfurling" effect.

struct SectionRevealModifier: ViewModifier {
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        if Theme.Animation.isReduceMotionEnabled {
            // Simple fade for accessibility
            content
                .opacity(appeared ? 1 : 0)
                .animation(Theme.Animation.settle, value: appeared)
        } else {
            // Full staggered reveal with "manuscript unfurling" effect
            content
                .opacity(appeared ? 1 : 0)
                // swiftlint:disable:next hardcoded_offset
                .offset(y: appeared ? 0 : 30)
                // swiftlint:disable:next hardcoded_animation_spring
                .animation(
                    Theme.Animation.settle
                    .delay(delay),
                    value: appeared
                )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FloatingSanctuarySettings()
    }
}
