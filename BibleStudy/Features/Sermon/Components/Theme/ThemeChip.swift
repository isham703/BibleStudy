//
//  ThemeChip.swift
//  BibleStudy
//
//  Display component for a theme with optional confidence indicator.
//  Used in sermon detail views and theme editor.
//

import SwiftUI

// MARK: - Theme Chip

struct ThemeChip: View {
    let theme: NormalizedTheme
    let confidence: Double?
    let sourceTheme: String?
    let isUserAdded: Bool
    let showConfidence: Bool
    let onRemove: (() -> Void)?

    init(
        theme: NormalizedTheme,
        confidence: Double? = nil,
        sourceTheme: String? = nil,
        isUserAdded: Bool = false,
        showConfidence: Bool = false,
        onRemove: (() -> Void)? = nil
    ) {
        self.theme = theme
        self.confidence = confidence
        self.sourceTheme = sourceTheme
        self.isUserAdded = isUserAdded
        self.showConfidence = showConfidence
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: theme.icon)
                .font(.caption)
                .foregroundStyle(Color("AccentBronze"))

            Text(theme.displayName)
                .font(.subheadline)
                .foregroundStyle(Color("PrimaryText"))

            if isUserAdded {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(Color("SecondaryText"))
            }

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("AppSurface"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("Border"), lineWidth: 1)
                )
        )
    }
}

// MARK: - Theme Chip Row

/// A row displaying theme with source and confidence info
struct ThemeChipRow: View {
    let assignment: SermonThemeAssignment
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let theme = assignment.normalizedTheme {
                    ThemeChip(
                        theme: theme,
                        confidence: assignment.confidence,
                        sourceTheme: assignment.primarySourceTheme,
                        isUserAdded: assignment.overrideState == .userAdded,
                        onRemove: onRemove
                    )
                }

                Spacer()
            }

            // Source theme info
            if let sourceTheme = assignment.primarySourceTheme {
                HStack(spacing: 4) {
                    Text("From:")
                        .font(.caption2)
                        .foregroundStyle(Color("TertiaryText"))

                    Text("\"\(sourceTheme)\"")
                        .font(.caption2)
                        .foregroundStyle(Color("SecondaryText"))
                        .italic()
                }
                .padding(.leading, 4)
            }

            // Confidence indicator
            if assignment.overrideState == .auto {
                ConfidenceIndicator(confidence: assignment.confidence)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
    let confidence: Double

    private var filledDots: Int {
        Int(confidence * 5)
    }

    private var label: String {
        if confidence >= 0.95 {
            return "Exact match"
        } else if confidence >= 0.8 {
            return "High confidence"
        } else if confidence >= 0.6 {
            return "Medium confidence"
        } else {
            return "Low confidence"
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < filledDots ? Color("AccentBronze") : Color("Border"))
                    .frame(width: 4, height: 4)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("TertiaryText"))
                .padding(.leading, 4)
        }
    }
}

// MARK: - Selectable Theme Chip

/// Theme chip that can be selected/deselected
struct SelectableThemeChip: View {
    let theme: NormalizedTheme
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color("AccentBronze") : Color("SecondaryText"))

                Text(theme.displayName)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? Color("PrimaryText") : Color("SecondaryText"))

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color("AccentBronze"))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color("AccentBronze").opacity(0.1) : Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color("AccentBronze") : Color("Border"), lineWidth: 1)
                    )
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        ThemeChip(theme: .salvation)

        ThemeChip(
            theme: .faith,
            confidence: 0.85,
            sourceTheme: "Walking in Faith",
            onRemove: {}
        )

        ThemeChip(
            theme: .sovereignty,
            isUserAdded: true,
            onRemove: {}
        )

        ConfidenceIndicator(confidence: 0.95)
        ConfidenceIndicator(confidence: 0.75)
        ConfidenceIndicator(confidence: 0.5)

        HStack {
            SelectableThemeChip(theme: .grace, isSelected: true, isDisabled: false, onTap: {})
            SelectableThemeChip(theme: .love, isSelected: false, isDisabled: false, onTap: {})
            SelectableThemeChip(theme: .prayer, isSelected: false, isDisabled: true, onTap: {})
        }
    }
    .padding()
    .background(Color("AppBackground"))
}
