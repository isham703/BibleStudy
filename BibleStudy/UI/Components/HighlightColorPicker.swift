import SwiftUI

// MARK: - Highlight Color Picker
// Allows users to select a highlight color and optional category

struct HighlightColorPicker: View {
    @Binding var selectedColor: HighlightColor
    @Binding var selectedCategory: HighlightCategory
    var onSelect: ((HighlightColor, HighlightCategory) -> Void)?

    @State private var showCategoryPicker = false

    init(
        selectedColor: Binding<HighlightColor>,
        selectedCategory: Binding<HighlightCategory> = .constant(.none),
        onSelect: ((HighlightColor, HighlightCategory) -> Void)? = nil
    ) {
        _selectedColor = selectedColor
        _selectedCategory = selectedCategory
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Color Selection Row
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    Button {
                        selectedColor = color
                        onSelect?(color, selectedCategory)
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if selectedColor == color {
                                    Circle()
                                        .stroke(Color.primaryText, lineWidth: AppTheme.Border.regular)
                                        .frame(width: 38, height: 38)
                                }
                            }
                    }
                }
            }

            // Category Selection
            Button {
                showCategoryPicker = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    categoryIcon(for: selectedCategory)
                        .font(Typography.UI.subheadline)

                    Text(selectedCategory.displayName)
                        .font(Typography.UI.caption1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(Typography.UI.caption1)
                }
                .foregroundStyle(selectedCategory == .none ? Color.secondaryText : Color.primaryText)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(Color.elevatedBackground)
                )
            }
        }
        .padding(AppTheme.Spacing.sm)
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(
                selectedCategory: $selectedCategory,
                selectedColor: $selectedColor,
                onSelect: { category in
                    onSelect?(selectedColor, category)
                }
            )
        }
    }

    @ViewBuilder
    private func categoryIcon(for category: HighlightCategory) -> some View {
        if category.usesStreamlineIcon {
            Image(category.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: category.icon)
        }
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: HighlightCategory
    @Binding var selectedColor: HighlightColor
    var onSelect: ((HighlightCategory) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                ForEach(HighlightCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                        // Optionally suggest a color based on category
                        if category != .none {
                            selectedColor = category.suggestedColor
                        }
                        onSelect?(category)
                        dismiss()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            // Category icon with suggested color
                            categoryIcon(for: category)
                                .foregroundStyle(category.suggestedColor.color)
                                .frame(width: AppTheme.IconContainer.medium)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(category.displayName)
                                    .font(Typography.UI.body)
                                    .foregroundStyle(Color.primaryText)

                                Text(category.description)
                                    .font(Typography.UI.caption1)
                                    .foregroundStyle(Color.secondaryText)
                            }

                            Spacer()

                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.scholarAccent)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func categoryIcon(for category: HighlightCategory) -> some View {
        if category.usesStreamlineIcon {
            Image(category.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        } else {
            Image(systemName: category.icon)
                .font(Typography.UI.title3)
        }
    }
}

// MARK: - Simple Highlight Color Picker (Legacy)
// For cases where only color is needed

struct SimpleHighlightColorPicker: View {
    @Binding var selectedColor: HighlightColor
    var onSelect: ((HighlightColor) -> Void)?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ForEach(HighlightColor.allCases, id: \.self) { color in
                Button {
                    selectedColor = color
                    onSelect?(color)
                } label: {
                    Circle()
                        .fill(color.color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            if selectedColor == color {
                                Circle()
                                    .stroke(Color.primaryText, lineWidth: AppTheme.Border.regular)
                                    .frame(width: 38, height: 38)
                            }
                        }
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
    }
}

// MARK: - Highlight Color Button
// Single color button for quick highlight action

struct HighlightColorButton: View {
    let color: HighlightColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.color)
                .frame(width: 24, height: 24)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.xl) {
        HighlightColorPicker(
            selectedColor: .constant(.amber),
            selectedCategory: .constant(.promise)
        )

        SimpleHighlightColorPicker(selectedColor: .constant(.amber))

        HStack {
            ForEach(HighlightColor.allCases, id: \.self) { color in
                HighlightColorButton(color: color, isSelected: color == .amber) {}
            }
        }
    }
    .padding()
    .background(Color.appBackground)
}
