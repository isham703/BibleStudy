//
//  SermonGroupSelector.swift
//  BibleStudy
//
//  Group and sort selection sheet for sermon library
//  V2.1: Deterministic groups (Date, Book, Speaker)
//

import SwiftUI

// MARK: - Sermon Group Selector

struct SermonGroupSelector: View {
    @Binding var selectedGroup: SermonGroupOption
    @Binding var selectedSort: SermonSortOption
    let groupCounts: [SermonGroupOption: Int]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Group By Section
                Section {
                    ForEach(SermonGroupOption.allCases) { option in
                        groupRow(option)
                    }
                } header: {
                    Text("GROUP BY")
                        .font(Typography.Editorial.sectionHeader)
                        .tracking(Typography.Editorial.sectionTracking)
                        .foregroundStyle(Color("TertiaryText"))
                }

                // Sort By Section
                Section {
                    ForEach(SermonSortOption.allCases) { option in
                        sortRow(option)
                    }
                } header: {
                    Text("SORT BY")
                        .font(Typography.Editorial.sectionHeader)
                        .tracking(Typography.Editorial.sectionTracking)
                        .foregroundStyle(Color("TertiaryText"))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Organize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color("AccentBronze"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Group Row

    private func groupRow(_ option: SermonGroupOption) -> some View {
        Button {
            withAnimation(Theme.Animation.settle) {
                selectedGroup = option
                option.save()
            }
            HapticService.shared.selectionChanged()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: option.icon)
                    .font(Typography.Icon.base)
                    .foregroundStyle(
                        selectedGroup == option
                            ? Color("AccentBronze")
                            : Color("TertiaryText")
                    )
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(option.rawValue)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Text(option.description)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                Spacer()

                // Group count badge
                if option != .none, let count = groupCounts[option], count > 0 {
                    Text("\(count)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(Color("TertiaryText"))
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color("AppSurface"))
                        )
                }

                // Selection indicator
                if selectedGroup == option {
                    Image(systemName: "checkmark")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("AccentBronze"))
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .listRowBackground(Color("AppSurface"))
    }

    // MARK: - Sort Row

    private func sortRow(_ option: SermonSortOption) -> some View {
        Button {
            withAnimation(Theme.Animation.settle) {
                selectedSort = option
                option.save()
            }
            HapticService.shared.selectionChanged()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: option.icon)
                    .font(Typography.Icon.base)
                    .foregroundStyle(
                        selectedSort == option
                            ? Color("AccentBronze")
                            : Color("TertiaryText")
                    )
                    .frame(width: 28)

                Text(option.rawValue)
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextPrimary"))

                Spacer()

                // Selection indicator
                if selectedSort == option {
                    Image(systemName: "checkmark")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("AccentBronze"))
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .listRowBackground(Color("AppSurface"))
    }
}

// MARK: - Group Selector Button

/// Compact button to trigger the group selector sheet
struct SermonGroupButton: View {
    let currentGroup: SermonGroupOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: currentGroup.icon)
                    .font(Typography.Icon.xs)

                if currentGroup != .none {
                    Text(currentGroup.rawValue)
                        .font(Typography.Command.caption)
                }

                Image(systemName: "chevron.down")
                    .font(Typography.Icon.xxs)
            }
            .foregroundStyle(Color("AccentBronze"))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Group Selector") {
    SermonGroupSelector(
        selectedGroup: .constant(.date),
        selectedSort: .constant(.newest),
        groupCounts: [
            .date: 5,
            .book: 12,
            .speaker: 3
        ]
    )
}

#Preview("Group Button") {
    VStack(spacing: Theme.Spacing.lg) {
        SermonGroupButton(currentGroup: .none) {}
        SermonGroupButton(currentGroup: .date) {}
        SermonGroupButton(currentGroup: .book) {}
        SermonGroupButton(currentGroup: .speaker) {}
    }
    .padding()
    .background(Color("AppBackground"))
}
