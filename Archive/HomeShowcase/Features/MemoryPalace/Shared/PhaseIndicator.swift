import SwiftUI

// MARK: - Phase Indicator
// Shows progress through the 3 phases: Visualize → Connect → Recall
// Each variant has a distinct visual style

struct PhaseIndicator: View {
    let currentPhase: MemorizationPhase
    let accentColor: Color
    let style: PhaseIndicatorStyle

    enum PhaseIndicatorStyle {
        case candlelit   // Flame-shaped segments
        case scholarly   // Simple rectangles
        case celestial   // Pulsing dots
    }

    var body: some View {
        HStack(spacing: HomeShowcaseTheme.Spacing.md) {
            ForEach(MemorizationPhase.allCases, id: \.rawValue) { phase in
                phaseView(for: phase)
            }
        }
    }

    @ViewBuilder
    private func phaseView(for phase: MemorizationPhase) -> some View {
        let isActive = phase.rawValue <= currentPhase.rawValue
        let isCurrent = phase == currentPhase

        switch style {
        case .candlelit:
            candlelitPhase(phase: phase, isActive: isActive, isCurrent: isCurrent)
        case .scholarly:
            scholarlyPhase(phase: phase, isActive: isActive, isCurrent: isCurrent)
        case .celestial:
            celestialPhase(phase: phase, isActive: isActive, isCurrent: isCurrent)
        }
    }

    // MARK: - Candlelit Style (Flame shapes)

    private func candlelitPhase(phase: MemorizationPhase, isActive: Bool, isCurrent: Bool) -> some View {
        VStack(spacing: 4) {
            // Flame-shaped indicator
            Image(systemName: isActive ? "flame.fill" : "flame")
                .font(.system(size: 16))
                .foregroundStyle(isActive ? accentColor : Color.white.opacity(0.3))
                .shadow(color: isActive ? accentColor.opacity(0.5) : .clear, radius: 4)
                .scaleEffect(isCurrent ? 1.1 : 1.0)
                .accessibleAnimation(HomeShowcaseTheme.Animation.pulse, value: isCurrent)

            Text(phase.title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.4))
        }
        .accessibilityLabel("\(phase.title), \(isActive ? "completed" : "not started")")
    }

    // MARK: - Scholarly Style (Simple rectangles)

    private func scholarlyPhase(phase: MemorizationPhase, isActive: Bool, isCurrent: Bool) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? accentColor : Color.scholarInk.opacity(0.15))
                .frame(width: 32, height: 4)

            Text(phase.title.uppercased())
                .font(.system(size: 8, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundStyle(isActive ? Color.scholarInk : Color.footnoteGray)
        }
    }

    // MARK: - Celestial Style (Pulsing dots)

    private func celestialPhase(phase: MemorizationPhase, isActive: Bool, isCurrent: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                // Outer glow for current
                if isCurrent {
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .blur(radius: 4)
                }

                Circle()
                    .fill(isActive ? accentColor : Color.white.opacity(0.2))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.5), lineWidth: isActive ? 1 : 0)
                    )
            }
            .frame(width: 24, height: 24)

            Text(phase.title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.4))
        }
        .accessibilityLabel("\(phase.title), \(isActive ? "completed" : "not started")")
    }
}

// MARK: - Preview

#Preview("Phase Indicators") {
    VStack(spacing: 40) {
        // Candlelit
        ZStack {
            Color(hex: "030308")
            VStack {
                Text("Candlelit").foregroundStyle(.white).font(.caption)
                PhaseIndicator(
                    currentPhase: .connect,
                    accentColor: .candleAmber,
                    style: .candlelit
                )
            }
        }
        .frame(height: 100)

        // Scholarly
        ZStack {
            Color.vellumCream
            VStack {
                Text("Scholarly").foregroundStyle(Color.scholarInk).font(.caption)
                PhaseIndicator(
                    currentPhase: .connect,
                    accentColor: .scholarIndigo,
                    style: .scholarly
                )
            }
        }
        .frame(height: 100)

        // Celestial
        ZStack {
            Color.celestialDeep
            VStack {
                Text("Celestial").foregroundStyle(.white).font(.caption)
                PhaseIndicator(
                    currentPhase: .connect,
                    accentColor: .celestialPurple,
                    style: .celestial
                )
            }
        }
        .frame(height: 100)
    }
}
