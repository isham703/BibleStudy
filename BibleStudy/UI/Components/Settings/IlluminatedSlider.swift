import SwiftUI

// MARK: - Illuminated Slider
// A custom slider with gold gradient track and optional tick marks

struct IlluminatedSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let tickMarks: [Double]?
    let label: String
    let icon: String?
    let iconColor: Color
    let valueFormatter: (Double) -> String

    @State private var isDragging = false

    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        tickMarks: [Double]? = nil,
        label: String,
        icon: String? = nil,
        iconColor: Color = .scholarAccent,
        valueFormatter: @escaping (Double) -> String = { "\(Int($0))" }
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.tickMarks = tickMarks
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.valueFormatter = valueFormatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header row
            HStack(spacing: AppTheme.Spacing.md) {
                // Icon (optional)
                if let icon = icon {
                    iconView(icon: icon)
                }

                // Label
                Text(label)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                // Current value
                Text(valueFormatter(value))
                    .font(Typography.UI.subheadline.monospacedDigit())
                    .foregroundStyle(Color.scholarAccent)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.scholarAccent.opacity(AppTheme.Opacity.subtle + 0.02))
                    )
            }

            // Slider with tick marks
            VStack(spacing: AppTheme.Spacing.xs) {
                // Custom slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        Capsule()
                            .fill(Color.divider.opacity(AppTheme.Opacity.medium))
                            .frame(height: AppTheme.Divider.heavy)

                        // Filled track
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.scholarAccent.opacity(AppTheme.Opacity.overlay),
                                        Color.scholarAccent
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: filledWidth(in: geometry.size.width), height: AppTheme.Divider.heavy)

                        // Thumb
                        Circle()
                            .fill(.white)
                            .shadow(color: .black.opacity(AppTheme.Opacity.light), radius: 3, x: 0, y: 2)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .fill(Color.scholarAccent)
                                    .frame(width: AppTheme.ComponentSize.indicator + 2, height: AppTheme.ComponentSize.indicator + 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.scholarAccent.opacity(isDragging ? AppTheme.Opacity.medium : 0), lineWidth: AppTheme.Blur.medium)
                                    .blur(radius: AppTheme.Blur.subtle)
                            )
                            .offset(x: thumbOffset(in: geometry.size.width))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        isDragging = true
                                        updateValue(from: gesture.location.x, in: geometry.size.width)
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                        // Haptic feedback
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    }
                            )
                            .animation(AppTheme.Animation.quick, value: isDragging)
                    }
                    .frame(height: 24)
                }
                .frame(height: 24)

                // Tick marks (optional)
                if let tickMarks = tickMarks {
                    tickMarksView(tickMarks: tickMarks)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(valueFormatter(value))
        .accessibilityAdjustableAction { direction in
            let stepValue = step ?? 1
            switch direction {
            case .increment:
                value = min(value + stepValue, range.upperBound)
            case .decrement:
                value = max(value - stepValue, range.lowerBound)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Icon View

    private func iconView(icon: String) -> some View {
        Image(systemName: icon)
            .font(Typography.UI.iconSm.weight(.medium))
            .foregroundStyle(iconColor)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small + 2)
                    .fill(iconColor.opacity(AppTheme.Opacity.subtle + 0.02))
            )
    }

    // MARK: - Tick Marks

    private func tickMarksView(tickMarks: [Double]) -> some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(tickMarks.enumerated()), id: \.offset) { index, tickValue in
                    let isActive = value >= tickValue
                    let percentage = (tickValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                    // Position tick marks to align with thumb center (accounting for thumb width)
                    let tickX = 12 + (geometry.size.width - 24) * percentage

                    VStack(spacing: AppTheme.Spacing.xxs) {
                        Rectangle()
                            .fill(isActive ? Color.scholarAccent : Color.divider.opacity(AppTheme.Opacity.heavy))
                            .frame(width: AppTheme.Border.thin, height: AppTheme.Divider.heavy)

                        Text("\(Int(tickValue))")
                            .font(.system(size: Typography.Scale.xs - 2, weight: .medium))
                            .foregroundStyle(isActive ? Color.scholarAccent : Color.tertiaryText)
                    }
                    .position(
                        x: tickX,
                        y: 12
                    )
                }
            }
        }
        .frame(height: 24)
    }

    // MARK: - Calculations

    private func filledWidth(in totalWidth: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        // Track should extend to center of thumb (12px from thumb leading edge)
        let thumbCenter = 12 + (totalWidth - 24) * percentage
        return thumbCenter
    }

    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return (totalWidth - 24) * percentage
    }

    private func updateValue(from x: CGFloat, in totalWidth: CGFloat) {
        let percentage = max(0, min(1, x / totalWidth))
        var newValue = range.lowerBound + (range.upperBound - range.lowerBound) * percentage

        // Snap to step if provided
        if let step = step {
            newValue = round(newValue / step) * step
        }

        // Clamp to range
        newValue = max(range.lowerBound, min(range.upperBound, newValue))

        // Haptic feedback when crossing tick marks
        if let tickMarks = tickMarks {
            for tick in tickMarks where abs(newValue - tick) < 0.5 && abs(value - tick) >= 0.5 {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                break
            }
        }

        value = newValue
    }
}

// MARK: - Illuminated Font Size Slider
// Convenience wrapper specifically for font size selection in Settings

struct SettingsFontSizeSlider: View {
    @Binding var fontSize: Int
    let previewText: String

    private let fontSizes: [Double] = [14, 16, 18, 20, 22, 24, 26, 28]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            IlluminatedSlider(
                value: Binding(
                    get: { Double(fontSize) },
                    set: { fontSize = Int($0) }
                ),
                in: 14...28,
                step: 2,
                tickMarks: fontSizes,
                label: "Font Size",
                icon: "textformat.size",
                valueFormatter: { "\(Int($0))pt" }
            )

            // Live preview
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Preview")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)

                Text(previewText)
                    .font(Typography.Scripture.body(size: CGFloat(fontSize)))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.appBackground)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Illuminated Slider") {
    struct PreviewContainer: View {
        @State private var fontSize: Double = 18
        @State private var fontSizeInt: Int = 18

        var body: some View {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    IlluminatedSettingsCard(title: "Reading", icon: "book.fill") {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            IlluminatedSlider(
                                value: $fontSize,
                                in: 14...28,
                                step: 2,
                                tickMarks: [14, 18, 22, 28],
                                label: "Font Size",
                                icon: "textformat.size",
                                valueFormatter: { "\(Int($0))pt" }
                            )

                            SettingsDivider()

                            SettingsFontSizeSlider(
                                fontSize: $fontSizeInt,
                                previewText: "In the beginning God created the heaven and the earth."
                            )
                        }
                    }
                    .padding()
                }
            }
            .background(Color.appBackground)
        }
    }

    return PreviewContainer()
}
