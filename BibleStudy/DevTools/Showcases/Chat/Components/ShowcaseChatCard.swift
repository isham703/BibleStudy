import SwiftUI

// MARK: - Showcase Chat Card
// Card component for displaying chat variants in the directory

struct ShowcaseChatCard<Destination: View>: View {
    let variant: ChatVariant
    let destination: () -> Destination

    @State private var isPressed = false

    var body: some View {
        NavigationLink(destination: destination()) {
            cardContent
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.settle, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview area with gradient
            previewSection

            // Content area
            contentSection
        }
        .background(ChatPalette.Directory.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(ChatPalette.Directory.divider, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(Theme.Opacity.light), radius: 12, y: 6)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: variant.previewGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Chat preview mockup
            HStack(alignment: .bottom, spacing: 12) {
                // AI message preview
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(previewBubbleColor)
                        .frame(width: 140, height: 32)

                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(previewBubbleColor)
                        .frame(width: 100, height: 24)
                }

                Spacer()

                // User message preview
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(variant.accentColor.opacity(Theme.Opacity.pressed))
                    .frame(width: 80, height: 28)
            }
            .padding(20)
        }
        .frame(height: 100)
    }

    private var previewBubbleColor: Color {
        switch variant {
        case .minimalStudio:
            return Color.white.opacity(Theme.Opacity.high)
        case .scholarlyCompanion:
            return Color.white.opacity(Theme.Opacity.high)
        case .warmSanctuary:
            return Color.white.opacity(Theme.Opacity.divider)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 10) {
                Image(systemName: variant.icon)
                    .font(Typography.Icon.base)
                    .foregroundStyle(variant.accentColor)
                    .frame(width: 36, height: 36)
                    .background(variant.accentColor.opacity(Theme.Opacity.divider))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))

                VStack(alignment: .leading, spacing: 2) {
                    Text(variant.title)
                        .font(Typography.Command.headline)
                        .foregroundStyle(ChatPalette.Directory.primaryText)

                    Text(variant.subtitle)
                        .font(Typography.Command.meta)
                        .foregroundStyle(ChatPalette.Directory.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.Icon.sm)
                    .foregroundStyle(ChatPalette.Directory.tertiaryText)
            }

            // Tags
            HStack(spacing: 8) {
                ForEach(variant.tags, id: \.self) { tag in
                    Text(tag)
                        .font(Typography.Icon.xxs.weight(.medium))
                        .foregroundStyle(ChatPalette.Directory.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(ChatPalette.Directory.elevated)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ChatPalette.Directory.background
            .ignoresSafeArea()

        VStack(spacing: 20) {
            ForEach(ChatVariant.allCases) { variant in
                ShowcaseChatCard(variant: variant) {
                    Text("Destination")
                }
            }
        }
        .padding()
    }
}
