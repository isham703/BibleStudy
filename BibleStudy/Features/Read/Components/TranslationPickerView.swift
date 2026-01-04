import SwiftUI

// MARK: - Translation Picker View
// Sheet for quickly switching Bible translations

struct TranslationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let currentTranslationId: String
    let translations: [Translation]
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(translations) { translation in
                        TranslationRow(
                            translation: translation,
                            isSelected: translation.id == currentTranslationId
                        ) {
                            onSelect(translation.id)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle("Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Translation Row
struct TranslationRow: View {
    let translation: Translation
    let isSelected: Bool
    let action: () -> Void

    private var isDisabled: Bool { !translation.isAvailable }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Abbreviation badge
                Text(translation.abbreviation)
                    .font(Typography.UI.headline)
                    .foregroundStyle(badgeForegroundColor)
                    .frame(width: 56, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(badgeBackgroundColor)
                    )

                // Translation info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(translation.name)
                            .font(Typography.UI.body)
                            .foregroundStyle(isDisabled ? Color.tertiaryText : Color.primaryText)

                        // "Coming Soon" badge
                        if let status = translation.availabilityStatus {
                            Text(status)
                                .font(Typography.UI.caption2)
                                .foregroundStyle(Color.secondaryText)
                                .padding(.horizontal, AppTheme.Spacing.xs)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(Color.surfaceBackground)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.cardBorder, lineWidth: AppTheme.Border.hairline)
                                )
                        }
                    }

                    Text(translation.translationInfo)
                        .font(Typography.UI.caption1)
                        .foregroundStyle(isDisabled ? Color.tertiaryText : Color.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentGold)
                        .font(Typography.UI.title3)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? Color.selectedBackground : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? Color.accentGold : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var badgeForegroundColor: Color {
        if isDisabled {
            return Color.tertiaryText
        }
        return isSelected ? .white : Color.accentGold
    }

    private var badgeBackgroundColor: Color {
        if isDisabled {
            return Color.surfaceBackground
        }
        return isSelected ? Color.accentGold : Color.accentGold.opacity(AppTheme.Opacity.light)
    }
}

// MARK: - Preview
#Preview {
    TranslationPickerView(
        currentTranslationId: "kjv",
        translations: Translation.getAll()
    ) { translationId in
        print("Selected: \(translationId)")
    }
}
