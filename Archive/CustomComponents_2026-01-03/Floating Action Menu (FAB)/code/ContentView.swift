//
//  FloatingActionMenuView.swift
//
//  Created by M.Damra on 11/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        FloatingActionMenuView()
    }
}

#Preview {
    ContentView()
}

// MARK: - FAB Menu Item Model
/// Represents a single item in the Floating Action Menu.
/// Each item has:
/// - An icon (SF Symbol)
/// - A label text
/// - A custom color
/// - A highlight state (when selected during drag)
struct FABItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    var isHighlighted: Bool = false
}

// MARK: - Main FAB View
/// This is the main screen that displays:
/// - Background
/// - Sample content
/// - The floating menu button in bottom-right corner
struct FloatingActionMenuView: View {
    @State private var isExpanded = false   // Controls whether menu is open or closed
    
    var body: some View {
        ZStack {
            
            // Background Color
            Color(hex: "0d1b2a")
                .ignoresSafeArea()
            
            // Example content (blurred when menu is expanded)
            VStack {
                Image("logo")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                
                Text("Floating Action Menu")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Tap the button")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            .blur(radius: isExpanded ? 3 : 0)  // Blur when menu opens
            
            // Floating Action Button (FAB) positioned bottom-right
            FloatingActionButton(isExpanded: $isExpanded)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(24)
        }
    }
}

// MARK: - Floating Action Button
/// This struct contains:
/// - The main red FAB button (plus icon)
/// - The animated menu items above it
/// - Drag-to-select logic (like Android circular menus)
struct FloatingActionButton: View {
    
    // MARK: - Properties
    
    /// The menu items shown above the FAB
    @State private var menuItems: [FABItem] = [
        FABItem(icon: "pencil.and.outline", label: "New Note", color: Color(hex: "06d6a0")),
        FABItem(icon: "folder.badge.plus", label: "New Folder", color: Color(hex: "118ab2")),
        FABItem(icon: "square.and.arrow.up", label: "Share", color: Color(hex: "073b4c")),
        FABItem(icon: "tag.fill", label: "Add Tag", color: Color(hex: "ffd166")),
        FABItem(icon: "trash.fill", label: "Delete", color: Color(hex: "ef476f"))
    ]
    
    @Binding var isExpanded: Bool           // Whether menu is open
    @State private var selectedIndex: Int? = nil  // Which item is selected during drag
    @State private var dragOffset: CGSize = .zero // Drag position
    @State private var buttonRotation: Double = 0 // Plus icon rotates when opened
    @State private var showRipple = false         // Ripple effect
    
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private let itemSpacing: CGFloat = 65
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // ================================
            // MENU ITEMS (display only if expanded)
            // ================================
            VStack(alignment: .trailing, spacing: 16) {
                /// Reverse enumerated so the first item appears at top
                ForEach(Array(menuItems.enumerated().reversed()), id: \.element.id) { index, item in
                    fabMenuItem(item: item, index: index)
                }
            }
            .opacity(isExpanded ? 1 : 0)
            .offset(y: -80)
            .gesture(
                /// Drag gesture specifically for menu items
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isExpanded else { return }
                        handleDrag(value: value)  // Tracks which item you're hovering
                    }
                    .onEnded { _ in
                        handleDragEnd()         // Executes selected menu action
                    }
            )
            
