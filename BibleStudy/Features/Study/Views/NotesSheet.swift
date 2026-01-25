import SwiftUI

// MARK: - Notes Sheet
// Tabbed interface for viewing highlights and notes
// Opened from Bible reader bottom bar

struct NotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: NotesTab = .highlights

    let onNavigate: ((VerseRange) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                tabPicker

                // Content
                TabView(selection: $selectedTab) {
                    highlightsTab
                        .tag(NotesTab.highlights)

                    notesTab
                        .tag(NotesTab.notes)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color.appBackground)
            .navigationTitle("My Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("View", selection: $selectedTab) {
            ForEach(NotesTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Highlights Tab

    private var highlightsTab: some View {
        HighlightLibraryView { range in
            dismiss()
            onNavigate?(range)
        }
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        NotesLibraryView { range in
            dismiss()
            onNavigate?(range)
        }
    }
}

// MARK: - Notes Tab Enum

extension NotesSheet {
    enum NotesTab: String, CaseIterable, Identifiable {
        case highlights
        case notes

        var id: String { rawValue }

        var title: String {
            switch self {
            case .highlights: return "Highlights"
            case .notes: return "Notes"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NotesSheet(onNavigate: { range in
        print("Navigate to \(range)")
    })
    .environment(BibleService.shared)
}
