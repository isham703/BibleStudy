import SwiftUI

// MARK: - Sermon View
// Main container view for the Sermon Recording feature
// Switches between phases: Input → Recording → Processing → Viewing
//
// Presented as a fullScreenCover from HomeView, so it owns its own
// NavigationStack. Spoke views (Study Guide, Listen & Read, Journal)
// are pushed via NavigationLink(value: SermonDestination) with
// .navigationDestination registered on the stable root content.

struct SermonView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var flowState = SermonFlowState()
    @State private var showLibrary = false

    // MARK: - Viewing Phase State

    @State private var viewModel = SermonViewingViewModel()
    @State private var notesViewModel = SermonNotesViewModel()
    @State private var bookmarks: [SermonBookmark] = []
    @State private var showShareSheet = false
    @State private var showQuickCapture = false
    @State private var showDeleteConfirmation = false
    @State private var audioLoadTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                sermonBackground

                // Phase content
                phaseContent
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
            }
            .navigationDestination(for: SermonDestination.self) { destination in
                destinationView(for: destination)
            }
            .animation(flowState.phase == .input ? nil : Theme.Animation.slowFade, value: flowState.phase)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        handleBack()
                    } label: {
                        Image(systemName: flowState.phase == .input ? "xmark" : "chevron.left")
                            .font(Typography.Icon.md)
                            .foregroundStyle(Color("AccentBronze"))
                    }
                    .opacity(flowState.isProcessing ? 0 : 1)
                    .disabled(flowState.isProcessing)
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
            .sheet(isPresented: $showShareSheet) {
                if let shareText = generateShareText() {
                    ShareSheet(items: [shareText])
                }
            }
            .sheet(isPresented: $showQuickCapture) {
                if let sermon = flowState.currentSermon {
                    QuickCaptureSheet(
                        sermonId: sermon.id,
                        currentTime: viewModel.isPlaying ? viewModel.currentTime : nil,
                        onSave: { label, note, timestamp in
                            Task {
                                await flowState.addBookmark(
                                    label: label,
                                    note: note,
                                    timestampSeconds: timestamp
                                )
                                loadBookmarks()
                                let formatted = String(format: "%d:%02d", Int(timestamp) / 60, Int(timestamp) % 60)
                                ToastService.shared.showSuccess(message: "Note saved at \(formatted)")
                            }
                        }
                    )
                }
            }
            .overlay {
                _SermonObserverOverlay(
                    flowState: flowState,
                    viewModel: viewModel,
                    notesViewModel: notesViewModel,
                    appState: appState,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    audioLoadTask: $audioLoadTask,
                    onLoadBookmarks: loadBookmarks,
                    onSyncNotes: syncNotesViewModel,
                    onSetupAudio: setupAudioPlayer,
                    onDelete: deleteCurrentSermon
                )
            }
        }
        .onAppear {
            appState.hideTabBar = true
        }
        .onDisappear {
            appState.hideTabBar = false
        }
    }

    // MARK: - Background

    private var sermonBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("AppBackground").opacity(Theme.Opacity.textPrimary),
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
                    Color("AccentBronze").opacity(Theme.Opacity.subtle),
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
            SermonInputPhase(
                flowState: flowState,
                onShowLibrary: {
                    showLibrary = true
                },
                onSampleTap: {
                    flowState.loadSampleSermon()
                },
                onSermonTap: { sermon in
                    Task {
                        await flowState.loadExistingSermon(sermon)
                    }
                }
            )

        case .recording:
            SermonRecordingPhase(flowState: flowState)

        case .importing:
            importingView

        case .processing:
            SermonProcessingPhase(flowState: flowState)

        case .viewing:
            SermonViewingPhase(
                flowState: flowState,
                viewModel: viewModel,
                notesViewModel: notesViewModel,
                bookmarks: bookmarks,
                showShareSheet: $showShareSheet,
                showDeleteConfirmation: $showDeleteConfirmation,
                showQuickCapture: $showQuickCapture
            )

        case .error:
            errorView
        }
    }

    // MARK: - Importing View

    private var importingView: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentBronze")))
                // swiftlint:disable:next hardcoded_scale_effect
                .scaleEffect(1.5)

            Text("Importing audio...")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Typography.Icon.xxl)
                .foregroundStyle(Color("AccentBronze"))

            if let error = flowState.error {
                Text(error.localizedDescription)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.horizontal, 40)  // Error message spacing
            }

            Button {
                flowState.dismissError()
            } label: {
                Text("Try Again")
                    .font(Typography.Command.cta)
                    .foregroundStyle(Color("AccentBronze"))
                    .padding(.horizontal, Theme.Spacing.xxl)
                    // swiftlint:disable:next hardcoded_padding_edge
                    .padding(.vertical, 14)  // Button padding
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.button)
                            .stroke(Color("AccentBronze").opacity(Theme.Opacity.textSecondary), lineWidth: Theme.Stroke.hairline)
                    )
            }
        }
    }

    // MARK: - Destination View

    @ViewBuilder
    private func destinationView(for destination: SermonDestination) -> some View {
        switch destination {
        case .studyGuide(let scrollTo):
            SermonStudyGuideView(
                flowState: flowState,
                viewModel: viewModel,
                notesViewModel: notesViewModel,
                scrollTo: scrollTo,
                onAddNote: { showQuickCapture = true },
                onShare: { showShareSheet = true },
                onNewSermon: { flowState.reset() },
                onDelete: { showDeleteConfirmation = true }
            )

        case .listenRead(let autoPlay):
            SermonListenReadView(
                flowState: flowState,
                viewModel: viewModel,
                autoPlay: autoPlay,
                onAddNote: { showQuickCapture = true },
                onShare: { showShareSheet = true },
                onNewSermon: { flowState.reset() },
                onDelete: { showDeleteConfirmation = true }
            )

        case .journal:
            SermonJournalView(
                flowState: flowState,
                bookmarks: $bookmarks,
                onSeek: { timestamp in
                    viewModel.seekToTime(timestamp)
                    if !viewModel.isPlaying {
                        viewModel.togglePlayPause()
                    }
                },
                onAddNote: { showQuickCapture = true },
                onShare: { showShareSheet = true },
                onNewSermon: { flowState.reset() },
                onDelete: { showDeleteConfirmation = true }
            )
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

    // MARK: - Viewing Helpers

    private func loadBookmarks() {
        guard let sermonId = flowState.currentSermon?.id else { return }
        do {
            bookmarks = try SermonRepository.shared.fetchBookmarks(
                sermonId: sermonId,
                includeDeleted: false
            )
        } catch {
            print("[SermonView] Failed to load bookmarks: \(error)")
        }
        syncNotesViewModel()
    }

    private func syncNotesViewModel() {
        guard let studyGuide = flowState.currentStudyGuide else { return }
        notesViewModel.update(studyGuide: studyGuide)
    }

    private func setupAudioPlayer() {
        var allSamples: [Float] = []
        for chunk in flowState.audioChunks {
            if let samples = chunk.waveformSamples {
                allSamples.append(contentsOf: samples)
            }
        }
        viewModel.waveformSamples = allSamples.isEmpty ? Array(repeating: 0.3, count: 100) : allSamples
        viewModel.duration = Double(flowState.currentSermon?.durationSeconds ?? 0)

        audioLoadTask?.cancel()
        audioLoadTask = Task {
            do {
                guard let sermon = flowState.currentSermon else { return }
                let urls = try await SermonSyncService.shared.getChunkURLs(sermonId: sermon.id)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    viewModel.loadAudio(urls: urls)
                }
            } catch {
                print("[SermonView] Failed to load audio: \(error)")
            }
        }

        if let transcript = flowState.currentTranscript {
            viewModel.segments = transcript.segments
        }
    }

    private func generateShareText() -> String? {
        guard let sermon = flowState.currentSermon else { return nil }

        var text = """
        \(sermon.displayTitle)
        """

        if let speaker = sermon.speakerName {
            text += "\nBy \(speaker)"
        }

        text += "\nRecorded: \(sermon.recordedAt.formatted(date: .long, time: .omitted))"
        text += "\nDuration: \(sermon.formattedDuration)"

        if let studyGuide = flowState.currentStudyGuide {
            text += "\n\n--- Summary ---\n\(studyGuide.content.summary)"

            if !studyGuide.content.keyThemes.isEmpty {
                text += "\n\n--- Key Themes ---"
                for theme in studyGuide.content.keyThemes {
                    text += "\n- \(theme)"
                }
            }
        }

        if let transcript = flowState.currentTranscript {
            text += "\n\n--- Transcript ---\n\(transcript.content)"
        }

        return text
    }

    private func deleteCurrentSermon() async {
        guard let sermon = flowState.currentSermon else { return }
        viewModel.cleanup()

        do {
            try await SermonSyncService.shared.deleteSermon(sermon)
            HapticService.shared.deleteConfirmed()
            ToastService.shared.showSermonDeleted(title: sermon.displayTitle)
            flowState.reset()
        } catch {
            HapticService.shared.warning()
            ToastService.shared.showDeleteError(message: error.localizedDescription)
        }
    }
}

