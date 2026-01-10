import SwiftUI

// MARK: - Usage Row
// Displays usage statistics with progress bar for subscription limits

struct UsageRow: View {
    let label: String
    let used: Int
    let total: Int
    let icon: String
    let iconColor: Color
    let onTap: (() -> Void)?

    @State private var animatedProgress: Double = 0
    @State private var isPulsing = false

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(1.0, Double(used) / Double(total))
    }

    private var isExhausted: Bool {
        used >= total
    }

    private var remaining: Int {
        max(0, total - used)
    }

    init(
        label: String,
        used: Int,
        total: Int,
        icon: String,
        iconColor: Color = .accentIndigo,
        onTap: (() -> Void)? = nil
    ) {
        self.label = label
        self.used = used
        self.total = total
        self.icon = icon
        self.iconColor = iconColor
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                iconView

                // Label and progress
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        Text(label)
                            .font(Typography.Command.subheadline)
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        // Usage count
                        usageLabel
                    }

                    // Progress bar
                    progressBar
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .onAppear {
            withAnimation(Theme.Animation.slowFade.delay(0.1)) {
                animatedProgress = progress
            }
            if isExhausted && !Theme.Animation.isReduceMotionEnabled {
                startPulseAnimation()
            }
        }
        .onChange(of: used) { _, _ in
            withAnimation(Theme.Animation.settle) {
                animatedProgress = progress
            }
            if isExhausted && !Theme.Animation.isReduceMotionEnabled {
                startPulseAnimation()
            } else {
                isPulsing = false
            }
        }
    }

    // MARK: - Icon

    private var iconView: some View {
        Image(systemName: icon)
            .font(Typography.Icon.xs.weight(.medium))
            .foregroundStyle(isExhausted ? Color.error : iconColor)
            .frame(width: 24, height: 24)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input + 1)
                    .fill((isExhausted ? Color.error : iconColor).opacity(Theme.Opacity.subtle + 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input + 1)
                    .stroke(
                        (isExhausted ? Color.error : iconColor).opacity(isPulsing ? Theme.Opacity.heavy : 0),
                        lineWidth: Theme.Stroke.control
                    )
                    .blur(radius: isPulsing ? 4 : 0)
            )
            .animation(
                isPulsing ? Theme.Animation.fade : .default,
                value: isPulsing
            )
    }

    // MARK: - Usage Label

    private var usageLabel: some View {
        HStack(spacing: 2) {
            if isExhausted {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(Typography.Icon.xxs)
                    .foregroundStyle(Color.error)
            }

            Text(isExhausted ? "Limit reached" : "\(remaining) remaining")
                .font(Typography.Command.meta.monospacedDigit())
                .foregroundStyle(isExhausted ? Color.error : Color.secondaryText)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color.divider.opacity(Theme.Opacity.medium))

                // Filled portion
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(progressGradient)
                    .frame(width: geometry.size.width * animatedProgress)
            }
        }
        .frame(height: 3)
    }

    private var progressGradient: LinearGradient {
        if isExhausted {
            return LinearGradient(
                colors: [Color.error.opacity(Theme.Opacity.pressed), Color.error],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if progress > 0.66 {
            return LinearGradient(
                colors: [Color.warning.opacity(Theme.Opacity.pressed), Color.warning],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [iconColor.opacity(Theme.Opacity.overlay), iconColor],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Pulse Animation

    private func startPulseAnimation() {
        isPulsing = true
    }
}

// MARK: - Usage Statistics View
// Groups multiple usage rows with a header and reset countdown

struct UsageStatisticsView: View {
    @Environment(\.colorScheme) private var colorScheme
    let aiInsightsUsed: Int
    let aiInsightsTotal: Int
    let highlightsUsed: Int
    let highlightsTotal: Int
    let notesUsed: Int
    let notesTotal: Int
    let onUpgrade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Text("Today's Usage")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)

                Spacer()

                // Reset countdown
                resetCountdown
            }

            // Usage rows
            VStack(spacing: Theme.Spacing.sm) {
                UsageRow(
                    label: "AI Insights",
                    used: aiInsightsUsed,
                    total: aiInsightsTotal,
                    icon: "sparkles",
                    iconColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)),
                    onTap: { if aiInsightsUsed >= aiInsightsTotal { onUpgrade() } }
                )

                // Highlights are now unlimited for all users - no need to show usage
                // UsageRow removed to avoid confusion

                UsageRow(
                    label: "Notes",
                    used: notesUsed,
                    total: notesTotal,
                    icon: "note.text",
                    iconColor: Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)),
                    onTap: { if notesUsed >= notesTotal { onUpgrade() } }
                )
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.appBackground)
        )
    }

    // MARK: - Reset Countdown

    private var resetCountdown: some View {
        HStack(spacing: 2) {
            Image(systemName: "arrow.counterclockwise")
                .font(Typography.Icon.xxs)

            Text("Resets \(resetTimeText)")
                .font(Typography.Command.meta)
        }
        .foregroundStyle(Color.tertiaryText)
    }

    private var resetTimeText: String {
        let calendar = Calendar.current
        let now = Date()

        // Calculate time until midnight
        guard let midnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) else {
            return "at midnight"
        }

        let components = calendar.dateComponents([.hour, .minute], from: now, to: midnight)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "in \(minutes)m"
        } else {
            return "soon"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct UsageStatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Partial usage
            IlluminatedSettingsCard(title: "Subscription", icon: "crown.fill", showDivider: false) {
                UsageStatisticsView(
                    aiInsightsUsed: 2,
                    aiInsightsTotal: 3,
                    highlightsUsed: 1,
                    highlightsTotal: 3,
                    notesUsed: 0,
                    notesTotal: 2,
                    onUpgrade: {}
                )
            }

            // Exhausted limits
            IlluminatedSettingsCard(title: "Subscription", icon: "crown.fill", showDivider: false) {
                UsageStatisticsView(
                    aiInsightsUsed: 3,
                    aiInsightsTotal: 3,
                    highlightsUsed: 3,
                    highlightsTotal: 3,
                    notesUsed: 2,
                    notesTotal: 2,
                    onUpgrade: {}
                )
            }
        }
        .padding()
        .background(Color.appBackground)
        .previewDisplayName("Usage Statistics")
    }
}

struct UsageRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.md) {
            UsageRow(label: "AI Insights", used: 0, total: 3, icon: "sparkles")
            UsageRow(label: "AI Insights", used: 1, total: 3, icon: "sparkles")
            UsageRow(label: "AI Insights", used: 2, total: 3, icon: "sparkles")
            UsageRow(label: "AI Insights", used: 3, total: 3, icon: "sparkles")
        }
        .padding()
        .background(Color.surfaceBackground)
        .previewDisplayName("Usage Row States")
    }
}
#endif
