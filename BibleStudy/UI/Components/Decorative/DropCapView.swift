import SwiftUI

// MARK: - Drop Cap View
// Illuminated initial letter for chapter/paragraph beginnings
// Supports 5 styles: simple, illuminated, uncial, floriate, versal

struct DropCapView: View {
    let letter: Character
    let style: DropCapStyle
    let size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    init(
        letter: Character,
        style: DropCapStyle = .illuminated,
        size: CGFloat = Typography.Scale.dropCap
    ) {
        self.letter = letter
        self.style = style
        self.size = size
    }

    var body: some View {
        switch style {
        case .none:
            EmptyView()
        case .simple:
            simpleDropCap
        case .illuminated:
            illuminatedDropCap
        case .uncial:
            uncialDropCap
        case .floriate:
            floriateDropCap
        case .versal:
            versalDropCap
        }
    }

    // MARK: - Style Implementations

    /// Simple large letter, no decoration
    private var simpleDropCap: some View {
        Text(String(letter).uppercased())
            .font(Typography.Illuminated.dropCap(size: size))
            .foregroundStyle(Color.primaryText)
            .accessibilityHidden(true)
    }

    /// Gold-accented with subtle glow effect
    private var illuminatedDropCap: some View {
        ZStack {
            // Glow effect
            Text(String(letter).uppercased())
                .font(Typography.Illuminated.dropCap(size: size))
                .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.medium))
                .blur(radius: AppTheme.Blur.medium)

            // Main letter with gold gradient
            Text(String(letter).uppercased())
                .font(Typography.Illuminated.dropCap(size: size))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.illuminatedGold,
                            Color.divineGold,
                            Color.burnishedGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Highlight accent
            Text(String(letter).uppercased())
                .font(Typography.Illuminated.dropCap(size: size))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(AppTheme.Opacity.disabled),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
        .accessibilityHidden(true)
    }

    /// Celtic/medieval uncial style
    private var uncialDropCap: some View {
        ZStack {
            // Celtic knot border (simplified geometric)
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(
                    Color.divineGold,
                    lineWidth: AppTheme.Border.regular
                )
                .frame(width: size * 1.1, height: size * 1.1)

            // Inner decorative border
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .stroke(
                    Color.burnishedGold.opacity(AppTheme.Opacity.heavy),
                    lineWidth: AppTheme.Border.thin
                )
                .frame(width: size * 0.95, height: size * 0.95)

            // Letter
            Text(String(letter).uppercased())
                .font(Typography.Illuminated.dropCap(size: size * 0.7))
                .foregroundStyle(Color.divineGold)
        }
        .accessibilityHidden(true)
    }

    /// Floral/vine decoration
    private var floriateDropCap: some View {
        ZStack {
            // Decorative vine flourish (using SF Symbol)
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.25))
                .foregroundStyle(Color.malachite.opacity(AppTheme.Opacity.strong))
                .offset(x: -size * 0.35, y: -size * 0.35)

            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.2))
                .foregroundStyle(Color.malachite.opacity(AppTheme.Opacity.disabled))
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.35, y: size * 0.3)

            // Main letter
            Text(String(letter).uppercased())
                .font(Typography.Illuminated.dropCap(size: size))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.divineGold,
                            Color.burnishedGold
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .accessibilityHidden(true)
    }

    /// Classic manuscript versal letter
    private var versalDropCap: some View {
        ZStack {
            // Background panel
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(
                    colorScheme == .dark
                        ? Color.chapelShadow
                        : Color.monasteryStone.opacity(AppTheme.Opacity.medium)
                )
                .frame(width: size * 1.15, height: size * 1.15)

            // Gold border
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.illuminatedGold,
                            Color.burnishedGold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AppTheme.Border.regular
                )
                .frame(width: size * 1.15, height: size * 1.15)

            // Corner decorations
            ForEach(0..<4) { corner in
                Circle()
                    .fill(Color.divineGold)
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)
                    .offset(
                        x: (corner % 2 == 0 ? -1 : 1) * size * 0.52,
                        y: (corner < 2 ? -1 : 1) * size * 0.52
                    )
            }

            // Main letter
            Text(String(letter).uppercased())
                .font(Typography.Illuminated.dropCap(size: size * 0.8))
                .foregroundStyle(
                    colorScheme == .dark
                        ? Color.illuminatedGold
                        : Color.vermillion
                )
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Drop Cap Container
// Wraps content with a drop cap, handling text flow around the initial

struct DropCapContainer<Content: View>: View {
    let letter: Character
    let style: DropCapStyle
    let content: () -> Content

    @State private var dropCapSize: CGSize = .zero

    init(
        letter: Character,
        style: DropCapStyle = .illuminated,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.letter = letter
        self.style = style
        self.content = content
    }

    var body: some View {
        if style == .none {
            content()
        } else {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                DropCapView(letter: letter, style: style)
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                dropCapSize = geo.size
                            }
                        }
                    )

                content()
            }
        }
    }
}

// MARK: - Preview

#Preview("Drop Cap Styles") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xxl) {
            ForEach(DropCapStyle.allCases, id: \.self) { style in
                if style != .none {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(style.displayName)
                            .font(Typography.UI.caption1Bold)
                            .foregroundStyle(.secondary)

                        DropCapView(letter: "I", style: style)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Drop Cap in Context") {
    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
        DropCapContainer(letter: "I", style: .illuminated) {
            Text("n the beginning God created the heaven and the earth. And the earth was without form, and void; and darkness was upon the face of the deep.")
                .font(Typography.Scripture.body())
        }
    }
    .padding()
}
