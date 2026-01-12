import SwiftUI

// MARK: - Prayer Generating Phase
// Displays animated loading state while prayer is being generated
// Portico-style with indeterminate shimmer progress

struct PrayerGeneratingPhase: View {
    let selectedCategory: PrayerCategory
    let intentionText: String
    let reduceMotion: Bool
    var onCancel: (() -> Void)?

    @State private var isAnimating = false
    @State private var showReassurance = false

    // Truncate intention for display (2 lines max)
    private var truncatedIntention: String {
        let trimmed = intentionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 80 {
            return String(trimmed.prefix(77)) + "..."
        }
        return trimmed
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Safe area padding + breathing room (Dynamic Island = 59pt)
            Spacer()
                .frame(height: 59 + Theme.Spacing.xl)

            // Animated columns - dramatic pulsing height animation
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    PulsingBar(
                        index: index,
                        isAnimating: isAnimating,
                        reduceMotion: reduceMotion
                    )
                }
            }
            .padding(.bottom, Theme.Spacing.sm)

            VStack(spacing: Theme.Spacing.md) {
                // Main status text
                Text("Crafting your prayer")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                // Time-based reassurance (appears after 2 seconds)
                if showReassurance {
                    Text("This may take a moment…")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // User's intention (no quotes, cleaner preview style)
                if !truncatedIntention.isEmpty {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Your intention:")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))

                        Text(truncatedIntention)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                // Category badge
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: selectedCategory.icon)
                        .font(Typography.Icon.sm)
                        .foregroundStyle(Color("AppAccentAction"))

                    Text(selectedCategory.rawValue)
                        .font(Typography.Command.label)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.subtle))
                )
            }

            // Cancel option with consequence info (tighter spacing)
            if let onCancel = onCancel {
                VStack(spacing: Theme.Spacing.xs) {
                    Button {
                        HapticService.shared.lightTap()
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(Typography.Command.label.weight(.medium))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(
                                Capsule()
                                    .stroke(Color.appDivider, lineWidth: Theme.Stroke.control)
                            )
                    }

                    Text("Your intention will be saved")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("TertiaryText"))
                }
                .padding(.top, Theme.Spacing.lg)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startAnimations()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Crafting your \(selectedCategory.rawValue.lowercased()) prayer for: \(truncatedIntention)")
        .accessibilityAddTraits(.updatesFrequently)
        .transition(.opacity)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Start bar animation immediately
        isAnimating = true

        // Show reassurance message after 2 seconds
        guard !reduceMotion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showReassurance = true
            }
        }
    }
}

// MARK: - Pulsing Bar Component

private struct PulsingBar: View {
    let index: Int
    let isAnimating: Bool
    let reduceMotion: Bool

    // Base heights for visual variety
    private var baseHeight: CGFloat {
        switch index {
        case 0: return 24
        case 1: return 36
        case 2: return 28
        default: return 30
        }
    }

    // Staggered animation delay for wave effect
    private var animationDelay: Double {
        Double(index) * 0.15
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color("AppAccentAction"))  // Use accent color for better visibility
            .frame(width: 6, height: reduceMotion ? baseHeight : (isAnimating ? baseHeight + 20 : baseHeight))
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(animationDelay),
                value: isAnimating
            )
    }
}

// MARK: - Preview

#Preview("Generating Phase") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
        PrayerGeneratingPhase(
            selectedCategory: .gratitude,
            intentionText: "I'm grateful for my family and the peace we share",
            reduceMotion: false,
            onCancel: {}
        )
    }
}
