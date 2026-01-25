//
//  SermonStatusView.swift
//  BibleStudy
//
//  Unified sermon status indicator with ceremonial motion
//  Processing: neutral pulse (NOT bronze - reserved for verified)
//  Ready: bronze checkmark (verified meaning)
//  Error: red triangle (needs attention)
//  Pending: neutral clock (waiting)
//

import SwiftUI

// MARK: - Sermon Status View

struct SermonStatusView: View {
    let sermon: Sermon
    let layout: StatusLayout

    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum StatusLayout {
        case compact   // 32x32 for preview cards
        case full      // 44x44 for library cards

        var size: CGFloat {
            switch self {
            case .compact: return 32
            case .full: return 44
            }
        }

        var iconFont: Font {
            switch self {
            case .compact: return Typography.Icon.md
            case .full: return Typography.Icon.lg
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .compact: return 1.5
            case .full: return 2
            }
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundColor)

            // Status content
            if sermon.isProcessing {
                processingIndicator
            } else {
                statusIcon
            }
        }
        .frame(width: layout.size, height: layout.size)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            updatePulseState()
        }
        .onChange(of: sermon.isProcessing) { _, isProcessing in
            if isProcessing {
                startPulse()
            } else {
                stopPulse()
            }
        }
    }

    // MARK: - Processing Indicator

    private var processingIndicator: some View {
        ZStack {
            // Pulsing outer ring - neutral color, NOT bronze
            Circle()
                .stroke(Color("TertiaryText"), lineWidth: layout.strokeWidth)
                .scaleEffect(isPulsing ? 1.0 : 0.97)
                .opacity(isPulsing ? 1.0 : 0.7)
                .animation(
                    isPulsing && !reduceMotion
                        ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                        : nil,
                    value: isPulsing
                )

            // Center waveform icon
            Image(systemName: "waveform")
                .font(layout.iconFont)
                .foregroundStyle(Color("TertiaryText"))
        }
    }

    // MARK: - Status Icon

    private var statusIcon: some View {
        Image(systemName: iconName)
            .font(layout.iconFont)
            .foregroundStyle(iconColor)
    }

    // MARK: - Computed Properties

    /// Background color based on status
    /// Uses semantic colors with 14% opacity for backgrounds
    private var backgroundColor: Color {
        if sermon.isProcessing {
            return Color("AppSurface")
        } else if sermon.isComplete {
            return Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
        } else if sermon.hasError {
            return Color("FeedbackError").opacity(Theme.Opacity.selectionBackground)
        } else {
            // Pending
            return Color("AppSurface")
        }
    }

    /// Icon name based on status
    private var iconName: String {
        if sermon.hasError {
            return "exclamationmark.triangle.fill"
        } else if sermon.isComplete {
            return "checkmark.circle.fill"
        } else {
            // Pending
            return "clock"
        }
    }

    /// Icon color based on status
    /// Bronze reserved for "Ready/Verified" state only
    private var iconColor: Color {
        if sermon.hasError {
            return Color("FeedbackError")
        } else if sermon.isComplete {
            return Color("AccentBronze")
        } else {
            // Pending
            return Color("TertiaryText")
        }
    }

    /// Accessibility label for VoiceOver
    private var accessibilityLabel: String {
        if sermon.isProcessing {
            return "Processing sermon"
        } else if sermon.hasError {
            return "Sermon processing error"
        } else if sermon.isComplete {
            return "Sermon ready"
        } else {
            return "Sermon pending"
        }
    }

    // MARK: - Pulse Control

    private func updatePulseState() {
        if sermon.isProcessing && !reduceMotion {
            startPulse()
        }
    }

    private func startPulse() {
        guard !reduceMotion else { return }
        isPulsing = true
    }

    private func stopPulse() {
        isPulsing = false
    }
}

// MARK: - Preview

#Preview("Status States - Full") {
    VStack(spacing: Theme.Spacing.lg) {
        HStack(spacing: Theme.Spacing.lg) {
            VStack {
                SermonStatusView(
                    sermon: .mockProcessing,
                    layout: .full
                )
                Text("Processing")
                    .font(Typography.Command.caption)
            }

            VStack {
                SermonStatusView(
                    sermon: .mockComplete,
                    layout: .full
                )
                Text("Complete")
                    .font(Typography.Command.caption)
            }

            VStack {
                SermonStatusView(
                    sermon: .mockError,
                    layout: .full
                )
                Text("Error")
                    .font(Typography.Command.caption)
            }

            VStack {
                SermonStatusView(
                    sermon: .mockPending,
                    layout: .full
                )
                Text("Pending")
                    .font(Typography.Command.caption)
            }
        }
    }
    .padding()
    .background(Color("AppBackground"))
}

#Preview("Status States - Compact") {
    HStack(spacing: Theme.Spacing.lg) {
        SermonStatusView(sermon: .mockProcessing, layout: .compact)
        SermonStatusView(sermon: .mockComplete, layout: .compact)
        SermonStatusView(sermon: .mockError, layout: .compact)
        SermonStatusView(sermon: .mockPending, layout: .compact)
    }
    .padding()
    .background(Color("AppBackground"))
}

// MARK: - Mock Sermons for Preview

private extension Sermon {
    static var mockProcessing: Sermon {
        Sermon(
            id: UUID(),
            userId: UUID(),
            title: "Processing Sermon",
            recordedAt: Date(),
            durationSeconds: 1200,
            transcriptionStatus: .running,
            studyGuideStatus: .pending
        )
    }

    static var mockComplete: Sermon {
        Sermon(
            id: UUID(),
            userId: UUID(),
            title: "Complete Sermon",
            recordedAt: Date(),
            durationSeconds: 1200,
            transcriptionStatus: .succeeded,
            studyGuideStatus: .succeeded
        )
    }

    static var mockError: Sermon {
        Sermon(
            id: UUID(),
            userId: UUID(),
            title: "Error Sermon",
            recordedAt: Date(),
            durationSeconds: 1200,
            transcriptionStatus: .failed,
            transcriptionError: "Transcription failed",
            studyGuideStatus: .pending
        )
    }

    static var mockPending: Sermon {
        Sermon(
            id: UUID(),
            userId: UUID(),
            title: "Pending Sermon",
            recordedAt: Date(),
            durationSeconds: 1200,
            transcriptionStatus: .pending,
            studyGuideStatus: .pending
        )
    }
}
