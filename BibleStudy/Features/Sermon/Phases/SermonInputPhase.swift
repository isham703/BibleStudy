import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sermon Input Phase
// Initial screen for starting a sermon recording or importing audio

struct SermonInputPhase: View {
    @Bindable var flowState: SermonFlowState
    @State private var showFilePicker = false
    @State private var illuminationPhase: CGFloat = 0
    @FocusState private var titleFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                // Header with illuminated microphone
                headerSection

                // Divider
                SermonDivider()

                // Input fields
                inputFieldsSection

                // Action buttons
                actionButtonsSection

                Spacer(minLength: 24)
            }
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.top, Theme.Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await flowState.importAudio(from: url)
                    }
                }
            case .failure(let error):
                print("[SermonInputPhase] File picker error: \(error)")
            }
        }
        .onAppear {
            startIlluminationAnimation()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Illuminated microphone icon
            ZStack {
                // Outer glow (pulsing)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentBronze.opacity(Theme.Opacity.medium),
                                Color.accentBronze.opacity(Theme.Opacity.subtle),
                                .clear
                            ],
                            center: .center,
                            startRadius: 24,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + illuminationPhase * 0.05)

                // Inner circle
                Circle()
                    .fill(Color.surfaceRaised)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: Theme.Stroke.control
                            )
                    )
                    .shadow(color: Color.accentBronze.opacity(Theme.Opacity.medium), radius: 20)

                // Microphone icon
                Image(systemName: "waveform.circle.fill")
                    .font(Typography.Icon.xxl)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title
            VStack(spacing: Theme.Spacing.xs) {
                Text("SERMON")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.accentBronze)
                    .tracking(2.0)

                Text("from Your Voice")
                    .font(Typography.Scripture.body)
                    .italic()
                    .foregroundStyle(Color.textPrimary)
            }

            // Subtitle
            Text("Capture the Word as it speaks")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Input Fields Section

    private var inputFieldsSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Title input
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Title")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.textSecondary)
                    .tracking(1.5)

                TextField("Optional sermon title", text: $flowState.title)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textPrimary)
                    .padding(Theme.Spacing.lg)
                    .background(Color.surfaceRaised.opacity(Theme.Opacity.heavy))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                    )
                    .focused($titleFocused)
            }

            // Speaker input
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Speaker")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.textSecondary)
                    .tracking(1.5)

                TextField("Optional speaker name", text: $flowState.speakerName)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textPrimary)
                    .padding(Theme.Spacing.lg)
                    .background(Color.surfaceRaised.opacity(Theme.Opacity.heavy))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                    )
            }
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Record button (primary)
            Button {
                Task {
                    await flowState.startRecording()
                }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "mic.fill")
                        .font(Typography.Icon.md.weight(.medium))

                    Text("Begin Recording")
                        .font(Typography.Scripture.heading)
                }
                .foregroundStyle(Color.surfaceParchment)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg + 2)
                .background(
                    LinearGradient(
                        colors: [Color.accentBronze, Color.decorativeGold.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.accentBronze.opacity(Theme.Opacity.disabled), radius: 12, y: 4)
            }
            .buttonStyle(.plain)

            // Import button (secondary)
            Button {
                showFilePicker = true
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "doc.badge.plus")
                        .font(Typography.Icon.md.weight(.medium))

                    Text("Import Audio")
                        .font(Typography.Scripture.heading)
                }
                .foregroundStyle(Color.accentBronze)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg + 2)
                .background(Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)

            // Supported formats note
            Text("Supports MP3, M4A, WAV • Max 500MB")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.textSecondary.opacity(Theme.Opacity.overlay))
        }
    }

    // MARK: - Animation

    private func startIlluminationAnimation() {
        withAnimation(Theme.Animation.slowFade) {
            illuminationPhase = 1
        }
    }
}

// MARK: - Sermon Divider

struct SermonDivider: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.accentBronze.opacity(Theme.Opacity.heavy)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Stroke.hairline)

            // Diamond ornament
            Image(systemName: "diamond.fill")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color.accentBronze)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentBronze.opacity(Theme.Opacity.heavy), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Theme.Stroke.hairline)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }
}


#Preview {
    SermonInputPhase(flowState: SermonFlowState())
        .preferredColorScheme(.dark)
}
