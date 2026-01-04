//
//  ReadingMenuSheet.swift
//  BibleStudy
//
//  Apple Books-style compact reading menu
//  Ordered by frequency of use (Fitts' Law + Hick's Law)
//

import SwiftUI

// MARK: - Reading Menu Sheet

/// Compact bottom sheet with reading controls
/// Items ordered by frequency: Contents, Search, Translation, Settings, Audio, Share
struct ReadingMenuSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Current reading state
    let bookName: String
    let chapterNumber: Int
    let currentVerse: Int
    let totalVerses: Int
    let currentTranslation: String

    // Audio state
    let isAudioPlaying: Bool

    // Actions
    let onContentsTap: () -> Void
    let onSearchTap: () -> Void
    let onTranslationTap: () -> Void
    let onSettingsTap: () -> Void
    let onAudioTap: () -> Void
    let onShareTap: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // Contents - Most frequent: navigation
                ReadingMenuItem(
                    icon: "book",
                    iconColor: .accentGold,
                    title: "Contents",
                    subtitle: "\(bookName) \(chapterNumber) • v.\(currentVerse) of \(totalVerses)",
                    showChevron: true,
                    useMonospacedDigits: true
                ) {
                    dismiss()
                    onContentsTap()
                }

                // Search - High frequency: lookup
                ReadingMenuItem(
                    icon: "magnifyingglass",
                    iconColor: .primaryText,
                    title: "Search",
                    subtitle: nil,
                    showChevron: false
                ) {
                    dismiss()
                    onSearchTap()
                }

                // Translation - High for scripture users
                ReadingMenuItem(
                    icon: "character.book.closed",
                    iconColor: .accentBlue,
                    title: "Translation",
                    subtitle: currentTranslation,
                    showChevron: true
                ) {
                    dismiss()
                    onTranslationTap()
                }

                // Themes & Settings - Medium: appearance
                ReadingMenuItem(
                    icon: "paintpalette",
                    iconColor: .accentRose,
                    title: "Themes & Settings",
                    subtitle: nil,
                    showChevron: true
                ) {
                    dismiss()
                    onSettingsTap()
                }

                // Audio - Medium: listen
                ReadingMenuItem(
                    icon: isAudioPlaying ? "speaker.wave.2.fill" : "speaker.wave.2",
                    iconColor: isAudioPlaying ? .accentGold : .primaryText,
                    title: isAudioPlaying ? "Pause Audio" : "Play Audio",
                    subtitle: nil,
                    showChevron: false
                ) {
                    dismiss()
                    onAudioTap()
                }

                // Share Chapter - Low: share whole chapter
                ReadingMenuItem(
                    icon: "square.and.arrow.up",
                    iconColor: .primaryText,
                    title: "Share Chapter",
                    subtitle: nil,
                    showChevron: false
                ) {
                    dismiss()
                    onShareTap()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reading Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
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

// MARK: - Reading Menu Item

struct ReadingMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showChevron: Bool
    var useMonospacedDigits: Bool = false
    let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22

    var body: some View {
        Button(action: {
            HapticService.shared.lightTap()
            action()
        }) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(Typography.UI.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 28, alignment: .center)

                // Title and subtitle
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(title)
                        .font(Typography.UI.body)
                        .foregroundStyle(Color.primaryText)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(useMonospacedDigits ? Typography.UI.caption1.monospacedDigit() : Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                Spacer()

                // Chevron for items that open sub-sheets
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)\(subtitle.map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Reading Menu Sheet") {
    Color.appBackground
        .sheet(isPresented: .constant(true)) {
            ReadingMenuSheet(
                bookName: "Genesis",
                chapterNumber: 1,
                currentVerse: 15,
                totalVerses: 31,
                currentTranslation: "KJV",
                isAudioPlaying: false,
                onContentsTap: {},
                onSearchTap: {},
                onTranslationTap: {},
                onSettingsTap: {},
                onAudioTap: {},
                onShareTap: {}
            )
        }
}

#Preview("Reading Menu - Audio Playing") {
    Color.appBackground
        .sheet(isPresented: .constant(true)) {
            ReadingMenuSheet(
                bookName: "Psalm",
                chapterNumber: 23,
                currentVerse: 1,
                totalVerses: 6,
                currentTranslation: "ESV",
                isAudioPlaying: true,
                onContentsTap: {},
                onSearchTap: {},
                onTranslationTap: {},
                onSettingsTap: {},
                onAudioTap: {},
                onShareTap: {}
            )
        }
}
