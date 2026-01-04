import SwiftUI

// MARK: - Illuminated Chapter Header
// Decorative chapter header with illuminated manuscript styling
// Features: chapter label, large number, decorative underline

struct IlluminatedChapterHeader: View {
    let chapterNumber: Int
    let bookName: String?
    let showBookName: Bool
    let dividerStyle: OrnamentalDividerStyle

    @Environment(\.colorScheme) private var colorScheme

    init(
        chapterNumber: Int,
        bookName: String? = nil,
        showBookName: Bool = false,
        dividerStyle: OrnamentalDividerStyle = .chapterUnderline
    ) {
        self.chapterNumber = chapterNumber
        self.bookName = bookName
        self.showBookName = showBookName
        self.dividerStyle = dividerStyle
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Book name (optional)
            if showBookName, let bookName = bookName {
                Text(bookName.uppercased())
                    .font(Typography.Illuminated.sectionTitle())
                    .tracking(3)
                    .foregroundStyle(Color.primaryText)
            }

            // Chapter label
            Text("CHAPTER")
                .font(Typography.UI.caption2.weight(.medium))
                .tracking(4)
                .foregroundStyle(Color.secondaryText)

            // Large chapter number
            Text("\(chapterNumber)")
                .font(Typography.Illuminated.chapterNumber())
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.illuminatedGold,
                            Color.divineGold,
                            Color.burnishedGold
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Decorative underline
            OrnamentalDivider(style: dividerStyle)
                .padding(.horizontal, AppTheme.Spacing.xxxl - 8)
                .padding(.top, AppTheme.Spacing.xs)
        }
        .padding(.vertical, AppTheme.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chapter \(chapterNumber)")
    }
}

// MARK: - Illuminated Book Title
// Decorative book title with flourishes

struct IlluminatedBookTitle: View {
    let title: String
    let subtitle: String?
    let showFlourishes: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        subtitle: String? = nil,
        showFlourishes: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showFlourishes = showFlourishes
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Title with optional flourishes
            HStack(spacing: AppTheme.Spacing.md) {
                if showFlourishes {
                    flourish
                        .scaleEffect(x: -1, y: 1)
                }

                Text(title.uppercased())
                    .font(Typography.Illuminated.bookTitle())
                    .tracking(2)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)

                if showFlourishes {
                    flourish
                }
            }

            // Subtitle (e.g., "The Gospel According to")
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Typography.Illuminated.sectionTitle())
                    .foregroundStyle(Color.secondaryText)
            }

            // Decorative underline
            OrnamentalDivider(style: .manuscript)
                .padding(.horizontal, AppTheme.Spacing.xxxl + 12)
                .padding(.top, AppTheme.Spacing.sm)
        }
        .padding(.vertical, AppTheme.Spacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    /// Decorative flourish element
    private var flourish: some View {
        Image(systemName: "leaf.fill")
            .font(Typography.UI.iconSm)
            .foregroundStyle(Color.divineGold.opacity(AppTheme.Opacity.strong))
            .rotationEffect(.degrees(-30))
    }
}

// MARK: - Compact Chapter Indicator
// Smaller chapter indicator for inline use

struct CompactChapterIndicator: View {
    let chapterNumber: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.divineGold.opacity(AppTheme.Opacity.disabled)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)

            // Chapter number
            Text("\(chapterNumber)")
                .font(Typography.Display.title2)
                .foregroundStyle(Color.divineGold)

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.divineGold.opacity(AppTheme.Opacity.disabled), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: AppTheme.Divider.thin)
        }
        .frame(height: AppTheme.Spacing.xxl)
        .padding(.vertical, AppTheme.Spacing.sm)
        .accessibilityLabel("Chapter \(chapterNumber)")
    }
}

// MARK: - Section Header
// For sections within chapters (e.g., "The Beatitudes")

struct IlluminatedSectionHeader: View {
    let title: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(Typography.Illuminated.sectionTitle())
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            // Small decorative element
            HStack(spacing: AppTheme.Spacing.xs) {
                Diamond()
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                    .frame(width: AppTheme.Spacing.xs, height: AppTheme.Spacing.xs)

                Diamond()
                    .fill(Color.divineGold)
                    .frame(width: AppTheme.ComponentSize.dot, height: AppTheme.ComponentSize.dot)

                Diamond()
                    .fill(Color.divineGold.opacity(AppTheme.Opacity.heavy))
                    .frame(width: AppTheme.Spacing.xs, height: AppTheme.Spacing.xs)
            }
        }
        .padding(.vertical, AppTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

// MARK: - Preview

#Preview("Illuminated Chapter Header") {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xxxl) {
            IlluminatedChapterHeader(chapterNumber: 1)

            IlluminatedChapterHeader(
                chapterNumber: 3,
                bookName: "Genesis",
                showBookName: true
            )

            IlluminatedChapterHeader(
                chapterNumber: 23,
                dividerStyle: .flourish
            )
        }
        .padding()
    }
    .background(Color(.systemBackground))
}

#Preview("Illuminated Book Title") {
    VStack(spacing: AppTheme.Spacing.xxxl) {
        IlluminatedBookTitle(title: "Genesis")

        IlluminatedBookTitle(
            title: "Matthew",
            subtitle: "The Gospel According to"
        )

        IlluminatedBookTitle(
            title: "Psalms",
            showFlourishes: false
        )
    }
    .padding()
}

#Preview("Compact Indicators") {
    VStack(spacing: AppTheme.Spacing.xl) {
        CompactChapterIndicator(chapterNumber: 1)
        CompactChapterIndicator(chapterNumber: 12)
        CompactChapterIndicator(chapterNumber: 119)

        IlluminatedSectionHeader(title: "The Beatitudes")
        IlluminatedSectionHeader(title: "The Lord's Prayer")
    }
    .padding()
}
