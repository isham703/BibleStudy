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
                    Color.divineGold.opacity(0.03)
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
                        .padding(.top, AppTheme.Spacing.xl)

                    // Divider
                    headerDivider
                        .padding(.vertical, AppTheme.Spacing.xxl)

                    // Card list
                    cardList
                        .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                        .frame(height: AppTheme.Spacing.xxxl)
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
        VStack(spacing: AppTheme.Spacing.md) {
            // Decorative icon
            Image(systemName: "book.pages.fill")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.divineGold)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isVisible)

            // Title
            Text("Reading the Bible")
                .font(.custom("CormorantGaramond-SemiBold", size: 32))
                .foregroundStyle(Color.showcasePrimaryText)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)

            // Subtitle
            Text("Explore different reading experiences")
                .font(.system(size: 15, weight: .regular))
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
                            Color.divineGold.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center ornament
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.divineGold.opacity(0.6))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.divineGold.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, AppTheme.Spacing.xxxl)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)
    }

    // MARK: - Card List

    private var cardList: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ForEach(Array(ReaderVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                ShowcaseReaderCard(variant: variant) {
                    destinationView(for: variant)
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 30)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8).delay(0.5 + Double(index) * 0.1),
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
            ScholarReaderView()
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
