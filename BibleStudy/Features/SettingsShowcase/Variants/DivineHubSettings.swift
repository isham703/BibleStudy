import SwiftUI

// MARK: - Divine Hub Settings
/// A bold hub-and-spoke navigation design with prominent iconography,
/// quick-access toggle grid, and expandable category panels.

struct DivineHubSettings: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedCategory: HubCategory?
    @State private var showProfileSheet = false

    // Quick toggles state
    @State private var aiEnabled = true
    @State private var darkMode = true
    @State private var syncEnabled = true
    @State private var notificationsEnabled = true

    // Detailed settings state
    @State private var scholarMode = false
    @State private var voiceNarration = false
    @State private var fontSize: Double = 18
    @State private var hapticFeedback = true
    @State private var dailyVerse = true

    var body: some View {
        ZStack {
            // Background
            hubBackground

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    headerSection

                    quickAccessGrid

                    categoryHubs

                    footerSection
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, 60)
                .padding(.bottom, AppTheme.Spacing.xxxl)
            }

            // Top bar
            VStack {
                topBar
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hub Background

    private var hubBackground: some View {
        ZStack {
            Color(hex: "0A0908")
                .ignoresSafeArea()

            // Radial hub glow
            RadialGradient(
                colors: [
                    Color.accentGold.opacity(0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            // Grid pattern overlay
            GridPatternView()
                .opacity(0.02)
                .ignoresSafeArea()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    )
            }

            Spacer()

            Text("SETTINGS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.tertiaryText)
                .kerning(3)

            Spacer()

            Button {
                showProfileSheet = true
            } label: {
                Circle()
                    .fill(Color.accentGold.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text("JS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.accentGold)
                    }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.5))
                .ignoresSafeArea()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Central hub icon
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.accentGold.opacity(0.1 - Double(index) * 0.03), lineWidth: 1)
                        .frame(width: 120 + CGFloat(index) * 40)
                }

                // Main hub
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentGold.opacity(0.3),
                                Color.accentGold.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.accentGold)
                    }
            }
            .padding(.vertical, AppTheme.Spacing.lg)

            Text("Control Center")
                .font(.custom("Cinzel-Regular", size: 24))
                .foregroundStyle(Color.primaryText)

            Text("Tap to toggle • Hold for details")
                .font(Typography.caption)
                .foregroundStyle(Color.tertiaryText)
        }
    }

    // MARK: - Quick Access Grid

    private var quickAccessGrid: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("QUICK ACCESS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.accentGold.opacity(0.7))
                .kerning(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                    GridItem(.flexible(), spacing: AppTheme.Spacing.md)
                ],
                spacing: AppTheme.Spacing.md
            ) {
                QuickToggleTile(
                    icon: "sparkles",
                    title: "AI Insights",
                    isOn: $aiEnabled,
                    color: Color.accentGold
                )

                QuickToggleTile(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    isOn: $darkMode,
                    color: Color(hex: "6B7A9E")
                )

                QuickToggleTile(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    isOn: $syncEnabled,
                    color: Color(hex: "6B9E8F")
                )

                QuickToggleTile(
                    icon: "bell.fill",
                    title: "Notifications",
                    isOn: $notificationsEnabled,
                    color: Color(hex: "9E6B7A")
                )
            }
        }
        .padding(.top, AppTheme.Spacing.lg)
    }

    // MARK: - Category Hubs

    private var categoryHubs: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("CATEGORIES")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.accentGold.opacity(0.7))
                .kerning(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, AppTheme.Spacing.lg)

            ForEach(HubCategory.allCases) { category in
                CategoryHub(
                    category: category,
                    isExpanded: expandedCategory == category,
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if expandedCategory == category {
                                expandedCategory = nil
                            } else {
                                expandedCategory = category
                            }
                        }
                    }
                ) {
                    expandedContent(for: category)
                }
            }
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private func expandedContent(for category: HubCategory) -> some View {
        switch category {
        case .ai:
            VStack(spacing: AppTheme.Spacing.md) {
                HubToggleRow(
                    title: "Scholar Mode",
                    subtitle: "Advanced theological analysis",
                    isOn: $scholarMode
                )
                HubToggleRow(
                    title: "Voice Narration",
                    subtitle: "Audio guidance for insights",
                    isOn: $voiceNarration
                )
                HubNavigationRow(title: "AI Preferences", subtitle: "Customize insight depth")
            }

        case .reading:
            VStack(spacing: AppTheme.Spacing.md) {
                // Font size mini slider
                HStack {
                    Text("Font Size")
                        .font(Typography.body)
                        .foregroundStyle(Color.primaryText)

                    Spacer()

                    HStack(spacing: AppTheme.Spacing.md) {
                        Button {
                            if fontSize > 12 { fontSize -= 2 }
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }

                        Text("\(Int(fontSize))")
                            .font(Typography.monospacedBody)
                            .foregroundStyle(Color.accentGold)
                            .frame(width: 30)

                        Button {
                            if fontSize < 32 { fontSize += 2 }
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .foregroundStyle(Color.secondaryText)
                }
                .padding(.vertical, AppTheme.Spacing.xs)

                HubNavigationRow(title: "Typography", subtitle: "Fonts, spacing, margins")
                HubNavigationRow(title: "Theme", subtitle: "Light, Dark, Sepia, OLED")
                HubNavigationRow(title: "Reading Mode", subtitle: "Scroll, Page Curl")
            }

        case .account:
            VStack(spacing: AppTheme.Spacing.md) {
                HubNavigationRow(title: "Profile", subtitle: "john.smith@email.com")
                HubNavigationRow(title: "Subscription", subtitle: "Premium • Active")
                HubNavigationRow(title: "Data & Privacy", subtitle: "Export, delete data")
                HubDestructiveRow(title: "Sign Out")
            }

        case .more:
            VStack(spacing: AppTheme.Spacing.md) {
                HubToggleRow(
                    title: "Daily Verse",
                    subtitle: "Morning inspiration",
                    isOn: $dailyVerse
                )
                HubToggleRow(
                    title: "Haptic Feedback",
                    subtitle: "Tactile responses",
                    isOn: $hapticFeedback
                )
                HubNavigationRow(title: "About", subtitle: "Version 1.0.0")
                HubNavigationRow(title: "Help & Support", subtitle: "FAQs, contact us")
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Decorative spokes
            HStack(spacing: AppTheme.Spacing.lg) {
                ForEach(0..<5) { _ in
                    Circle()
                        .fill(Color.accentGold.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }

            Text("Divine Hub Design")
                .font(Typography.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.top, AppTheme.Spacing.xxxl)
    }
}

// MARK: - Hub Category

enum HubCategory: String, CaseIterable, Identifiable {
    case ai = "AI & Intelligence"
    case reading = "Reading Experience"
    case account = "Account & Sync"
    case more = "More Options"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ai: return "brain.head.profile"
        case .reading: return "book.fill"
        case .account: return "person.crop.circle.fill"
        case .more: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .ai: return Color.accentGold
        case .reading: return Color(hex: "6B8E9F")
        case .account: return Color(hex: "7A9E7A")
        case .more: return Color(hex: "9E7A8E")
        }
    }

    var itemCount: Int {
        switch self {
        case .ai: return 3
        case .reading: return 4
        case .account: return 4
        case .more: return 4
        }
    }
}

// MARK: - Quick Toggle Tile

struct QuickToggleTile: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            VStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isOn ? color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isOn ? color : Color.tertiaryText)
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isOn ? Color.primaryText : Color.tertiaryText)

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(isOn ? color : Color.tertiaryText.opacity(0.5))
                        .frame(width: 6, height: 6)

                    Text(isOn ? "ON" : "OFF")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isOn ? color : Color.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                    .fill(Color.white.opacity(isOn ? 0.05 : 0.02))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                            .strokeBorder(
                                isOn ? color.opacity(0.3) : Color.white.opacity(0.05),
                                lineWidth: 1
                            )
                    }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// MARK: - Category Hub

