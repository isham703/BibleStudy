import SwiftUI

// MARK: - Showcase Chat Input Bar
// Shared input component with voice and text support for showcase
// Adapts styling based on the chat variant

struct ShowcaseChatInputBar: View {
    @Binding var text: String
    let variant: ChatVariant
    let onSend: () -> Void
    let onVoice: () -> Void

    @State private var isRecording = false
    @FocusState private var isFocused: Bool

    private var palette: InputPalette {
        InputPalette(variant: variant)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Voice button
            voiceButton

            // Text input field
            inputField

            // Send button
            sendButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(palette.containerBackground)
    }

    // MARK: - Voice Button

    private var voiceButton: some View {
        Button(action: {
            isRecording.toggle()
            onVoice()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            ZStack {
                Circle()
                    .fill(isRecording ? palette.voiceActiveBackground : palette.voiceBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(Typography.Icon.base)
                    .foregroundStyle(isRecording ? palette.voiceActiveIcon : palette.voiceIcon)
                    .scaleEffect(isRecording ? 1.1 : 1.0)
            }
            .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .overlay {
            if isRecording {
                Circle()
                    .stroke(palette.voiceActiveBackground.opacity(Theme.Opacity.medium), lineWidth: 2)
                    .frame(width: 52, height: 52)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .opacity(isRecording ? 0 : 1)
                    .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: isRecording)
            }
        }
    }

    // MARK: - Input Field

    private var inputField: some View {
        HStack(spacing: 8) {
            TextField("Ask about scripture...", text: $text, axis: .vertical)
                .font(Typography.Command.callout)
                .foregroundStyle(palette.textColor)
                .lineLimit(1...4)
                .focused($isFocused)
                .tint(palette.cursorColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(palette.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .stroke(isFocused ? palette.inputBorderFocused : palette.inputBorder, lineWidth: 1)
        )
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button(action: {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            onSend()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            Circle()
                .fill(canSend ? palette.sendBackground : palette.sendDisabledBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "arrow.up")
                        .font(Typography.Command.callout.weight(.semibold))
                        .foregroundStyle(canSend ? palette.sendIcon : palette.sendDisabledIcon)
                )
        }
        .disabled(!canSend)
        .animation(.easeInOut(duration: 0.2), value: canSend)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Input Palette Helper

private struct InputPalette {
    let variant: ChatVariant

    // Container
    var containerBackground: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.background
        case .scholarlyCompanion: return ChatPalette.Scholarly.background
        case .warmSanctuary: return ChatPalette.Sanctuary.background
        }
    }

    // Voice button
    var voiceBackground: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.inputBackground
        case .scholarlyCompanion: return ChatPalette.Scholarly.accentSubtle
        case .warmSanctuary: return ChatPalette.Sanctuary.surface
        }
    }

    var voiceIcon: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.secondaryText
        case .scholarlyCompanion: return ChatPalette.Scholarly.accent
        case .warmSanctuary: return ChatPalette.Sanctuary.accent
        }
    }

    var voiceActiveBackground: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.accent
        case .scholarlyCompanion: return ChatPalette.Scholarly.accent
        case .warmSanctuary: return ChatPalette.Sanctuary.accent
        }
    }

    var voiceActiveIcon: Color {
        return .white
    }

    // Input field
    var inputBackground: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.inputBackground
        case .scholarlyCompanion: return ChatPalette.Scholarly.inputBackground
        case .warmSanctuary: return ChatPalette.Sanctuary.inputBackground
        }
    }

    var inputBorder: Color {
        switch variant {
        case .minimalStudio: return Color.clear
        case .scholarlyCompanion: return ChatPalette.Scholarly.aiBorder
        case .warmSanctuary: return ChatPalette.Sanctuary.aiBorder
        }
    }

    var inputBorderFocused: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.accent.opacity(Theme.Opacity.subtle)
        case .scholarlyCompanion: return ChatPalette.Scholarly.accent.opacity(Theme.Opacity.medium)
        case .warmSanctuary: return ChatPalette.Sanctuary.accent.opacity(Theme.Opacity.medium)
        }
    }

    var textColor: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.primaryText
        case .scholarlyCompanion: return ChatPalette.Scholarly.primaryText
        case .warmSanctuary: return ChatPalette.Sanctuary.primaryText
        }
    }

    var cursorColor: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.accent
        case .scholarlyCompanion: return ChatPalette.Scholarly.accent
        case .warmSanctuary: return ChatPalette.Sanctuary.accent
        }
    }

    // Send button
    var sendBackground: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.sendButton
        case .scholarlyCompanion: return ChatPalette.Scholarly.sendButton
        case .warmSanctuary: return ChatPalette.Sanctuary.sendButton
        }
    }

    var sendIcon: Color { .white }

    var sendDisabledBackground: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.buttonDisabled
        case .scholarlyCompanion: return ChatPalette.Scholarly.buttonDisabled
        case .warmSanctuary: return ChatPalette.Sanctuary.buttonDisabled
        }
    }

    var sendDisabledIcon: Color {
        switch variant {
        case .minimalStudio: return ChatPalette.Minimal.tertiaryText
        case .scholarlyCompanion: return ChatPalette.Scholarly.tertiaryText
        case .warmSanctuary: return ChatPalette.Sanctuary.tertiaryText
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        ShowcaseChatInputBar(text: .constant(""), variant: .minimalStudio, onSend: {}, onVoice: {})
        ShowcaseChatInputBar(text: .constant("Hello"), variant: .scholarlyCompanion, onSend: {}, onVoice: {})
        ShowcaseChatInputBar(text: .constant(""), variant: .warmSanctuary, onSend: {}, onVoice: {})
            .background(ChatPalette.Sanctuary.background)
    }
}
