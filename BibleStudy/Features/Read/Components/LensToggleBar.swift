import SwiftUI

// MARK: - Lens Toggle Bar
// Segmented control for switching between different lenses

struct LensToggleBar: View {
    @Binding var activeLens: Lens

    private let lenses: [Lens] = [.understand, .context, .crossRefs, .language, .interpretation]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(lenses, id: \.self) { lens in
                    LensButton(
                        lens: lens,
                        isActive: activeLens == lens
                    ) {
                        withAnimation(AppTheme.Animation.quick) {
                            if activeLens == lens {
                                activeLens = .none
                            } else {
                                activeLens = lens
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
    }
}

// MARK: - Lens Button
struct LensButton: View {
    let lens: Lens
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: lens.icon)
                    .font(Typography.UI.caption1)
                Text(lens.title)
                    .font(Typography.UI.chipLabel)
            }
            .foregroundStyle(isActive ? .white : Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isActive ? Color.accentGold : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        LensToggleBar(activeLens: .constant(.none))
        LensToggleBar(activeLens: .constant(.context))
        LensToggleBar(activeLens: .constant(.crossRefs))
    }
    .padding()
    .background(Color.appBackground)
}
