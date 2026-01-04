import Foundation
import UserNotifications

// MARK: - Notification Service
// HIG-compliant notification management with user-controlled settings

@MainActor
@Observable
final class NotificationService: NSObject {
    // MARK: - Singleton
    static let shared = NotificationService()

    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()

    // Authorization state
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isAuthorized: Bool = false

    // User preferences (persisted)
    var dailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReminderEnabled, forKey: Keys.dailyReminderEnabled)
            Task { await updateDailyReminder() }
        }
    }

    var dailyReminderTime: Date {
        didSet {
            UserDefaults.standard.set(dailyReminderTime, forKey: Keys.dailyReminderTime)
            Task { await updateDailyReminder() }
        }
    }

    var streakReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(streakReminderEnabled, forKey: Keys.streakReminderEnabled)
            Task { await updateStreakReminder() }
        }
    }

    // MARK: - UserDefaults Keys
    private enum Keys {
        static let dailyReminderEnabled = "dailyReminderEnabled"
        static let dailyReminderTime = "dailyReminderTime"
        static let streakReminderEnabled = "streakReminderEnabled"
        static let hasRequestedPermission = "hasRequestedNotificationPermission"
    }

    // MARK: - Notification Identifiers
    private enum NotificationID {
        static let dailyReminder = "com.biblestudy.daily.reminder"
        static let streakReminder = "com.biblestudy.streak.reminder"
        static let achievementUnlocked = "com.biblestudy.achievement"
    }

    // MARK: - Initialization

    private override init() {
        // Load preferences
        self.dailyReminderEnabled = UserDefaults.standard.bool(forKey: Keys.dailyReminderEnabled)
        self.streakReminderEnabled = UserDefaults.standard.bool(forKey: Keys.streakReminderEnabled)

        // Default reminder time: 8:00 AM (but user can change)
        if let savedTime = UserDefaults.standard.object(forKey: Keys.dailyReminderTime) as? Date {
            self.dailyReminderTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        }

        super.init()

        // Set delegate
        notificationCenter.delegate = self

        // Check current authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Request notification permission (call contextually, not on first launch)
    /// Returns true if authorized
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            UserDefaults.standard.set(true, forKey: Keys.hasRequestedPermission)
            await checkAuthorizationStatus()

            if granted {
                // Set up default notifications
                await setupDefaultNotifications()
            }

            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    /// Whether we should prompt the user to enable notifications
    /// Call after first completed session (HIG compliant - contextual request)
    var shouldPromptForNotifications: Bool {
        let hasRequested = UserDefaults.standard.bool(forKey: Keys.hasRequestedPermission)
        return !hasRequested && authorizationStatus == .notDetermined
    }

    // MARK: - Daily Reminder

    /// Update daily reminder based on current settings
    func updateDailyReminder() async {
        // Remove existing
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.dailyReminder]
        )

        guard dailyReminderEnabled, isAuthorized else { return }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Time for Scripture"
        content.body = randomDailyMessage()
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        // Create trigger for user's selected time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dailyReminderTime)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        // Schedule
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyReminder,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }

    private func randomDailyMessage() -> String {
        let messages = [
            "A few minutes in God's Word can transform your day.",
            "Your daily verse is waiting for you.",
            "Continue your reading journey today.",
            "Build your streak with today's reading.",
            "Scripture has something for you today.",
            "Take a moment to reflect on God's Word.",
            "Your Bible study time awaits."
        ]
        return messages.randomElement() ?? messages[0]
    }

    // MARK: - Streak Reminder

    /// Update streak protection reminder
    func updateStreakReminder() async {
        // Remove existing
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.streakReminder]
        )

        guard streakReminderEnabled, isAuthorized else { return }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Protect Your Streak!"
        content.body = "Don't forget to read today to keep your streak going."
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"

        // Trigger at 8 PM if user hasn't read today
        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: NotificationID.streakReminder,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule streak reminder: \(error)")
        }
    }

    // MARK: - Setup

    /// Set up default notifications after authorization
    private func setupDefaultNotifications() async {
        // Enable daily reminder by default
        dailyReminderEnabled = true
        streakReminderEnabled = true

        await updateDailyReminder()
        await updateStreakReminder()

        // Register notification categories
        await registerCategories()
    }

    /// Register notification categories for actions
    private func registerCategories() async {
        // Daily reminder category with "Read Now" action
        let readAction = UNNotificationAction(
            identifier: "READ_NOW",
            title: "Read Now",
            options: [.foreground]
        )

        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [readAction],
            intentIdentifiers: [],
            options: []
        )

        // Streak reminder category
        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [readAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([dailyCategory, streakCategory])
    }

    // MARK: - One-time Notifications

    /// Send achievement unlocked notification
    func sendAchievementNotification(title: String, body: String) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "\(title): \(body)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.achievementUnlocked).\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send achievement notification: \(error)")
        }
    }

    // MARK: - Cancel Streak Reminder for Today

    /// Call when user completes reading for the day
    func cancelTodaysStreakReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.streakReminder]
        )

        // Reschedule for tomorrow
        Task {
            await updateStreakReminder()
        }
    }

    // MARK: - Clear All

    /// Remove all pending notifications
    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Clear badge count
    func clearBadge() async {
        try? await notificationCenter.setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show banner and sound even when app is open
        return [.banner, .sound]
    }

    /// Handle notification tap/action
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case "READ_NOW", UNNotificationDefaultActionIdentifier:
            // User tapped notification or "Read Now" action
            // Navigate to reading view (handled by app)
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .notificationTapped,
                    object: nil,
                    userInfo: ["action": "openReading"]
                )
            }
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let notificationTapped = Notification.Name("notificationTapped")
}

