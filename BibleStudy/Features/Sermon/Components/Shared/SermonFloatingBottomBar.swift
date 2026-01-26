//
//  SermonFloatingBottomBar.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Floating capsule toolbar for sermon notes.
//  Matches BibleReaderBottomBar pattern: ultraThinMaterial + hairline stroke.
//  Positioned via safeAreaInset(edge: .bottom) in parent.
//
//  Buttons: Add Note, Share, Overflow (New / Delete)
//

import SwiftUI

// MARK: - Sermon Floating Bottom Bar

struct SermonFloatingBottomBar: View {
    let isVisible: Bool
    let isSampleSermon: Bool
    let onAddNoteTap: () -> Void
    let onShareTap: () -> Void
    let onNewSermonTap: () -> Void
    let onDeleteTap: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Add Note
            FloatingBarButton(
                icon: "note.text.badge.plus",
                accessibilityLabel: "Add Note",
                action: onAddNoteTap
            )

            // Share
            FloatingBarButton(
                icon: "square.and.arrow.up",
                accessibilityLabel: "Share",
                action: onShareTap
            )

            // Overflow menu
            Menu {
                Button {
                    onNewSermonTap()
                } label: {
                    Label("New Sermon", systemImage: "plus")
                }

                if !isSampleSermon {
                    Button(role: .destructive) {
                        onDeleteTap()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                FloatingBarIcon(
                    icon: "ellipsis",
                    accessibilityLabel: "More options"
                )
            }
            .accessibilityLabel("More options")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(barBackground)
        .overlay(
            Capsule()
                .stroke(Color("AppDivider").opacity(0.5), lineWidth: Theme.Stroke.hairline)
        )
        .padding(.bottom, Theme.Spacing.md)
        .offset(y: isVisible ? 0 : 80)
        .opacity(isVisible ? 1 : 0)
        .animation(Theme.Animation.fade, value: isVisible)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Notes toolbar")
    }

    @ViewBuilder
    private var barBackground: some View {
        if reduceTransparency {
            Capsule()
                .fill(Color("AppSurface"))
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Floating Bar Button

private struct FloatingBarButton: View {
    let icon: String
    let accessibilityLabel: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticService.shared.lightTap()
            action()
        } label: {
            FloatingBarIcon(icon: icon, accessibilityLabel: accessibilityLabel)
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(Theme.Animation.fade, value: isPressed)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
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
}

// MARK: - Floating Bar Icon

private struct FloatingBarIcon: View {
    let icon: String
    let accessibilityLabel: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color("AppSurface").opacity(0.8))
                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)

            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color("AppTextSecondary"))
        }
    }
}

// MARK: - Preview

#Preview("Floating Bottom Bar") {
    ZStack {
        Color("AppBackground").ignoresSafeArea()
        VStack {
            Spacer()
            SermonFloatingBottomBar(
                isVisible: true,
                isSampleSermon: false,
                onAddNoteTap: {},
                onShareTap: {},
                onNewSermonTap: {},
                onDeleteTap: {}
            )
        }
    }
}
