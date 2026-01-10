import SwiftUI

// MARK: - Ask Modal View
// Full-screen modal wrapper for Ask functionality
// Presents AskTabContentView with close button in toolbar

struct AskModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var viewModel: AskViewModel

    // MARK: - Animation State
    @State private var appeared = false
    @State private var goldenLightOpacity: Double = 0.3

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Main content with close button in toolbar
            AskTabContentView(
                viewModel: viewModel,
                showCloseButton: true,
                onClose: { dismiss() }
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 40)

            // Golden light wash overlay (entrance effect)
            if !respectsReducedMotion {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Colors.Semantic.accentSeal(for: ThemeMode.current(from: colorScheme)).opacity(goldenLightOpacity),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .background(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
        .interactiveDismissDisabled(viewModel.isLoading)
        .onAppear {
            startEntranceAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkNavigationRequested)) { _ in
            dismiss()
        }
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        if respectsReducedMotion {
            appeared = true
            goldenLightOpacity = 0
            return
        }

        // Phase 1: Golden light appears
        withAnimation(Theme.Animation.slowFade) {
            goldenLightOpacity = 0.3
        }

        // Phase 2: Content rises in
        withAnimation(Theme.Animation.settle) {
            appeared = true
        }

        // Phase 3: Golden light fades
        withAnimation(Theme.Animation.slowFade.delay(0.2)) {
            goldenLightOpacity = 0
        }
    }
}

// MARK: - Preview

#Preview {
    AskModalView(viewModel: AskViewModel())
        .environment(AppState())
}
