//
//  ThemePickerGrid.swift
//  BibleStudy
//
//  Grid of selectable themes for the theme editor.
//  Groups themes by category for easy browsing.
//

import SwiftUI

// MARK: - Theme Picker Grid

struct ThemePickerGrid: View {
    @Binding var selectedThemes: Set<NormalizedTheme>
    let assignedThemes: Set<NormalizedTheme>
    let maxThemes: Int

    private var canAddMore: Bool {
        selectedThemes.count < maxThemes
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120), spacing: 8)],
            spacing: 8
        ) {
            ForEach(NormalizedTheme.allCases) { theme in
                let isAssigned = assignedThemes.contains(theme)
                let isSelected = selectedThemes.contains(theme)
                let isDisabled = !isSelected && !canAddMore

                SelectableThemeChip(
                    theme: theme,
                    isSelected: isSelected || isAssigned,
                    isDisabled: isAssigned || isDisabled
                ) {
                    toggleTheme(theme)
                }
            }
        }
    }

    private func toggleTheme(_ theme: NormalizedTheme) {
        if selectedThemes.contains(theme) {
            selectedThemes.remove(theme)
        } else if canAddMore {
            selectedThemes.insert(theme)
        }
    }
}

// MARK: - Categorized Theme Picker

/// Theme picker organized by theological category
struct CategorizedThemePicker: View {
    @Binding var selectedThemes: Set<NormalizedTheme>
    let assignedThemes: Set<NormalizedTheme>
    let maxThemes: Int

    private var canAddMore: Bool {
        selectedThemes.count < maxThemes
    }

    private let categories: [(String, [NormalizedTheme])] = [
        ("Salvation & Grace", [.salvation, .grace, .forgiveness]),
        ("Faith & Trust", [.faith, .hope, .perseverance]),
        ("Character & Virtue", [.love, .humility, .wisdom, .obedience, .righteousness]),
        ("Relationship with God", [.prayer, .worship, .holiness]),
        ("Community & Service", [.fellowship, .service, .evangelism]),
        ("Trials & Growth", [.suffering, .healing, .transformation]),
        ("God's Nature", [.sovereignty, .faithfulness, .mercy, .justice]),
        ("Eschatology & Future", [.kingdom, .eternity]),
        ("Scripture & Truth", [.truth, .covenant]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(categories, id: \.0) { category, themes in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color("SecondaryText"))
                        .textCase(.uppercase)

                    ThemeFlowLayout(spacing: 8) {
                        ForEach(themes) { theme in
                            let isAssigned = assignedThemes.contains(theme)
                            let isSelected = selectedThemes.contains(theme)
                            let isDisabled = !isSelected && !canAddMore

                            SelectableThemeChip(
                                theme: theme,
                                isSelected: isSelected || isAssigned,
                                isDisabled: isAssigned || isDisabled
                            ) {
                                toggleTheme(theme)
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggleTheme(_ theme: NormalizedTheme) {
        if selectedThemes.contains(theme) {
            selectedThemes.remove(theme)
        } else if canAddMore {
            selectedThemes.insert(theme)
        }
    }
}

// MARK: - Theme Flow Layout

/// A layout that wraps items horizontally like a flow layout
struct ThemeFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.origin.x, y: bounds.minY + frame.origin.y),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = min(maxWidth, frames.map { $0.maxX }.max() ?? 0)

        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            Text("Grid Layout")
                .font(.headline)

            ThemePickerGrid(
                selectedThemes: .constant([.faith, .salvation]),
                assignedThemes: [.love],
                maxThemes: 5
            )

            Divider()

            Text("Categorized Layout")
                .font(.headline)

            CategorizedThemePicker(
                selectedThemes: .constant([.faith]),
                assignedThemes: [.salvation],
                maxThemes: 5
            )
        }
        .padding()
    }
    .background(Color("AppBackground"))
}
