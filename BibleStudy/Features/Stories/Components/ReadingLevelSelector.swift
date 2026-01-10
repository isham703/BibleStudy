import SwiftUI

// MARK: - Story Reading Level Selector
// Picker for selecting story reading level (Child/Teen/Adult)

struct StoryReadingLevelSelector: View {
    @Binding var selectedLevel: StoryReadingLevel
    var showAllOption: Bool = false
    @Binding var showAll: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if showAllOption {
                StoryReadingLevelButton(
                    label: "All",
                    icon: "books.vertical",
                    isSelected: showAll,
                    action: { showAll = true }
                )
            }

            ForEach(StoryReadingLevel.allCases, id: \.self) { level in
                StoryReadingLevelButton(
                    label: level.displayName,
                    icon: level.icon,
                    isSelected: !showAll && selectedLevel == level,
                    action: {
                        showAll = false
                        selectedLevel = level
                    }
                )
            }
        }
    }
}

// MARK: - Simple Selector (without All option)
struct StoryReadingLevelPicker: View {
    @Binding var selectedLevel: StoryReadingLevel

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(StoryReadingLevel.allCases, id: \.self) { level in
                StoryReadingLevelButton(
                    label: level.displayName,
                    icon: level.icon,
                    isSelected: selectedLevel == level,
                    action: { selectedLevel = level }
                )
            }
        }
    }
}

// MARK: - Story Reading Level Button
struct StoryReadingLevelButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.Command.caption)
                Text(label)
                    .font(Typography.Command.meta)
            }
            .foregroundStyle(isSelected ? .white : Color.primaryText)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.fade, value: isSelected)
    }
}

// MARK: - Story Reading Level Info Sheet
struct StoryReadingLevelInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text("Reading levels help tailor stories to different audiences. All stories maintain biblical accuracy while adjusting language complexity and thematic depth.")
                        .font(Typography.Command.body)
                        .foregroundStyle(Color.secondaryText)

                    ForEach(StoryReadingLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: level.icon)
                                    .font(Typography.Command.title3)
                                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                    .frame(width: 32)

                                Text(level.displayName)
                                    .font(Typography.Scripture.heading)
                                    .foregroundStyle(Color.primaryText)
                            }

                            Text(level.levelDescription)
                                .font(Typography.Command.body)
                                .foregroundStyle(Color.secondaryText)
                        }
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Reading Levels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var level: StoryReadingLevel = .adult
        @State private var showAll = true

        var body: some View {
            VStack(spacing: Theme.Spacing.xl) {
                Text("With All Option")
                    .font(Typography.Command.headline)

                StoryReadingLevelSelector(
                    selectedLevel: $level,
                    showAllOption: true,
                    showAll: $showAll
                )

                Text("Without All Option")
                    .font(Typography.Command.headline)

                StoryReadingLevelPicker(selectedLevel: $level)

                Text("Selected: \(level.displayName)")
                    .font(Typography.Command.body)
            }
            .padding()
            .background(Color.appBackground)
        }
    }

    return PreviewWrapper()
}
