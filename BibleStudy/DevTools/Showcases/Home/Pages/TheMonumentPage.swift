import SwiftUI

// MARK: - The Monument Page
// Sculptural design inspired by Vatican marble statues and heroic Roman figures
// Design: Cool stone tones, moonlit highlights, draped apostles in heroic poses
// Theme Tokens: moonlitMarble, stoicSlate, stoicCharcoal, stoicGray, stoicTaupe
// Philosophy: Inner virtue, stoic resilience, timeless forms

struct TheMonumentPage: View {
    @State private var isAwakened = false
    @State private var stonePulse = false
    @Environment(\.dismiss) private var dismiss

    // Mock data
    private let greeting = SanctuaryMockData.fullGreeting
    private let dailyVerse = SanctuaryMockData.dailyVerse
    private let activePlan = SanctuaryMockData.activePlan

    var body: some View {
        ZStack {
            // Stone gallery background
            backgroundLayer

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Sculptural header
                    sculpturalHeader
                        .padding(.top, 50)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Virtue pedestal (main card)
                    virtuePedestalCard
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Stone relief divider
                    stoneReliefDivider
                        .padding(.bottom, Theme.Spacing.xl)

                    // Apostle gallery (feature cards)
                    apostleGallery
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)

                    // Resilience reflection
                    resilienceSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(Typography.Icon.sm)
                        Text("Back")
                            .font(Typography.Command.callout)
                    }
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.heavy))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                // Chisel mark
                Image(systemName: "staroflife.fill")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.medium))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(Theme.Animation.settle) {
                isAwakened = true
            }
            withAnimation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true)
            ) {
                stonePulse = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            // Deep slate base
            Color(hex: "4A5568")
                .ignoresSafeArea()

            // Marble texture gradient
            LinearGradient(
                colors: [
                    Color.surfaceSlate,
                    Color(hex: "4A5568"),
                    Color.surfaceSlate.opacity(Theme.Opacity.pressed)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Moonlight from above
            RadialGradient(
                colors: [
                    Color.decorativeMarble.opacity(stonePulse ? 0.06 : 0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 450
            )
            .ignoresSafeArea()

            // Stone veining effect (subtle lines)
            GeometryReader { geometry in
                Path { path in
                    // Diagonal veins
                    for index in stride(from: 0, to: 5, by: 1) {
                        let offset = CGFloat(index) * 80
                        path.move(to: CGPoint(x: offset, y: 0))
                        path.addLine(to: CGPoint(x: offset + geometry.size.height * 0.3, y: geometry.size.height))
                    }
                }
                .stroke(Color.decorativeMarble.opacity(Theme.Opacity.faint), lineWidth: 1)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Sculptural Header

    private var sculpturalHeader: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Draped figure silhouette (abstract)
            ZStack {
                // Base pedestal
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(Color.feedbackInfo.opacity(Theme.Opacity.subtle))
                    .frame(width: 80, height: 8)
                    .offset(y: 50)

                // Figure (abstract representation)
                VStack(spacing: 0) {
                    // Head
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.decorativeMarble.opacity(Theme.Opacity.subtle), Color.feedbackInfo.opacity(Theme.Opacity.light)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)

                    // Draped body (triangular)
                    Triangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.decorativeMarble.opacity(Theme.Opacity.light), Color.feedbackInfo.opacity(Theme.Opacity.divider)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 70)
                }
                .shadow(color: Color.black.opacity(Theme.Opacity.subtle), radius: 10, x: 5, y: 5)
            }
            .frame(height: 130)

            // Greeting
            VStack(spacing: Theme.Spacing.xs) {
                Text("MONUMENTUM")
                    .font(Typography.Icon.xxxs.weight(.semibold))
                    .tracking(4)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.tertiary))

                Text("Stand Resolute")
                    .font(.custom("CormorantGaramond-SemiBold", size: 32))
                    .foregroundStyle(Color.decorativeMarble)

                Text("Like marble, be shaped by discipline")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.stoicLightGray)
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .scaleEffect(isAwakened ? 1 : 0.95)
        .animation(.easeOut(duration: 0.8).delay(0.1), value: isAwakened)
    }

    // MARK: - Virtue Pedestal Card

    private var virtuePedestalCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Pedestal header
            HStack {
                Text("TODAY'S MEDITATION")
                    .font(Typography.Icon.xxs.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.tertiary))

                Spacer()

                // Virtue indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.decorativeTaupe)
                        .frame(width: 6, height: 6)
                    Text("FORTITUDE")
                        .font(Typography.Icon.xxxs)
                        .tracking(1)
                        .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.heavy))
                }
            }

            // Scripture carved in stone style
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(dailyVerse.text)
                    .font(.custom("CormorantGaramond-Regular", size: 21))
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.high))
                    .lineSpacing(7)

                // Reference
                HStack(spacing: Theme.Spacing.sm) {
                    Rectangle()
                        .fill(Color.decorativeTaupe.opacity(Theme.Opacity.medium))
                        .frame(width: 16, height: 1)

                    Text(dailyVerse.reference)
                        .font(.custom("CormorantGaramond-SemiBold", size: 13))
                        .foregroundStyle(Color.decorativeTaupe)
                }
            }

            // Contemplation button
            Button {
                // Begin
            } label: {
                HStack {
                    Spacer()
                    Text("Begin Contemplation")
                        .font(Typography.Icon.sm)
                    Spacer()
                }
                .foregroundStyle(Color.decorativeMarble)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .fill(Color.feedbackInfo.opacity(Theme.Opacity.light))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.input)
                        .strokeBorder(Color.decorativeMarble.opacity(Theme.Opacity.light), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.surfaceSlate.opacity(Theme.Opacity.medium))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Color.decorativeMarble.opacity(Theme.Opacity.overlay), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: isAwakened)
    }

    // MARK: - Stone Relief Divider

    private var stoneReliefDivider: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Left relief pattern
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.feedbackInfo.opacity(Theme.Opacity.subtle))
                        .frame(width: 3, height: 12)
                }
            }

            // Central medallion
            Circle()
                .fill(Color.feedbackInfo.opacity(Theme.Opacity.light))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .strokeBorder(Color.decorativeMarble.opacity(Theme.Opacity.light), lineWidth: 1)
                )

            // Center line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.feedbackInfo.opacity(Theme.Opacity.subtle), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Central medallion
            Circle()
                .fill(Color.feedbackInfo.opacity(Theme.Opacity.light))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .strokeBorder(Color.decorativeMarble.opacity(Theme.Opacity.light), lineWidth: 1)
                )

            // Right relief pattern
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.feedbackInfo.opacity(Theme.Opacity.subtle))
                        .frame(width: 3, height: 12)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .opacity(isAwakened ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.4), value: isAwakened)
    }

    // MARK: - Apostle Gallery

    private var apostleGallery: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("VIRTUES GALLERY")
                .font(Typography.Icon.xxs)
                .tracking(2)
                .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.medium))

            // Horizontal scroll of virtue cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    MonumentVirtueCard(
                        virtue: "Wisdom",
                        icon: "lightbulb.fill",
                        description: "Discern truth"
                    )

                    MonumentVirtueCard(
                        virtue: "Courage",
                        icon: "shield.fill",
                        description: "Face trials"
                    )

                    MonumentVirtueCard(
                        virtue: "Justice",
                        icon: "scale.3d",
                        description: "Act rightly"
                    )

                    MonumentVirtueCard(
                        virtue: "Temperance",
                        icon: "circle.hexagongrid.fill",
                        description: "Exercise restraint"
                    )
                }
                .padding(.horizontal, 2)
            }
        }
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isAwakened)
    }

    // MARK: - Resilience Section

    private var resilienceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Chiseled header
            HStack(spacing: Theme.Spacing.sm) {
                Rectangle()
                    .fill(Color.decorativeTaupe.opacity(Theme.Opacity.lightMedium))
                    .frame(width: 20, height: 2)

                Text("ON RESILIENCE")
                    .font(Typography.Icon.xxs)
                    .tracking(2)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.tertiary))

                Rectangle()
                    .fill(Color.decorativeTaupe.opacity(Theme.Opacity.lightMedium))
                    .frame(width: 20, height: 2)
            }

            // Epictetus quote
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("\"It's not what happens to you, but how you react to it that matters.\"")
                    .font(.custom("CormorantGaramond-Italic", size: 17))
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.pressed))
                    .lineSpacing(4)

                Text("— EPICTETUS")
                    .font(Typography.Icon.xxxs.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.tertiary))
            }

            // Daily practice prompt
            Button {
                // Journal
            } label: {
                HStack {
                    Image(systemName: "pencil.line")
                        .font(Typography.Command.caption)
                    Text("Record today's challenge")
                        .font(Typography.Command.meta)
                }
                .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.heavy))
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Color.feedbackInfo.opacity(Theme.Opacity.overlay))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .strokeBorder(Color.decorativeTaupe.opacity(Theme.Opacity.divider), lineWidth: 1)
        )
        .opacity(isAwakened ? 1 : 0)
        .offset(y: isAwakened ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.6), value: isAwakened)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Monument Virtue Card

private struct MonumentVirtueCard: View {
    let virtue: String
    let icon: String
    let description: String

    var body: some View {
        Button {
            // Explore virtue
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                // Pedestal top
                Rectangle()
                    .fill(Color.feedbackInfo.opacity(Theme.Opacity.subtle))
                    .frame(width: 60, height: 3)

                Image(systemName: icon)
                    .font(Typography.Icon.lg.weight(.ultraLight))
                    .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.heavy))
                    .frame(height: 36)

                VStack(spacing: 2) {
                    Text(virtue.uppercased())
                        .font(Typography.Command.meta.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(Color.decorativeMarble.opacity(Theme.Opacity.pressed))

                    Text(description)
                        .font(Typography.Icon.xxs)
                        .foregroundStyle(Color.stoicLightGray)
                }

                // Pedestal bottom
                Rectangle()
                    .fill(Color.feedbackInfo.opacity(Theme.Opacity.light))
                    .frame(width: 70, height: 4)
            }
            .frame(width: 100)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .fill(Color.surfaceSlate.opacity(Theme.Opacity.lightMedium))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.input)
                    .strokeBorder(Color.feedbackInfo.opacity(Theme.Opacity.light), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TheMonumentPage()
    }
}
