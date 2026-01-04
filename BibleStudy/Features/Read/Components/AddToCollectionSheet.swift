import SwiftUI

// MARK: - Add to Collection Sheet

struct AddToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collectionService = StudyCollectionService.shared
    @State private var isLoading = true
    @State private var showNewCollection = false
    @State private var newCollectionName = ""

    let range: VerseRange
    let onSelect: (StudyCollection) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if collectionService.collections.isEmpty {
                    emptyState
                } else {
                    collectionsList
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewCollection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await collectionService.loadCollections()
                isLoading = false
            }
            .alert("New Collection", isPresented: $showNewCollection) {
                TextField("Collection name", text: $newCollectionName)
                Button("Cancel", role: .cancel) {
                    newCollectionName = ""
                }
                Button("Create") {
                    Task {
                        if let collection = try? await collectionService.createCollection(name: newCollectionName) {
                            onSelect(collection)
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("Enter a name for your new collection")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "folder")
                .font(Typography.UI.largeTitle)
                .foregroundStyle(Color.tertiaryText)

            Text("No collections yet")
                .font(Typography.UI.headline)
                .foregroundStyle(Color.primaryText)

            Text("Create your first collection to organize verses")
                .font(Typography.UI.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                showNewCollection = true
            } label: {
                Label("Create Collection", systemImage: "plus")
                    .font(Typography.UI.bodyBold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var collectionsList: some View {
        List {
            ForEach(collectionService.collections) { collection in
                Button {
                    onSelect(collection)
                    dismiss()
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: collection.icon)
                            .font(Typography.UI.title3)
                            .foregroundStyle(Color(collection.color))
                            .frame(width: AppTheme.IconContainer.medium)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text(collection.name)
                                .font(Typography.UI.bodyBold)
                                .foregroundStyle(Color.primaryText)

                            Text("\(collection.itemCount) items")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.secondaryText)
                        }

                        Spacer()

                        if collection.contains(verseRange: range) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentGold)
                        }
                    }
                }
                .disabled(collection.contains(verseRange: range))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddToCollectionSheet(
        range: VerseRange(
            bookId: 43,
            chapter: 3,
            verseStart: 16,
            verseEnd: 16
        )
    ) { collection in
        print("Selected: \(collection.name)")
    }
}
