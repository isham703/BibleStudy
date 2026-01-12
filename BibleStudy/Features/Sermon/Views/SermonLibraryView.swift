import SwiftUI

// MARK: - Sermon Library View
// Lists all saved sermons with search and filtering

struct SermonLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SermonLibraryViewModel()
    @State private var searchText = ""

    let onSelect: (Sermon) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color("AppBackground")
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if filteredSermons.isEmpty {
                    emptyStateView
                } else {
                    sermonList
                }
            }
            .navigationTitle("Your Sermons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color("AccentBronze"))
                }
            }
            .searchable(text: $searchText, prompt: "Search sermons")
            .task {
                await viewModel.loadSermons()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Filtered Sermons

    private var filteredSermons: [Sermon] {
        if searchText.isEmpty {
            return viewModel.sermons
        }
        return viewModel.sermons.filter { sermon in
            sermon.title.localizedCaseInsensitiveContains(searchText) ||
            (sermon.speakerName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentBronze")))

            Text("Loading sermons...")
                .font(Typography.Scripture.body)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Image(systemName: "waveform.circle")
                // swiftlint:disable:next hardcoded_font_system
                .font(Typography.Icon.display)
                .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

            VStack(spacing: Theme.Spacing.sm) {
                Text(searchText.isEmpty ? "No Sermons Yet" : "No Results")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.appTextPrimary)

                Text(searchText.isEmpty
                    ? "Record or import your first sermon to get started"
                    : "Try a different search term"
                )
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.Spacing.xxl + Theme.Spacing.sm)
    }

    // MARK: - Sermon List

    private var sermonList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(filteredSermons) { sermon in
                    SermonLibraryCard(sermon: sermon) {
                        onSelect(sermon)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteSermon(sermon)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
    }
}

// MARK: - Sermon Library Card

struct SermonLibraryCard: View {
    let sermon: Sermon
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Theme.Spacing.lg) {
                // Status indicator
                statusIcon
                    .frame(width: 40, height: 40)

                // Info
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(sermon.displayTitle)
                        .font(Typography.Scripture.heading)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.sm) {
                        if let speaker = sermon.speakerName {
                            Text(speaker)
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        Text("•")
                            .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

                        Text(sermon.formattedDuration)
                            .foregroundStyle(Color.appTextSecondary)

                        Text("•")
                            .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))

                        Text(sermon.recordedAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .font(Typography.Scripture.body)
                    .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.sm)
                    .foregroundStyle(Color("AccentBronze").opacity(Theme.Opacity.textSecondary))
            }
            .padding(Theme.Spacing.lg)
            .background(Color("AppSurface").opacity(Theme.Opacity.pressed))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(Color("AccentBronze").opacity(Theme.Opacity.selectionBackground), lineWidth: Theme.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusBackgroundColor)

            if sermon.isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentBronze")))
                    .scaleEffect(0.98)
            } else {
                Image(systemName: statusIconName)
                    // swiftlint:disable:next hardcoded_font_system
                    .font(Typography.Icon.base)
                    .foregroundStyle(statusIconColor)
            }
        }
    }

    private var statusBackgroundColor: Color {
        if sermon.hasError {
            return Color.red.opacity(Theme.Opacity.selectionBackground)
        } else if sermon.isComplete {
            return Color("AccentBronze").opacity(Theme.Opacity.selectionBackground)
        } else {
            return Color("AppSurface")
        }
    }

    private var statusIconName: String {
        if sermon.hasError {
            return "exclamationmark.triangle.fill"
        } else if sermon.isComplete {
            return "checkmark.circle.fill"
        } else {
            return "clock"
        }
    }

    private var statusIconColor: Color {
        if sermon.hasError {
            return Color.red
        } else if sermon.isComplete {
            return Color("AccentBronze")
        } else {
            return Color.appTextSecondary
        }
    }
}

// MARK: - Sermon Library ViewModel

@MainActor
@Observable
final class SermonLibraryViewModel {
    var sermons: [Sermon] = []
    var isLoading = false

    private let syncService = SermonSyncService.shared

    func loadSermons() async {
        isLoading = true
        defer { isLoading = false }

        await syncService.loadSermons()
        sermons = syncService.sermons.sorted { $0.recordedAt > $1.recordedAt }
    }

    func deleteSermon(_ sermon: Sermon) async {
        do {
            try await syncService.deleteSermon(sermon)
            sermons.removeAll { $0.id == sermon.id }
            HapticService.shared.success()
        } catch {
            print("[SermonLibraryViewModel] Failed to delete sermon: \(error)")
            HapticService.shared.warning()
        }
    }
}

// MARK: - Preview

#Preview {
    SermonLibraryView { sermon in
        print("Selected: \(sermon.title)")
    }
    .preferredColorScheme(.dark)
}
