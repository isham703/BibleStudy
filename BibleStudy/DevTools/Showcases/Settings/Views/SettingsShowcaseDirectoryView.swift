import SwiftUI

// MARK: - Settings Showcase Directory
/// Main directory screen displaying all available settings page variations
/// for team members and stakeholders to compare design approaches.

struct SettingsShowcaseDirectory: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedVariant: SettingsVariant?
    @State private var hoveredCard: SettingsVariant?
    @Namespace private var heroAnimation

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        headerSection

                        variantCardsGrid

                        footerSection
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
            .navigationDestination(item: $selectedVariant) { variant in
                variant.destinationView
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "0D0C0B"),
                Color(hex: "141210"),
                Color(hex: "0D0C0B")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            // Subtle ambient gold glow at top
            RadialGradient(
                colors: [
                    Color.accentBronze.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Ornamental top accent
            Rectangle()
                .fill(Color.accentBronze.opacity(Theme.Opacity.tertiary))
                .frame(width: 60, height: Theme.Stroke.hairline)

            Text("Settings Options")
                .font(.custom("Cinzel-Regular", size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.decorativeCream,
                            Color.accentBronze,
                            Color(hex: "C9943D")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .kerning(2)

            Text("Design Directory")
                .font(Typography.caption)
                .foregroundStyle(Color.tertiaryText)
                .textCase(.uppercase)
                .kerning(3)

            Text("Compare settings page variations to find the perfect design for Bible Study")
                .font(Typography.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.Spacing.xs)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    // MARK: - Variant Cards Grid

    private var variantCardsGrid: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ForEach(SettingsVariant.allCases) { variant in
                VariantCard(
                    variant: variant,
                    isHovered: hoveredCard == variant,
                    onTap: { selectedVariant = variant }
                )
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveredCard = isHovered ? variant : nil
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(Color.accentBronze.opacity(Theme.Opacity.subtle))
                .frame(width: 120, height: Theme.Stroke.hairline)

            Text("Tap any card to view the full design")
                .font(Typography.footnote)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

// MARK: - Variant Card Component

struct VariantCard: View {
    let variant: SettingsVariant
    let isHovered: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Preview area
                previewSection

                // Info section
                infoSection
            }
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.accentBronze.opacity(isHovered ? 0.5 : 0.15),
                                Color.accentBronze.opacity(isHovered ? 0.3 : 0.05),
                                Color.accentBronze.opacity(isHovered ? 0.5 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isHovered ? Color.accentBronze.opacity(Theme.Opacity.divider) : Color.black.opacity(Theme.Opacity.subtle),
                radius: isHovered ? 20 : 10,
                y: isHovered ? 8 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }

    private var previewSection: some View {
        ZStack {
            // Preview background gradient
            LinearGradient(
                colors: variant.previewColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Preview content hint
            variant.previewContent
                .padding(Theme.Spacing.lg)
        }
        .frame(height: 160)
    }

    private var infoSection: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(variant.title)
                    .font(.custom("Cinzel-Regular", size: 18))
                    .foregroundStyle(Color.primaryText)

                Text(variant.subtitle)
                    .font(Typography.footnote)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            // Arrow indicator
            Image(systemName: "arrow.right")
                .font(Typography.Icon.sm)
                .foregroundStyle(Color.accentBronze)
                .padding(Theme.Spacing.sm)
                .background(
                    Circle()
                        .fill(Color.accentBronze.opacity(Theme.Opacity.overlay))
                )
        }
        .padding(Theme.Spacing.lg)
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color.surfaceCharcoal,
                Color(hex: "151311")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Settings Variant Model

enum SettingsVariant: String, CaseIterable, Identifiable, Hashable {
    case floatingSanctuary
    case sacredScroll
    case divineHub

    var id: String { rawValue }

    var title: String {
        switch self {
        case .floatingSanctuary: return "Floating Sanctuary"
        case .sacredScroll: return "Sacred Scroll"
        case .divineHub: return "Divine Hub"
        }
    }

    var subtitle: String {
        switch self {
        case .floatingSanctuary:
            return "Elevated cards with ambient glow, grouped by context with floating navigation"
        case .sacredScroll:
            return "Continuous scroll with parallax sections and immersive full-width controls"
        case .divineHub:
            return "Hub-and-spoke navigation with bold iconography and quick-access toggles"
        }
    }

    var previewColors: [Color] {
        switch self {
        case .floatingSanctuary:
            return [Color(hex: "1A1614"), Color(hex: "0F0E0C")]
        case .sacredScroll:
            return [Color(hex: "14110F"), Color(hex: "1F1A16")]
        case .divineHub:
            return [Color(hex: "0D0B0A"), Color(hex: "171412")]
        }
    }

    @ViewBuilder
    var previewContent: some View {
        switch self {
        case .floatingSanctuary:
            FloatingSanctuaryPreview()
        case .sacredScroll:
            SacredScrollPreview()
        case .divineHub:
            DivineHubPreview()
        }
    }

    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .floatingSanctuary:
            FloatingSanctuarySettings()
        case .sacredScroll:
            SacredScrollSettings()
        case .divineHub:
            DivineHubSettings()
        }
    }
}

// MARK: - Preview Components

struct FloatingSanctuaryPreview: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Mini floating cards
            HStack(spacing: Theme.Spacing.sm) {
                previewCard
                previewCard
            }
            HStack(spacing: Theme.Spacing.sm) {
                previewCard
                previewCard
            }
        }
    }

    private var previewCard: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.tag)
            .fill(Color.white.opacity(Theme.Opacity.faint))
            .frame(height: 40)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .strokeBorder(Color.accentBronze.opacity(Theme.Opacity.light), lineWidth: 0.5)
            }
    }
}

struct SacredScrollPreview: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color.white.opacity(Theme.Opacity.faint))
                    .frame(height: 28)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
    }
}

struct DivineHubPreview: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Center hub
            Circle()
                .fill(Color.accentBronze.opacity(Theme.Opacity.light))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "gearshape.fill")
                        .font(Typography.Command.title3)
                        .foregroundStyle(Color.accentBronze)
                }

            // Spokes
            HStack(spacing: Theme.Spacing.xl) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.white.opacity(Theme.Opacity.faint))
                        .frame(width: 30, height: 30)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsShowcaseDirectory()
}
