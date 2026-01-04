import SwiftUI

// MARK: - Room Navigator
// Horizontal scrollable room selector for navigating the memory palace
// Each room is represented by an icon that glows when selected

struct RoomNavigator: View {
    let rooms: [PalaceRoom]
    @Binding var currentRoom: Int
    let accentColor: Color
    let isVisible: Bool
    let onRoomTap: ((Int) -> Void)?

    init(
        rooms: [PalaceRoom] = PalaceRoom.psalm23Rooms,
        currentRoom: Binding<Int>,
        accentColor: Color,
        isVisible: Bool = true,
        onRoomTap: ((Int) -> Void)? = nil
    ) {
        self.rooms = rooms
        self._currentRoom = currentRoom
        self.accentColor = accentColor
        self.isVisible = isVisible
        self.onRoomTap = onRoomTap
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                    ForEach(Array(rooms.enumerated()), id: \.offset) { index, room in
                        roomButton(index: index, room: room)
                            .id(index)
                    }
                }
                .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
            }
            .onChange(of: currentRoom) { _, newValue in
                withAnimation(HomeShowcaseTheme.Animation.sacredSpring) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .padding(.top, HomeShowcaseTheme.Spacing.xl)
        .opacity(isVisible ? 1 : 0)
        .accessibleAnimation(HomeShowcaseTheme.Animation.reverent.delay(0.2), value: isVisible)
    }

    private func roomButton(index: Int, room: PalaceRoom) -> some View {
        Button(action: {
            withAnimation(HomeShowcaseTheme.Animation.sacredSpring) {
                currentRoom = index
            }
            onRoomTap?(index)
        }) {
            VStack(spacing: HomeShowcaseTheme.Spacing.sm) {
                ZStack {
                    // Glow effect for selected room
                    if currentRoom == index {
                        Circle()
                            .fill(room.primaryColor.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .blur(radius: 8)
                    }

                    Circle()
                        .fill(currentRoom == index ? room.primaryColor : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: room.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(currentRoom == index ? .white : .white.opacity(0.5))
                }

                Text(room.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(currentRoom == index ? .white : .white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .accessibilityLabel("\(room.name), Room \(index + 1) of \(rooms.count)")
        .accessibilityHint(currentRoom == index ? "Currently selected" : "Double tap to navigate")
    }
}

// MARK: - Light Mode Variant

struct RoomNavigatorLight: View {
    let rooms: [PalaceRoom]
    @Binding var currentRoom: Int
    let accentColor: Color
    let isVisible: Bool
    let onRoomTap: ((Int) -> Void)?

    init(
        rooms: [PalaceRoom] = PalaceRoom.psalm23Rooms,
        currentRoom: Binding<Int>,
        accentColor: Color,
        isVisible: Bool = true,
        onRoomTap: ((Int) -> Void)? = nil
    ) {
        self.rooms = rooms
        self._currentRoom = currentRoom
        self.accentColor = accentColor
        self.isVisible = isVisible
        self.onRoomTap = onRoomTap
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HomeShowcaseTheme.Spacing.lg) {
                    ForEach(Array(rooms.enumerated()), id: \.offset) { index, room in
                        roomButton(index: index, room: room)
                            .id(index)
                    }
                }
                .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
            }
            .onChange(of: currentRoom) { _, newValue in
                withAnimation(HomeShowcaseTheme.Animation.sacredSpring) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .padding(.top, HomeShowcaseTheme.Spacing.xl)
        .opacity(isVisible ? 1 : 0)
        .accessibleAnimation(HomeShowcaseTheme.Animation.reverent.delay(0.2), value: isVisible)
    }

    private func roomButton(index: Int, room: PalaceRoom) -> some View {
        Button(action: {
            withAnimation(HomeShowcaseTheme.Animation.sacredSpring) {
                currentRoom = index
            }
            onRoomTap?(index)
        }) {
            VStack(spacing: HomeShowcaseTheme.Spacing.xs) {
                // Marginalia-style room number
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(currentRoom == index ? Color.marginRed : Color.footnoteGray)

                // Simple rectangular indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(currentRoom == index ? accentColor : Color.scholarInk.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: room.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(currentRoom == index ? .white : Color.scholarInk.opacity(0.4))
                    )

                Text(room.name)
                    .font(.system(size: 9, weight: .medium, design: .serif))
                    .foregroundStyle(currentRoom == index ? Color.scholarInk : Color.footnoteGray)
                    .lineLimit(1)
            }
            .frame(width: 60)
        }
    }
}

// MARK: - Preview

#Preview("Dark Navigator") {
    ZStack {
        Color.celestialDeep
        VStack {
            RoomNavigator(
                currentRoom: .constant(2),
                accentColor: .celestialPurple
            )
            Spacer()
        }
    }
    .ignoresSafeArea()
}

#Preview("Light Navigator") {
    ZStack {
        Color.vellumCream
        VStack {
            RoomNavigatorLight(
                currentRoom: .constant(1),
                accentColor: .scholarIndigo
            )
            Spacer()
        }
    }
    .ignoresSafeArea()
}
