import SwiftUI

// MARK: - Note Editor
// Sheet for creating and editing notes with Markdown support

struct NoteEditor: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let range: VerseRange
    let existingNote: Note?
    let allNotes: [Note]
    let onSave: (String, NoteTemplate, [UUID]) -> Void
    let onDelete: (() -> Void)?
    let onNavigateToNote: ((Note) -> Void)?

    @State private var content: String
    @State private var selectedTemplate: NoteTemplate
    @State private var linkedNoteIds: [UUID]
    @State private var showDeleteConfirmation = false
    @State private var showPreview = false
    @State private var showTemplateSheet = false
    @State private var showLinkPicker = false
    @FocusState private var isContentFocused: Bool

    init(
        range: VerseRange,
        existingNote: Note? = nil,
        allNotes: [Note] = [],
        onSave: @escaping (String, NoteTemplate, [UUID]) -> Void,
        onDelete: (() -> Void)? = nil,
        onNavigateToNote: ((Note) -> Void)? = nil
    ) {
        self.range = range
        self.existingNote = existingNote
        self.allNotes = allNotes
        self.onSave = onSave
        self.onDelete = onDelete
        self.onNavigateToNote = onNavigateToNote
        _content = State(initialValue: existingNote?.content ?? "")
        _selectedTemplate = State(initialValue: existingNote?.template ?? .freeform)
        _linkedNoteIds = State(initialValue: existingNote?.linkedNoteIds ?? [])
    }

    private var linkedNotes: [Note] {
        allNotes.filter { linkedNoteIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Reference header
                referenceHeader

                Divider()
                    .background(Color.appDivider)

                // Formatting toolbar
                formattingToolbar

                Divider()
                    .background(Color.appDivider)

                // Linked notes display (if any)
                if !linkedNotes.isEmpty {
                    linkedNotesSection
                    Divider()
                        .background(Color.appDivider)
                }

                // Note content or preview
                if showPreview {
                    markdownPreview
                } else {
                    noteContent
                }

                Spacer()
            }
            .background(Color.appBackground)
            .navigationTitle(existingNote == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(content, selectedTemplate, linkedNoteIds)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             content.count > Note.maxContentLength)
                }

                if existingNote != nil, onDelete != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Note", systemImage: "trash")
                                .foregroundStyle(Color("FeedbackError"))
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete Note",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this note? This action cannot be undone.")
            }
            .sheet(isPresented: $showTemplateSheet) {
                templatePickerSheet
            }
            .sheet(isPresented: $showLinkPicker) {
                NoteLinkPicker(
                    currentNoteId: existingNote?.id,
                    allNotes: allNotes,
                    linkedNoteIds: $linkedNoteIds
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                isContentFocused = true
            }
        }
    }

    // MARK: - Linked Notes Section
    private var linkedNotesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(linkedNotes) { note in
                    Button {
                        onNavigateToNote?(note)
                    } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "link")
                                .font(Typography.Command.meta)

                            Text(note.reference)
                                .font(Typography.Command.meta)
                        }
                        .foregroundStyle(Color("AppAccentAction"))
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                        )
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(Color("AppSurface"))
    }

    // MARK: - Reference Header
    private var referenceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(range.reference)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color("AppTextPrimary"))

                if let book = Book.find(byId: range.bookId) {
                    Text("\(book.testament.rawValue.capitalized) Testament")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }

            Spacer()

            // Template badge
            Button {
                showTemplateSheet = true
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: selectedTemplate.icon)
                    Text(selectedTemplate.displayName)
                }
                .font(Typography.Command.caption)
                .foregroundStyle(Color("AppAccentAction"))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                )
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color("AppSurface"))
    }

    // MARK: - Formatting Toolbar
    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // Text formatting
                FormatButton(icon: "bold", label: "Bold") {
                    insertMarkdown("**", "**")
                }

                FormatButton(icon: "italic", label: "Italic") {
                    insertMarkdown("*", "*")
                }

                FormatButton(icon: "strikethrough", label: "Strikethrough") {
                    insertMarkdown("~~", "~~")
                }

                Divider()
                    .frame(height: 24)

                // Headers
                FormatButton(icon: "number", label: "H1") {
                    insertLinePrefix("# ")
                }

                FormatButton(icon: "number.square", label: "H2") {
                    insertLinePrefix("## ")
                }

                Divider()
                    .frame(height: 24)

                // Lists
                FormatButton(icon: "list.bullet", label: "Bullet") {
                    insertLinePrefix("- ")
                }

                FormatButton(icon: "list.number", label: "Numbered") {
                    insertLinePrefix("1. ")
                }

                FormatButton(icon: "checklist", label: "Checkbox") {
                    insertLinePrefix("- [ ] ")
                }

                Divider()
                    .frame(height: 24)

                // Quote & Link
                FormatButton(icon: "text.quote", label: "Quote") {
                    insertLinePrefix("> ")
                }

                FormatButton(icon: "link", label: "URL Link") {
                    insertMarkdown("[", "](url)")
                }

                Divider()
                    .frame(height: 24)

                // Note linking button
                Button {
                    showLinkPicker = true
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "link.badge.plus")
                            .font(Typography.Command.subheadline)

                        if !linkedNoteIds.isEmpty {
                            Text("\(linkedNoteIds.count)")
                                .font(Typography.Command.meta)
                        }
                    }
                    .foregroundStyle(linkedNoteIds.isEmpty ? Color("AppTextSecondary") : Color("AppAccentAction"))
                    .frame(height: 32)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .background(linkedNoteIds.isEmpty ? Color.clear : Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground))
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Link to other notes")

                Divider()
                    .frame(height: 24)

                // Preview toggle
                Button {
                    showPreview.toggle()
                } label: {
                    Image(systemName: showPreview ? "pencil" : "eye")
                        .font(Typography.Command.subheadline)
                        .foregroundStyle(showPreview ? Color("AppAccentAction") : Color("AppTextSecondary"))
                        .frame(width: 32, height: 32)
                        .background(showPreview ? Color("AppAccentAction").opacity(Theme.Opacity.selectionBackground) : Color.clear)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .background(Color("AppSurface"))
    }

    // MARK: - Note Content
    private var noteContent: some View {
        VStack(spacing: 0) {
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color("AppTextPrimary"))
                .scrollContentBackground(.hidden)
                .padding(Theme.Spacing.md)
                .focused($isContentFocused)
                .overlay(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Write your thoughts using Markdown...")
                            .font(Typography.Command.body)
                            .foregroundStyle(Color("TertiaryText"))
                            .padding(Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.sm)
                            .allowsHitTesting(false)
                    }
                }

            // MARK: - Character Counter
            // Displays writing progress with classical aesthetics
            // State transitions: Subtle → Contemplative Warning → Urgent Reverence

            VStack(spacing: Theme.Spacing.xs) {
                // Progress bar - illuminated gold fill reveals as writing progresses
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track - subtle vellum background
                        RoundedRectangle(cornerRadius: Theme.Radius.xs)
                            .fill(Color("AppSurface").opacity(Theme.Opacity.subtle))
                            .frame(height: 2 + 1)

                        // Fill - divine gold that transforms with state
                        RoundedRectangle(cornerRadius: Theme.Opacity.focusStroke)
                            .fill(progressBarColor)
                            .frame(width: progressWidth(in: geometry.size.width), height: 2 + 1)
                            .shadow(color: progressBarColor.opacity(Theme.Opacity.textSecondary), radius: progressGlowRadius, y: 0)
                            .animation(Theme.Animation.settle, value: content.count)
                    }
                }
                .frame(height: 3)

                // Character count text with sacred numerals
                HStack(spacing: Theme.Spacing.xs) {
                    Spacer()

                    // State icon (appears when approaching/over limit)
                    if shouldShowStateIcon {
                        Image(systemName: stateIcon)
                            .font(Typography.Command.meta)
                            .foregroundStyle(characterCountColor)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Count display
                    Text(characterCountText)
                        .font(Typography.Command.caption)  // Slightly larger for better readability
                        .fontDesign(.serif)  // Manuscript aesthetic
                        .foregroundStyle(characterCountColor)
                        .animation(Theme.Animation.slowFade, value: characterCountColor)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.sm)
            .padding(.bottom, Theme.Spacing.md)
        }
    }

    // MARK: - Markdown Preview
    private var markdownPreview: some View {
        ScrollView {
            MarkdownRenderer(content: content)
                .padding(Theme.Spacing.md)
        }
    }

    // MARK: - Template Picker Sheet
    private var templatePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(NoteTemplate.allCases, id: \.self) { template in
                    Button {
                        if existingNote == nil && content.isEmpty {
                            // Apply template content for new empty notes
                            content = template.templateContent
                        }
                        selectedTemplate = template
                        showTemplateSheet = false
                    } label: {
                        HStack {
                            Image(systemName: template.icon)
                                .font(Typography.Command.title3)
                                .foregroundStyle(Color("AppAccentAction"))
                                .frame(width: Theme.Size.iconSizeLarge)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.displayName)
                                    .font(Typography.Command.body)
                                    .foregroundStyle(Color("AppTextPrimary"))

                                Text(templateDescription(for: template))
                                    .font(Typography.Command.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }

                            Spacer()

                            if selectedTemplate == template {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color("AppAccentAction"))
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showTemplateSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    // MARK: - Character Counter Helpers

    /// Warning threshold - show warning state this many characters before limit
    private static let warningThreshold = 5000

    private var progressFraction: Double {
        min(Double(content.count) / Double(Note.maxContentLength), 1.0)
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        totalWidth * progressFraction
    }

    private var characterCountText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","

        let current = formatter.string(from: NSNumber(value: content.count)) ?? "\(content.count)"
        let max = formatter.string(from: NSNumber(value: Note.maxContentLength)) ?? "\(Note.maxContentLength)"

        return "\(current) / \(max)"
    }

    private var characterCountColor: Color {
        if content.count > Note.maxContentLength {
            // Over limit - error red (urgent)
            return Color("FeedbackError")
        } else if content.count > Note.maxContentLength - Self.warningThreshold {
            // Approaching limit - warning ochre (contemplative warning)
            return Color("FeedbackWarning")
        } else {
            // Normal - aged ink (subtle elegance)
            return Color("AppSurface").opacity(Theme.Opacity.pressed)
        }
    }

    private var progressBarColor: Color {
        if content.count > Note.maxContentLength {
            // Over limit - error red with urgency
            return Color("FeedbackError")
        } else if content.count > Note.maxContentLength - Self.warningThreshold {
            // Approaching - warning ochre with gentle warning
            return Color("FeedbackWarning")
        } else if content.count > Note.maxContentLength / 2 {
            // Halfway - accent seal with confidence
            return Color("AccentBronze")
        } else {
            // Beginning - accent seal with gentle encouragement
            return Color("AccentBronze").opacity(Theme.Opacity.pressed)
        }
    }

    private var progressGlowRadius: CGFloat {
        if content.count > Note.maxContentLength {
            // Over limit - strong glow for urgency
            return 4
        } else if content.count > Note.maxContentLength - Self.warningThreshold {
            // Approaching - moderate glow for awareness
            return 3
        } else {
            // Normal - subtle glow for elegance
            return 2
        }
    }

    private var shouldShowStateIcon: Bool {
        content.count > Note.maxContentLength - Self.warningThreshold
    }

    private var stateIcon: String {
        if content.count > Note.maxContentLength {
            return "exclamationmark.triangle.fill"  // Over limit warning
        } else {
            return "hourglass"  // Approaching limit indicator
        }
    }

    private func templateDescription(for template: NoteTemplate) -> String {
        switch template {
        case .freeform: return "Write freely without structure"
        case .observation: return "What you notice in the text"
        case .application: return "How to apply this to life"
        case .questions: return "Questions raised by the passage"
        case .exegesis: return "Deep study with context and language"
        case .prayer: return "ACTS prayer framework"
        }
    }

    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        content += prefix + "text" + suffix
    }

    private func insertLinePrefix(_ prefix: String) {
        if content.isEmpty || content.hasSuffix("\n") {
            content += prefix
        } else {
            content += "\n" + prefix
        }
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Typography.Command.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Markdown Renderer
struct MarkdownRenderer: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            ForEach(Array(parseLines().enumerated()), id: \.offset) { _, line in
                renderLine(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parseLines() -> [String] {
        content.components(separatedBy: "\n")
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        if line.hasPrefix("## ") {
            Text(line.dropFirst(3))
                .font(Typography.Command.headline)
                .foregroundStyle(Color("AppTextPrimary"))
        } else if line.hasPrefix("# ") {
            Text(line.dropFirst(2))
                .font(Typography.Command.title3)
                .foregroundStyle(Color("AppTextPrimary"))
        } else if line.hasPrefix("> ") {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color("AppAccentAction"))
                    .frame(width: 3)

                Text(renderInlineMarkdown(String(line.dropFirst(2))))
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .italic()
                    .padding(.leading, Theme.Spacing.sm)
            }
        } else if line.hasPrefix("- [ ] ") {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "square")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("TertiaryText"))

                Text(renderInlineMarkdown(String(line.dropFirst(6))))
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
        } else if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.square.fill")
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color("FeedbackSuccess"))

                Text(renderInlineMarkdown(String(line.dropFirst(6))))
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .strikethrough()
            }
        } else if line.hasPrefix("- ") {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(Color("AppTextPrimary"))
                    .frame(width: 4, height: 4)
                    .padding(.top, Theme.Spacing.sm)

                Text(renderInlineMarkdown(String(line.dropFirst(2))))
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
        } else if let match = line.firstMatch(of: /^(\d+)\. (.*)/) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Text("\(match.1).")
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(width: 24, alignment: .trailing)

                Text(renderInlineMarkdown(String(match.2)))
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
        } else if line.hasPrefix("|") && line.hasSuffix("|") {
            // Table row (simplified rendering)
            let cells = line.dropFirst().dropLast()
                .components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            HStack {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                    Text(cell)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)
            .background(Color("AppSurface"))
        } else if !line.isEmpty {
            Text(renderInlineMarkdown(line))
                .font(Typography.Command.body)
                .foregroundStyle(Color("AppTextPrimary"))
        } else {
            Spacer().frame(height: Theme.Spacing.sm)
        }
    }

    private func renderInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)

        // Bold (**text**)
        while let range = result.range(of: "**", options: []) {
            if let endRange = result[range.upperBound...].range(of: "**") {
                let contentRange = range.upperBound..<endRange.lowerBound
                result[contentRange].inlinePresentationIntent = .stronglyEmphasized
                result.removeSubrange(endRange)
                result.removeSubrange(range)
            } else {
                break
            }
        }

        // Italic (*text*)
        while let range = result.range(of: "*", options: []) {
            if let endRange = result[range.upperBound...].range(of: "*") {
                let contentRange = range.upperBound..<endRange.lowerBound
                result[contentRange].inlinePresentationIntent = .emphasized
                result.removeSubrange(endRange)
                result.removeSubrange(range)
            } else {
                break
            }
        }

        // Strikethrough (~~text~~)
        while let range = result.range(of: "~~", options: []) {
            if let endRange = result[range.upperBound...].range(of: "~~") {
                let contentRange = range.upperBound..<endRange.lowerBound
                result[contentRange].strikethroughStyle = .single
                result.removeSubrange(endRange)
                result.removeSubrange(range)
            } else {
                break
            }
        }

        return result
    }
}

