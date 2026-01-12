import SwiftUI

// MARK: - Audio Verse Picker Sheet
// Scrollable list of verses for quick navigation during audio playback

struct AudioVersePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
                            .foregroundStyle(Color("AppTextSecondary"))
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
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                // Verse number badge
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color("AppAccentAction") : Color("AppSurface"))
                        .frame(width: 32, height: 32)

                    Text("\(verse.number)")
                        .font(Typography.Command.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isPlaying ? .white : Color("AppTextSecondary"))
                }

                // Verse preview text
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(verse.text)
                        .font(Typography.Command.body)
                        .foregroundStyle(isPlaying ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if isPlaying {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(Typography.Command.meta)
                            Text("Now playing")
                                .font(Typography.Command.meta)
                        }
                        .foregroundStyle(Color("AppAccentAction"))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Play indicator
                if isPlaying {
                    Image(systemName: "waveform")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(Color("AppAccentAction"))
                        .symbolEffect(.variableColor.iterative)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isPlaying ? Color("AppAccentAction").opacity(Theme.Opacity.subtle) : Color.clear)
        .accessibilityLabel("Verse \(verse.number)")
        .accessibilityHint(isPlaying ? "Currently playing. Double tap to restart from beginning of verse" : "Double tap to play from this verse")
        .accessibilityAddTraits(isPlaying ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    AudioVersePickerSheet(audioService: AudioService.shared)
}
