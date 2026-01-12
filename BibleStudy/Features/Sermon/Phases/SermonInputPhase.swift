import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sermon Input Phase
// Hero-style landing screen with curved header image
// Title is auto-generated from study guide after processing

struct SermonInputPhase: View {
    @Bindable var flowState: SermonFlowState
    var onShowLibrary: (() -> Void)?
    @State private var showFilePicker = false
    @State private var isAwakened = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero header with curved bottom
                    HeroHeader(imageName: "SermonHero")

                // Main content
                VStack(spacing: Theme.Spacing.lg) {
                    // Title block - negative padding pulls content up to hero curve
                    titleBlock
                        .padding(.top, -Theme.Spacing.lg)

                    // Action buttons
                    actionSection

                    // Footer hint
                    footerHint
                        .padding(.top, Theme.Spacing.sm)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl * 2)
            }
            }

            // Library button overlay
            if let onShowLibrary = onShowLibrary {
                libraryButton(action: onShowLibrary)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(colorScheme == .dark ? Color.warmCharcoal : Color.appBackground)
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
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
        }
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("NEW SERMON")
                .font(Typography.Command.meta)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))

            Text("Capture & Study")
                .font(Typography.Scripture.title)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Record live or import an audio file")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.top, Theme.Spacing.xs)
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.2), value: isAwakened)
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Primary: Record button
            Button {
                HapticService.shared.mediumTap()
                Task {
                    await flowState.startRecording()
                }
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: "mic.fill")
                            .font(Typography.Icon.md)
                            .foregroundStyle(.white)
                    }

                    Text("Begin Recording")
                        .font(Typography.Command.cta)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [
                            Color("AppAccentAction"),
                            Color("AppAccentAction").opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                // Subtle ink-like shadow rather than material drop shadow
                .shadow(color: Color("AppAccentAction").opacity(0.15), radius: 6, y: 2)
            }
            .buttonStyle(SermonPressButtonStyle())
            .accessibilityLabel("Begin recording sermon")
            .accessibilityHint("Double tap to start recording with your microphone")
            .opacity(isAwakened ? 1 : 0)
            .offset(y: isAwakened ? 0 : 10)
            .animation(Theme.Animation.slowFade.delay(0.3), value: isAwakened)

            // Divider with "or" - shortened lines for intentional appearance
            HStack(spacing: Theme.Spacing.lg) {
                Rectangle()
                    .fill(Color("AppTextSecondary").opacity(0.3))
                    .frame(width: 60, height: 1)

                Text("or")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))

                Rectangle()
                    .fill(Color("AppTextSecondary").opacity(0.3))
                    .frame(width: 60, height: 1)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .opacity(isAwakened ? 1 : 0)
            .animation(Theme.Animation.slowFade.delay(0.35), value: isAwakened)

            // Secondary: Import button - more intentional surface treatment
            Button {
                HapticService.shared.lightTap()
                showFilePicker = true
            } label: {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "square.and.arrow.down")
                        .font(Typography.Icon.md)
                        .foregroundStyle(Color("AppAccentAction"))

                    Text("Import Audio File")
                        .font(Typography.Command.body.weight(.medium))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.control)
                )
            }
            .buttonStyle(SermonPressButtonStyle())
            .accessibilityLabel("Import audio file")
            .accessibilityHint("Double tap to select an audio file from your device")
            .opacity(isAwakened ? 1 : 0)
            .offset(y: isAwakened ? 0 : 10)
            .animation(Theme.Animation.slowFade.delay(0.4), value: isAwakened)
        }
    }

    // MARK: - Footer Hint

    private var footerHint: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "checkmark.circle")
                    .font(Typography.Icon.xs)
                Text("MP3, M4A, WAV")
            }
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "arrow.up.circle")
                    .font(Typography.Icon.xs)
                Text("Up to 500MB per file")
            }
            .font(Typography.Command.caption)
            .foregroundStyle(Color("AppTextSecondary"))
        }
        .opacity(isAwakened ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.45), value: isAwakened)
    }

    // MARK: - Library Button

    private func libraryButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticService.shared.lightTap()
            action()
        } label: {
            Image(systemName: "list.bullet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.black.opacity(0.3))
                )
        }
        .padding(.trailing, Theme.Spacing.md)
        .padding(.top, 59 + Theme.Spacing.xs) // Match HeroHeader's safe area offset
        .accessibilityLabel("Sermon Library")
    }
}

// MARK: - Button Style

private struct SermonPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SermonInputPhase(flowState: SermonFlowState())
    }
    .preferredColorScheme(.dark)
}
