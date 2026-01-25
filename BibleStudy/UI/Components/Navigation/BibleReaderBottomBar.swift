import SwiftUI

// MARK: - Bible Reader Bottom Bar
// Compact floating bottom toolbar for Bible reader
// Audio button changes state when playing and opens full player

struct BibleReaderBottomBar: View {
    @Bindable var viewModel: BibleReaderBottomBarViewModel
    let audioService: AudioService
    let isVisible: Bool
    let onNotesTap: () -> Void
    let onSearchTap: () -> Void
    let onAudioTap: () -> Void
    let onMiniPlayerTap: () -> Void

    private var isAudioPlaying: Bool {
        audioService.isPlaying
    }

    private var isAudioLoading: Bool {
        audioService.isLoading
    }

    private var hasActiveAudio: Bool {
        audioService.playbackState != .idle
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ToolbarIconButton(
                icon: "highlighter",
                badge: viewModel.totalNotesCount > 0 ? viewModel.totalNotesCount : nil,
                accessibilityLabel: "Notes",
                action: onNotesTap
            )

            ToolbarIconButton(
                icon: "magnifyingglass",
                accessibilityLabel: "Search",
                action: onSearchTap
            )

            ToolbarIconButton(
                icon: isAudioPlaying ? "speaker.wave.2.fill" : "speaker.wave.2",
                isActive: isAudioPlaying,
                isLoading: isAudioLoading,
                accessibilityLabel: isAudioLoading ? "Loading Audio" : (isAudioPlaying ? "Now Playing" : "Audio"),
                action: {
                    if hasActiveAudio {
                        onMiniPlayerTap()  // Open full player to control playback
                    } else {
                        onAudioTap()       // Start new audio
                    }
                }
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(Color.appDivider.opacity(0.5), lineWidth: Theme.Stroke.hairline)
        )
        .padding(.bottom, Theme.Spacing.md)
        .offset(y: isVisible ? 0 : 80)
        .opacity(isVisible ? 1 : 0)
        .animation(Theme.Animation.fade, value: isVisible)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reader toolbar")
    }
}

// MARK: - Toolbar Icon Button

private struct ToolbarIconButton: View {
    let icon: String
    var badge: Int? = nil
    var isActive: Bool = false
    var isLoading: Bool = false
    let accessibilityLabel: String
    let action: () -> Void

    @State private var isPressed = false

    private var iconColor: Color {
        (isActive || isLoading) ? Color("AppAccentAction") : Color("AppTextSecondary")
    }

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(Color("AppSurface").opacity(0.8))
                    .frame(width: 44, height: 44)

                if isLoading {
                    ProgressView()
                        .tint(Color("AppAccentAction"))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                if let count = badge, count > 0 {
                    Text(count > 9 ? "9+" : "\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Circle().fill(Color("AppAccentAction")))
                        .offset(x: 14, y: -14)
                }

                if isActive && badge == nil && !isLoading {
                    Circle()
                        .fill(Color("AppAccentAction"))
                        .frame(width: 6, height: 6)
                        .offset(x: 14, y: -14)
                }
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(Theme.Animation.fade, value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isLoading ? "Audio is loading" : "Open \(accessibilityLabel.lowercased())")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Preview

#Preview("Toolbar Mode") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            Spacer()
            BibleReaderBottomBar(
                viewModel: BibleReaderBottomBarViewModel(),
                audioService: AudioService.shared,
                isVisible: true,
                onNotesTap: {},
                onSearchTap: {},
                onAudioTap: {},
                onMiniPlayerTap: {}
            )
        }
    }
}
