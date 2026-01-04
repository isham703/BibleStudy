import SwiftUI

// MARK: - Ornamental Divider Style
// Different decorative divider styles for manuscript aesthetics

enum OrnamentalDividerStyle: String, CaseIterable {
    case simple          // Clean horizontal line
    case manuscript      // Diamond/lozenge pattern
    case celtic          // Celtic knot-inspired
    case floral          // Floral/vine motifs
    case geometric       // Geometric pattern
    case flourish        // Calligraphic flourishes
    case chapterUnderline // Decorative chapter underline
    case sectionBreak    // Section break (three dots/symbols)

    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .manuscript: return "Manuscript"
        case .celtic: return "Celtic"
        case .floral: return "Floral"
        case .geometric: return "Geometric"
        case .flourish: return "Flourish"
        case .chapterUnderline: return "Chapter Underline"
        case .sectionBreak: return "Section Break"
        }
    }
}

// MARK: - Ornamental Divider View

struct OrnamentalDivider: View {
    let style: OrnamentalDividerStyle
    let color: Color
    let width: CGFloat?

    @Environment(\.colorScheme) private var colorScheme

    init(
        style: OrnamentalDividerStyle = .manuscript,
        color: Color = Color.divineGold,
        width: CGFloat? = nil
    ) {
        self.style = style
        self.color = color
        self.width = width
    }

    var body: some View {
        Group {
            switch style {
            case .simple:
                simpleDivider
            case .manuscript:
                manuscriptDivider
            case .celtic:
                celticDivider
            case .floral:
                floralDivider
            case .geometric:
                geometricDivider
            case .flourish:
                flourishDivider
            case .chapterUnderline:
                chapterUnderlineDivider
            case .sectionBreak:
                sectionBreakDivider
            }
        }
        .frame(maxWidth: width ?? .infinity)
        .accessibilityHidden(true)
    }

    // MARK: - Style Implementations

    /// Clean horizontal line
    private var simpleDivider: some View {
        Rectangle()
            .fill(color.opacity(AppTheme.Opacity.disabled))
            .frame(height: AppTheme.Divider.thin)
    }

    /// Diamond/lozenge pattern (classic manuscript)
    private var manuscriptDivider: some View {
        HStack(spacing: 0) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, color.opacity(AppTheme.Opacity.heavy)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)

