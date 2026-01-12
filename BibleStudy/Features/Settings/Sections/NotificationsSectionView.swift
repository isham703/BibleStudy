import SwiftUI

// MARK: - Notifications Section View
// Notification settings with expandable cards

struct NotificationsSectionView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showTimePicker = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SettingsCard(title: "Notifications", icon: "bell.fill") {
            if viewModel.notificationsAuthorized {
                authorizedContent
            } else {
                permissionPrompt
            }
        }
    }

    // MARK: - Authorized Content

    private var authorizedContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Daily Reading Reminder
            VStack(spacing: Theme.Spacing.sm) {
                SettingsToggle(
                    isOn: $viewModel.dailyReminderEnabled,
                    label: "Daily Reading Reminder",
                    description: nil,
                    icon: "bell.fill",
                    iconColor: Color("AppAccentAction")
                )

                if viewModel.dailyReminderEnabled {
                    timePickerRow
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(Theme.Animation.settle, value: viewModel.dailyReminderEnabled)

            SettingsDivider()

            // Streak Protection Reminder
            VStack(spacing: Theme.Spacing.sm) {
                SettingsToggle(
                    isOn: $viewModel.streakReminderEnabled,
                    label: "Streak Protection",
                    description: nil,
                    icon: "flame.fill",
                    iconColor: .feedbackError
                )

                if viewModel.streakReminderEnabled {
                    streakReminderInfo
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(Theme.Animation.settle, value: viewModel.streakReminderEnabled)
        }
    }

    private var timePickerRow: some View {
        HStack {
            Image(systemName: "clock")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(width: 28)

            Text("Reminder Time")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))

            Spacer()

            DatePicker(
                "",
                selection: $viewModel.dailyReminderTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(Color("AppAccentAction"))
        }
        .padding(.leading, Theme.Spacing.xxl - 12) // Align with toggle content
    }

    private var streakReminderInfo: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle")
                .font(Typography.Icon.xs)
                .foregroundStyle(Color("TertiaryText"))

            Text("We'll remind you at 8 PM if you haven't read today.")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
        }
        .padding(.leading, Theme.Spacing.xxl - 12) // Align with toggle content
    }

    // MARK: - Permission Prompt

    private var permissionPrompt: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle + 0.02))
                    .frame(width: 64, height: 64)

                Image(systemName: "bell.badge")
                    .font(Typography.Icon.xl.weight(.light))
                    .foregroundStyle(Color("AppAccentAction"))
            }

            // Description
            VStack(spacing: Theme.Spacing.xs) {
                Text("Stay on Track")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("Enable notifications to receive daily reading reminders and streak protection alerts.")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }

            // Enable button
            Button(action: {
                Task {
                    await viewModel.requestNotificationPermission()
                }
            }) {
                Text("Enable Notifications")
                    .font(Typography.Command.cta)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Color("AppAccentAction"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            }
        }
        .padding(.vertical, Theme.Spacing.md)
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
