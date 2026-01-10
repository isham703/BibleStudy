import SwiftUI

// MARK: - Prayer Display Phase
// Shows the generated prayer with actions (Copy, Share, Save)
// Features drop cap styling and category attribution

struct PrayerDisplayPhase: View {
    let prayer: Prayer
    let selectedCategory: PrayerCategory
    let onCopy: () -> Void
    let onShare: () -> Void
    let onSave: () -> Void
    let onNewPrayer: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            compactHeader

            // Generated Prayer Section
            generatedPrayerSection

            Spacer(minLength: 100)

            // New Prayer Button
            newPrayerButton
        }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)))
                .frame(height: Theme.Stroke.hairline)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xxl + Theme.Spacing.md)

            Text("YOUR PRAYER")
                .font(Typography.Editorial.label)
                .tracking(Typography.Editorial.labelTracking)
                .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Generated Prayer Section

    private var generatedPrayerSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Prayer Card
            VStack(spacing: Theme.Spacing.lg) {
                // Drop cap and text
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    // Get first letter for drop cap
                    let firstLetter = String(prayer.content.prefix(1))
                    let remainingText = String(prayer.content.dropFirst())

                    Text(firstLetter)
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.decorativeGold.opacity(0.15), Color.accentBronze],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 48)

                    Text(remainingText)
                        .font(Typography.Scripture.body)
                        .foregroundColor(Color.textPrimary)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Amen
                HStack {
                    Spacer()
                    Text(prayer.amen)
                        .font(Typography.Scripture.body)
                        .italic()
                        .foregroundColor(Color.accentBronze)
                }

                // Category indicator
                HStack {
                    Spacer()
                    HStack(spacing: Theme.Spacing.xs + 2) {
                        Text("—")
                        Text("A prayer for \(selectedCategory.rawValue.lowercased())")
                    }
                    .font(Typography.Scripture.body)
                    .italic()
                    .foregroundColor(Color.accentBronze.opacity(Theme.Opacity.pressed))
                }
            }
            .padding(Theme.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .fill(Color.surfaceRaised.opacity(Theme.Opacity.pressed))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.accentBronze.opacity(Theme.Opacity.medium),
                                        Color.feedbackWarning.opacity(Theme.Opacity.light)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: Theme.Stroke.hairline
                            )
                    )
            )
            .padding(.horizontal, Theme.Spacing.lg)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Your generated prayer: \(prayer.content). \(prayer.amen)")
            .accessibilityHint("Use the buttons below to copy, share, or save this prayer")

            // Action Buttons
            HStack(spacing: Theme.Spacing.lg) {
                ActionButton(icon: "doc.on.doc", label: "Copy", action: onCopy)
                ActionButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
                ActionButton(icon: "bookmark", label: "Save", isSuccessAction: true) { onSave() }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - New Prayer Button

    private var newPrayerButton: some View {
        Button(action: {
            HapticService.shared.lightTap()
            onNewPrayer()
        }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "plus")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Command.callout)
                Text("New Prayer")
                    .font(Typography.Scripture.heading)
            }
            .foregroundColor(Color.accentBronze)
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                Capsule()
                    .fill(Color.surfaceRaised)
                    .overlay(
                        Capsule()
                            .stroke(Color.accentBronze.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.hairline)
                    )
            )
        }
        .accessibilityLabel("Create new prayer")
        .accessibilityHint("Double tap to start over with a new prayer")
        .padding(.bottom, Theme.Spacing.xxl + Theme.Spacing.sm)
    }
}

// MARK: - Preview

#Preview("Display Phase") {
    ZStack {
        Color.surfaceParchment.ignoresSafeArea()
        PrayerDisplayPhase(
            prayer: Prayer(
                category: .gratitude,
                content: "Lord, as the deer pants for streams of water, so my soul longs for You. In this moment of stillness, I bring before You the burdens I carry and the hopes I hold.",
                amen: "Amen.",
                userContext: "I'm grateful for today"
            ),
            selectedCategory: .gratitude,
            onCopy: {},
            onShare: {},
            onSave: {},
            onNewPrayer: {}
        )
    }
}
