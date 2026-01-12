import SwiftUI

// MARK: - Recent Prayers Sheet
// Displays user's saved prayers in a scrollable sheet

struct RecentPrayersSheet: View {
    let prayerService: PrayerService
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var selectedPrayer: SavedPrayer?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if prayerService.savedPrayers.isEmpty {
                    emptyState
                } else {
                    prayerList
                }
            }
            .navigationTitle("Recent Prayers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccentAction"))
                }
            }
            .navigationDestination(item: $selectedPrayer) { prayer in
                PrayerDetailView(prayer: prayer)
            }
        }
        .task {
            await loadPrayers()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .tint(Color("AppAccentAction"))
            Text("Loading prayers...")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color("AppTextSecondary"))

            Text("No Saved Prayers")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color("AppTextPrimary"))

            Text("Prayers you save will appear here")
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Prayer List

    private var prayerList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(prayerService.savedPrayers) { prayer in
                    Button {
                        HapticService.shared.lightTap()
                        selectedPrayer = prayer
                    } label: {
                        PrayerCard(prayer: prayer)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Load Prayers

    private func loadPrayers() async {
        await prayerService.loadPrayers()
        isLoading = false
    }
}

// MARK: - Prayer Card

private struct PrayerCard: View {
    let prayer: SavedPrayer

    private var intentionPreview: String {
        let text = prayer.userContext
        if text.count > 50 {
            return "\u{201C}\(String(text.prefix(50)))...\u{201D}"
        }
        return "\u{201C}\(text)\u{201D}"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Tradition badge
            HStack {
                Text(prayer.tradition.rawValue)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppAccentAction"))

                Spacer()

                Text(prayer.createdAt, style: .relative)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("TertiaryText"))
            }

            // Prayer content preview
            Text(prayer.preview)
                .font(Typography.Scripture.body)
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(4)

            // User's intention
            if !prayer.userContext.isEmpty {
                Text(intentionPreview)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .italic()
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
        )
    }
}

// MARK: - Prayer Detail View

private struct PrayerDetailView: View {
    let prayer: SavedPrayer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text(prayer.tradition.rawValue)
                            .font(Typography.Command.label)
                            .foregroundStyle(Color("AppAccentAction"))

                        Spacer()

                        Text(prayer.createdAt, style: .date)
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                    }

                    if !prayer.userContext.isEmpty {
                        Text("Your intention:")
                            .font(Typography.Command.caption)
                            .foregroundStyle(Color("TertiaryText"))
                        Text(prayer.userContext)
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .italic()
                    }
                }

                Divider()

                // Full prayer content
                Text(prayer.content)
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineSpacing(6)

                // Amen
                Text(prayer.amen)
                    .font(Typography.Scripture.body.italic())
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Color.appBackground)
        .navigationTitle("Prayer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "\(prayer.content)\n\n\(prayer.amen)") {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color("AppAccentAction"))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Recent Prayers") {
    RecentPrayersSheet(prayerService: PrayerService.shared)
}