// MARK: - Note Card
// Displays a note in a list

struct NoteCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let note: Note
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header with reference and template
                HStack {
                    Text(note.reference)
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Color("AppAccentAction"))

                    Spacer()

                    // Linked notes indicator
                    if note.hasLinks {
                        HStack(spacing: 2) {
                            Image(systemName: "link")
                            Text("\(note.linkedNoteIds.count)")
                        }
                        .font(Typography.Command.meta)
                        .foregroundStyle(Color("AppAccentAction"))
                    }

                    // Template badge
                    HStack(spacing: 2) {
                        Image(systemName: note.template.icon)
                        Text(note.template.displayName)
                    }
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
                }

                // Preview
                Text(note.preview)
                    .font(Typography.Command.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Date
                Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }
}

// MARK: - Highlight Card
// Displays a highlight in a list

struct HighlightCard: View {
    let highlight: Highlight
    let verseText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Color indicator and reference
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(highlight.color.color)
                        .frame(width: 12, height: 12)

                    Text(highlight.reference)
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }

                // Verse text preview
                if let text = verseText {
                    Text(text)
                        .font(Typography.Scripture.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Date
                Text(highlight.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.Command.meta)
                    .foregroundStyle(Color("TertiaryText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .background(highlight.color.color.opacity(Theme.Opacity.subtle))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        NoteEditor(
            range: VerseRange(bookId: 1, chapter: 1, verseStart: 1, verseEnd: 3),
            onSave: { _, _, _ in }
        )
    }
}
