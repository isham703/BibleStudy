import SwiftUI

// MARK: - Settings Footer View
// Design Rationale: Minimal branding footer with subtle divider.
// Uses hairline stroke for divider per design system.
// Stoic-Existential Renaissance design

struct SettingsFooterView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Subtle divider line
            Rectangle()
                .fill(Color("AppAccentAction").opacity(Theme.Opacity.textSecondary))
                .frame(width: 40, height: Theme.Stroke.hairline)

            // App branding
            Text("Bible Study • Stoic")
                .font(Typography.Command.caption)
                .foregroundStyle(Color("TertiaryText"))
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

// MARK: - Preview

#Preview("Settings Footer") {
    VStack {
        Spacer()
        SettingsFooterView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.appBackground)
}
