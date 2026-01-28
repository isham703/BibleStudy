import SwiftUI

// MARK: - Highlighted Caption Text
// Renders caption text with detected Bible references highlighted in accent color.
// Tapping a highlighted reference triggers the onReferenceTapped callback.

struct HighlightedCaptionText: View {
    let text: String
    let font: Font
    let baseColor: Color
    let highlightColor: Color
    let onReferenceTapped: ((ParsedReference) -> Void)?

    /// Optional volatile text to append inline (shown in secondary color, not highlighted)
    let volatileSuffix: String?
    let volatileColor: Color

    init(
        text: String,
        font: Font = Typography.Command.body,
        baseColor: Color = Color("AppTextPrimary"),
        highlightColor: Color = Color("AppAccentAction"),
        onReferenceTapped: ((ParsedReference) -> Void)? = nil,
        volatileSuffix: String? = nil,
        volatileColor: Color = Color("AppTextSecondary")
    ) {
        self.text = text
        self.font = font
        self.baseColor = baseColor
        self.highlightColor = highlightColor
        self.onReferenceTapped = onReferenceTapped
        self.volatileSuffix = volatileSuffix
        self.volatileColor = volatileColor
    }

    var body: some View {
        // Only compute ranges when we have a tap handler (avoids wasted work)
        let ranges = onReferenceTapped != nil
            ? CaptionReferenceDetector.findRanges(in: text)
            : []

        if ranges.isEmpty || onReferenceTapped == nil {
            // No references or no tap handler — plain text with optional volatile suffix
            if let suffix = volatileSuffix, !suffix.isEmpty {
                Text(buildPlainAttributedString(suffix: suffix))
                    .font(font)
            } else {
                Text(text)
                    .font(font)
                    .foregroundStyle(baseColor)
            }
        } else {
            // Build attributed text with tappable highlights
            buildHighlightedText(ranges: ranges)
        }
    }

    // MARK: - Attributed Text Builder

    @ViewBuilder
    private func buildHighlightedText(
        ranges: [(range: Range<String.Index>, reference: ParsedReference)]
    ) -> some View {
        // Build an AttributedString with highlights
        let attributed = buildAttributedString(ranges: ranges)

        Text(attributed)
            .font(font)
            .environment(\.openURL, OpenURLAction { url in
                if let refIndex = url.host(),
                   let index = Int(refIndex),
                   index < ranges.count {
                    onReferenceTapped?(ranges[index].reference)
                }
                return .handled
            })
    }

    private func buildAttributedString(
        ranges: [(range: Range<String.Index>, reference: ParsedReference)]
    ) -> AttributedString {
        var result = AttributedString(text)
        result.foregroundColor = UIColor(baseColor)

        // Apply highlights in reverse order to preserve indices
        for (index, match) in ranges.enumerated().reversed() {
            guard let attrRange = Range(match.range, in: result) else { continue }

            result[attrRange].foregroundColor = UIColor(highlightColor)
            result[attrRange].underlineStyle = .single
            result[attrRange].underlineColor = UIColor(highlightColor.opacity(0.4))
            // Encode the reference index in a link for tap detection
            result[attrRange].link = URL(string: "bibleref://\(index)")
        }

        // Append volatile suffix inline if present
        if let suffix = volatileSuffix, !suffix.isEmpty {
            let separator = text.isEmpty ? "" : " "
            var volatileAttr = AttributedString(separator + suffix)
            volatileAttr.foregroundColor = UIColor(volatileColor)
            result.append(volatileAttr)
        }

        return result
    }

    /// Build attributed string for plain text (no highlights) with volatile suffix
    private func buildPlainAttributedString(suffix: String) -> AttributedString {
        let separator = text.isEmpty ? "" : " "
        var result = AttributedString(text)
        result.foregroundColor = UIColor(baseColor)

        var volatileAttr = AttributedString(separator + suffix)
        volatileAttr.foregroundColor = UIColor(volatileColor)
        result.append(volatileAttr)

        return result
    }
}

// MARK: - Preview

#Preview("Highlighted Captions") {
    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
        HighlightedCaptionText(
            text: "And so we see in Romans 8:1 that there is therefore now no condemnation.",
            onReferenceTapped: { ref in
                print("Tapped: \(ref.displayText)")
            }
        )

        HighlightedCaptionText(
            text: "Turn with me to John 3:16, one of the most well-known verses.",
            onReferenceTapped: { ref in
                print("Tapped: \(ref.displayText)")
            }
        )

        HighlightedCaptionText(
            text: "No references in this text at all."
        )

        // With volatile suffix (continuous flow)
        HighlightedCaptionText(
            text: "And so we see in Romans 8:1 that there is therefore now no condemnation.",
            onReferenceTapped: { ref in
                print("Tapped: \(ref.displayText)")
            },
            volatileSuffix: "For the law of the Spirit of life..."
        )
    }
    .padding()
    .background(Color.appBackground)
}
