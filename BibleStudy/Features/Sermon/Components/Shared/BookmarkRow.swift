//
//  BookmarkRow.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Displays a single sermon bookmark with label icon, timestamp chip,
//  and optional note text. Extracted for shared use across
//  Study Guide and Journal views.
//

import SwiftUI

// MARK: - Bookmark Row

struct BookmarkRow: View {
    let bookmark: SermonBookmark
    let onSeek: (TimeInterval) -> Void

    private var labelColor: Color {
        switch bookmark.label {
        case .keyPoint: return Color("AccentBronze")
        case .question: return Color("FeedbackInfo")
        case .highlight: return Color("FeedbackWarning")
        case .note: return Color("TertiaryText")
        case .none: return Color("TertiaryText")
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Label icon
            Image(systemName: bookmark.label?.icon ?? "bookmark")
                .font(Typography.Icon.sm)
                .foregroundStyle(labelColor)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(bookmark.displayLabel)
                        .font(Typography.Command.label)
                        .foregroundStyle(labelColor)

                    Spacer()

                    TimestampChip(timestamp: bookmark.timestampSeconds) {
                        onSeek(bookmark.timestampSeconds)
                    }
                }

                if let note = bookmark.note, !note.isEmpty {
                    Text(note)
                        .font(Typography.Command.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineSpacing(Typography.Command.bodyLineSpacing)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color("AppSurface"))
        )
    }
}
