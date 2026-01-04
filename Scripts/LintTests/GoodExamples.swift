// GoodExamples.swift
// These examples should produce ZERO SwiftLint violations
// Run: swiftlint lint Scripts/LintTests/GoodExamples.swift --config .swiftlint.yml

import SwiftUI

struct GoodExamplesView: View {
    @State private var isSelected = false
    
    var body: some View {
        // MARK: - Spacing (using tokens)
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text("Hello")
                    .padding(AppTheme.Spacing.lg)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
        }
        
        // MARK: - Typography (using tokens)
        Text("Title")
            .font(Typography.UI.title1)
        
        Text("Body text")
            .font(Typography.UI.body)
        
        Text("Scripture")
            .font(Typography.Scripture.body)
        
        // MARK: - Colors (using semantic colors)
        Text("Colored")
            .foregroundStyle(Color.primaryText)
            .background(Color.surfaceBackground)
        
        // MARK: - Corner Radius (using tokens)
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        
        // MARK: - Animation (using tokens)
        Rectangle()
            .animation(AppTheme.Animation.standard, value: isSelected)
            .animation(AppTheme.Animation.spring, value: isSelected)
        
        // MARK: - Opacity (using tokens)
        Color.accentGold.opacity(AppTheme.Opacity.light)
        Color.accentBlue.opacity(AppTheme.Opacity.disabled)
        
        // MARK: - Scale (using tokens)
        Image(systemName: "star")
            .scaleEffect(AppTheme.Scale.pressed)
            .scaleEffect(AppTheme.Scale.enlarged)
        
        // MARK: - Shadows (using tokens)
        Rectangle()
            .shadow(AppTheme.Shadow.medium)
        
        // MARK: - Icon containers (using tokens)
        Image(systemName: "star")
            .frame(width: AppTheme.IconContainer.small)
        
        // MARK: - Reduced motion support
        Rectangle()
            .animation(AppTheme.Animation.reduced(.spring), value: isSelected)
            .reducedMotionAnimation(.spring, value: isSelected)
    }
}
