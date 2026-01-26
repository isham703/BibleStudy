//
//  SermonFilterBar.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Horizontal filter chips for sermon notes section filtering.
//  Includes Quick Recap toggle at trailing edge.
//
//  When recap mode is active, filter chips are dimmed.
//  Search operates independently of both filter and recap.
//

import SwiftUI

// MARK: - Sermon Filter Bar

struct SermonFilterBar: View {
    @Binding var selectedFilter: SermonSectionFilter
    @Binding var isQuickRecapMode: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // Section filter chips
                ForEach(SermonSectionFilter.allCases) { filter in
                    SermonFilterChip(
                        label: filter.displayLabel,
                        isSelected: selectedFilter == filter,
                        isDisabled: isQuickRecapMode
                    ) {
                        withAnimation(Theme.Animation.fade) {
                            selectedFilter = filter
                        }
                        HapticService.shared.selectionChanged()
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color("AppDivider"))
                    .frame(width: Theme.Stroke.hairline, height: 20)
                    .padding(.horizontal, Theme.Spacing.xxs)

                // Quick Recap toggle
                recapToggle
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    // MARK: - Recap Toggle

    private var recapToggle: some View {
        Button {
            withAnimation(Theme.Animation.settle) {
                isQuickRecapMode.toggle()
                if isQuickRecapMode {
                    selectedFilter = .all
                }
            }
            HapticService.shared.selectionChanged()
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "sparkles")
                    .font(Typography.Icon.xxs)

                Text("Recap")
                    .font(Typography.Command.caption)
            }
            .foregroundStyle(isQuickRecapMode ? .white : Color("AppAccentAction"))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(
                Capsule()
                    .fill(isQuickRecapMode ? Color("AppAccentAction") : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isQuickRecapMode ? Color("AppAccentAction") : Color("AppDivider"),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick Recap")
        .accessibilityHint(isQuickRecapMode ? "Double tap to show all sections" : "Double tap to show condensed summary")
        .accessibilityAddTraits(isQuickRecapMode ? [.isSelected] : [])
    }
}

// MARK: - Sermon Filter Chip

private struct SermonFilterChip: View {
    let label: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.Command.caption)
                .foregroundStyle(chipForeground)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .frame(minHeight: Theme.Size.minTapTarget)
                .background(
                    Capsule()
                        .fill(chipBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(chipBorder, lineWidth: Theme.Stroke.hairline)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? Theme.Opacity.disabled : 1)
        .accessibilityLabel("\(label) filter")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var chipForeground: Color {
        isSelected ? .white : Color("AppTextSecondary")
    }

    private var chipBackground: Color {
        isSelected ? Color("AppAccentAction") : Color("AppSurface")
    }

    private var chipBorder: Color {
        isSelected ? Color("AppAccentAction") : Color("AppDivider")
    }
}

// MARK: - Preview

#Preview("Sermon Filter Bar") {
    VStack(spacing: Theme.Spacing.lg) {
        SermonFilterBar(
            selectedFilter: .constant(.all),
            isQuickRecapMode: .constant(false)
        )

        SermonFilterBar(
            selectedFilter: .constant(.quotes),
            isQuickRecapMode: .constant(false)
        )

        SermonFilterBar(
            selectedFilter: .constant(.all),
            isQuickRecapMode: .constant(true)
        )
    }
    .background(Color("AppBackground"))
}
