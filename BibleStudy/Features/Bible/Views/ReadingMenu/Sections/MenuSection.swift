import SwiftUI

// MARK: - Menu Section
// Main menu view with options for search, audio, settings, and insights
// Navigates to other sections via state mutations

struct MenuSection: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var state: ReadingMenuState
    let onAudioTap: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            menuHeader

            // Menu Items
            VStack(spacing: Theme.Spacing.sm) {
                BibleMenuRow(
                    icon: "magnifyingglass",
                    iconColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)),
                    title: "Search",
                    subtitle: "Find verses and passages"
                ) {
                    state.navigateToSearch()
                }

                menuDivider

                BibleMenuRow(
                    icon: "speaker.wave.2",
                    iconColor: Color.navyDeep,
                    title: "Listen",
                    subtitle: "Audio playback"
                ) {
                    dismiss()
                    onAudioTap()
                }

                menuDivider

                BibleMenuRow(
                    icon: "slider.horizontal.3",
                    iconColor: Color.bibleOlive,
                    title: "Display Settings",
                    subtitle: "Font, spacing, theme"
                ) {
                    state.navigateToSettings()
                }

                menuDivider

                BibleMenuRow(
                    icon: "sparkles",
                    iconColor: Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)),
                    title: "Insights",
                    subtitle: "Choose which insights to show"
                ) {
                    state.navigateToInsights()
                }
            }
            .padding(Theme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Menu.border, lineWidth: Theme.Stroke.hairline)
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xxl)
    }

    // MARK: - Menu Header

    private var menuHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reading Options")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.primaryText)

                Text("Customize your experience")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }

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

    // MARK: - Divider

    private var menuDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(Theme.Opacity.light))
            .frame(height: Theme.Stroke.hairline)
            .padding(.horizontal, Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var state = ReadingMenuState()

        var body: some View {
            MenuSection(state: state) {
                print("Audio tapped")
            }
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}
