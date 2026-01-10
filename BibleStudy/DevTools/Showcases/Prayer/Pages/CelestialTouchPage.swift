//
//  CelestialTouchPage.swift
//  BibleStudy
//
//  Style E: Celestial Touch - Interactive constellation particle effects
//  Viral-worthy: Magical touch interactions, particles that respond to gestures
//  TikTok aesthetic: Record your prayer being written as stars connect
//

import SwiftUI

struct CelestialTouchPage: View {
    @State private var prayerText: String = ""
    @State private var isGenerating = false
    @State private var generatedPrayer: String = ""
    @State private var showPrayer = false
    @State private var particles: [StarParticle] = []
    @State private var touchLocation: CGPoint = .zero
    @State private var showTouchEffect = false
    @State private var typingStars: [TypingStar] = []
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Cosmic background
            CosmicBackground()

            // Interactive particle layer
            ParticleCanvas(
                particles: $particles,
                touchLocation: touchLocation,
                showTouchEffect: showTouchEffect
            )
            .allowsHitTesting(false)

            // Typing stars animation
            ForEach(typingStars) { star in
                TypingStarView(star: star)
            }

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    inputSection

                    if showPrayer {
                        resultSection
                    }

                    Spacer(minLength: 140)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchLocation = value.location
                        showTouchEffect = true
                        spawnTouchParticles(at: value.location)
                    }
                    .onEnded { _ in
                        showTouchEffect = false
                    }
            )

            // Generate button
            VStack {
                Spacer()
                generateButton
            }
        }
        .onAppear {
            initializeParticles()
        }
        .onChange(of: prayerText) { oldValue, newValue in
            if newValue.count > oldValue.count {
                spawnTypingStar()
            }
        }
    }

    // MARK: - Particle Management

    private func initializeParticles() {
        particles = (0..<60).map { _ in
            StarParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.3...0.9),
                speed: CGFloat.random(in: 0.1...0.5),
                twinklePhase: Double.random(in: 0...(2.0 * Double.pi))
            )
        }
    }

    private func spawnTouchParticles(at location: CGPoint) {
        let newParticles = (0..<3).map { _ in
            StarParticle(
                position: location,
                size: CGFloat.random(in: 3...6),
                opacity: 0.9,
                speed: CGFloat.random(in: 1...3),
                twinklePhase: 0,
                velocity: CGPoint(
                    x: CGFloat.random(in: -2.0...2.0),
                    y: CGFloat.random(in: -3.0 ... -1.0)
                ),
                lifetime: 2.0
            )
        }
        particles.append(contentsOf: newParticles)
    }

    private func spawnTypingStar() {
        let inputFrame = CGRect(x: 40, y: 350, width: UIScreen.main.bounds.width - 80, height: 160)
        let star = TypingStar(
            position: CGPoint(
                x: CGFloat.random(in: inputFrame.minX...inputFrame.maxX),
                y: CGFloat.random(in: inputFrame.minY...inputFrame.maxY)
            )
        )
        typingStars.append(star)

        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            typingStars.removeAll { $0.id == star.id }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 80)

            // Constellation icon
            ZStack {
                // Connecting lines
                ConstellationIcon()
                    .stroke(Color.skyBlue.opacity(Theme.Opacity.tertiary), lineWidth: 1)
                    .frame(width: 80, height: 80)

                // Star points
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .offset(constellationOffset(for: i))
                        .shadow(color: Color.skyBlue, radius: 4)
                }
            }

            // Title
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("Celestial")
                        .font(Typography.Scripture.display.weight(.thin))
                        .foregroundColor(.white)

                    Text(" Prayer")
                        .font(Typography.Scripture.display.weight(.light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.skyBlue, Color(hex: "A78BFA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Text("TOUCH THE STARS")
                    .font(Typography.Command.meta.weight(.semibold))
                    .tracking(4)
                    .foregroundColor(Color.skyBlue.opacity(Theme.Opacity.heavy))
            }

            Text("Every keystroke creates a star. Every prayer connects the cosmos.")
                .font(Typography.Command.subheadline.weight(.light))
                .foregroundColor(Color.white.opacity(Theme.Opacity.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
        }
        .padding(.bottom, 40)
    }

    private func constellationOffset(for index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: 0, height: -35),
            CGSize(width: 30, height: -10),
            CGSize(width: 20, height: 25),
            CGSize(width: -25, height: 20),
            CGSize(width: -30, height: -15)
        ]
        return offsets[index % offsets.count]
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Label with star count
            HStack {
                Text("YOUR PRAYER")
                    .font(Typography.Icon.xxs.weight(.bold))
                    .tracking(2)
                    .foregroundColor(Color.skyBlue.opacity(Theme.Opacity.heavy))

                Spacer()

                if !prayerText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(Typography.Icon.xxxs)
                        Text("\(prayerText.count) stars")
                            .font(Typography.Icon.xxs)
                    }
                    .foregroundColor(Color.yellowAmber.opacity(Theme.Opacity.pressed))
                }
            }
            .padding(.horizontal, 28)

            // Input card with cosmic border
            ZStack(alignment: .topLeading) {
                // Animated cosmic border
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(Color(hex: "0F172A").opacity(Theme.Opacity.pressed))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.xl)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Color.skyBlue.opacity(Theme.Opacity.medium),
                                        Color(hex: "A78BFA").opacity(Theme.Opacity.subtle),
                                        Color(hex: "EC4899").opacity(Theme.Opacity.light),
                                        Color.skyBlue.opacity(Theme.Opacity.medium)
                                    ],
                                    center: .center
                                ),
                                lineWidth: isInputFocused ? 2 : 1
                            )
                    )
                    .shadow(color: Color.skyBlue.opacity(isInputFocused ? 0.3 : 0.1), radius: 15)

                // Text editor
                TextEditor(text: $prayerText)
                    .font(Typography.Command.body.weight(.light))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .padding(20)
                    .frame(minHeight: 160)

                // Placeholder
                if prayerText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Begin typing to create your constellation...")
                            .font(Typography.Command.body.weight(.light))
                            .foregroundColor(Color.white.opacity(Theme.Opacity.subtle))

                        Text("Each character spawns a star")
                            .font(Typography.Command.meta.weight(.light))
                            .foregroundColor(Color.skyBlue.opacity(Theme.Opacity.lightMedium))
                    }
                    .padding(24)
                    .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(spacing: 24) {
            // Constellation divider
            HStack(spacing: 8) {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.skyBlue)
                        .frame(width: 4 + CGFloat(i == 2 ? 4 : 0), height: 4 + CGFloat(i == 2 ? 4 : 0))
                        .shadow(color: Color.skyBlue, radius: 4)
                }
            }
            .padding(.top, 32)

            // Prayer card
            VStack(alignment: .leading, spacing: 16) {
                // Constellation complete badge
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(Typography.Command.caption)
                    Text("Constellation Complete")
                        .font(Typography.Command.meta.weight(.semibold))
                }
                .foregroundColor(Color.yellowAmber)

                // Prayer text
                Text(generatedPrayer.isEmpty ? samplePrayer : generatedPrayer)
                    .font(Typography.Scripture.body.weight(.light))
                    .foregroundColor(.white)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)

                // Scripture
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed")
                            .font(Typography.Icon.xxs)
                        Text("Psalm 147:4")
                            .font(Typography.Icon.xs)
                    }
                    .foregroundColor(Color.skyBlue.opacity(Theme.Opacity.pressed))
                }

                // Actions
                HStack(spacing: 12) {
                    CelestialActionButton(icon: "doc.on.doc", label: "Copy") {}
                    CelestialActionButton(icon: "square.and.arrow.up", label: "Share") {}
                    CelestialActionButton(icon: "star", label: "Save") {}
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                    .fill(Color(hex: "0F172A").opacity(Theme.Opacity.high))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.yellowAmber.opacity(Theme.Opacity.lightMedium),
                                        Color.skyBlue.opacity(Theme.Opacity.light),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generate) {
            HStack(spacing: 12) {
                if isGenerating {
                    CelestialLoadingIndicator()
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(Typography.Icon.base)
                }

                Text(isGenerating ? "Aligning stars..." : "Form Constellation")
                    .font(Typography.Command.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.blueAccent, Color.accentIndigo, Color.violetAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(Theme.Opacity.light), lineWidth: 1)
                    )
                    .shadow(color: Color.accentIndigo.opacity(Theme.Opacity.medium), radius: 20, x: 0, y: 10)
            )
        }
        .disabled(isGenerating || prayerText.isEmpty)
        .opacity(prayerText.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }

    private func generate() {
        withAnimation(Theme.Animation.settle) {
            isGenerating = true
        }

        // Spawn celebration particles
        for _ in 0..<20 {
            spawnTouchParticles(at: CGPoint(
                x: UIScreen.main.bounds.width / 2 + CGFloat.random(in: -100...100),
                y: UIScreen.main.bounds.height / 2 + CGFloat.random(in: -100...100)
            ))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(Theme.Animation.settle) {
                isGenerating = false
                showPrayer = true
            }
        }
    }

    private var samplePrayer: String {
        """
        Lord, You who count the stars and call them each by name, \
        You know the deepest longings of my heart.

        As I gaze upon the heavens You created, \
        I am reminded of Your infinite care for me.

        Connect the scattered pieces of my life \
        into a constellation of Your grace. \
        Guide me by Your light.

        Amen.
        """
    }
}

