import SwiftUI

// MARK: - AI Chat Directory View
// Main dark-themed directory listing all AI chat design variations

struct AIChatDirectoryView: View {
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Dark background
            ChatPalette.Directory.background
                .ignoresSafeArea()

            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    ChatPalette.Directory.accent.opacity(0.03)
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
                        .padding(.top, 24)

                    // Divider
                    headerDivider
                        .padding(.vertical, 32)

                    // Card list
                    cardList
                        .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: 48)
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
        VStack(spacing: 16) {
            // Decorative icon
            ZStack {
                Circle()
                    .fill(ChatPalette.Directory.accent.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(ChatPalette.Directory.accent)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isVisible)

            // Title
            Text("AI Chat Options")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(ChatPalette.Directory.primaryText)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: isVisible)

            // Subtitle
            Text("Compare design variations for Bible study conversations")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ChatPalette.Directory.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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
                            ChatPalette.Directory.accent.opacity(0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Center ornament
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(ChatPalette.Directory.accent.opacity(0.6))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            ChatPalette.Directory.accent.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 48)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: isVisible)
    }

    // MARK: - Card List

    private var cardList: some View {
        VStack(spacing: 20) {
            ForEach(Array(ChatVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                ShowcaseChatCard(variant: variant) {
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
    private func destinationView(for variant: ChatVariant) -> some View {
        switch variant {
        case .minimalStudio:
            MinimalStudioChatView()
        case .scholarlyCompanion:
            ScholarlyCompanionChatView()
        case .warmSanctuary:
            WarmSanctuaryChatView()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AIChatDirectoryView()
    }
}
