//
//  CeremonialAppearModifier.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Centralized "ceremonial appear" animation that respects Reduce Motion.
//  Gates drift/scale behind accessibility settings per Motion Doctrine.
//
//  Usage:
//    .ceremonialAppear(isAwakened: isAwakened, delay: 0.2)
//    .ceremonialAppear(isAwakened: isAwakened, delay: 0.3, includeDrift: false)
//

import SwiftUI

// MARK: - Ceremonial Appear Modifier

struct CeremonialAppearModifier: ViewModifier {
    let isAwakened: Bool
    let delay: Double
    let includeDrift: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isAwakened ? 1 : 0)
            .offset(y: shouldApplyDrift ? (isAwakened ? 0 : driftDistance) : 0)
            .animation(animation, value: isAwakened)
    }

    // MARK: - Computed Properties

    /// Whether to apply vertical drift animation
    private var shouldApplyDrift: Bool {
        includeDrift && !reduceMotion
    }

    /// Drift distance in points (subtle, per Motion Doctrine)
    private var driftDistance: CGFloat {
        10
    }

    /// Animation with appropriate timing
    /// - Reduce Motion: faster fade only (150ms)
    /// - Normal: slowFade with delay
    private var animation: Animation {
        if reduceMotion {
            return .easeInOut(duration: 0.15).delay(delay)
        } else {
            return Theme.Animation.slowFade.delay(delay)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply ceremonial appear animation with optional drift.
    ///
    /// Respects `accessibilityReduceMotion`:
    /// - Normal: slowFade (420ms) + 10pt vertical drift
    /// - Reduce Motion: fast fade (150ms), no drift
    ///
    /// - Parameters:
    ///   - isAwakened: Whether the view should be visible
    ///   - delay: Animation delay in seconds
    ///   - includeDrift: Whether to include vertical drift (default: true)
    func ceremonialAppear(
        isAwakened: Bool,
        delay: Double,
        includeDrift: Bool = true
    ) -> some View {
        self.modifier(CeremonialAppearModifier(
            isAwakened: isAwakened,
            delay: delay,
            includeDrift: includeDrift
        ))
    }
}

// MARK: - Preview

#Preview("Ceremonial Appear") {
    struct PreviewContainer: View {
        @State private var isAwakened = false

        var body: some View {
            VStack(spacing: Theme.Spacing.lg) {
                Button("Toggle Awaken") {
                    withAnimation {
                        isAwakened.toggle()
                    }
                }
                .padding()

                VStack(spacing: Theme.Spacing.md) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .fill(Color("AppSurface"))
                            .frame(height: 60)
                            .overlay(
                                Text("Card \(index + 1)")
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Color("AppTextPrimary"))
                            )
                            .ceremonialAppear(
                                isAwakened: isAwakened,
                                delay: Double(index) * 0.1
                            )
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("AppBackground"))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAwakened = true
                }
            }
        }
    }

    return PreviewContainer()
}
