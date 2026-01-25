//
//  CentralThesisCallout.swift
//  BibleStudy
//
//  Stoic-Existential Renaissance Design System
//
//  Displays the sermon's central thesis as a contemplative callout
//  with a bronze accent bar (wax seal strip metaphor).
//
//  Typography: Serif italic for gravity (Scripture.quote)
//  Visual: Left bronze bar, subtle bronze-tinted background
//

import SwiftUI

// MARK: - Central Thesis Callout

struct CentralThesisCallout: View {
    let thesis: String
    let delay: Double
    let isAwakened: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Bronze accent bar (wax seal strip metaphor)
            Rectangle()
                .fill(Color("AccentBronze"))
                .frame(width: 2)

            Text(thesis)
                .font(Typography.Scripture.quote)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineSpacing(Typography.Scripture.quoteLineSpacing)
                .frame(maxWidth: Theme.Reading.maxWidth, alignment: .leading)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.input)
                .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
        )
        .ceremonialAppear(isAwakened: isAwakened, delay: delay)
    }
}

// MARK: - Preview

#Preview("Central Thesis Callout") {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            CentralThesisCallout(
                thesis: "Grace is not merely God's response to our failure - it is the foundation upon which our entire identity in Christ is built.",
                delay: 0.2,
                isAwakened: true
            )

            CentralThesisCallout(
                thesis: "The cross reveals both the depth of human sin and the greater depth of divine love.",
                delay: 0.3,
                isAwakened: true
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
    }
    .background(Color("AppBackground"))
}