struct CategoryHub<Content: View>: View {
    let category: HubCategory
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: AppTheme.Spacing.lg) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(category.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.custom("Cinzel-Regular", size: 16))
                            .foregroundStyle(Color.primaryText)

                        Text("\(category.itemCount) options")
                            .font(Typography.caption)
                            .foregroundStyle(Color.tertiaryText)
                    }

                    Spacer()

                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(category.color)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(AppTheme.Spacing.lg)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(category.color.opacity(0.2))
                        .frame(height: 1)

                    content
                        .padding(AppTheme.Spacing.lg)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .fill(Color.white.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                        .strokeBorder(
                            isExpanded ? category.color.opacity(0.3) : Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                }
        )
    }
}

// MARK: - Hub Toggle Row

struct HubToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(Color.primaryText)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(GoldToggleStyle())
                .labelsHidden()
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - Hub Navigation Row

struct HubNavigationRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        Button {
            // Navigate
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.body)
                        .foregroundStyle(Color.primaryText)

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Color.tertiaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.tertiaryText)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hub Destructive Row

struct HubDestructiveRow: View {
    let title: String

    var body: some View {
        Button {
            // Action
        } label: {
            HStack {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(Color(hex: "C94A4A"))

                Spacer()

                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "C94A4A"))
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Sheet

struct ProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentGold.opacity(0.3), Color.accentGold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Text("JS")
                    .font(.custom("Cinzel-Regular", size: 36))
                    .foregroundStyle(Color.accentGold)
            }
            .padding(.top, AppTheme.Spacing.xl)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text("John Smith")
                    .font(.custom("Cinzel-Regular", size: 24))
                    .foregroundStyle(Color.primaryText)

                Text("john.smith@email.com")
                    .font(Typography.body)
                    .foregroundStyle(Color.secondaryText)

                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("Premium Member")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.accentGold)
                .padding(.top, AppTheme.Spacing.sm)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(Typography.body)
                    .foregroundStyle(Color.accentGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentGold.opacity(0.15))
                    )
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(Color(hex: "141210"))
    }
}

// MARK: - Grid Pattern View

struct GridPatternView: View {
    var body: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 30

            // Vertical lines
            for x in stride(from: 0, to: size.width, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
            }

            // Horizontal lines
            for y in stride(from: 0, to: size.height, by: gridSize) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DivineHubSettings()
    }
}
