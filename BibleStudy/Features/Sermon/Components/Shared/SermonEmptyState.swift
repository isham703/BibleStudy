//
//  SermonEmptyState.swift
//  BibleStudy
//
//  Empty state for sermon library with static waveform illustration
//  Follows restrained design: single fade-in, no looping animations
//

import SwiftUI

// MARK: - Sermon Empty State

struct SermonEmptyState: View {
    let title: String
    let message: String

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            // Static waveform illustration
            SermonWaveformIllustration()
                .frame(height: 80)
                .frame(maxWidth: 160)

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text(message)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(Theme.Animation.slowFade) {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Static Waveform Illustration

/// Editorial waveform illustration using hairline strokes
/// Static by design - no looping animations (per design doctrine)
private struct SermonWaveformIllustration: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("AccentBronze").opacity(0.3))
                    .frame(width: 4, height: barHeight(for: index))
            }
        }
    }

    /// Static bar heights creating a waveform shape
    private func barHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [24, 40, 56, 64, 56, 40, 24]
        return heights[index]
    }
}

// MARK: - Preset Empty States

extension SermonEmptyState {
    /// Empty library state (no sermons yet)
    static var noSermons: SermonEmptyState {
        SermonEmptyState(
            title: "No Sermons Yet",
            message: "Record or import your first sermon to get started"
        )
    }

    /// Search with no results
    static var noResults: SermonEmptyState {
        SermonEmptyState(
            title: "No Results",
            message: "Try a different search term"
        )
    }

    /// Filtered view with no matches
    static func noMatches(filter: String) -> SermonEmptyState {
        SermonEmptyState(
            title: "No \(filter) Sermons",
            message: "No sermons match this filter"
        )
    }
}

// MARK: - Preview

#Preview("No Sermons") {
    VStack {
        Spacer()
        SermonEmptyState.noSermons
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("AppBackground"))
}

#Preview("No Results") {
    VStack {
        Spacer()
        SermonEmptyState.noResults
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("AppBackground"))
}

#Preview("Filtered Empty") {
    VStack {
        Spacer()
        SermonEmptyState.noMatches(filter: "Processing")
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("AppBackground"))
}
