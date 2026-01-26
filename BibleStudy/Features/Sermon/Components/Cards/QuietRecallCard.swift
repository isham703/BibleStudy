//
//  QuietRecallCard.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Retrieval practice interstitial between Read sections (1–5) and
//  Reflect sections (6–8) in the Study Guide. Prompts the user to
//  write the sermon's core message from memory before continuing.
//
//  Three states: collapsed (prompt + Begin), expanded (TextEditor),
//  saved (preview + Edit). Inline editing — no sheet — to keep the
//  user in scroll context.
//
//  Visual: Bronze accent bar family (matches ReflectBridgeCard).
//  Storage: .journalEntry with metadata {"kind":"recall"}.
//

import Auth
import SwiftUI

// MARK: - Quiet Recall Card

struct QuietRecallCard: View {
    let sermonId: UUID
    let isAwakened: Bool
    let delay: Double

    // MARK: - Card State

    private enum CardState {
        case collapsed
        case expanded
        case saved
    }

    @State private var cardState: CardState = .collapsed
    @State private var recallText: String = ""
    @State private var savedText: String = ""
    @State private var previousState: CardState = .collapsed
    @FocusState private var isEditorFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let engagementService = SermonEngagementService.shared
    private let maxCharacters = 1000

    // MARK: - Computed

    private var characterCount: Int { recallText.count }
    private var isOverLimit: Bool { characterCount > maxCharacters }
    private var canSave: Bool {
        !recallText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isOverLimit
    }

    private var targetId: String {
        SermonEngagement.fingerprint(
            sermonId: sermonId,
            type: .journalEntry,
            content: "quiet_recall_\(sermonId.uuidString)"
        )
    }

    private var promptText: String {
        let prompts = [
            "Before moving on, pause. What was the core message you just heard?",
            "Take a moment. In your own words, what is the main takeaway from this sermon?",
            "What would you say if a friend asked you what this sermon was about?",
        ]
        // Deterministic hash — hashValue is randomly seeded per process launch
        let hash = sermonId.uuidString.utf8.reduce(UInt(0)) { ($0 &* 31) &+ UInt($1) }
        let index = Int(hash % UInt(prompts.count))
        return prompts[index]
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Bronze accent bar
            Rectangle()
                .fill(Color("AccentBronze"))
                .frame(width: 2)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header
                Text("QUIET RECALL")
                    .font(Typography.Command.meta)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("AccentBronze"))

                switch cardState {
                case .collapsed:
                    collapsedContent
                case .expanded:
                    expandedContent
                case .saved:
                    savedContent
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
        )
        .ceremonialAppear(isAwakened: isAwakened, delay: delay)
        .onAppear { loadExistingRecallIfNeeded() }
        .onChange(of: engagementService.engagements) {
            loadExistingRecallIfNeeded()
        }
    }

    // MARK: - Collapsed Content

    private var collapsedContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Contemplative prompt
            Text(promptText)
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineSpacing(Typography.Scripture.quoteLineSpacing)
                .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

            // Begin button
            Button {
                HapticService.shared.lightTap()
                beginEditing()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "pencil.line")
                        .font(Typography.Icon.sm)
                    Text("Begin")
                        .font(Typography.Command.cta)
                }
                .foregroundStyle(Color("AccentBronze"))
                .frame(minHeight: Theme.Size.minTapTarget)
                .padding(.horizontal, Theme.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Color("AccentBronze"), lineWidth: Theme.Stroke.control)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Begin writing your recall")
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Prompt (stays visible while writing)
            Text(promptText)
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineSpacing(Typography.Scripture.quoteLineSpacing)
                .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

            // TextEditor
            TextEditor(text: $recallText)
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
                .accessibilityLabel("Your recall")
                .accessibilityValue(recallText.isEmpty ? "Empty" : "\(characterCount) of \(maxCharacters) characters")

            // Character count
            HStack {
                Spacer()
                Text("\(characterCount)/\(maxCharacters)")
                    .font(Typography.Command.meta)
                    .foregroundStyle(isOverLimit ? Color("FeedbackError") : Color("TertiaryText"))
            }

            // Action buttons
            HStack {
                Button("Cancel") {
                    cancelEditing()
                }
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))

                Spacer()

                Button("Save") {
                    saveRecall()
                }
                .font(Typography.Command.cta)
                .foregroundStyle(canSave ? Color("AppAccentAction") : Color("TertiaryText"))
                .disabled(!canSave)
            }
        }
    }

    // MARK: - Saved Content

    private var savedContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Saved indicator
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.circle")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AccentBronze"))

                Text("Saved to My Journal")
                    .font(Typography.Command.label)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            // Preview of saved text
            Text(savedText)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(3)
                .lineSpacing(Typography.Command.bodyLineSpacing)
                .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)

            // Edit link
            HStack {
                Spacer()
                Button("Edit") {
                    HapticService.shared.lightTap()
                    beginEditing()
                }
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AccentBronze"))
                .accessibilityLabel("Edit your recall")
            }
        }
    }

    // MARK: - Actions

    private func loadExistingRecallIfNeeded() {
        guard cardState != .expanded else { return }
        if let existing = engagementService.journalEntry(targetId: targetId),
           let content = existing.content, !content.isEmpty {
            savedText = content
            cardState = .saved
        }
    }

    private func beginEditing() {
        previousState = cardState
        if cardState == .saved {
            recallText = savedText
        }
        withAnimation(reduceMotion ? nil : Theme.Animation.settle) {
            cardState = .expanded
        }
        isEditorFocused = true
    }

    private func cancelEditing() {
        isEditorFocused = false
        recallText = ""
        withAnimation(reduceMotion ? nil : Theme.Animation.settle) {
            cardState = previousState
        }
    }

    private func saveRecall() {
        let trimmed = recallText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isEditorFocused = false

        Task {
            guard let userId = SupabaseManager.shared.currentUser?.id else {
                ToastService.shared.showInfo(message: "Sign in to save journal entries")
                return
            }
            await engagementService.saveJournalEntry(
                userId: userId,
                sermonId: sermonId,
                targetId: targetId,
                content: trimmed,
                metadata: "{\"kind\":\"recall\"}"
            )
            savedText = trimmed
            recallText = ""
            withAnimation(reduceMotion ? nil : Theme.Animation.settle) {
                cardState = .saved
            }
            HapticService.shared.success()
            ToastService.shared.showSuccess(message: "Saved. Added to My Journal.")
        }
    }
}

// MARK: - Preview

#Preview("Quiet Recall Card — Collapsed") {
    ScrollView {
        QuietRecallCard(
            sermonId: UUID(),
            isAwakened: true,
            delay: 0
        )
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
    .preferredColorScheme(.dark)
}
