//
//  ThemeEditorSheet.swift
//  BibleStudy
//
//  Sheet for editing theme assignments on a sermon.
//  Shows assigned themes with source info and allows add/remove.
//

import Combine
import SwiftUI

// MARK: - Theme Editor Sheet

struct ThemeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sermonId: UUID
    let sermonTitle: String

    @StateObject private var viewModel: ThemeEditorViewModel

    init(sermonId: UUID, sermonTitle: String) {
        self.sermonId = sermonId
        self.sermonTitle = sermonTitle
        _viewModel = StateObject(wrappedValue: ThemeEditorViewModel(sermonId: sermonId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sermonTitle)
                            .font(.headline)
                            .foregroundStyle(Color("PrimaryText"))

                        Text("Max 5 themes per sermon")
                            .font(.caption)
                            .foregroundStyle(Color("TertiaryText"))
                    }
                    .padding(.horizontal)

                    // Assigned Themes Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Assigned Themes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color("SecondaryText"))
                                .textCase(.uppercase)

                            Text("(\(viewModel.assignedThemes.count))")
                                .font(.subheadline)
                                .foregroundStyle(Color("TertiaryText"))

                            Spacer()
                        }

                        if viewModel.assignedThemes.isEmpty {
                            Text("No themes assigned yet")
                                .font(.subheadline)
                                .foregroundStyle(Color("TertiaryText"))
                                .italic()
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.assignedThemes) { assignment in
                                    ThemeChipRow(assignment: assignment) {
                                        viewModel.removeTheme(assignment)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Add Theme Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Theme")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color("SecondaryText"))
                            .textCase(.uppercase)

                        if viewModel.canAddMore {
                            CategorizedThemePicker(
                                selectedThemes: $viewModel.pendingThemes,
                                assignedThemes: viewModel.assignedThemeSet,
                                maxThemes: viewModel.remainingSlots
                            )
                        } else {
                            Text("Maximum themes reached")
                                .font(.subheadline)
                                .foregroundStyle(Color("TertiaryText"))
                                .italic()
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(Color("AppBackground"))
            .navigationTitle("Edit Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!viewModel.hasChanges)
                }
            }
        }
    }
}

// MARK: - Theme Editor View Model

@MainActor
final class ThemeEditorViewModel: ObservableObject {
    let sermonId: UUID

    @Published var assignedThemes: [SermonThemeAssignment] = []
    @Published var pendingThemes: Set<NormalizedTheme> = []
    @Published var removedThemes: Set<NormalizedTheme> = []

    private let themeService = ThemeNormalizationService.shared
    private let repository = SermonRepository.shared

    private var originalThemes: Set<NormalizedTheme> = []

    init(sermonId: UUID) {
        self.sermonId = sermonId
        loadAssignments()
    }

    // MARK: - Computed Properties

    var assignedThemeSet: Set<NormalizedTheme> {
        Set(assignedThemes.compactMap { $0.normalizedTheme })
    }

    var canAddMore: Bool {
        assignedThemes.count + pendingThemes.count < 5
    }

    var remainingSlots: Int {
        max(0, 5 - assignedThemes.count)
    }

    var hasChanges: Bool {
        !pendingThemes.isEmpty || !removedThemes.isEmpty
    }

    // MARK: - Actions

    func loadAssignments() {
        assignedThemes = themeService.themeAssignments(for: sermonId)
        originalThemes = assignedThemeSet
    }

    func removeTheme(_ assignment: SermonThemeAssignment) {
        if let theme = assignment.normalizedTheme {
            removedThemes.insert(theme)
            assignedThemes.removeAll { $0.theme == assignment.theme }
        }
    }

    func save() {
        // Remove themes
        for theme in removedThemes {
            themeService.removeUserTheme(theme, from: sermonId)
        }

        // Add pending themes
        for theme in pendingThemes {
            themeService.addUserTheme(theme, to: sermonId)
        }
    }
}

#Preview {
    ThemeEditorSheet(
        sermonId: UUID(),
        sermonTitle: "The Good Samaritan"
    )
}
