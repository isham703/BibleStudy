//
//  SectionJumpBar.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Horizontal scrolling chip bar for section navigation.
//  Sticky positioned via safeAreaInset(edge: .top) in parent.
//
//  Active chip = last tapped (no scroll-position tracking).
//  Bronze accent for active state, stroke-only for inactive.
//

import SwiftUI

// MARK: - Section Jump Bar

struct SectionJumpBar: View {
    let sections: [SermonSectionID]
    let activeSectionID: SermonSectionID?
    let onSectionTap: (SermonSectionID) -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(sections) { section in
                    SectionChip(
                        section: section,
                        isActive: section == activeSectionID,
                        onTap: { onSectionTap(section) }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(jumpBarBackground)
    }

    @ViewBuilder
    private var jumpBarBackground: some View {
        if reduceTransparency {
            Color("AppBackground")
        } else {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Section Chip

private struct SectionChip: View {
    let section: SermonSectionID
    let isActive: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            onTap()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(section.displayLabel)
                    .font(Typography.Command.label)
            }
            .foregroundStyle(isActive ? .white : Color("AccentBronze"))
            .padding(.horizontal, Theme.Spacing.md)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(chipBackground)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(Theme.Animation.fade, value: isPressed)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("\(section.displayLabel) tab")
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : [.isButton])
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isActive {
            Capsule()
                .fill(Color("AccentBronze"))
        } else {
            Capsule()
                .stroke(Color("AccentBronze").opacity(Theme.Opacity.disabled), lineWidth: Theme.Stroke.hairline)
        }
    }
}

// MARK: - Preview

#Preview("Section Jump Bar") {
    VStack(spacing: Theme.Spacing.lg) {
        SectionJumpBar(
            sections: SermonSectionID.allCases,
            activeSectionID: .keyTakeaways,
            onSectionTap: { section in
                print("Tapped: \(section.displayLabel)")
            }
        )

        SectionJumpBar(
            sections: [.summary, .keyTakeaways, .notableQuotes, .scriptureReferences],
            activeSectionID: nil,
            onSectionTap: { _ in }
        )
    }
    .background(Color("AppBackground"))
}
