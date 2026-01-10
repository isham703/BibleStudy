import SwiftUI

// MARK: - Connection Node
// An animated node that can pulse, glow, and change states
// Used as the foundation for network graph animations

struct ConnectionNode: View {
    let size: CGFloat
    var color: Color = .accentBronze
    var isActive: Bool = false
    var isPulsing: Bool = false
    var glowIntensity: CGFloat = 0.5

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: CGFloat = 0.0

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        ZStack {
            // Outer glow ring (when active)
            if isActive && !respectsReducedMotion {
                Circle()
                    .fill(color.opacity(Theme.Opacity.lightMedium * glowIntensity))
                    .frame(width: size * 2, height: size * 2)
                    .opacity(glowOpacity)
            }

            // Middle pulse ring
            if isPulsing && !respectsReducedMotion {
                Circle()
                    .stroke(color.opacity(Theme.Opacity.medium), lineWidth: Theme.Stroke.control)
                    .frame(width: size * 1.5, height: size * 1.5)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)
            }

            // Core node
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(isActive ? 1.0 : 0.6),
                            color.opacity(isActive ? 0.8 : 0.4)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // Inner highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isActive ? 0.6 : 0.3),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(x: -size * 0.1, y: -size * 0.1)
        }
        .onAppear {
            if isPulsing && !respectsReducedMotion {
                startPulseAnimation()
            }
            if isActive && !respectsReducedMotion {
                startGlowAnimation()
            }
        }
        .onChange(of: isPulsing) { _, newValue in
            if newValue && !respectsReducedMotion {
                startPulseAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue && !respectsReducedMotion {
                startGlowAnimation()
            } else {
                withAnimation(Theme.Animation.settle) {
                    glowOpacity = 0
                }
            }
        }
    }

    private func startPulseAnimation() {
        pulseScale = 1.0
        withAnimation(
            Theme.Animation.slowFade
            .repeatForever(autoreverses: false)
        ) {
            pulseScale = 2.0
        }
    }

    private func startGlowAnimation() {
        withAnimation(Theme.Animation.slowFade.repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }
}

// MARK: - Node State
enum NodeState {
    case idle
    case active
    case pulsing
    case success
    case dimmed

    var color: Color {
        switch self {
        case .idle: return .accentBronze.opacity(Theme.Opacity.heavy)
        case .active: return .accentBronze
        case .pulsing: return .accentBronze
        case .success: return .highlightGreen
        case .dimmed: return .tertiaryText
        }
    }

    var isActive: Bool {
        switch self {
        case .active, .pulsing, .success: return true
        default: return false
        }
    }

    var isPulsing: Bool {
        self == .pulsing
    }
}

// MARK: - Stateful Connection Node
struct StatefulConnectionNode: View {
    let size: CGFloat
    var state: NodeState = .idle

    var body: some View {
        ConnectionNode(
            size: size,
            color: state.color,
            isActive: state.isActive,
            isPulsing: state.isPulsing
        )
    }
}

// MARK: - Preview
#Preview("Connection Node States") {
    VStack(spacing: Theme.Spacing.xxl) {
        HStack(spacing: Theme.Spacing.xxl) {
            VStack {
                ConnectionNode(size: 16, isActive: false)
                Text("Idle").font(Typography.Command.caption)
            }

            VStack {
                ConnectionNode(size: 16, isActive: true)
                Text("Active").font(Typography.Command.caption)
            }

            VStack {
                ConnectionNode(size: 16, isPulsing: true)
                Text("Pulsing").font(Typography.Command.caption)
            }
        }

        HStack(spacing: Theme.Spacing.xxl) {
            VStack {
                StatefulConnectionNode(size: 20, state: .success)
                Text("Success").font(Typography.Command.caption)
            }

            VStack {
                StatefulConnectionNode(size: 20, state: .dimmed)
                Text("Dimmed").font(Typography.Command.caption)
            }
        }

        // Various sizes
        HStack(spacing: Theme.Spacing.xxl) {
            ConnectionNode(size: 8, isActive: true)
            ConnectionNode(size: 12, isActive: true)
            ConnectionNode(size: 16, isActive: true)
            ConnectionNode(size: 24, isActive: true)
        }
    }
    .padding()
    .background(Color.appBackground)
}
