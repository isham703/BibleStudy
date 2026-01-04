import SwiftUI

// MARK: - Reader Top Bar
// Apple Books-style top bar with book/chapter, translation, and settings access
// Hides on scroll down, shows on scroll up with premium choreographed animation

struct ReaderTopBar: View {
    let bookName: String
    let chapter: Int
    let translationName: String
    let isVisible: Bool
    let isAudioPlaying: Bool
    let onBookTap: () -> Void
    let onTranslationTap: () -> Void
    let onSettingsTap: () -> Void
    let onVoiceTap: () -> Void
    let onSearchTap: () -> Void

    // MARK: - Animation State
    // Content elements animate slightly after container for staggered feel
    @State private var contentOpacity: Double = 1
    @State private var translationScale: CGFloat = 1
    @State private var hasAppeared: Bool = false

    // Premium spring animation - refined feel like Apple Books
    private var chromeSpring: Animation {
        AppTheme.Animation.spring
    }

    // Faster spring for content elements (staggered feel)
    private var contentSpring: Animation {
        AppTheme.Animation.spring
    }

    var body: some View {
        HStack(spacing: 0) {
            // Book + Chapter (tappable)
            Button(action: onBookTap) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text("\(bookName) \(chapter)")
                        .font(Typography.Codex.emphasis)
                        .foregroundStyle(Color.primaryText)

                    Image(systemName: "chevron.down")
                        .font(Typography.UI.iconXxs)
                        .foregroundStyle(Color.secondaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Book and chapter: \(bookName) \(chapter)")
            .accessibilityHint("Opens book and chapter selector")
            .opacity(contentOpacity)

            Spacer()

            // Translation (tappable)
            Button(action: onTranslationTap) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(translationName)
                        .font(Typography.Codex.caption)
                        .foregroundStyle(Color.divineGold)

                    Image(systemName: "chevron.down")
                        .font(Typography.UI.iconXxxs)
                        .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.overlay))
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(Color.divineGold.opacity(AppTheme.Opacity.subtle))
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Translation: \(translationName)")
            .accessibilityHint("Opens translation selector")
            .scaleEffect(translationScale)
            .opacity(contentOpacity)

            Spacer()
                .frame(width: AppTheme.Spacing.md)

            // Voice button
            Button(action: onVoiceTap) {
                Image(systemName: isAudioPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(Typography.UI.iconMd)
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: AppTheme.IconSize.xl + 4, height: AppTheme.IconSize.xl + 4)
                    .background(Color.elevatedBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isAudioPlaying ? "Pause Audio" : "Play Audio")
            .accessibilityHint("Plays or pauses audio narration")
            .opacity(contentOpacity)

            Spacer()
                .frame(width: AppTheme.Spacing.xs)

            // Search button
            Button(action: onSearchTap) {
                Image(systemName: "magnifyingglass")
                    .font(Typography.UI.iconMd)
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: AppTheme.IconSize.xl + 4, height: AppTheme.IconSize.xl + 4)
                    .background(Color.elevatedBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search")
            .accessibilityHint("Opens search to find verses")
            .opacity(contentOpacity)

            Spacer()
                .frame(width: AppTheme.Spacing.xs)

            // Settings button
            Button(action: onSettingsTap) {
                Image(systemName: "textformat.size")
                    .font(Typography.UI.iconMd)
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: AppTheme.IconSize.xl + 4, height: AppTheme.IconSize.xl + 4)
                    .background(Color.elevatedBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reading settings")
            .accessibilityHint("Opens font size and display settings")
            .opacity(contentOpacity)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .frame(minHeight: 60)
        .background(
            // Subtle blur background with extended area for status bar
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(isVisible ? 0.98 : 0)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(
            // Bottom border - fades with visibility
            Rectangle()
                .fill(Color.divider.opacity(isVisible ? 0.5 : 0))
                .frame(height: AppTheme.Divider.hairline),
            alignment: .bottom
        )
        // Primary transform: slide up and fade
        .offset(y: isVisible ? 0 : -80)
        .opacity(isVisible ? 1 : 0)
        // Choreographed animation
        .animation(chromeSpring, value: isVisible)
        .onAppear {
            // Sync initial state
            if !hasAppeared {
                contentOpacity = isVisible ? 1 : 0
                translationScale = isVisible ? 1 : 0.95
                hasAppeared = true
            }
        }
        .onChange(of: isVisible) { _, newValue in
            // Staggered content animation
            if newValue {
                // Appearing: content fades in slightly after container
                withAnimation(contentSpring.delay(0.05)) {
                    contentOpacity = 1
                    translationScale = 1
                }
            } else {
                // Disappearing: content fades first
                withAnimation(contentSpring) {
                    contentOpacity = 0
                    translationScale = 0.95
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Reader Top Bar - Interactive") {
    struct PreviewContainer: View {
        @State private var isVisible = true
        @State private var isAudioPlaying = false

        var body: some View {
            VStack {
                ReaderTopBar(
                    bookName: "Ephesians",
                    chapter: 2,
                    translationName: "ESV",
                    isVisible: isVisible,
                    isAudioPlaying: isAudioPlaying,
                    onBookTap: {},
                    onTranslationTap: {},
                    onSettingsTap: {},
                    onVoiceTap: { isAudioPlaying.toggle() },
                    onSearchTap: {}
                )

                Spacer()

                // Toggle button to test animation
                Button {
                    isVisible.toggle()
                } label: {
                    Text(isVisible ? "Hide Top Bar" : "Show Top Bar")
                        .font(Typography.UI.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Capsule().fill(Color.accentGold))
                }
                .padding(.bottom, AppTheme.Spacing.xxxl + 2)
            }
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}

#Preview("Reader Top Bar - Visible") {
    VStack {
        ReaderTopBar(
            bookName: "Ephesians",
            chapter: 2,
            translationName: "ESV",
            isVisible: true,
            isAudioPlaying: false,
            onBookTap: {},
            onTranslationTap: {},
            onSettingsTap: {},
            onVoiceTap: {},
            onSearchTap: {}
        )
        Spacer()
    }
    .background(Color.appBackground)
}
