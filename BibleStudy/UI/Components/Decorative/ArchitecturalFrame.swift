import SwiftUI

// MARK: - Architectural Frame
// Pillar and arch overlay for Sacred Threshold variant
// Creates sense of entering a sacred space

struct ArchitecturalFrame: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pillarOffset: CGFloat = 100
    @State private var archProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Left pillar with shadow
                pillar(at: 30)
                    .position(x: 30, y: 100)
                    .offset(y: reduceMotion ? 0 : pillarOffset)

                // Right pillar
                pillar(at: geometry.size.width - 30)
                    .position(x: geometry.size.width - 30, y: 100)
                    .offset(y: reduceMotion ? 0 : pillarOffset)

                // Arch connecting pillars
                archPath(width: geometry.size.width)
                    .trim(from: 0, to: reduceMotion ? 1 : archProgress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
            }
        }
        .onAppear {
            animateFrame()
        }
        .allowsHitTesting(false)
    }

    private func pillar(at xPosition: CGFloat) -> some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.3))
                .frame(width: 36, height: 140)
                .offset(x: 4, y: 4)
                .blur(radius: 8)

            // Pillar body
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 36, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            // Pillar cap (Corinthian-inspired)
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 42, height: 8)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 38, height: 4)
            }
            .offset(y: -72)
        }
    }

    private func archPath(width: CGFloat) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 50, y: 40))
            path.addQuadCurve(
                to: CGPoint(x: width - 50, y: 40),
                control: CGPoint(x: width / 2, y: -30)
            )
        }
    }

    private func animateFrame() {
        guard !reduceMotion else { return }

        // Pillars rise up
        withAnimation(.easeOut(duration: 0.8)) {
            pillarOffset = 0
        }

        // Arch draws after pillars
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            archProgress = 1
        }
    }
}

// MARK: - Room Indicator

struct RoomIndicator: View {
    let totalRooms: Int
    let currentRoom: Int
    let roomColors: [Color]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalRooms, id: \.self) { index in
                Circle()
                    .fill(index == currentRoom ? roomColors[index] : Color.white.opacity(0.3))
                    .frame(width: index == currentRoom ? 10 : 6, height: index == currentRoom ? 10 : 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentRoom)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ArchitecturalFrame()

        VStack {
            Spacer()

            RoomIndicator(
                totalRooms: 5,
                currentRoom: 2,
                roomColors: [
                    .thresholdGold,
                    .thresholdIndigo,
                    .thresholdPurple,
                    .thresholdRose,
                    .thresholdBlue
                ]
            )
            .padding(.bottom, 100)
        }
    }
}
