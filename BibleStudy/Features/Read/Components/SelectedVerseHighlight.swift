import SwiftUI

// MARK: - Selected Verse Highlight
// ViewModifier that adds a gold glow effect to the selected verse
// Design: Gold border + soft glow shadow, persists while insight is open
// Animation: Uses luminous timing for ethereal appearance

struct SelectedVerseHighlight: ViewModifier {
    // MARK: - Properties

    let isSelected: Bool
    var showBorder: Bool = true
    var showGlow: Bool = true

    // MARK: - State

    @State private var glowIntensity: Double = 0

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .padding(showBorder && isSelected ? AppTheme.Spacing.sm : 0)
            .background(highlightBackground)
            .overlay(highlightBorder)
            .animation(AppTheme.Animation.luminous, value: isSelected)
            .onChange(of: isSelected) { _, newValue in
                if newValue {
                    // Pulse glow on selection
                    withAnimation(AppTheme.Animation.luminous) {
                        glowIntensity = 1.0
                    }
                    // Settle to resting glow
                    withAnimation(AppTheme.Animation.contemplative.delay(0.4)) {
                        glowIntensity = 0.6
                    }
                } else {
                    withAnimation(AppTheme.Animation.quick) {
                        glowIntensity = 0
                    }
                }
            }
    }

    // MARK: - Highlight Background

    @ViewBuilder
    private var highlightBackground: some View {
        if isSelected && showGlow {
            // Soft gold glow behind content
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color.divineGold.opacity(AppTheme.Opacity.faint * glowIntensity))
                .shadow(
                    color: Color.divineGold.opacity(AppTheme.Opacity.medium * glowIntensity),
                    radius: 12,
                    x: 0,
                    y: 0
                )
        }
    }

    // MARK: - Highlight Border

    @ViewBuilder
    private var highlightBorder: some View {
        if isSelected && showBorder {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.illuminatedGold.opacity(AppTheme.Opacity.pressed * glowIntensity),
                            Color.divineGold.opacity(AppTheme.Opacity.strong * glowIntensity),
                            Color.burnishedGold.opacity(AppTheme.Opacity.disabled * glowIntensity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: AppTheme.Border.regular
                )
                .shadow(
                    color: Color.divineGold.opacity(AppTheme.Opacity.disabled * glowIntensity),
                    radius: 8,
                    x: 0,
                    y: 0
                )
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply the selected verse highlight effect
    /// - Parameters:
    ///   - isSelected: Whether the verse is currently selected
    ///   - showBorder: Whether to show the gold border (default true)
    ///   - showGlow: Whether to show the soft glow (default true)
    func selectedVerseHighlight(
        isSelected: Bool,
        showBorder: Bool = true,
        showGlow: Bool = true
    ) -> some View {
        modifier(SelectedVerseHighlight(
            isSelected: isSelected,
            showBorder: showBorder,
            showGlow: showGlow
        ))
    }
}

// MARK: - Minimal Verse Highlight
// A simpler highlight for when multiple verses are selected

struct MinimalVerseHighlight: ViewModifier {
    let isHighlighted: Bool
    let color: Color

    func body(content: Content) -> some View {
        content
            .background(
                isHighlighted ?
                color.opacity(AppTheme.Opacity.subtle) :
                Color.clear
            )
            .animation(AppTheme.Animation.quick, value: isHighlighted)
    }
}

extension View {
    /// Apply a minimal highlight (just background color)
    func minimalHighlight(isHighlighted: Bool, color: Color = Color.divineGold) -> some View {
        modifier(MinimalVerseHighlight(isHighlighted: isHighlighted, color: color))
    }
}

// MARK: - Preview

#Preview("Selected Verse Highlight") {
    struct PreviewContainer: View {
        @State private var isSelected = false

        var body: some View {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Instructions
                Text("Tap the verse to toggle selection")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(.secondary)

                VStack(spacing: AppTheme.Spacing.lg) {
                    // Verse before
                    Text("19 So then you are no longer strangers and aliens, but you are fellow citizens with the saints and members of the household of God,")
                        .font(Typography.Illuminated.body())
                        .foregroundStyle(Color.primaryText)
                        .padding(.horizontal)

                    // Selected verse
                    Text("20 built on the foundation of the apostles and prophets, Christ Jesus himself being the cornerstone,")
                        .font(Typography.Illuminated.body())
                        .foregroundStyle(Color.primaryText)
                        .selectedVerseHighlight(isSelected: isSelected)
                        .padding(.horizontal)
                        .onTapGesture {
                            isSelected.toggle()
                        }

                    // Verse after
                    Text("21 in whom the whole structure, being joined together, grows into a holy temple in the Lord.")
                        .font(Typography.Illuminated.body())
                        .foregroundStyle(Color.primaryText)
                        .padding(.horizontal)
                }

                Spacer()

                // State indicator
                HStack {
                    Circle()
                        .fill(isSelected ? Color.green : Color.gray)
                        .frame(width: AppTheme.Spacing.md, height: AppTheme.Spacing.md)

                    Text(isSelected ? "Selected" : "Not selected")
                        .font(Typography.UI.caption1)
                }
            }
            .padding()
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}

#Preview("Highlight Variations") {
    VStack(spacing: AppTheme.Spacing.xl) {
        // Full highlight
        Text("Full highlight (border + glow)")
            .font(Typography.Illuminated.body())
            .selectedVerseHighlight(isSelected: true, showBorder: true, showGlow: true)

        // Border only
        Text("Border only (no glow)")
            .font(Typography.Illuminated.body())
            .selectedVerseHighlight(isSelected: true, showBorder: true, showGlow: false)

        // Glow only
        Text("Glow only (no border)")
            .font(Typography.Illuminated.body())
            .selectedVerseHighlight(isSelected: true, showBorder: false, showGlow: true)

        // Minimal
        Text("Minimal highlight")
            .font(Typography.Illuminated.body())
            .minimalHighlight(isHighlighted: true)
    }
    .padding()
    .background(Color.appBackground)
}
