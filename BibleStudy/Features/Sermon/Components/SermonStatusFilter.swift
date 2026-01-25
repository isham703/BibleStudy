//
//  SermonStatusFilter.swift
//  BibleStudy
//
//  Horizontal filter chips for sermon status filtering
//  Options: All | Ready | Processing | Needs Attention
//

import SwiftUI

// MARK: - Sermon Status Filter Option

enum SermonStatusFilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case ready = "Ready"
    case processing = "Processing"
    case needsAttention = "Attention"

    var id: String { rawValue }

    var icon: String? {
        switch self {
        case .all: return nil
        case .ready: return "checkmark.circle.fill"
        case .processing: return "waveform"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .all: return Color("AppAccentAction")
        case .ready: return Color("AccentBronze")
        case .processing: return Color("TertiaryText")
        case .needsAttention: return Color("FeedbackError")
        }
    }

    /// Filter sermons by this option
    func matches(_ sermon: Sermon) -> Bool {
        switch self {
        case .all:
            return true
        case .ready:
            return sermon.isComplete
        case .processing:
            return sermon.isProcessing
        case .needsAttention:
            return sermon.hasError
        }
    }
}

// MARK: - Sermon Status Filter Bar

struct SermonStatusFilterBar: View {
    @Binding var selectedFilter: SermonStatusFilterOption
    let counts: SermonStatusCounts

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(SermonStatusFilterOption.allCases) { option in
                    SermonStatusFilterChip(
                        option: option,
                        count: counts.count(for: option),
                        isSelected: selectedFilter == option
                    ) {
                        withAnimation(Theme.Animation.fade) {
                            selectedFilter = option
                        }
                        HapticService.shared.selectionChanged()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }
}

// MARK: - Sermon Status Filter Chip

struct SermonStatusFilterChip: View {
    let option: SermonStatusFilterOption
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                // Icon (for specific filters, not "All")
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(Typography.Icon.xxs)
                }

                Text(option.rawValue)
                    .font(Typography.Command.caption)

                if count > 0 {
                    Text("\(count)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("TertiaryText"))
                }
            }
            .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? option.accentColor.opacity(Theme.Opacity.selectionBackground) : Color("AppSurface"))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? option.accentColor : Color("AppDivider"),
                        lineWidth: Theme.Stroke.hairline
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let selectedState = isSelected ? "Selected" : ""
        return "\(option.rawValue) filter, \(count) sermons \(selectedState)"
    }
}

// MARK: - Sermon Status Counts

struct SermonStatusCounts {
    let all: Int
    let ready: Int
    let processing: Int
    let needsAttention: Int

    func count(for option: SermonStatusFilterOption) -> Int {
        switch option {
        case .all: return all
        case .ready: return ready
        case .processing: return processing
        case .needsAttention: return needsAttention
        }
    }

    /// Calculate counts from a list of sermons
    static func from(_ sermons: [Sermon]) -> SermonStatusCounts {
        SermonStatusCounts(
            all: sermons.count,
            ready: sermons.filter { $0.isComplete }.count,
            processing: sermons.filter { $0.isProcessing }.count,
            needsAttention: sermons.filter { $0.hasError }.count
        )
    }
}

// MARK: - Preview

#Preview("Filter Bar") {
    VStack {
        SermonStatusFilterBar(
            selectedFilter: .constant(.all),
            counts: SermonStatusCounts(all: 42, ready: 35, processing: 5, needsAttention: 2)
        )

        SermonStatusFilterBar(
            selectedFilter: .constant(.ready),
            counts: SermonStatusCounts(all: 42, ready: 35, processing: 5, needsAttention: 2)
        )

        SermonStatusFilterBar(
            selectedFilter: .constant(.processing),
            counts: SermonStatusCounts(all: 42, ready: 35, processing: 5, needsAttention: 2)
        )

        SermonStatusFilterBar(
            selectedFilter: .constant(.needsAttention),
            counts: SermonStatusCounts(all: 42, ready: 35, processing: 5, needsAttention: 2)
        )
    }
    .padding(.vertical)
    .background(Color("AppBackground"))
}

#Preview("Individual Chips") {
    HStack(spacing: Theme.Spacing.sm) {
        SermonStatusFilterChip(option: .all, count: 42, isSelected: true, action: {})
        SermonStatusFilterChip(option: .ready, count: 35, isSelected: false, action: {})
        SermonStatusFilterChip(option: .processing, count: 5, isSelected: false, action: {})
        SermonStatusFilterChip(option: .needsAttention, count: 2, isSelected: false, action: {})
    }
    .padding()
    .background(Color("AppBackground"))
}
