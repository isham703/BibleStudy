import SwiftUI

// MARK: - Study Tab View
// Notebook, Highlights, Stories, Topics, and Word Study

struct StudyTabView: View {
    @State private var selectedSection: StudySection = .notebook
    @State private var navigateToVerse: VerseRange?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section Picker (scrollable for 5 items)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(StudySection.allCases, id: \.self) { section in
                            StudySectionButton(
                                section: section,
                                isSelected: selectedSection == section
                            ) {
                                withAnimation(AppTheme.Animation.quick) {
                                    selectedSection = section
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, AppTheme.Spacing.sm)

                Divider()

                // Content
                switch selectedSection {
                case .notebook:
                    NotebookView()
                case .highlights:
                    HighlightLibraryView { range in
                        navigateToVerse = range
                    }
                case .stories:
                    StoryExplorerView()
                case .topics:
                    TopicExplorerView()
                case .wordStudy:
                    WordStudyView()
                }
            }
            .navigationTitle("Study")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Search action
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(item: $navigateToVerse) { range in
                VersePreviewSheet(verseRange: range)
            }
            .navigationDestination(for: Story.self) { story in
                StoryReaderView(story: story)
            }
        }
    }
}

// MARK: - Study Section Button
struct StudySectionButton: View {
    let section: StudySection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                sectionIcon
                    .font(Typography.UI.caption1)
                Text(section.title)
                    .font(Typography.UI.chipLabel)
            }
            .foregroundStyle(isSelected ? .white : Color.primaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color.scholarAccent : Color.surfaceBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var sectionIcon: some View {
        if section.usesStreamlineIcon {
            Image(section.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: section.icon)
        }
    }
}

// MARK: - Study Section
enum StudySection: String, CaseIterable {
    case notebook
    case highlights
    case stories
    case topics
    case wordStudy

    var title: String {
        switch self {
        case .notebook: return "Notes"
        case .highlights: return "Highlights"
        case .stories: return "Stories"
        case .topics: return "Topics"
        case .wordStudy: return "Words"
        }
    }

    var icon: String {
        switch self {
        case .notebook: return AppIcons.Study.notes
        case .highlights: return AppIcons.Study.highlights
        case .stories: return AppIcons.Study.stories
        case .topics: return AppIcons.Study.topics
        case .wordStudy: return AppIcons.Study.words
        }
    }

    /// Whether this section uses a Streamline asset (vs SF Symbol)
    var usesStreamlineIcon: Bool {
        switch self {
        case .notebook, .highlights, .stories, .topics:
            return true
        case .wordStudy:
            return false  // Uses SF Symbol
        }
    }
}

// MARK: - Word Study View (Placeholder)
struct WordStudyView: View {
    var body: some View {
        EmptyStateView(
            icon: "character.book.closed",
            title: "Word Study",
            message: "Search for Hebrew or Greek words to explore their meanings."
        )
    }
}

#Preview {
    StudyTabView()
        .environment(BibleService.shared)
}
