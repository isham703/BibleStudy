// BadExamples.swift
// These examples should produce SwiftLint violations
// Run: swiftlint lint Scripts/LintTests/BadExamples.swift --config .swiftlint.yml
// Expected: Multiple violations (see comments)

import SwiftUI

struct BadExamplesView: View {
    @State private var isAnimating = false
    
    var body: some View {
        // VIOLATION: hardcoded_stack_spacing
        VStack(spacing: 16) {
            // VIOLATION: hardcoded_padding_single
            Text("Hello")
                .padding(8)
            
            // VIOLATION: hardcoded_padding_edge
            Text("World")
                .padding(.horizontal, 24)
        }
        
        // VIOLATION: hardcoded_font_system
        Text("Bad font")
            .font(.system(size: 14))
        
        // VIOLATION: hardcoded_font_custom
        Text("Custom font")
            .font(.custom("Helvetica", size: 16))
        
        // VIOLATION: hardcoded_swiftui_text_style
        Text("Text style")
            .font(.title2)
        
        // VIOLATION: hardcoded_rounded_rectangle
        RoundedRectangle(cornerRadius: 12)
        
        // VIOLATION: hardcoded_animation_ease
        Rectangle()
            .animation(.easeInOut(duration: 0.3), value: isAnimating)
        
        // VIOLATION: hardcoded_animation_spring
        Rectangle()
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimating)
        
        // VIOLATION: hardcoded_opacity
        Color.blue.opacity(0.15)
        
        // VIOLATION: hardcoded_scale_reduced
        Image(systemName: "star")
            .scaleEffect(0.95)
        
        // VIOLATION: hardcoded_scale_enlarged  
        Image(systemName: "star")
            .scaleEffect(1.2)
        
        // VIOLATION: hardcoded_color_rgb
        Color(red: 1, green: 0, blue: 0)
    }
}
