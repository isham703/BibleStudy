import SwiftUI

// MARK: - Story Reading Level Selector
// Picker for selecting story reading level (Child/Teen/Adult)

struct StoryReadingLevelSelector: View {
    @Binding var selectedLevel: StoryReadingLevel
    var showAllOption: Bool = false
    @Binding var showAll: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
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
        HStack(spacing: AppTheme.Spacing.sm) {
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.UI.caption1)
                Text(label)
                    .font(Typography.UI.chipLabel)
            }
            .foregroundStyle(isSelected ? .white : Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentGold : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
        .animation(AppTheme.Animation.quick, value: isSelected)
    }
}

// MARK: - Story Reading Level Info Sheet
struct StoryReadingLevelInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    Text("Reading levels help tailor stories to different audiences. All stories maintain biblical accuracy while adjusting language complexity and thematic depth.")
                        .font(Typography.UI.warmBody)
                        .foregroundStyle(Color.secondaryText)

                    ForEach(StoryReadingLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: level.icon)
                                    .font(Typography.UI.title3)
                                    .foregroundStyle(Color.accentGold)
                                    .frame(width: AppTheme.IconContainer.medium)

                                Text(level.displayName)
                                    .font(Typography.Display.headline)
                                    .foregroundStyle(Color.primaryText)
                            }

                            Text(level.levelDescription)
                                .font(Typography.UI.warmBody)
                                .foregroundStyle(Color.secondaryText)
                        }
                        .padding(AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
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
            VStack(spacing: AppTheme.Spacing.xl) {
                Text("With All Option")
                    .font(Typography.UI.headline)

                StoryReadingLevelSelector(
                    selectedLevel: $level,
                    showAllOption: true,
                    showAll: $showAll
                )

                Text("Without All Option")
                    .font(Typography.UI.headline)

                StoryReadingLevelPicker(selectedLevel: $level)

                Text("Selected: \(level.displayName)")
                    .font(Typography.UI.body)
            }
            .padding()
            .background(Color.appBackground)
        }
    }

    return PreviewWrapper()
}
