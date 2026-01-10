import SwiftUI

// MARK: - Minimal Input Card
// Clean, elevated card for prayer input

struct MinimalInputCard: View {
    @Binding var text: String
    var placeholder: String = "What's on your heart?"

    @FocusState private var isFocused: Bool
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            Text(placeholder)
                .font(Typography.Scripture.prompt.weight(.medium))
                .foregroundStyle(DeepPrayerColors.primaryText)

            // Hint text
            Text("Describe your situation, and I'll craft a prayer.")
                .font(Typography.Command.caption)
                .foregroundStyle(DeepPrayerColors.tertiaryText)

            // Text input
            TextEditor(text: $text)
                .font(Typography.Scripture.footnote)
                .foregroundStyle(DeepPrayerColors.primaryText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100, maxHeight: 140)
                .focused($isFocused)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("e.g., \"I'm anxious about my son who has drifted away...\"")
                            .font(Typography.Scripture.footnote)
                            .foregroundStyle(DeepPrayerColors.placeholderText)
                            .italic()
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(DeepPrayerColors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(
                    isFocused
                        ? DeepPrayerColors.roseBorder
                        : DeepPrayerColors.surfaceBorder,
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Minimal Input Card") {
    ZStack {
        DeepPrayerColors.sacredNavy.ignoresSafeArea()

        VStack(spacing: 20) {
            MinimalInputCard(
                text: .constant(""),
                placeholder: "What's on your heart?"
            )

            MinimalInputCard(
                text: .constant("I'm worried about my relationship with my brother. We haven't spoken in months."),
                placeholder: "What's on your heart?"
            )
        }
        .padding()
    }
}
