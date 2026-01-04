import SwiftUI

// MARK: - Time-Aware Sanctuary Page
// Main switcher that automatically displays the appropriate Sanctuary variant
// based on the current time of day (Liturgy of the Hours)

struct TimeAwareSanctuaryPage: View {
    @State private var currentTime: SanctuaryTimeOfDay = .current
    @State private var manualOverride: SanctuaryTimeOfDay?
    @State private var showTimePicker = false

    // Use manual override if set, otherwise use current time
    private var activeTime: SanctuaryTimeOfDay {
        manualOverride ?? currentTime
    }

    var body: some View {
        ZStack {
            // Display the appropriate sanctuary view
            sanctuaryView(for: activeTime)
                .id(activeTime) // Force view recreation on time change
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            // Debug overlay (only in DEBUG builds)
            #if DEBUG
            VStack {
                Spacer()
                debugOverlay
                    .padding(.bottom, 140) // Above the candle for Compline
            }
            #endif
        }
        .animation(.easeInOut(duration: 0.5), value: activeTime)
        .onAppear {
            startTimeUpdates()
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                selectedTime: Binding(
                    get: { manualOverride ?? currentTime },
                    set: { manualOverride = $0 }
                ),
                onReset: { manualOverride = nil }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Sanctuary View Router

    @ViewBuilder
    private func sanctuaryView(for time: SanctuaryTimeOfDay) -> some View {
        switch time {
        case .dawn:
            DawnSanctuaryView()
        case .meridian:
            MeridianSanctuaryView()
        case .afternoon:
            AfternoonSanctuaryView()
        case .vespers:
            VespersSanctuaryView()
        case .compline:
            ComplineSanctuaryView()
        }
    }

    // MARK: - Debug Overlay

    #if DEBUG
    private var debugOverlay: some View {
        Button(action: { showTimePicker = true }) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .medium))
                Text(activeTime.name)
                    .font(.system(size: 12, weight: .semibold))
                if manualOverride != nil {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                }
            }
            .foregroundStyle(activeTime.isLightMode ? Color.black.opacity(0.6) : Color.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(activeTime.isLightMode
                        ? Color.black.opacity(0.08)
                        : Color.white.opacity(0.1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    #endif

    // MARK: - Time Updates

    private func startTimeUpdates() {
        // Update time every minute (only if no manual override)
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            if manualOverride == nil {
                let newTime = SanctuaryTimeOfDay.current
                if newTime != currentTime {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        currentTime = newTime
                    }
                }
            }
        }
    }
}

// MARK: - Time Picker Sheet

struct TimePickerSheet: View {
    @Binding var selectedTime: SanctuaryTimeOfDay
    let onReset: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("LITURGY OF THE HOURS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.secondary)

                    Text("Preview Different Times")
                        .font(.system(size: 20, weight: .semibold))
                }
                .padding(.top)

                // Time options
                VStack(spacing: 12) {
                    ForEach(SanctuaryTimeOfDay.allCases) { time in
                        TimeOptionButton(
                            time: time,
                            isSelected: selectedTime == time,
                            action: {
                                selectedTime = time
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Reset button
                Button(action: {
                    onReset()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Use Current Time")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Time Option Button

private struct TimeOptionButton: View {
    let time: SanctuaryTimeOfDay
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: time.primaryIcon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(time.primaryColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(time.primaryColor.opacity(0.15))
                    )

                // Labels
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(time.name.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)

                        Text("(\(time.liturgicalName))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Text(time.timeRange)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(time.primaryColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected
                        ? time.primaryColor.opacity(0.1)
                        : Color(uiColor: .secondarySystemGroupedBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? time.primaryColor.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Time-Aware Sanctuary") {
    NavigationStack {
        TimeAwareSanctuaryPage()
    }
}

#Preview("Time Picker") {
    TimePickerSheet(
        selectedTime: .constant(.dawn),
        onReset: {}
    )
}
