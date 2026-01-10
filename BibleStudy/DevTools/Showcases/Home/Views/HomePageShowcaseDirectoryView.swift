import SwiftUI

// MARK: - Home Page Showcase Directory View
// Main dark-themed directory listing all home page variations
// Design: Stoic aesthetic with contemplative atmosphere

struct HomePageShowcaseDirectoryView: View {
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Dark background with subtle texture
            backgroundLayer

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, Theme.Spacing.xl)

                    // Ornamental divider
                    stoicDivider
                        .padding(.vertical, Theme.Spacing.xxl)

                    // Design philosophy quote
                    philosophyQuote
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.xxl)

                    // Card list
                    cardList
                        .padding(.horizontal, Theme.Spacing.lg)

                    Spacer()
                        .frame(height: Theme.Spacing.xxl * 2)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }

    // MARK: - Background Layer

    private var backgroundLayer: some View {
        ZStack {
            Color.showcaseBackground
                .ignoresSafeArea()

            // Subtle gradient overlay (marble-like depth)
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.decorativeTaupe.opacity(Theme.Opacity.faint),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Vignette effect
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(Theme.Opacity.subtle)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Classical icon
            Image(systemName: "building.columns")
                .font(Typography.Icon.hero.weight(.ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.decorativeTaupe, Color.decorativeTaupe.opacity(Theme.Opacity.tertiary)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)
                .animation(Theme.Animation.settle.delay(0.1), value: isVisible)

            // Title
            VStack(spacing: Theme.Spacing.xs) {
                Text("HOME PAGE")
                    .font(Typography.Icon.xxs.weight(.medium))
                    .tracking(4)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.heavy))

                Text("Options")
                    .font(.custom("CormorantGaramond-SemiBold", size: 36))
                    .foregroundStyle(Color.showcasePrimaryText)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)

            // Subtitle
            Text("Explore stoic design variations")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.showcaseSecondaryText)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)
        }
    }

    // MARK: - Stoic Divider

    private var stoicDivider: some View {
        HStack(spacing: 20) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.decorativeTaupe.opacity(Theme.Opacity.subtle)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center laurel ornament
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .font(Typography.Icon.xxxs)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.medium))
                    .rotationEffect(.degrees(-45))

                Circle()
                    .fill(Color.decorativeTaupe.opacity(Theme.Opacity.lightMedium))
                    .frame(width: 4, height: 4)

                Image(systemName: "leaf.fill")
                    .font(Typography.Icon.xxxs)
                    .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.medium))
                    .rotationEffect(.degrees(45))
                    .scaleEffect(x: -1, y: 1)
            }

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.decorativeTaupe.opacity(Theme.Opacity.subtle),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)
    }

    // MARK: - Philosophy Quote

    private var philosophyQuote: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("\"The soul becomes dyed with the color of its thoughts.\"")
                .font(.custom("CormorantGaramond-Italic", size: 16))
                .foregroundStyle(Color.showcaseSecondaryText)
                .multilineTextAlignment(.center)

            Text("- MARCUS AURELIUS")
                .font(Typography.Icon.xxs)
                .tracking(2)
                .foregroundStyle(Color.decorativeTaupe.opacity(Theme.Opacity.tertiary))
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.5), value: isVisible)
    }

    // MARK: - Card List

    private var cardList: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ForEach(Array(HomePageVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                StoicShowcaseCard(variant: variant) {
                    destinationView(for: variant)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(
                    Theme.Animation.settle.delay(0.6 + Double(index) * 0.1),
                    value: isVisible
                )
            }
        }
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for variant: HomePageVariant) -> some View {
        switch variant {
        case .theForum:
            TheForumPage()
        case .thePortico:
            ThePorticoPage()
        case .theMeditationChamber:
            TheMeditationChamberPage()
        case .theStoa:
            TheStoaPage()
        case .theAtrium:
            TheAtriumPage()
        case .theScriptorium:
            TheScriptoriumPage()
        case .theLibrary:
            TheLibraryPage()
        case .theVigil:
            TheVigilPage()
        case .theThreshold:
            TheThresholdPage()
        case .theBasilica:
            TheBasilicaPage()
        case .theMonument:
            TheMonumentPage()
        case .theTriumph:
            TheTriumphPage()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomePageShowcaseDirectoryView()
    }
}
