import SwiftUI

// MARK: - Reader Showcase Directory View
// Main dark-themed directory listing all reader page variations

struct ReaderShowcaseDirectoryView: View {
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Dark background
            Color.showcaseBackground
                .ignoresSafeArea()

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.accentBronze.opacity(Theme.Opacity.faint)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Main content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, Theme.Spacing.xl)

                    // Divider
                    headerDivider
                        .padding(.vertical, Theme.Spacing.xxl)

                    // Card list
                    cardList
                        .padding(.horizontal, Theme.Spacing.lg)

                    Spacer()
                        .frame(height: Theme.Spacing.xxl)
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Decorative icon
            Image(systemName: "book.pages.fill")
                .font(Typography.Icon.xxl.weight(.light))
                .foregroundStyle(Color.accentBronze)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)
                .animation(Theme.Animation.settle.delay(0.1), value: isVisible)

            // Title
            Text("Reading the Bible")
                .font(.custom("CormorantGaramond-SemiBold", size: 32))
                .foregroundStyle(Color.showcasePrimaryText)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)

            // Subtitle
            Text("Explore different reading experiences")
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color.showcaseSecondaryText)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)
        }
    }

    // MARK: - Header Divider

    private var headerDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.accentBronze.opacity(Theme.Opacity.lightMedium)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center ornament
            Image(systemName: "sparkle")
                .font(Typography.Icon.xxs)
                .foregroundStyle(Color.accentBronze.opacity(Theme.Opacity.tertiary))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentBronze.opacity(Theme.Opacity.lightMedium),
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

    // MARK: - Card List

    private var cardList: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ForEach(Array(ReaderVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                ShowcaseReaderCard(variant: variant) {
                    destinationView(for: variant)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(
                    Theme.Animation.settle.delay(0.5 + Double(index) * 0.1),
                    value: isVisible
                )
            }
        }
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for variant: ReaderVariant) -> some View {
        switch variant {
        case .illuminatedScriptorium:
            IlluminatedScriptoriumReaderView()
        case .candlelitChapel:
            CandlelitChapelReaderView()
        case .scholarsMarginalia:
            BibleReaderView()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReaderShowcaseDirectoryView()
    }
    .environment(BibleService.shared)
}