            // ==========================================
            // MAIN RED FAB BUTTON (tap or drag)
            // ==========================================
            mainButton
                .onTapGesture {
                    toggleMenu()
                }
                .gesture(
                    /// Drag gestures on the main button
                    /// Minimum distance prevents tap misfire
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            guard isExpanded else { return }
                            handleDrag(value: value)
                        }
                        .onEnded { _ in
                            handleDragEnd()
                        }
                )
        }
    }
    
    // MARK: - Main Button UI
    /// This is the circular red button with the plus icon.
    /// It rotates when the menu opens (plus turns into X).
    private var mainButton: some View {
        ZStack {
            // Outer shadow circle
            Circle()
                .fill(Color(hex: "e63946"))
                .frame(width: 60, height: 60)
                .shadow(color: Color(hex: "e63946").opacity(0.4), radius: 12, x: 0, y: 6)
            
            // Inner gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "e63946"), Color(hex: "c1121f")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            
            // Plus icon with rotation animation
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(buttonRotation))
        }
        .scaleEffect(isExpanded ? 1.1 : 1.0)
    }
    
    // MARK: - Menu Item UI
    /// Each menu item consists of:
    /// - A label (text bubble)
    /// - A circular icon button
    /// - Highlight ring when selected via drag
    private func fabMenuItem(item: FABItem, index: Int) -> some View {
        let isSelected = selectedIndex == index
        
        return HStack(spacing: 12) {
            
            // =============================
            // LABEL (text bubble)
            // =============================
            Text(item.label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                )
                .opacity(isExpanded ? 1 : 0)
                .offset(x: isExpanded ? 0 : 50)
            
            // =============================
            // ICON CIRCLE
            // =============================
            ZStack {
                // Color circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(
                        color: item.color.opacity(isSelected ? 0.6 : 0.3),
                        radius: isSelected ? 12 : 6,
                        x: 0,
                        y: isSelected ? 6 : 3
                    )
                
                // White ring when selected
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 56, height: 56)
                }
                
                // SF Symbol icon
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isSelected ? 1.15 : (isExpanded ? 1.0 : 0.5))
            .opacity(isExpanded ? 1 : 0)
        }
        .offset(y: isExpanded ? 0 : CGFloat(menuItems.count - index) * 20)
        /// Smooth stagger animation during menu expansion
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7)
            .delay(isExpanded ? Double(menuItems.count - 1 - index) * 0.05 : 0),
            value: isExpanded
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Drag Handlers
    /// This determines which menu item you're dragging over.
    /// Works by checking Y position relative to menu layout.
    private func handleDrag(value: DragGesture.Value) {
        let dragY = -value.translation.height
        
        let firstItemOffset: CGFloat = 70
        let itemHeight: CGFloat = 66
        
        if dragY > firstItemOffset - 30 {
            let relativeY = dragY - firstItemOffset + 30
            let itemIndex = Int(relativeY / itemHeight)
            
            if itemIndex >= 0 && itemIndex < menuItems.count {
                // Activate haptic + highlight new item
                if selectedIndex != itemIndex {
                    haptic.impactOccurred(intensity: 0.4)
                    withAnimation(.spring(response: 0.2)) {
                        selectedIndex = itemIndex
                    }
                }
            }
            else if itemIndex >= menuItems.count {
                // Lock on the last item when dragging past bottom
                if selectedIndex != menuItems.count - 1 {
                    withAnimation(.spring(response: 0.2)) {
                        selectedIndex = menuItems.count - 1
                    }
                }
            }
        } else {
            // Drag outside menu area resets highlight
            if selectedIndex != nil {
                withAnimation(.spring(response: 0.2)) {
                    selectedIndex = nil
                }
            }
        }
    }
    
    /// Called when drag ends.
    /// Executes the selected item, triggers ripple and closes menu.
    private func handleDragEnd() {
        if let index = selectedIndex {
            haptic.impactOccurred(intensity: 1.0)
            print("Selected: \(menuItems[index].label)")
            triggerRipple()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                closeMenu()
            }
        }
        
        withAnimation(.spring(response: 0.3)) {
            selectedIndex = nil
            dragOffset = .zero
        }
    }
    
    // MARK: - Actions
    /// Opens or closes the floating menu
    public func toggleMenu() {
        haptic.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isExpanded.toggle()
            buttonRotation = isExpanded ? 45 : 0  // Plus → X
        }
        
        triggerRipple()
    }
    
    /// Closes the menu with animation
    private func closeMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
            buttonRotation = 0
            selectedIndex = nil
        }
    }
    
    /// Simple ripple animation used for feedback
    private func triggerRipple() {
        showRipple = true
        withAnimation(.easeOut(duration: 0.4)) {
            showRipple = false
        }
    }
}

// MARK: - Hex Color Extension
// Note: init(hex:) is defined in SanctuaryColors.swift - removed duplicate here
