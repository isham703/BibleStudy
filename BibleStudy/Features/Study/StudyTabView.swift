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
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(StudySection.allCases, id: \.self) { section in
                            StudySectionButton(
                                section: section,
                                isSelected: selectedSection == section
                            ) {
                                withAnimation(Theme.Animation.fade) {
                                    selectedSection = section
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, Theme.Spacing.sm)

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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                sectionIcon
                    .font(Typography.Command.caption)
                Text(section.title)
                    .font(Typography.Command.meta)
            }
            .foregroundStyle(isSelected ? .white : Color("AppTextPrimary"))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color("AppAccentAction") : Color("AppSurface"))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color("AppDivider"), lineWidth: Theme.Stroke.hairline)
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
