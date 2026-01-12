import SwiftUI

// MARK: - Gold Toggle Style
/// A custom toggle style with gold accent for the on state.
/// Features smooth spring animation and subtle shadow effects.

struct GoldToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        GoldToggleStyleBody(configuration: configuration)
    }
}

private struct GoldToggleStyleBody: View {
    let configuration: ToggleStyleConfiguration
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            configuration.label

            ZStack {
                // Track background
                Capsule()
                    .fill(configuration.isOn ? Color("AppAccentAction") : Color.white.opacity(Theme.Opacity.selectionBackground))
                    .frame(width: Theme.Toggle.trackWidth, height: Theme.Toggle.trackHeight)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: Theme.Toggle.thumbSize, height: Theme.Toggle.thumbSize)
                    .shadow(color: .black.opacity(Theme.Opacity.selectionBackground), radius: 2, y: 1)
                    .offset(x: configuration.isOn ? Theme.Toggle.thumbOffset : -Theme.Toggle.thumbOffset)
            }
            .onTapGesture {
                withAnimation(Theme.Animation.settle) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct GoldToggleStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Toggle("Feature Enabled", isOn: .constant(true))
                .toggleStyle(GoldToggleStyle())

            Toggle("Feature Disabled", isOn: .constant(false))
                .toggleStyle(GoldToggleStyle())
        }
        .padding()
        .background(Color("AppSurface"))
    }
}
#endif
