import SwiftUI

// MARK: - Scripture Finds You POC
// Context-aware verse surfacing - the right word at the right moment
// Aesthetic: Ambient, gentle, notification-like but sacred

struct ScriptureFindsYouPOC: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var currentContext = 0
    @State private var showingVerse = false
    @State private var pulsePhase: CGFloat = 0

    private let contexts: [LifeContext] = [
        LifeContext(
            time: "Monday, 7:14 AM",
            situation: "Before your presentation",
            icon: "briefcase.fill",
            verse: "Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.",
            reference: "Joshua 1:9",
            reason: "You have a big meeting at 9am. This verse has carried many through moments of fear."
        ),
        LifeContext(
            time: "Tuesday, 11:42 PM",
            situation: "After you journaled about feeling alone",
            icon: "moon.stars.fill",
            verse: "The Lord is close to the brokenhearted and saves those who are crushed in spirit.",
            reference: "Psalm 34:18",
            reason: "Your journal entry mentioned loneliness. You are not alone."
        ),
        LifeContext(
            time: "Saturday, 6:30 AM",
            situation: "Your anniversary morning",
            icon: "heart.fill",
            verse: "Love is patient, love is kind. It does not envy, it does not boast, it is not proud.",
            reference: "1 Corinthians 13:4",
            reason: "Celebrating 5 years together. A reminder of the love you've built."
        ),
        LifeContext(
            time: "Wednesday, 3:15 PM",
            situation: "After receiving difficult news",
            icon: "cloud.rain.fill",
            verse: "Come to me, all you who are weary and burdened, and I will give you rest.",
            reference: "Matthew 11:28",
            reason: "The news was hard. Rest is offered to you."
        )
    ]

    var currentContextData: LifeContext {
        contexts[currentContext]
    }

    var body: some View {
        ZStack {
            // Soft ambient background
            ambientBackground

            VStack(spacing: 0) {
                // Header
                header

                Spacer()

                // Context card or verse reveal
                if showingVerse {
                    verseReveal
                } else {
                    contextCard
                }

                Spacer()

                // Navigation dots and action
                bottomSection
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulsePhase = 1
            }
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            // Soft gradient
            LinearGradient(
                colors: [
                    Color(hex: "0f172a"),
                    Color(hex: "1e1b4b"),
                    Color(hex: "0f172a")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient glow
            RadialGradient(
                colors: [
                    Color(hex: "3b82f6").opacity(0.15 + pulsePhase * 0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )

            // Soft particles
            GeometryReader { geo in
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: CGFloat.random(in: 100...200))
                        .blur(radius: 50)
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(spacing: 4) {
                Text("SCRIPTURE FINDS YOU")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "60a5fa"))

                Text("Context-aware verses")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Color.clear.frame(width: 20)
        }
        .padding(.top, 60)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: isVisible)
    }

    // MARK: - Context Card

    private var contextCard: some View {
        VStack(spacing: 32) {
            // Time and context
            VStack(spacing: 16) {
                Text(currentContextData.time)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))

                // Situation icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "3b82f6").opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(1 + pulsePhase * 0.1)

                    Image(systemName: currentContextData.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: "60a5fa"))
                }

                Text(currentContextData.situation)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            // Notification card
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // App icon
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "d4a853"), Color(hex: "b8942e")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("BibleStudy")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("A verse for this moment")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Text("now")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Divider()
                    .background(.white.opacity(0.1))

                Text(currentContextData.reason)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )

            // Tap to reveal
            Button(action: revealVerse) {
                Text("Tap to reveal verse")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "60a5fa"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: "3b82f6").opacity(0.2))
                    )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 30)
        .animation(.spring(duration: 0.7).delay(0.2), value: isVisible)
    }

    // MARK: - Verse Reveal

    private var verseReveal: some View {
        VStack(spacing: 32) {
            // Glowing verse card
            VStack(spacing: 24) {
                // Quote mark
                Text("\u{201C}")
                    .font(.system(size: 60, weight: .light, design: .serif))
                    .foregroundStyle(Color(hex: "60a5fa").opacity(0.5))
                    .offset(y: 10)

                // Verse text
                Text(currentContextData.verse)
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)

                // Reference
                Text(currentContextData.reference)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "60a5fa"))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1e3a5f").opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "60a5fa").opacity(0.5),
                                        Color(hex: "3b82f6").opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color(hex: "3b82f6").opacity(0.3), radius: 30, y: 10)
            )

            // Actions
            HStack(spacing: 24) {
                actionButton(icon: "bookmark", label: "Save")
                actionButton(icon: "square.and.arrow.up", label: "Share")
                actionButton(icon: "text.quote", label: "Reflect")
            }

            // Next context button
            Button(action: nextContext) {
                Text("See another moment")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private func actionButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Context dots
            HStack(spacing: 8) {
                ForEach(0..<contexts.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentContext ? Color(hex: "60a5fa") : .white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.bottom, 40)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)
    }

    // MARK: - Actions

    private func revealVerse() {
        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            showingVerse = true
        }
    }

    private func nextContext() {
        withAnimation(.easeOut(duration: 0.3)) {
            showingVerse = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(duration: 0.5)) {
                currentContext = (currentContext + 1) % contexts.count
            }
        }
    }
}

// MARK: - Life Context Model

struct LifeContext {
    let time: String
    let situation: String
    let icon: String
    let verse: String
    let reference: String
    let reason: String
}

// MARK: - Preview

#Preview {
    ScriptureFindsYouPOC()
}
