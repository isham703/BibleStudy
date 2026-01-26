//
//  SermonSearchBar.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Search bar for filtering sermon notes content.
//  Follows NotesLibraryView search bar pattern.
//

import SwiftUI

// MARK: - Sermon Search Bar

struct SermonSearchBar: View {
    @Binding var searchQuery: String
    var matchCount: Int? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("TertiaryText"))

            TextField("Search notes...", text: $searchQuery)
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if let count = matchCount, !searchQuery.isEmpty {
                Text("\(count) section\(count == 1 ? "" : "s")")
                    .font(Typography.Command.meta)
                    .foregroundStyle(count > 0 ? Color("AccentBronze") : Color("FeedbackWarning"))
                    .transition(.opacity)
            }

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .animation(Theme.Animation.fade, value: matchCount)
    }
}

// MARK: - Preview

#Preview("Sermon Search Bar") {
    VStack(spacing: Theme.Spacing.lg) {
        SermonSearchBar(searchQuery: .constant(""))
        SermonSearchBar(searchQuery: .constant("grace"))
    }
    .padding(.horizontal, Theme.Spacing.lg)
    .background(Color("AppBackground"))
}
