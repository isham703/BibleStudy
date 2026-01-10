import SwiftUI

// MARK: - Floating Divider
/// A subtle divider for separating rows within floating section cards.
/// Inset from the leading edge to align with content after icons.

struct FloatingDivider: View {
    var insetLeading: Bool = true

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(Theme.Opacity.faint))
            .frame(height: 1)
            .padding(.leading, insetLeading ? 56 : Theme.Spacing.lg)  // Icon width (32) + spacing (md=12) + alignment (12)
            .padding(.trailing, Theme.Spacing.lg)
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#if DEBUG
struct FloatingDivider_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Text("Row Above")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            FloatingDivider()

            Text("Row Below")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            FloatingDivider(insetLeading: false)

            Text("Full Width Divider Above")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.surfaceBackground)
    }
}
#endif
