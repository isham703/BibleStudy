import SwiftUI

// MARK: - Notifications Section View
// Notification settings with expandable cards

struct NotificationsSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showTimePicker = false

    var body: some View {
        IlluminatedSettingsCard(title: "Notifications", icon: "bell.fill") {
            if viewModel.notificationsAuthorized {
                authorizedContent
            } else {
                permissionPrompt
            }
        }
    }

    // MARK: - Authorized Content

    private var authorizedContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Daily Reading Reminder
            VStack(spacing: AppTheme.Spacing.sm) {
                IlluminatedToggle(
                    isOn: $viewModel.dailyReminderEnabled,
                    label: "Daily Reading Reminder",
                    description: nil,
                    icon: "bell.fill",
                    iconColor: .scholarAccent
                )

                if viewModel.dailyReminderEnabled {
                    timePickerRow
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(AppTheme.Animation.unfurl, value: viewModel.dailyReminderEnabled)

            SettingsDivider()

            // Streak Protection Reminder
            VStack(spacing: AppTheme.Spacing.sm) {
                IlluminatedToggle(
                    isOn: $viewModel.streakReminderEnabled,
                    label: "Streak Protection",
                    description: nil,
                    icon: "flame.fill",
                    iconColor: .vermillion
                )

                if viewModel.streakReminderEnabled {
                    streakReminderInfo
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(AppTheme.Animation.unfurl, value: viewModel.streakReminderEnabled)
        }
    }

    private var timePickerRow: some View {
        HStack {
            Image(systemName: "clock")
                .font(Typography.UI.iconSm)
                .foregroundStyle(Color.secondaryText)
                .frame(width: 28)

            Text("Reminder Time")
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.secondaryText)

            Spacer()

            DatePicker(
                "",
                selection: $viewModel.dailyReminderTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(Color.scholarAccent)
        }
        .padding(.leading, AppTheme.Spacing.xxxl - 12) // Align with toggle content
    }

    private var streakReminderInfo: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "info.circle")
                .font(Typography.UI.iconXs)
                .foregroundStyle(Color.tertiaryText)

            Text("We'll remind you at 8 PM if you haven't read today.")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.leading, AppTheme.Spacing.xxxl - 12) // Align with toggle content
    }

    // MARK: - Permission Prompt

    private var permissionPrompt: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle + 0.02))
                    .frame(width: 64, height: 64)

                Image(systemName: "bell.badge")
                    .font(.system(size: Typography.Scale.xl + 6, weight: .light))
                    .foregroundStyle(Color.scholarAccent)
            }

            // Description
            VStack(spacing: AppTheme.Spacing.xs) {
                Text("Stay on Track")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)

                Text("Enable notifications to receive daily reading reminders and streak protection alerts.")
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Enable button
            Button(action: {
                Task {
                    await viewModel.requestNotificationPermission()
                }
            }) {
                Text("Enable Notifications")
                    .font(Typography.UI.buttonLabel)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(Color.scholarAccent)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }
}

// MARK: - Preview

#Preview("Notifications Section") {
    ScrollView {
        NotificationsSectionView(viewModel: SettingsViewModel())
            .padding()
    }
    .background(Color.appBackground)
}
