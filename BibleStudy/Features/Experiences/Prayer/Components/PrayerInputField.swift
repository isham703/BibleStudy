import SwiftUI

// MARK: - Prayer Input Field
// TextEditor styled with Sacred Manuscript medieval aesthetics

struct PrayerInputField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState.Binding var isFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    // swiftlint:disable:next hardcoded_font_custom
                    .font(.system(size: 17, weight: .regular, design: .serif).italic())
                    .foregroundStyle(Color.tertiaryText.opacity(Theme.Opacity.strong))
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.lg)
            }

            TextEditor(text: $text)
                // swiftlint:disable:next hardcoded_font_custom
                .font(.system(size: 17, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.primaryText)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .focused($isFocused)
        }
        // swiftlint:disable:next hardcoded_frame_size
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.appBackground.opacity(Theme.Opacity.heavy))
        )
        .overlay(
            ManuscriptBorder(isFocused: isFocused, colorScheme: colorScheme)
        )
        .shadow(
            color: isFocused ? Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium) : Color.clear,
            // swiftlint:disable:next hardcoded_shadow_radius
            radius: 12
        )
    }
}

// MARK: - Manuscript Border (Animated gold corners)

private struct ManuscriptBorder: View {
    let isFocused: Bool
    let colorScheme: ColorScheme

    private var sealColor: Color {
        Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme))
    }

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
                .stroke(sealColor, lineWidth: Theme.Stroke.control)

                // Top-right corner
                Path { path in
                    path.move(to: CGPoint(x: width - cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: cornerLength))
                }
                .stroke(sealColor, lineWidth: Theme.Stroke.control)

                // Bottom-left corner
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height - cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: cornerLength, y: height))
                }
                .stroke(sealColor, lineWidth: Theme.Stroke.control)

                // Bottom-right corner
                Path { path in
                    path.move(to: CGPoint(x: width - cornerLength, y: height))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: width, y: height - cornerLength))
                }
                .stroke(sealColor, lineWidth: Theme.Stroke.control)
            }
            .animation(Theme.Animation.settle, value: isFocused)
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
