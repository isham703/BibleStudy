// GoodExamples.swift
// These examples should produce ZERO SwiftLint violations
// Run: swiftlint lint Scripts/LintTests/GoodExamples.swift --config .swiftlint.yml

import SwiftUI

struct GoodExamplesView: View {
    @State private var isSelected = false

    var body: some View {
        // MARK: - Spacing (using Theme.Spacing tokens)
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Hello")
                    .padding(Theme.Spacing.lg)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
        }

        // MARK: - Typography (using Typography tokens)
        Text("Title")
            .font(Typography.Scripture.title)

        Text("Body text")
            .font(Typography.Command.body)

        Text("Scripture")
            .font(Typography.Scripture.body)

        // MARK: - Colors (using Asset Catalog colors)
        Text("Colored")
            .foregroundStyle(Color("AppTextPrimary"))
            .background(Color("AppSurface"))

        // MARK: - Corner Radius (using Theme.Radius tokens)
        RoundedRectangle(cornerRadius: Theme.Radius.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.input))

        // MARK: - Animation (using Theme.Animation tokens)
        Rectangle()
            .animation(Theme.Animation.fade, value: isSelected)
            .animation(Theme.Animation.settle, value: isSelected)

        // MARK: - Opacity (using Theme.Opacity tokens)
        Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground)
        Color("AppAccentAction").opacity(Theme.Opacity.disabled)

        // MARK: - Stroke (using Theme.Stroke tokens)
        Rectangle()
            .stroke(Color("AppDivider"), lineWidth: Theme.Stroke.hairline)

        // MARK: - Reading layout (using Theme.Reading tokens)
        Text("Scripture passage")
            .frame(maxWidth: Theme.Reading.maxWidth)
            .padding(.horizontal, Theme.Reading.horizontalPadding)
    }
}
