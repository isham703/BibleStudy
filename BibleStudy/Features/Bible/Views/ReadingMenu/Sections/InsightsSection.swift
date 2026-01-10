import SwiftUI

// MARK: - Insights Section
// Settings for insight type toggles (Theology, Reflection, Connections, Greek)
// Persists preferences to BibleSettings singleton

struct InsightsSection: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var state: ReadingMenuState

    private var scholarSettings: BibleSettings { BibleSettings.shared }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
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
            .padding(Theme.Spacing.md)
            .background(Color.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Menu.border, lineWidth: Theme.Stroke.hairline)
            )

            // Quick actions
            HStack(spacing: Theme.Spacing.md) {
                Button {
                    scholarSettings.enableAll()
                } label: {
                    Text("Enable All")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                Button {
                    scholarSettings.disableAll()
                } label: {
                    Text("Disable All")
                        .font(Typography.Command.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(Color.secondaryText)

                Spacer()
            }
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

    // MARK: - Insight Toggle Row

    private func insightToggleRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(Theme.Opacity.subtle + 0.02))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(Typography.Icon.md.weight(.semibold))
                    .foregroundStyle(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.Scripture.body.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                Text(subtitle)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: isEnabled)
                .labelsHidden()
                .tint(color)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .opacity(isEnabled.wrappedValue ? 1.0 : 0.6)
    }

    // MARK: - Divider

    private var insightDivider: some View {
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
            InsightsSection(state: state)
                .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}
