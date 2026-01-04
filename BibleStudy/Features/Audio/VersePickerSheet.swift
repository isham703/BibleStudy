import SwiftUI

// MARK: - Audio Verse Picker Sheet
// Scrollable list of verses for quick navigation during audio playback

struct AudioVersePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let audioService: AudioService

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    if let chapter = audioService.currentChapter {
                        ForEach(chapter.verses, id: \.number) { verse in
                            VerseRow(
                                verse: verse,
                                isPlaying: audioService.currentVerse == verse.number,
                                onTap: {
                                    HapticService.shared.lightTap()
                                    audioService.seekToVerse(verse.number)
                                    dismiss()
                                }
                            )
                            .id(verse.number)
                        }
                    } else {
                        Text("No chapter loaded")
                            .foregroundStyle(Color.secondaryText)
                    }
                }
                .listStyle(.plain)
                .onAppear {
                    // Scroll to current verse
                    if let currentVerse = audioService.currentVerse {
                        withAnimation {
                            proxy.scrollTo(currentVerse, anchor: .center)
                        }
                    }
                }
            }
            .navigationTitle("Verses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let chapter = audioService.currentChapter {
                        Text("\(chapter.bookName) \(chapter.chapterNumber)")
                            .font(Typography.UI.caption1)
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close verse picker")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Verse Row

private struct VerseRow: View {
    let verse: AudioVerse
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                // Verse number badge
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.Semantic.accent : Color.surfaceBackground)
                        .frame(width: 32, height: 32)

                    Text("\(verse.number)")
                        .font(Typography.UI.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(isPlaying ? .white : Color.secondaryText)
                }

                // Verse preview text
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(verse.text)
                        .font(Typography.UI.body)
                        .foregroundStyle(isPlaying ? Color.primaryText : Color.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if isPlaying {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(Typography.UI.caption2)
                            Text("Now playing")
                                .font(Typography.UI.caption2)
                        }
                        .foregroundStyle(Color.Semantic.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Play indicator
                if isPlaying {
                    Image(systemName: "waveform")
                        .font(Typography.UI.subheadline)
                        .foregroundStyle(Color.Semantic.accent)
                        .symbolEffect(.variableColor.iterative)
                }
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isPlaying ? Color.Semantic.accent.opacity(AppTheme.Opacity.subtle) : Color.clear)
        .accessibilityLabel("Verse \(verse.number)")
        .accessibilityHint(isPlaying ? "Currently playing. Double tap to restart from beginning of verse" : "Double tap to play from this verse")
        .accessibilityAddTraits(isPlaying ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    AudioVersePickerSheet(audioService: AudioService.shared)
}
