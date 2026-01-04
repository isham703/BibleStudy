import SwiftUI

// MARK: - Sacred Threshold Page
// Architectural Journey + Spatial Navigation aesthetic
// Exploratory, adventurous design with room-based navigation

struct SacredThresholdPage: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false
    @State private var currentRoom: SacredRoom = .memoryPalace

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic ambient background
                ambientBackground
                    .animation(.easeInOut(duration: 0.8), value: currentRoom)

                // Floating particles
                if !reduceMotion {
                    FloatingParticles(roomColor: currentRoom.primaryColor)
                        .animation(.easeInOut(duration: 0.5), value: currentRoom)
                }

                // Architectural frame
                ArchitecturalFrame()
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 1.0).delay(0.2), value: isVisible)

                // Main content
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.lg)

                    Spacer()
                        .frame(height: AppTheme.Spacing.xl)

                    // Room indicators
                    roomIndicators
                        .opacity(isVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.6), value: isVisible)

                    Spacer()
                        .frame(height: AppTheme.Spacing.lg)

                    // Paging carousel
                    roomCarousel(geometry: geometry)

                    Spacer()
                        .frame(height: AppTheme.Spacing.lg)

                    // Swipe hints
                    swipeHints
                        .opacity(isVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.8), value: isVisible)

                    Spacer()
                        .frame(height: AppTheme.Spacing.xl)

                    // Mini room icons
                    miniRoomIcons
                        .opacity(isVisible ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.9), value: isVisible)

                    Spacer()
                        .frame(height: AppTheme.Spacing.xxl)
                }
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        LinearGradient(
            colors: [
                currentRoom.ambientColor.opacity(0.4),
                Color.black.opacity(0.95),
                Color.black
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("SACRED THRESHOLD")
                .font(SanctuaryTypography.Threshold.headerTitle)
                .tracking(6)
                .foregroundStyle(Color.white.opacity(0.9))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: isVisible)

            Text("Choose your path")
                .font(SanctuaryTypography.Threshold.headerSubtitle)
                .foregroundStyle(Color.white.opacity(0.5))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.5), value: isVisible)
        }
    }

    // MARK: - Room Indicators

    private var roomIndicators: some View {
        HStack(spacing: 8) {
            ForEach(SacredRoom.allCases, id: \.self) { room in
                Circle()
                    .fill(room == currentRoom ? room.primaryColor : Color.white.opacity(0.3))
                    .frame(width: room == currentRoom ? 10 : 6, height: room == currentRoom ? 10 : 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentRoom)
            }
        }
    }

    // MARK: - Room Carousel

    private func roomCarousel(geometry: GeometryProxy) -> some View {
        TabView(selection: $currentRoom) {
            ForEach(SacredRoom.allCases, id: \.self) { room in
                RoomCard(room: room, isVisible: isVisible)
                    .tag(room)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: geometry.size.height * 0.55)
        .onChange(of: currentRoom) { _, _ in
            HomeShowcaseHaptics.roomTransition()
        }
    }

    // MARK: - Swipe Hints

    private var swipeHints: some View {
        HStack {
            // Left hint
            if let prevRoom = currentRoom.previous {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .medium))
                    Text(prevRoom.shortName)
                        .font(SanctuaryTypography.Threshold.swipeHint)
                }
                .foregroundStyle(Color.white.opacity(0.3))
            } else {
                Spacer().frame(width: 80)
            }

            Spacer()

            // Center dot
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 4, height: 4)

            Spacer()

            // Right hint
            if let nextRoom = currentRoom.next {
                HStack(spacing: 4) {
                    Text(nextRoom.shortName)
                        .font(SanctuaryTypography.Threshold.swipeHint)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.3))
            } else {
                Spacer().frame(width: 80)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }

    // MARK: - Mini Room Icons

    private var miniRoomIcons: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SacredRoom.allCases, id: \.self) { room in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentRoom = room
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: room.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(room == currentRoom ? room.primaryColor : Color.white.opacity(0.4))

                                Circle()
                                    .fill(room == currentRoom ? room.primaryColor : Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(width: 50, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(room == currentRoom ? room.primaryColor.opacity(0.15) : Color.white.opacity(0.05))
                            )
                        }
                        .buttonStyle(.plain)
                        .id(room)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
            }
            .onChange(of: currentRoom) { _, newRoom in
                withAnimation(.spring(response: 0.3)) {
                    proxy.scrollTo(newRoom, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Sacred Room Enum

enum SacredRoom: String, CaseIterable {
    case livingScripture
    case livingCommentary
    case memoryPalace
    case prayersDeep
    case compline

    var name: String {
        switch self {
        case .livingScripture: return "Living Scripture"
        case .livingCommentary: return "Living Commentary"
        case .memoryPalace: return "Memory Palace"
        case .prayersDeep: return "Prayers from the Deep"
        case .compline: return "Compline"
        }
    }

    var shortName: String {
        switch self {
        case .livingScripture: return "Scripture"
        case .livingCommentary: return "Commentary"
        case .memoryPalace: return "Memory"
        case .prayersDeep: return "Prayers"
        case .compline: return "Compline"
        }
    }

    var icon: String {
        switch self {
        case .livingScripture: return "book.pages.fill"
        case .livingCommentary: return "text.book.closed.fill"
        case .memoryPalace: return "building.columns.fill"
        case .prayersDeep: return "hands.sparkles.fill"
        case .compline: return "moon.stars.fill"
        }
    }

    var description: String {
        switch self {
        case .livingScripture: return "Enter the Prodigal Son's story in first person"
        case .livingCommentary: return "Discover deep insights with living marginalia"
        case .memoryPalace: return "Walk through 5 rooms to memorize Psalm 23"
        case .prayersDeep: return "Craft a personal prayer from the heart"
        case .compline: return "End your day with ancient evening prayers"
        }
    }

    var progress: String? {
        switch self {
        case .livingScripture: return "5 scenes"
        case .livingCommentary: return "4 insights"
        case .memoryPalace: return "2/5 rooms"
        case .prayersDeep: return nil
        case .compline: return "~15 min"
        }
    }

    var primaryColor: Color {
        switch self {
        case .livingScripture: return .thresholdGold
        case .livingCommentary: return .thresholdIndigo
        case .memoryPalace: return .thresholdPurple
        case .prayersDeep: return .thresholdRose
        case .compline: return .thresholdBlue
        }
    }

    var ambientColor: Color {
        switch self {
        case .livingScripture: return .thresholdGoldAmbient
        case .livingCommentary: return .thresholdIndigoAmbient
        case .memoryPalace: return .thresholdPurpleAmbient
        case .prayersDeep: return .thresholdRoseAmbient
        case .compline: return .thresholdBlueAmbient
        }
    }

    var previous: SacredRoom? {
        guard let index = SacredRoom.allCases.firstIndex(of: self), index > 0 else { return nil }
        return SacredRoom.allCases[index - 1]
    }

    var next: SacredRoom? {
        guard let index = SacredRoom.allCases.firstIndex(of: self), index < SacredRoom.allCases.count - 1 else { return nil }
        return SacredRoom.allCases[index + 1]
    }

    var aiFeature: AIFeature {
        switch self {
        case .livingScripture: return .livingScripture
        case .livingCommentary: return .livingCommentary
        case .memoryPalace: return .memoryPalace
        case .prayersDeep: return .prayersFromDeep
        case .compline: return .compline
        }
    }
}

// MARK: - Room Card

private struct RoomCard: View {
    let room: SacredRoom
    let isVisible: Bool

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        NavigationLink(destination: room.aiFeature.destinationView) {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Icon
                Image(systemName: room.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(room.primaryColor)
                    .scaleEffect(pulseScale)

                // Room name
                Text(room.name.uppercased())
                    .font(SanctuaryTypography.Threshold.roomName)
                    .tracking(-1)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)

                // Description
                Text(room.description)
                    .font(SanctuaryTypography.Threshold.roomDescription)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                // Progress (if any)
                if let progress = room.progress {
                    // Progress bar for memory palace
                    if room == .memoryPalace {
                        VStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(room.primaryColor)
                                        .frame(width: geo.size.width * 0.4, height: 8)
                                }
                            }
                            .frame(height: 8)
                            .padding(.horizontal, AppTheme.Spacing.xxl)

                            Text(progress)
                                .font(SanctuaryTypography.Threshold.progressText)
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                    } else {
                        Text(progress)
                            .font(SanctuaryTypography.Threshold.progressText)
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }

                Spacer()
                    .frame(height: AppTheme.Spacing.md)

                // CTA Button
                HStack(spacing: 8) {
                    Text("Enter \(room.shortName)")
                        .font(SanctuaryTypography.Threshold.ctaButton)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(room.primaryColor)
                )
                .shadow(color: room.primaryColor.opacity(0.4), radius: 12, y: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xxl)
            .background(cardBackground)
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .brightness(isPressed ? -0.05 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 60)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.5), value: isVisible)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
        .simultaneousGesture(TapGesture().onEnded { _ in
            HomeShowcaseHaptics.portalEnter()
        })
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                HomeShowcaseHaptics.thresholdPress()
            }
        }, perform: {})
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        room.primaryColor.opacity(0.1),
                        Color.black.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [
                        room.primaryColor.opacity(0.5),
                        room.primaryColor.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1.5
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SacredThresholdPage()
    }
}