// MARK: - Observation Isolation
// Modifiers that read @Observable properties live here so their
// re-evaluations don't trigger SermonView.body re-evaluation.
// This prevents NavigationStack destination invalidation when
// background processes mutate SermonFlowState during navigation.

private struct _SermonObserverOverlay: View {
    @Bindable var flowState: SermonFlowState
    var viewModel: SermonViewingViewModel
    var notesViewModel: SermonNotesViewModel
    var appState: AppState
    @Binding var showDeleteConfirmation: Bool
    @Binding var audioLoadTask: Task<Void, Never>?
    var onLoadBookmarks: () -> Void
    var onSyncNotes: () -> Void
    var onSetupAudio: () -> Void
    var onDelete: () async -> Void

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
            .confirmationDialog(
                "Delete \"\(flowState.currentSermon?.displayTitle ?? "Sermon")\"?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await onDelete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            .onChange(of: flowState.phase) { oldPhase, newPhase in
                if oldPhase == .viewing && newPhase != .viewing {
                    audioLoadTask?.cancel()
                    audioLoadTask = nil
                    viewModel.cleanup()
                }
                if newPhase == .viewing {
                    onSetupAudio()
                    onLoadBookmarks()
                }
            }
            .onChange(of: flowState.currentStudyGuide) { _, newGuide in
                if newGuide != nil {
                    onSyncNotes()
                }
            }
    }
}

// MARK: - Preview

#Preview {
    SermonView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