            // Center diamond
            Diamond()
                .fill(color)
                .frame(width: AppTheme.Spacing.sm, height: AppTheme.Spacing.sm)
                .padding(.horizontal, AppTheme.Spacing.sm)

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(AppTheme.Opacity.heavy), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .frame(height: AppTheme.Spacing.md)
    }

    /// Celtic knot-inspired pattern
    private var celticDivider: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            // Left fade line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, color.opacity(AppTheme.Opacity.disabled)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)

            // Celtic knot symbol (simplified)
            ZStack {
                // Interlocking circles
                Circle()
                    .stroke(color, lineWidth: AppTheme.Border.medium)
                    .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)
                    .offset(x: -AppTheme.Spacing.xs)

                Circle()
                    .stroke(color, lineWidth: AppTheme.Border.medium)
                    .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)
                    .offset(x: AppTheme.Spacing.xs)

                // Center dot
                Circle()
                    .fill(color)
                    .frame(width: AppTheme.Spacing.xs, height: AppTheme.Spacing.xs)
            }
            .frame(width: AppTheme.Spacing.xl)

            // Right fade line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(AppTheme.Opacity.disabled), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .frame(height: AppTheme.Spacing.lg)
    }

    /// Floral/vine motifs
    private var floralDivider: some View {
        HStack(spacing: 0) {
            // Left vine
            Image(systemName: "leaf.fill")
                .font(Typography.UI.iconXxs)
                .foregroundStyle(Color.malachite.opacity(AppTheme.Opacity.strong))
                .rotationEffect(.degrees(-45))

            Spacer()

            // Center flower
            ZStack {
                ForEach(0..<6) { i in
                    Ellipse()
                        .fill(color.opacity(AppTheme.Opacity.overlay))
                        .frame(width: 6, height: 10)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
                Circle()
                    .fill(color)
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
            }
            .frame(width: AppTheme.IconSize.medium, height: AppTheme.IconSize.medium)

            Spacer()

            // Right vine
            Image(systemName: "leaf.fill")
                .font(Typography.UI.iconXxs)
                .foregroundStyle(Color.malachite.opacity(AppTheme.Opacity.strong))
                .rotationEffect(.degrees(45))
                .scaleEffect(x: -1, y: 1)
        }
        .frame(height: AppTheme.IconSize.medium)
        .padding(.horizontal, AppTheme.Spacing.sm)
    }

    /// Geometric pattern
    private var geometricDivider: some View {
        HStack(spacing: AppTheme.Spacing.sm - 2) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, color.opacity(AppTheme.Opacity.medium)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)

            // Geometric shapes
            ForEach(0..<3) { i in
                if i == 1 {
                    // Center larger diamond
                    Diamond()
                        .fill(color)
                        .frame(width: AppTheme.ComponentSize.indicator + 2, height: AppTheme.ComponentSize.indicator + 2)
                } else {
                    // Side smaller diamonds
                    Diamond()
                        .stroke(color, lineWidth: AppTheme.Border.thin)
                        .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
                }
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(AppTheme.Opacity.medium), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .frame(height: AppTheme.Spacing.md)
    }

    /// Calligraphic flourishes
    private var flourishDivider: some View {
        HStack(spacing: 0) {
            // Left flourish (using rotated parenthesis-like shape)
            Flourish()
                .stroke(color, lineWidth: AppTheme.Border.medium)
                .frame(width: 40, height: AppTheme.Spacing.md)
                .scaleEffect(x: -1, y: 1)

            Spacer()

            // Center ornament
            Diamond()
                .fill(color)
                .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)

            Spacer()

            // Right flourish
            Flourish()
                .stroke(color, lineWidth: AppTheme.Border.medium)
                .frame(width: 40, height: AppTheme.Spacing.md)
        }
        .frame(height: AppTheme.Spacing.lg)
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    /// Decorative chapter underline
    private var chapterUnderlineDivider: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            // Main line with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            color.opacity(AppTheme.Opacity.strong),
                            color,
                            color.opacity(AppTheme.Opacity.strong),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.medium)

            // Secondary thinner line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            color.opacity(AppTheme.Opacity.medium),
                            color.opacity(AppTheme.Opacity.heavy),
                            color.opacity(AppTheme.Opacity.medium),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .frame(height: AppTheme.Spacing.sm)
    }

    /// Section break (three symbols)
    private var sectionBreakDivider: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            ForEach(0..<3) { i in
                if i == 1 {
                    // Center larger symbol
                    Image(systemName: "sparkle")
                        .font(Typography.UI.iconXs.weight(.medium))
                        .foregroundStyle(color)
                } else {
                    // Side smaller symbols
                    Diamond()
                        .fill(color.opacity(AppTheme.Opacity.overlay))
                        .frame(width: AppTheme.ComponentSize.dotSmall - 1, height: AppTheme.ComponentSize.dotSmall - 1)
                }
            }

            Spacer()
        }
        .frame(height: AppTheme.IconSize.medium)
    }
}

// MARK: - Custom Shapes

/// Diamond/lozenge shape
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: center.y))
        path.closeSubpath()

        return path
    }
}

/// Calligraphic flourish shape
struct Flourish: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // S-curve flourish
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.maxY)
        )

        return path
    }
}

// MARK: - Convenience View Modifiers

extension View {
    /// Add ornamental divider below content
    func ornamentalDivider(
        style: OrnamentalDividerStyle = .manuscript,
        color: Color = Color.divineGold,
        spacing: CGFloat = AppTheme.Spacing.lg
    ) -> some View {
        VStack(spacing: spacing) {
            self
            OrnamentalDivider(style: style, color: color)
        }
    }
}

// MARK: - Preview

#Preview("Ornamental Divider Styles") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xxl) {
            ForEach(OrnamentalDividerStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text(style.displayName)
                        .font(Typography.UI.caption1Bold)
                        .foregroundStyle(.secondary)

                    OrnamentalDivider(style: style)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xl)
    }
    .background(Color(.systemBackground))
}

#Preview("Dividers in Context") {
    VStack(spacing: AppTheme.Spacing.xl) {
        Text("CHAPTER 1")
            .font(Typography.UI.caption1Bold)
            .tracking(2)

        Text("1")
            .font(Typography.Illuminated.chapterNumber())
            .foregroundStyle(Color.divineGold)

        OrnamentalDivider(style: .chapterUnderline)
            .padding(.horizontal, AppTheme.Spacing.xxxl - 8)

        Text("In the beginning God created the heaven and the earth.")
            .font(Typography.Scripture.body())
            .multilineTextAlignment(.center)

        Spacer()

        OrnamentalDivider(style: .sectionBreak)
    }
    .padding()
}
