//
//  QuickCaptureSheet.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Quick capture sheet for adding notes/bookmarks to a sermon.
//  Auto-fills current playback timestamp. Triggered from floating bar.
//

import SwiftUI

// MARK: - Quick Capture Sheet

struct QuickCaptureSheet: View {
    let sermonId: UUID
    let currentTime: TimeInterval?
    let onSave: (BookmarkLabel, String?, TimeInterval) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedLabel: BookmarkLabel = .keyPoint
    @State private var noteText: String = ""
    @FocusState private var isNoteFocused: Bool

    private var effectiveTimestamp: TimeInterval {
        currentTime ?? 0
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Timestamp display
                timestampRow

                // Label selection
                labelSelectionRow

                // Note input
                noteInput

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .background(Color("AppBackground"))
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Timestamp Row

    private var timestampRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "clock")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("TertiaryText"))

            if let time = currentTime, time > 0 {
                Text("at \(formatTimestamp(time))")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                Text("No timestamp")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("TertiaryText"))
            }
        }
    }

    // MARK: - Label Selection

    private var labelSelectionRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("TYPE")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.sm),
                    GridItem(.flexible(), spacing: Theme.Spacing.sm)
                ],
                spacing: Theme.Spacing.sm
            ) {
                ForEach(BookmarkLabel.allCases, id: \.self) { label in
                    LabelChip(
                        label: label,
                        isSelected: selectedLabel == label,
                        onTap: {
                            HapticService.shared.lightTap()
                            selectedLabel = label
                        }
                    )
                }
            }
        }
    }

    // MARK: - Note Input

    private var noteInput: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("NOTE")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            TextField("What did this sermon confront in you?", text: $noteText, axis: .vertical)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1...3)
                .focused($isNoteFocused)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color("AppSurface"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                )

            Text("One sentence is enough.")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
        }
    }

    // MARK: - Actions

    private func saveNote() {
        let note = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(selectedLabel, note.isEmpty ? nil : note, effectiveTimestamp)
        HapticService.shared.selectionChanged()
        dismiss()
    }

    private func formatTimestamp(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Label Chip

private struct LabelChip: View {
    let label: BookmarkLabel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: label.icon)
                    .font(.system(size: 12))

                Text(label.displayName)
                    .font(Typography.Command.label)
            }
            .foregroundStyle(isSelected ? .white : Color("AppTextSecondary"))
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(
                Capsule()
                    .fill(isSelected ? Color("AppAccentAction") : Color("AppSurface"))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.clear : Color("AppDivider"),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label.displayName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

// MARK: - Preview

#Preview("Quick Capture Sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            QuickCaptureSheet(
                sermonId: UUID(),
                currentTime: 154.0,
                onSave: { label, note, time in
                    print("Saved: \(label.displayName), note: \(note ?? "none"), at \(time)")
                }
            )
        }
}
