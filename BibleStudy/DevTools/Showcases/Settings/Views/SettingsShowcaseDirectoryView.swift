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
                    VStack(spacing: AppTheme.Spacing.xl) {
                        headerSection

                        variantCardsGrid

                        footerSection
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.xl)
                    .padding(.bottom, AppTheme.Spacing.xxxl)
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
                    Color.divineGold.opacity(0.03),
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
        VStack(spacing: AppTheme.Spacing.md) {
            // Ornamental top accent
            OrnamentalDivider(style: .simple)
                .frame(width: 60)
                .foregroundStyle(Color.divineGold.opacity(0.6))

            Text("Settings Options")
                .font(.custom("Cinzel-Regular", size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "F5E6B8"),
                            Color.divineGold,
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
                .padding(.top, AppTheme.Spacing.xs)
        }
        .padding(.bottom, AppTheme.Spacing.lg)
    }

    // MARK: - Variant Cards Grid

    private var variantCardsGrid: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
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
        VStack(spacing: AppTheme.Spacing.md) {
            OrnamentalDivider(style: .flourish)
                .frame(width: 120)
                .foregroundStyle(Color.divineGold.opacity(0.3))

            Text("Tap any card to view the full design")
                .font(Typography.footnote)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.top, AppTheme.Spacing.xl)
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
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.divineGold.opacity(isHovered ? 0.5 : 0.15),
                                Color.divineGold.opacity(isHovered ? 0.3 : 0.05),
                                Color.divineGold.opacity(isHovered ? 0.5 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: isHovered ? Color.divineGold.opacity(0.15) : Color.black.opacity(0.3),
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
                .padding(AppTheme.Spacing.lg)
        }
        .frame(height: 160)
    }

    private var infoSection: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
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
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.divineGold)
                .padding(AppTheme.Spacing.sm)
                .background(
                    Circle()
                        .fill(Color.divineGold.opacity(0.1))
                )
        }
        .padding(AppTheme.Spacing.lg)
    }

    private var cardBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: "1A1816"),
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
        VStack(spacing: AppTheme.Spacing.sm) {
            // Mini floating cards
            HStack(spacing: AppTheme.Spacing.sm) {
                previewCard
                previewCard
            }
            HStack(spacing: AppTheme.Spacing.sm) {
                previewCard
                previewCard
            }
        }
    }

    private var previewCard: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.white.opacity(0.05))
            .frame(height: 40)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.divineGold.opacity(0.2), lineWidth: 0.5)
            }
    }
}

struct SacredScrollPreview: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 28)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
    }
}

struct DivineHubPreview: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Center hub
            Circle()
                .fill(Color.divineGold.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.divineGold)
                }

            // Spokes
            HStack(spacing: AppTheme.Spacing.xl) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.05))
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
