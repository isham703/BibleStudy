import SwiftUI

// MARK: - Sermon View
// Main container view for the Sermon Recording feature
// Switches between phases: Input → Recording → Processing → Viewing

struct SermonView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var flowState = SermonFlowState()
    @State private var showLibrary = false

    var body: some View {
        ZStack {
            // Background
            sermonBackground

            // Phase content
            phaseContent
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
        .animation(Theme.Animation.slowFade, value: flowState.phase)
        .navigationBarBackButtonHidden(flowState.phase != .input)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if flowState.phase != .input {
                    Button {
                        handleBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color.accentBronze)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if flowState.phase == .input {
                    Button {
                        showLibrary = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color.accentBronze)
                    }
                }
            }
        }
        .sheet(isPresented: $showLibrary) {
            SermonLibraryView(onSelect: { sermon in
                showLibrary = false
                Task {
                    await flowState.loadExistingSermon(sermon)
                }
            })
        }
        .alert(
            "Error",
            isPresented: $flowState.showErrorAlert,
            presenting: flowState.error
        ) { _ in
            Button("Dismiss", role: .cancel) {
                flowState.dismissError()
            }
            if flowState.audioChunks.isEmpty == false {
                Button("Retry") {
                    flowState.retry()
                }
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .onAppear {
            appState.hideTabBar = true
        }
        .onDisappear {
            appState.hideTabBar = false
            flowState.reset()
        }
    }

    // MARK: - Background

    private var sermonBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.surfaceParchment,
                    Color.surfaceParchment.opacity(Theme.Opacity.high),
                    // swiftlint:disable:next hardcoded_color_rgb
                    Color(red: 0.08, green: 0.07, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [
                    Color.accentBronze.opacity(Theme.Opacity.faint),
                    .clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch flowState.phase {
        case .input:
            SermonInputPhase(flowState: flowState)

        case .recording:
            SermonRecordingPhase(flowState: flowState)

        case .importing:
            importingView

        case .processing:
            SermonProcessingPhase(flowState: flowState)

        case .viewing:
            SermonViewingPhase(flowState: flowState)

        case .error:
            errorView
        }
    }

    // MARK: - Importing View

    private var importingView: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentBronze))
                // swiftlint:disable:next hardcoded_scale_effect
                .scaleEffect(1.5)

            Text("Importing audio...")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color.accentBronze)

            if let error = flowState.error {
                Text(error.localizedDescription)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.horizontal, 40)  // Error message spacing
            }

            Button {
                flowState.dismissError()
            } label: {
                Text("Try Again")
                    .font(Typography.Command.cta)
                    .foregroundStyle(Color.accentBronze)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.vertical, 14)  // Button padding
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(Color.accentBronze.opacity(Theme.Opacity.heavy), lineWidth: Theme.Stroke.hairline)
                    )
            }
        }
    }

    // MARK: - Navigation

    private func handleBack() {
        switch flowState.phase {
        case .recording:
            // Show confirmation if recording
            if flowState.isRecording {
                flowState.cancelRecording()
            } else {
                flowState.reset()
            }

        case .processing:
            // Can't go back during processing
            break

        case .viewing:
            // Reset to input
            flowState.reset()

        case .error:
            flowState.dismissError()

        default:
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SermonView()
            .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
