//
//  JournalEntrySheet.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Journal entry sheet for responding to discussion questions.
//  Presents the question in italic serif, a TextEditor for response,
//  character count (1000 max), and Save button.
//

import SwiftUI

// MARK: - Journal Entry Sheet

struct JournalEntrySheet: View {
    let question: StudyQuestion
    let sermonId: UUID
    let existingContent: String?
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var isEditorFocused: Bool

    private let maxCharacters = 1000

    private var characterCount: Int { text.count }
    private var isOverLimit: Bool { characterCount > maxCharacters }
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isOverLimit }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Question display
                questionView

                // Text editor
                editorView

                // Character count
                characterCountView

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .background(Color("AppBackground"))
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmed)
                        HapticService.shared.selectionChanged()
                        dismiss()
                    }
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(canSave ? Color("AppAccentAction") : Color("TertiaryText"))
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            text = existingContent ?? ""
            isEditorFocused = true
        }
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("QUESTION")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))
                .accessibilityHidden(true)

            Text(question.question)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .italic()
                .lineSpacing(Typography.Scripture.bodyLineSpacing)
                .accessibilityLabel("Question: \(question.question)")
        }
    }

    // MARK: - Editor View

    private var editorView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("YOUR RESPONSE")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundStyle(Color("TertiaryText"))

            TextEditor(text: $text)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .scrollContentBackground(.hidden)
                .focused($isEditorFocused)
                .frame(minHeight: 120, maxHeight: 240)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color("AppSurface"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .stroke(
                            isOverLimit ? Color("FeedbackError") : Color("AppDivider"),
                            lineWidth: Theme.Stroke.hairline
                        )
                )
                .accessibilityLabel("Your response")
                .accessibilityValue(text.isEmpty ? "Empty" : "\(characterCount) of \(maxCharacters) characters")
        }
    }

    // MARK: - Character Count

    private var characterCountView: some View {
        HStack {
            Spacer()

            Text("\(characterCount)/\(maxCharacters)")
                .font(Typography.Command.meta)
                .foregroundStyle(isOverLimit ? Color("FeedbackError") : Color("TertiaryText"))
        }
    }
}

// MARK: - Preview

#Preview("Journal Entry Sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            JournalEntrySheet(
                question: StudyQuestion(
                    question: "How does understanding grace change your relationship with God?",
                    type: .application
                ),
                sermonId: UUID(),
                existingContent: nil,
                onSave: { text in
                    print("Saved: \(text)")
                }
            )
        }
}

#Preview("Journal Entry - Existing") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            JournalEntrySheet(
                question: StudyQuestion(
                    question: "How does understanding grace change your relationship with God?",
                    type: .application
                ),
                sermonId: UUID(),
                existingContent: "Grace has transformed how I approach God in prayer. Instead of feeling like I need to earn His attention, I come freely knowing I'm already accepted.",
                onSave: { text in
                    print("Updated: \(text)")
                }
            )
        }
}
