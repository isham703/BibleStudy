import SwiftUI

// MARK: - Bible Settings Row
// Generic settings row container with title and content
// Used in SettingsSection for advanced settings items

struct BibleSettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(title)
                .font(Typography.Scripture.body.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            Spacer()

            content
        }
        .padding(Theme.Spacing.md)
    }
}

// MARK: - Preview

#if DEBUG
struct BibleSettingsRow_Previews: PreviewProvider {
    static var previews: some View {
        BibleSettingsRowPreviewWrapper()
    }
}

private struct BibleSettingsRowPreviewWrapper: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            BibleSettingsRow(title: "Line Spacing") {
                Text("Normal")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }

            Divider()

            BibleSettingsRow(title: "Content Width") {
                Text("Standard")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
        }
        .background(Color.surfaceBackground)
        .padding()
    }
}
#endif