// MARK: - Notification Permission View

import SwiftUI

struct NotificationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationService = NotificationService.shared

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentGold.opacity(AppTheme.Opacity.lightMedium))
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.badge.fill")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(.system(size: AppTheme.IconSize.xxl))
                    .foregroundStyle(Color.accentGold)
            }

            // Title
            Text("Stay on Track")
                .font(Typography.UI.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryText)

            // Description
            Text("Get gentle reminders to help you build a consistent Bible reading habit.")
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            // Features
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                NotificationFeatureRow(
                    icon: "sun.max.fill",
                    text: "Daily reading reminders"
                )
                NotificationFeatureRow(
                    icon: "flame.fill",
                    text: "Streak protection alerts"
                )
                NotificationFeatureRow(
                    icon: "trophy.fill",
                    text: "Achievement celebrations"
                )
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()

            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                Button(action: enableNotifications) {
                    Text("Enable Notifications")
                        .font(Typography.UI.buttonLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(Color.accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }

                Button("Maybe Later") {
                    onComplete()
                }
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.secondaryText)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(Color.appBackground)
    }

    private func enableNotifications() {
        Task {
            await notificationService.requestAuthorization()
            onComplete()
        }
    }
}

private struct NotificationFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.UI.body)
                .foregroundStyle(Color.accentGold)
                .frame(width: AppTheme.IconContainer.small)

            Text(text)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)
        }
    }
}

// MARK: - Notification Settings View (for Settings screen)

struct NotificationSettingsView: View {
    @State private var notificationService = NotificationService.shared
    @State private var showingTimePicker = false

    var body: some View {
        List {
            Section {
                if notificationService.isAuthorized {
                    // Daily reminder toggle
                    Toggle(isOn: $notificationService.dailyReminderEnabled) {
                        Label("Daily Reminder", systemImage: "bell.fill")
                    }

                    // Reminder time picker
                    if notificationService.dailyReminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $notificationService.dailyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                    }

                    // Streak reminder toggle
                    Toggle(isOn: $notificationService.streakReminderEnabled) {
                        Label("Streak Protection", systemImage: "flame.fill")
                    }
                } else {
                    // Not authorized - show button to open settings
                    Button(action: openSettings) {
                        HStack {
                            Label("Enable Notifications", systemImage: "bell.badge")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if notificationService.isAuthorized {
                    Text("Daily reminders help you build a consistent reading habit. Streak protection alerts you before your streak expires.")
                } else {
                    Text("Enable notifications to receive daily reading reminders and streak protection alerts.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("Permission View") {
    NotificationPermissionView(onComplete: {})
}

#Preview("Settings View") {
    NavigationStack {
        NotificationSettingsView()
    }
}
