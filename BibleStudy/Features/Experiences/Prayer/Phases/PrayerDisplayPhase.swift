import SwiftUI

// MARK: - Prayer Display Phase
// Shows the generated prayer with actions (Copy, Share, Save)
// Portico-style prayer card with blue accents

struct PrayerDisplayPhase: View {
    let prayer: Prayer
    let selectedCategory: PrayerCategory
    let onCopy: () -> Void
    let onShare: () -> Void
    let onSave: () -> Void
    let onNewPrayer: () -> Void
    var onRegenerate: (() -> Void)?
    var onEditIntention: (() -> Void)?
    @State private var isRevealed = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.xl) {
                // Success indicator - account for Dynamic Island safe area
                successHeader
                    .padding(.top, 59 + Theme.Spacing.xl)

                // Prayer card
                prayerCard

                // Quick actions
                quickActions

                // Secondary actions
                secondaryActions

                // New prayer button
                newPrayerButton

                // Bottom breathing room
                Spacer()
                    .frame(height: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .onAppear {
            withAnimation(Theme.Animation.slowFade) {
                isRevealed = true
            }
        }
    }

    // MARK: - Success Header

    private var successHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.Icon.lg)
                .foregroundStyle(Color("FeedbackSuccess"))

            Text("Prayer Generated")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.1), value: isRevealed)
    }

    // MARK: - Prayer Card

    private var prayerCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Category badge
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: selectedCategory.icon)
                    .font(Typography.Icon.xs)
                    .foregroundStyle(Color("HighlightBlue"))

                Text(selectedCategory.rawValue)
                    .font(Typography.Editorial.label)
                    .tracking(Typography.Editorial.labelTracking)
                    .foregroundStyle(Color("TertiaryText"))
            }

            // Prayer content
            Text(prayer.content)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineSpacing(Typography.Scripture.bodyLineSpacing)

            // Closing
            Text(prayer.amen)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .fontWeight(.medium)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("HighlightBlue").opacity(0.25),
                            Color.appDivider
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: Theme.Stroke.hairline
                )
        )
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 20)
        .animation(Theme.Animation.slowFade.delay(0.15), value: isRevealed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your generated prayer: \(prayer.content). \(prayer.amen)")
        .accessibilityHint("Use the buttons below to copy, share, or save this prayer")
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: Theme.Spacing.md) {
            ActionButton(icon: "doc.on.doc", label: "Copy", action: onCopy)
            ActionButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
            ActionButton(icon: "bookmark", label: "Save", isSuccessAction: true, action: onSave)
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.25), value: isRevealed)
    }

    // MARK: - Secondary Actions

    private var secondaryActions: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let onRegenerate = onRegenerate {
                Button {
                    onRegenerate()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(Typography.Icon.sm)
                        Text("Regenerate")
                            .font(Typography.Command.label.weight(.medium))
                    }
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        Capsule()
                            .stroke(Color.appDivider, lineWidth: Theme.Stroke.control)
                    )
                }
            }

            if let onEditIntention = onEditIntention {
                Button {
                    onEditIntention()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "pencil")
                            .font(Typography.Icon.sm)
                        Text("Edit Intention")
                            .font(Typography.Command.label.weight(.medium))
                    }
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        Capsule()
                            .stroke(Color.appDivider, lineWidth: Theme.Stroke.control)
                    )
                }
            }
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.3), value: isRevealed)
    }

    // MARK: - New Prayer Button

    private var newPrayerButton: some View {
        Button(action: {
            HapticService.shared.lightTap()
            onNewPrayer()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "plus")
                    .font(Typography.Icon.sm)
                Text("New Prayer")
                    .font(Typography.Command.cta)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(Color("AppAccentAction"))
            )
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(Theme.Animation.slowFade.delay(0.35), value: isRevealed)
        .accessibilityLabel("Create new prayer")
        .accessibilityHint("Double tap to start over with a new prayer")
    }
}

// MARK: - Preview

#Preview("Display Phase") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
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
            onNewPrayer: {},
            onRegenerate: {},
            onEditIntention: {}
        )
    }
}
