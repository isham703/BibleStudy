//
//  SermonRecordTab.swift
//  BibleStudy
//
//  Record tab content for sermon navigation.
//  Contains record and import buttons with optional onboarding prompt.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sermon Record Tab

struct SermonRecordTab: View {
    let isFirstTimeUser: Bool
    let hasSampleInLibrary: Bool

    // Actions
    let onRecordTap: () -> Void
    let onImportTap: () -> Void
    let onSeeExampleTap: () -> Void

    @State private var isAwakened = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Section header (outside card for tight tab connection)
            recordHeader
                .ceremonialAppear(isAwakened: isAwakened, delay: 0.08)

            // Card container
            VStack(spacing: Theme.Spacing.md) {
                // First-time user onboarding prompt
                if isFirstTimeUser {
                    onboardingPrompt
                        .ceremonialAppear(isAwakened: isAwakened, delay: 0.1)
                }

                // Primary: Record button
                recordButton
                    .ceremonialAppear(isAwakened: isAwakened, delay: isFirstTimeUser ? 0.15 : 0.1)

                // Reassurance text
                Text("Stop anytime. We'll generate a transcript + study guide.")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .ceremonialAppear(isAwakened: isAwakened, delay: isFirstTimeUser ? 0.18 : 0.13)

                // Divider with "or"
                orDivider
                    .ceremonialAppear(isAwakened: isAwakened, delay: isFirstTimeUser ? 0.2 : 0.15)

                // Secondary: Import button
                importButton
                    .ceremonialAppear(isAwakened: isAwakened, delay: isFirstTimeUser ? 0.22 : 0.17)

                // Footer hint
                footerHint
                    .padding(.top, Theme.Spacing.sm)
                    .ceremonialAppear(isAwakened: isAwakened, delay: isFirstTimeUser ? 0.25 : 0.2)

                // See example link (if sample exists in library)
                if hasSampleInLibrary {
                    seeExampleLink
                        .padding(.top, Theme.Spacing.md)
                        .ceremonialAppear(isAwakened: isAwakened, delay: isFirstTimeUser ? 0.28 : 0.23)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color("AppSurface").opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Color("AppDivider").opacity(0.5), lineWidth: Theme.Stroke.hairline)
            )
        }
        .onAppear {
            if reduceMotion {
                isAwakened = true
            } else {
                withAnimation(Theme.Animation.settle) {
                    isAwakened = true
                }
            }
        }
    }

    // MARK: - Record Header

    private var recordHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("RECORD NEW")
                .font(Typography.Editorial.sectionHeader)
                .tracking(Typography.Editorial.sectionTracking)
                .foregroundStyle(Color("TertiaryText"))
                .accessibilityLabel("Record new")

            if isFirstTimeUser {
                Text("Tap the button below to begin.")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Onboarding Prompt

    private var onboardingPrompt: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color("AccentBronze"))

            Text("Record Your First Sermon")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)

            Text("Capture any sermon, we'll create a searchable transcript and study guide.")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, Theme.Spacing.md)
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button(action: onRecordTap) {
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
            .shadow(color: Color("AppAccentAction").opacity(0.15), radius: 6, y: 2)
        }
        .buttonStyle(RecordButtonStyle())
        .accessibilityLabel("Begin recording sermon")
        .accessibilityHint("Double tap to start recording with your microphone")
    }

    // MARK: - Or Divider

    private var orDivider: some View {
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
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Import Button

    private var importButton: some View {
        Button(action: onImportTap) {
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
        .buttonStyle(RecordButtonStyle())
        .accessibilityLabel("Import audio file")
        .accessibilityHint("Double tap to select an audio file from your device")
    }

    // MARK: - Footer Hint

    private var footerHint: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "checkmark.circle")
                .font(Typography.Icon.xs)
            Text("MP3 / M4A / WAV · Up to 500MB")
        }
        .font(Typography.Command.caption)
        .foregroundStyle(Color("AppTextSecondary"))
    }

    // MARK: - See Example Link

    private var seeExampleLink: some View {
        Button(action: onSeeExampleTap) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "book.pages")
                    .font(Typography.Icon.sm)

                Text("See an example in Your Sermons")
                    .font(Typography.Command.caption)

                Image(systemName: "arrow.right")
                    .font(Typography.Icon.xxs)
            }
            .foregroundStyle(Color("AccentBronze"))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("See example sermon")
        .accessibilityHint("Switches to library tab to show sample sermon")
    }
}

// MARK: - Button Style

private struct RecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Record Tab - First Time User") {
    ScrollView {
        SermonRecordTab(
            isFirstTimeUser: true,
            hasSampleInLibrary: true,
            onRecordTap: { print("Record") },
            onImportTap: { print("Import") },
            onSeeExampleTap: { print("See example") }
        )
        .padding(Theme.Spacing.lg)
    }
    .background(Color("AppBackground"))
}

#Preview("Record Tab - Returning User") {
    ScrollView {
        SermonRecordTab(
            isFirstTimeUser: false,
            hasSampleInLibrary: false,
            onRecordTap: { print("Record") },
            onImportTap: { print("Import") },
            onSeeExampleTap: { print("See example") }
        )
        .padding(Theme.Spacing.lg)
    }
    .background(Color("AppBackground"))
}
