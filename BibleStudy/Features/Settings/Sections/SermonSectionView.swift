import SwiftUI
import Speech

// MARK: - Sermon Section View
// Settings section for sermon recording preferences.
// Gated to iOS 26+ — hidden on older OS versions.

@available(iOS 26, *)
struct SermonSectionView: View {
    @Bindable var viewModel: SettingsViewModel

    @AppStorage(AppConfiguration.UserDefaultsKeys.liveCaptionsEnabled)
    private var liveCaptionsEnabled: Bool = false

    // MARK: - Preflight State

    @State private var preflightState: PreflightState = .idle
    @State private var downloadProgress: Double = 0
    @State private var preflightTask: Task<Void, Never>?

    private enum PreflightState: Equatable {
        case idle
        case requestingPermission
        case permissionDenied
        case checkingModel
        case downloadingModel
        case ready
        case failed(String)
    }

    /// Whether the feature is remotely enabled (kill switch)
    private var isRemotelyEnabled: Bool {
        FeatureFlagService.shared.isLiveCaptionsEnabled
    }

    var body: some View {
        SettingsCard(title: "Sermon", icon: "mic.fill") {
            VStack(spacing: Theme.Spacing.lg) {
                if isRemotelyEnabled {
                    // Live Captions toggle
                    SettingsToggle(
                        isOn: $liveCaptionsEnabled,
                        label: "Live Captions",
                        description: "Show real-time captions while recording. Generated on your device.",
                        icon: "captions.bubble.fill",
                        iconColor: Color("AppAccentAction")
                    )
                    .onChange(of: liveCaptionsEnabled) { _, newValue in
                        preflightTask?.cancel()
                        if newValue {
                            preflightTask = Task { await runPreflight() }
                        } else {
                            preflightState = .idle
                            downloadProgress = 0
                        }
                    }

                    // Preflight status
                    if liveCaptionsEnabled {
                        preflightStatusView
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } else {
                    // Kill switch active — feature disabled remotely
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(Typography.Icon.xs)
                            .foregroundStyle(Color("TertiaryText"))

                        Text("Live captions are temporarily unavailable.")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))

                        Spacer()
                    }
                }
            }
            .animation(Theme.Animation.settle, value: liveCaptionsEnabled)
            .animation(Theme.Animation.settle, value: preflightState)
        }
    }

    // MARK: - Preflight Status

    @ViewBuilder
    private var preflightStatusView: some View {
        switch preflightState {
        case .idle:
            EmptyView()

        case .requestingPermission:
            preflightRow(
                icon: "lock.shield",
                text: "Requesting speech recognition permission...",
                showSpinner: true
            )

        case .permissionDenied:
            VStack(spacing: Theme.Spacing.sm) {
                preflightRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Speech recognition permission denied.",
                    color: Color("FeedbackWarning")
                )

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }

        case .checkingModel:
            preflightRow(
                icon: "arrow.down.circle",
                text: "Checking language model...",
                showSpinner: true
            )

        case .downloadingModel:
            VStack(spacing: Theme.Spacing.sm) {
                preflightRow(
                    icon: "arrow.down.circle.fill",
                    text: "Downloading language model..."
                )

                // Download progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Theme.Radius.xs)
                            .fill(Color("AppSurface"))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                                    .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
                            )

                        RoundedRectangle(cornerRadius: Theme.Radius.xs)
                            .fill(Color("AppAccentAction"))
                            .frame(width: geo.size.width * downloadProgress)
                            .animation(Theme.Animation.settle, value: downloadProgress)
                    }
                }
                .frame(height: 6)
            }

        case .ready:
            preflightRow(
                icon: "checkmark.circle.fill",
                text: "Ready. Live captions will appear during recording.",
                color: Color("FeedbackSuccess")
            )

        case .failed(let reason):
            VStack(spacing: Theme.Spacing.sm) {
                preflightRow(
                    icon: "exclamationmark.triangle.fill",
                    text: reason,
                    color: Color("FeedbackWarning")
                )

                Button {
                    Task { await runPreflight() }
                } label: {
                    Text("Retry")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
    }

    private func preflightRow(
        icon: String,
        text: String,
        color: Color = Color("AppTextSecondary"),
        showSpinner: Bool = false
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if showSpinner {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color("AppAccentAction"))
            } else {
                Image(systemName: icon)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(color)
            }

            Text(text)
                .font(Typography.Command.caption)
                .foregroundStyle(color)

            Spacer()
        }
    }

    // MARK: - Preflight Logic

    private func runPreflight() async {
        // Step 1: Check / request speech recognition authorization
        preflightState = .requestingPermission

        let service = LiveTranscriptionService.shared

        let authStatus = service.authorizationStatus
        if authStatus != .authorized {
            let granted = await service.requestAuthorization()
            guard granted else {
                preflightState = .permissionDenied
                liveCaptionsEnabled = false
                return
            }
        }

        // Step 2: Check availability and language model
        preflightState = .checkingModel

        await service.checkAvailability()
        guard service.isAvailable else {
            preflightState = .failed("Speech recognition is not supported on this device.")
            liveCaptionsEnabled = false
            return
        }

        if await service.checkLanguageModelInstalled() {
            preflightState = .ready
            return
        }

        // Step 3: Download language model
        preflightState = .downloadingModel
        downloadProgress = 0

        do {
            try await service.installLanguageAssets { progress in
                Task { @MainActor in
                    downloadProgress = progress
                }
            }
            preflightState = .ready
        } catch {
            preflightState = .failed("Language model download failed. Please try again.")
            liveCaptionsEnabled = false
        }
    }
}

// MARK: - Preview

@available(iOS 26, *)
#Preview("Sermon Section") {
    ScrollView {
        SermonSectionView(viewModel: SettingsViewModel())
            .padding()
    }
    .background(Color.appBackground)
}
