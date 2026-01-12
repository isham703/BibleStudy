import SwiftUI

// MARK: - Sleep Timer Picker View
// Presents sleep timer options in a sheet

struct SleepTimerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let audioService: AudioService

    private let timerOptions: [(label: String, minutes: Int)] = [
        ("15 minutes", 15),
        ("30 minutes", 30),
        ("45 minutes", 45),
        ("1 hour", 60),
        ("2 hours", 120)
    ]

    var body: some View {
        NavigationStack {
            List {
                // Timer options
                Section {
                    ForEach(timerOptions, id: \.minutes) { option in
                        Button(action: {
                            HapticService.shared.lightTap()
                            audioService.setSleepTimer(minutes: option.minutes)
                            dismiss()
                        }) {
                            HStack {
                                Text(option.label)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Spacer()

                                if isSelected(minutes: option.minutes) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("AppAccentAction"))
                                        .font(Typography.Command.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .accessibilityLabel(option.label)
                        .accessibilityAddTraits(isSelected(minutes: option.minutes) ? .isSelected : [])
                    }

                    // End of chapter option
                    Button(action: {
                        HapticService.shared.lightTap()
                        audioService.setSleepTimerEndOfChapter()
                        dismiss()
                    }) {
                        HStack {
                            Text("End of chapter")
                                .foregroundStyle(Color("AppTextPrimary"))

                            Spacer()

                            if audioService.sleepTimerEndOfChapter {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color("AppAccentAction"))
                                    .font(Typography.Command.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .accessibilityLabel("End of chapter")
                    .accessibilityHint("Stop playback when the chapter ends")
                    .accessibilityAddTraits(audioService.sleepTimerEndOfChapter ? .isSelected : [])
                } header: {
                    Text("Stop playing after")
                }

                // Cancel option (if timer is active)
                if audioService.isSleepTimerActive {
                    Section {
                        Button(action: {
                            HapticService.shared.lightTap()
                            audioService.cancelSleepTimer()
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Cancel Timer")
                                    .foregroundStyle(Color("FeedbackError"))
                                Spacer()
                            }
                        }
                        .accessibilityLabel("Cancel sleep timer")
                    } footer: {
                        if !audioService.sleepTimerEndOfChapter && audioService.sleepTimerRemaining > 0 {
                            Text("Time remaining: \(audioService.formattedSleepTimerRemaining)")
                                .font(Typography.Command.caption.monospacedDigit())
                                .accessibilityAddTraits(.updatesFrequently)
                        }
                    }
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close sleep timer picker")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func isSelected(minutes: Int) -> Bool {
        guard !audioService.sleepTimerEndOfChapter else { return false }
        let selectedMinutes = Int(audioService.sleepTimerRemaining / 60)
        // Check if we're within 1 minute of the original selection (timer may have counted down)
        return audioService.isSleepTimerActive && abs(selectedMinutes - minutes) < 1
    }
}

// MARK: - Preview

#Preview {
    SleepTimerPickerView(audioService: AudioService.shared)
}
