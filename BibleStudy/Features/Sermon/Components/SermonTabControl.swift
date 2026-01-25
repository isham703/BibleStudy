//
//  SermonTabControl.swift
//  BibleStudy
//
//  Custom bronze-styled segmented tab control for sermon navigation.
//  Follows Motion Doctrine: ceremonial, restrained, ALL cubic easing.
//

import SwiftUI

// MARK: - Sermon Tab

enum SermonTab: String, CaseIterable {
    case library = "Your Sermons"
    case recordNew = "Record New"

    var displayName: String { rawValue }
}

// MARK: - Sermon Tab Control

/// Custom segmented tab control with bronze styling matching the design system.
/// Uses sliding underline indicator and differentiated haptics per tab.
struct SermonTabControl: View {
    @Binding var selectedTab: SermonTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SermonTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
        )
        // Sliding bronze underline indicator
        .overlay(alignment: .bottom) {
            underlineIndicator
        }
        // Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sermon navigation, \(selectedTab.displayName) selected")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                withAnimation(Theme.Animation.settle) {
                    selectedTab = .recordNew
                }
            case .decrement:
                withAnimation(Theme.Animation.settle) {
                    selectedTab = .library
                }
            @unknown default:
                break
            }
        }
    }

    // MARK: - Tab Button

    private func tabButton(for tab: SermonTab) -> some View {
        Button {
            // Differentiated haptics: light for Library (browsing), medium for Record (action)
            HapticService.shared.lightTap()
            if tab == .recordNew {
                HapticService.shared.mediumTap()
            }

            withAnimation(Theme.Animation.settle) {
                selectedTab = tab
            }
        } label: {
            Text(tab.displayName)
                .font(Typography.Command.label)
                .foregroundStyle(
                    selectedTab == tab
                        ? Color("AppTextPrimary")
                        : Color("TertiaryText")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    selectedTab == tab
                        ? Color("AccentBronze").opacity(0.12)
                        : Color.clear
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.displayName) tab")
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    // MARK: - Underline Indicator

    private var underlineIndicator: some View {
        GeometryReader { geo in
            let indicatorWidth = geo.size.width / 2 - Theme.Spacing.sm
            let libraryOffset = Theme.Spacing.xs
            let recordOffset = geo.size.width / 2 + Theme.Spacing.xs

            RoundedRectangle(cornerRadius: Theme.Radius.xs)
                .fill(Color("AccentBronze"))
                .frame(width: indicatorWidth, height: 2)
                .offset(x: selectedTab == .library ? libraryOffset : recordOffset)
                .animation(Theme.Animation.settle, value: selectedTab)
        }
        .frame(height: 2)
    }
}

// MARK: - Preview

#Preview("Tab Control - Library Selected") {
    VStack(spacing: Theme.Spacing.xl) {
        SermonTabControl(selectedTab: .constant(.library))
            .padding(.horizontal, Theme.Spacing.lg)

        SermonTabControl(selectedTab: .constant(.recordNew))
            .padding(.horizontal, Theme.Spacing.lg)
    }
    .padding(.vertical, Theme.Spacing.xl)
    .background(Color("AppBackground"))
}

#Preview("Tab Control - Interactive") {
    struct InteractivePreview: View {
        @State private var selectedTab: SermonTab = .library

        var body: some View {
            VStack(spacing: Theme.Spacing.xl) {
                SermonTabControl(selectedTab: $selectedTab)
                    .padding(.horizontal, Theme.Spacing.lg)

                Text("Selected: \(selectedTab.displayName)")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(.vertical, Theme.Spacing.xl)
            .background(Color("AppBackground"))
        }
    }

    return InteractivePreview()
}
