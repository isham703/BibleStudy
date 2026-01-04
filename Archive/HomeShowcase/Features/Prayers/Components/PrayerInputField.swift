import SwiftUI

// MARK: - Prayer Input Field
// TextEditor with variant-specific styling

struct PrayerInputField: View {
    @Binding var text: String
    let variant: PrayersShowcaseVariant
    let placeholder: String
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        switch variant {
        case .sacredManuscript:
            manuscriptStyle
        case .desertSilence:
            silenceStyle
        case .auroraVeil:
            auroraStyle
        }
    }

    // MARK: - Sacred Manuscript Style

    private var manuscriptStyle: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(.custom("CormorantGaramond-Italic", size: 17))
                    .foregroundStyle(Color.manuscriptOxide.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            TextEditor(text: $text)
                .font(.custom("CormorantGaramond-Italic", size: 17))
                .foregroundStyle(Color.manuscriptUmber)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .focused($isFocused)
        }
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.manuscriptVellum.opacity(0.5))
        )
        .overlay(
            ManuscriptBorder(isFocused: isFocused)
        )
        .shadow(
            color: isFocused ? Color.manuscriptGold.opacity(0.2) : Color.clear,
            radius: 12
        )
    }

    // MARK: - Desert Silence Style

    private var silenceStyle: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 19, weight: .ultraLight))
                        .foregroundStyle(Color.desertAsh)
                        .padding(.top, 8)
                }

                TextEditor(text: $text)
                    .font(.system(size: 19, weight: .ultraLight))
                    .foregroundStyle(Color.desertSumiInk)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
            }
            .frame(height: 100)

            // Simple underline
            Rectangle()
                .fill(isFocused ? Color.desertSumiInk : Color.desertAsh)
                .frame(height: 1)
                .animation(.easeOut(duration: 0.2), value: isFocused)
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Aurora Veil Style

    private var auroraStyle: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.auroraStarlight.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            TextEditor(text: $text)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .focused($isFocused)
        }
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.auroraTeal.opacity(0.1))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused
                    ? Color.auroraViolet.opacity(0.6)
                    : Color.white.opacity(0.2),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isFocused ? Color.auroraViolet.opacity(0.3) : Color.clear,
            radius: 12
        )
        .animation(.easeOut(duration: 0.2), value: isFocused)
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
                .stroke(Color.manuscriptGold, lineWidth: 2)

                // Top-right corner
                Path { path in
                    path.move(to: CGPoint(x: width - cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: cornerLength))
                }
                .stroke(Color.manuscriptGold, lineWidth: 2)

                // Bottom-left corner
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height - cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: cornerLength, y: height))
                }
                .stroke(Color.manuscriptGold, lineWidth: 2)

                // Bottom-right corner
                Path { path in
                    path.move(to: CGPoint(x: width - cornerLength, y: height))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: width, y: height - cornerLength))
                }
                .stroke(Color.manuscriptGold, lineWidth: 2)
            }
            .animation(.easeOut(duration: 0.3), value: isFocused)
        }
    }
}

// MARK: - Preview

#Preview("Sacred Manuscript") {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool

    ZStack {
        Color.manuscriptVellum.ignoresSafeArea()
        PrayerInputField(
            text: $text,
            variant: .sacredManuscript,
            placeholder: "What's on your heart?",
            isFocused: $focused
        )
        .padding()
    }
}

#Preview("Desert Silence") {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool

    ZStack {
        Color.desertDawnMist.ignoresSafeArea()
        PrayerInputField(
            text: $text,
            variant: .desertSilence,
            placeholder: "What's on your heart?",
            isFocused: $focused
        )
        .padding()
    }
}

#Preview("Aurora Veil") {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool

    ZStack {
        Color.auroraVoid.ignoresSafeArea()
        PrayerInputField(
            text: $text,
            variant: .auroraVeil,
            placeholder: "What's on your heart?",
            isFocused: $focused
        )
        .padding()
    }
}
