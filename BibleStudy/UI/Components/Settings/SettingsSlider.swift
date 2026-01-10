import SwiftUI

// MARK: - Slider
// Standard iOS slider with flat styling
// Stoic-Existential Renaissance design

struct SettingsSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double?
    let label: String
    let icon: String?
    let iconColor: Color
    let valueFormatter: (Double) -> String

    @Environment(\.colorScheme) private var colorScheme

    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        tickMarks: [Double]? = nil,
        label: String,
        icon: String? = nil,
        iconColor: Color = .accentIndigo,
        valueFormatter: @escaping (Double) -> String = { "\(Int($0))" }
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.valueFormatter = valueFormatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header row
            HStack(spacing: Theme.Spacing.md) {
                // Icon (optional)
                if let icon = icon {
                    iconView(icon: icon)
                }

                // Label
                Text(label)
                    .font(Typography.Command.body)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))

                Spacer()

                // Current value
                Text(valueFormatter(value))
                    .font(Typography.Command.meta.monospacedDigit())
                    .foregroundStyle(iconColor)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.tag)
                            .fill(iconColor.opacity(Theme.Opacity.divider))
                    )
            }

            // Standard iOS slider
            Slider(
                value: $value,
                in: range,
                step: step ?? 1
            )
            .tint(iconColor)
        }
    }

    // MARK: - Icon View

    private func iconView(icon: String) -> some View {
        Image(systemName: icon)
            .font(Typography.Icon.sm.weight(.medium))
            .foregroundStyle(iconColor)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tag)
                    .fill(iconColor.opacity(Theme.Opacity.divider))
            )
    }
}

// MARK: - Font Size Slider
// Convenience wrapper specifically for font size selection in Settings

struct SettingsFontSizeSlider: View {
    @Binding var fontSize: Int
    let previewText: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SettingsSlider(
                value: Binding(
                    get: { Double(fontSize) },
                    set: { fontSize = Int($0) }
                ),
                in: 14...28,
                step: 2,
                label: "Font Size",
                icon: "textformat.size",
                valueFormatter: { "\(Int($0))pt" }
            )

            // Live preview
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Preview")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))

                Text(previewText)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Colors.Surface.textPrimary(for: ThemeMode.current(from: colorScheme)))
                    .lineLimit(2)
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .fill(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(
                                Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)),
                                lineWidth: Theme.Stroke.hairline
                            )
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("Slider") {
    struct PreviewContainer: View {
        @State private var fontSize: Double = 18
        @State private var fontSizeInt: Int = 18

        var body: some View {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    SettingsCard(title: "Reading", icon: "book.fill") {
                        VStack(spacing: Theme.Spacing.lg) {
                            SettingsSlider(
                                value: $fontSize,
                                in: 14...28,
                                step: 2,
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
