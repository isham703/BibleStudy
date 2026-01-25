import SwiftUI

// MARK: - Note Template Filter Chip
// Tappable filter chip for note templates
// Shows template icon, name, and count badge when selected

struct NoteTemplateFilterChip: View {
    let template: NoteTemplate?  // nil = "All"
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    private var displayColor: Color {
        if let template = template {
            return template.accentColor
        }
        return Color("AppAccentAction")
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                if let template = template {
                    Image(systemName: template.icon)
                        .font(Typography.Icon.xs)
                }

                Text(template?.displayName ?? "All")
                    .font(Typography.Command.caption)

                if count > 0 {
                    Text("\(count)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("TertiaryText"))
                }
            }
            .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? displayColor.opacity(Theme.Opacity.selectionBackground) : Color("AppSurface"))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? displayColor : Color("AppDivider"),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let templateName = template?.displayName ?? "All"
        let selectedState = isSelected ? "Selected" : ""
        return "\(templateName) filter, \(count) notes \(selectedState)"
    }
}

// MARK: - Preview

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Theme.Spacing.sm) {
            NoteTemplateFilterChip(template: nil, count: 15, isSelected: true, action: {})
            NoteTemplateFilterChip(template: .freeform, count: 5, isSelected: false, action: {})
            NoteTemplateFilterChip(template: .observation, count: 3, isSelected: false, action: {})
            NoteTemplateFilterChip(template: .application, count: 2, isSelected: false, action: {})
            NoteTemplateFilterChip(template: .questions, count: 4, isSelected: false, action: {})
            NoteTemplateFilterChip(template: .exegesis, count: 1, isSelected: false, action: {})
            NoteTemplateFilterChip(template: .prayer, count: 0, isSelected: false, action: {})
        }
        .padding()
    }
    .background(Color("AppBackground"))
}
