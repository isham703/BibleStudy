//
//  SampleSermonCard.swift
//  BibleStudy
//
//  Featured card for the bundled sample sermon.
//  "SAMPLE" badge, dismiss affordance, tap to explore output.
//

import SwiftUI

// MARK: - Sample Sermon Card

struct SampleSermonCard: View {
    let onTap: () -> Void
    let onDismiss: () -> Void

    @State private var isPressed = false
    @State private var dragOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        cardContent
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(cardBorder)
            .offset(x: dragOffset)
            .opacity(dragOpacity)
            .gesture(swipeGesture)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(Theme.Animation.settle, value: isPressed)
            .animation(Theme.Animation.settle, value: dragOffset)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        Button {
            HapticService.shared.lightTap()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header: Badge + Dismiss
                HStack {
                    sampleBadge

                    Spacer()

                    dismissButton
                }

                // Title - quiet weight to not compete with primary CTA
                Text(SampleSermonService.shared.sampleTitle)
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)

                // Metadata
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Typography.Icon.xs)
                        .foregroundStyle(Color("FeedbackSuccess"))

                    Text(SampleSermonService.shared.sampleDuration)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.appTextSecondary)

                    Text("•")
                        .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

                    Text(SampleSermonService.shared.sampleScriptureRange)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                // Call to action - clearer outcome description
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Explore transcript + study guide")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AccentBronze"))

                    Image(systemName: "arrow.right")
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color("AccentBronze"))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
        }
        .buttonStyle(SampleCardButtonStyle(isPressed: $isPressed))
    }

    // MARK: - Components

    private var sampleBadge: some View {
        Text("SAMPLE")
            .font(Typography.Editorial.label)
            .tracking(Typography.Editorial.labelTracking)
            .foregroundStyle(Color("AccentBronze"))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .fill(Color("AccentBronze").opacity(Theme.Opacity.overlay))
            )
    }

    private var dismissButton: some View {
        Button {
            HapticService.shared.selectionChanged()
            onDismiss()
        } label: {
            Text("Hide")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.appTextSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        Color("AppSurface")
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .stroke(
                Color("AccentBronze").opacity(Theme.Opacity.divider),
                lineWidth: Theme.Stroke.hairline
            )
    }

    // MARK: - Swipe Gesture (Secondary Dismiss)

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Only track leftward drags with clear horizontal intent
                if abs(value.translation.width) > abs(value.translation.height) * 2,
                   value.translation.width < 0 {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                // Dismiss if dragged far enough left
                if abs(value.translation.width) > abs(value.translation.height) * 2,
                   value.translation.width < -80 {
                    HapticService.shared.selectionChanged()
                    onDismiss()
                } else {
                    dragOffset = 0
                }
            }
    }

    private var dragOpacity: Double {
        let maxDrag: CGFloat = 120
        let progress = min(abs(dragOffset) / maxDrag, 1.0)
        return 1.0 - (progress * 0.4)
    }
}

// MARK: - Button Style

private struct SampleCardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("Sample Sermon Card") {
    ZStack {
        Color("AppBackground")
            .ignoresSafeArea()

        VStack(spacing: Theme.Spacing.lg) {
            SampleSermonCard(
                onTap: { print("Tapped sample") },
                onDismiss: { print("Dismissed sample") }
            )
            .padding(.horizontal, Theme.Spacing.lg)

            Text("Swipe left or tap Hide to dismiss")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.appTextSecondary)
        }
    }
    .preferredColorScheme(.dark)
}
