//
//  ReadingMenuButton.swift
//  BibleStudy
//
//  Single entry point for reading controls - Apple Books style
//

import SwiftUI

// MARK: - Reading Menu Button

/// A subtle floating button that opens the Reading Menu
/// Positioned bottom-right by default, configurable for left/right preference
struct ReadingMenuButton: View {
    @Binding var isExpanded: Bool

    /// User preference for menu position (stored in UserDefaults)
    @AppStorage("readingMenuPosition") private var menuPosition: MenuPosition = .right

    /// Track if user has interacted with the menu (for discoverability)
    @AppStorage("hasUsedReadingMenu") private var hasUsedReadingMenu: Bool = false

    /// Show subtle pulse animation for first-time users
    @State private var showPulse: Bool = false

    var body: some View {
        Button {
            hasUsedReadingMenu = true
            withAnimation(AppTheme.Animation.spring) {
                isExpanded = true
            }
            HapticService.shared.lightTap()
        } label: {
            menuButtonContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reading Menu")
        .accessibilityHint("Open reading controls including contents, search, and settings")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            // Show pulse animation for new users
            if !hasUsedReadingMenu {
                withAnimation(AppTheme.Animation.reduced(AppTheme.Animation.slow.repeatForever(autoreverses: true))) {
                    showPulse = true
                }
            }
        }
    }

    // MARK: - Button Content

    private var menuButtonContent: some View {
        ZStack {
            // Pulse ring for discoverability (first-time users only)
            if showPulse && !hasUsedReadingMenu {
                Circle()
                    .stroke(Color.accentGold.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.regular)
                    .frame(width: 52, height: 52)
                    .scaleEffect(showPulse ? 1.3 : 1.0)
                    .opacity(showPulse ? 0 : 0.5)
            }

            // Main button
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "line.3.horizontal")
                        .font(Typography.UI.body.weight(.medium))
                        .foregroundStyle(Color.primaryText)
                )
                .shadow(AppTheme.Shadow.medium)
        }
    }
}

// MARK: - Menu Position

enum MenuPosition: String, CaseIterable {
    case left
    case right

    var alignment: Alignment {
        switch self {
        case .left: return .bottomLeading
        case .right: return .bottomTrailing
        }
    }

    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

// MARK: - Preview

#Preview("Reading Menu Button") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        // Simulated scripture content
        VStack {
            Text("In the beginning God created the heaven and the earth.")
                .font(Typography.Scripture.body())
                .padding()
            Spacer()
        }

        // Menu button
        VStack {
            Spacer()
            HStack {
                Spacer()
                ReadingMenuButton(isExpanded: .constant(false))
                    .padding()
            }
        }
    }
}

#Preview("Reading Menu Button - First Time User") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                ReadingMenuButton(isExpanded: .constant(false))
                    .padding()
            }
        }
    }
    .onAppear {
        // Reset for preview
        UserDefaults.standard.set(false, forKey: "hasUsedReadingMenu")
    }
}