// MARK: - Data Models

struct StarParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var twinklePhase: Double
    var velocity: CGPoint = .zero
    var lifetime: Double = Double.infinity
}

struct TypingStar: Identifiable {
    let id = UUID()
    let position: CGPoint
}

// MARK: - Cosmic Background

private struct CosmicBackground: View {
    var body: some View {
        ZStack {
            // Deep space
            LinearGradient(
                colors: [
                    Color(hex: "030712"),
                    Color(hex: "0F172A"),
                    Color(hex: "1E1B4B").opacity(Theme.Opacity.medium),
                    Color(hex: "030712")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Nebula hints
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blueAccent.opacity(Theme.Opacity.overlay),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.2)
                    .blur(radius: 50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.violetAccent.opacity(Theme.Opacity.overlay),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: -geo.size.width * 0.3, y: geo.size.height * 0.6)
                    .blur(radius: 40)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Particle Canvas

private struct ParticleCanvas: View {
    @Binding var particles: [StarParticle]
    let touchLocation: CGPoint
    let showTouchEffect: Bool

    @State private var animationPhase: Double = 0

    var body: some View {
        SwiftUI.TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    let twinkle = sin(time * 2 + particle.twinklePhase) * 0.3 + 0.7
                    let adjustedOpacity = particle.opacity * twinkle

                    // Draw star glow
                    let glowRect = CGRect(
                        x: particle.position.x - particle.size * 2,
                        y: particle.position.y - particle.size * 2,
                        width: particle.size * 4,
                        height: particle.size * 4
                    )
                    context.fill(
                        Circle().path(in: glowRect),
                        with: .color(Color.skyBlue.opacity(adjustedOpacity * 0.3))
                    )

                    // Draw star core
                    let rect = CGRect(
                        x: particle.position.x - particle.size / 2,
                        y: particle.position.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color.white.opacity(adjustedOpacity))
                    )
                }

                // Touch effect ripple
                if showTouchEffect {
                    let rippleSize: CGFloat = 60
                    let rippleRect = CGRect(
                        x: touchLocation.x - rippleSize / 2,
                        y: touchLocation.y - rippleSize / 2,
                        width: rippleSize,
                        height: rippleSize
                    )
                    context.stroke(
                        Circle().path(in: rippleRect),
                        with: .color(Color.skyBlue.opacity(Theme.Opacity.medium)),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}

// MARK: - Constellation Icon Shape

private struct ConstellationIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points: [CGPoint] = [
            CGPoint(x: rect.midX, y: rect.minY + 5),
            CGPoint(x: rect.maxX - 10, y: rect.midY - 10),
            CGPoint(x: rect.maxX - 20, y: rect.maxY - 15),
            CGPoint(x: rect.minX + 15, y: rect.maxY - 20),
            CGPoint(x: rect.minX + 10, y: rect.midY - 5)
        ]

        // Connect stars
        path.move(to: points[0])
        path.addLine(to: points[1])
        path.addLine(to: points[2])
        path.move(to: points[0])
        path.addLine(to: points[4])
        path.addLine(to: points[3])
        path.move(to: points[1])
        path.addLine(to: points[3])

        return path
    }
}

// MARK: - Typing Star View

private struct TypingStarView: View {
    let star: TypingStar
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var yOffset: CGFloat = 0

    var body: some View {
        Image(systemName: "star.fill")
            .font(Typography.Command.caption)
            .foregroundColor(Color.yellowAmber)
            .shadow(color: Color.yellowAmber, radius: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: yOffset)
            .position(star.position)
            .onAppear {
                withAnimation(Theme.Animation.settle) {
                    scale = 1
                }
                withAnimation(.easeOut(duration: 1.5)) {
                    yOffset = -50
                    opacity = 0
                }
            }
    }
}

// MARK: - Celestial Action Button

private struct CelestialActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(Typography.Command.callout)
                Text(label)
                    .font(Typography.Icon.xxs)
            }
            .foregroundColor(Color.skyBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Color.skyBlue.opacity(Theme.Opacity.overlay))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .stroke(Color.skyBlue.opacity(Theme.Opacity.subtle), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Celestial Loading Indicator

private struct CelestialLoadingIndicator: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .offset(y: -10)
                    .rotationEffect(.degrees(Double(i) * 90 + rotation))
            }
        }
        .frame(width: 24, height: 24)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CelestialTouchPage()
}
