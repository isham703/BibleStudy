import SwiftUI

// MARK: - Prayer Input Field
// TextEditor styled with Sacred Manuscript medieval aesthetics

struct PrayerInputField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(.custom("CormorantGaramond-Italic", size: 17))
                    .foregroundStyle(Color.tertiaryText.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            TextEditor(text: $text)
                .font(.custom("CormorantGaramond-Italic", size: 17))
                .foregroundStyle(Color.primaryText)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .focused($isFocused)
        }
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackground.opacity(0.5))
        )
        .overlay(
            ManuscriptBorder(isFocused: isFocused)
        )
        .shadow(
            color: isFocused ? Color.divineGold.opacity(0.2) : Color.clear,
            radius: 12
        )
    }
}

// MARK: - Manuscript Border (Animated gold corners)

private struct ManuscriptBorder: View {
    let isFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let cornerLength: CGFloat = isFocused ? 30 : 20

            ZStack {
                // Top-left corner
                Path { path in
                    path.move(to: CGPoint(x: 0, y: cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                }
                .stroke(Color.divineGold, lineWidth: 2)

                // Top-right corner
                Path { path in
                    path.move(to: CGPoint(x: width - cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: cornerLength))
                }
                .stroke(Color.divineGold, lineWidth: 2)

                // Bottom-left corner
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height - cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: cornerLength, y: height))
                }
                .stroke(Color.divineGold, lineWidth: 2)

                // Bottom-right corner
                Path { path in
                    path.move(to: CGPoint(x: width - cornerLength, y: height))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: width, y: height - cornerLength))
                }
                .stroke(Color.divineGold, lineWidth: 2)
            }
            .animation(.easeOut(duration: 0.3), value: isFocused)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool

    ZStack {
        Color.appBackground.ignoresSafeArea()
        PrayerInputField(
            text: $text,
            placeholder: "What's on your heart?",
            isFocused: $focused
        )
        .padding()
    }
}
