import SwiftUI

// MARK: - Chapter Side Panel
// Right-sliding panel showing all chapters for the current book.
// Opens via chapter button tap or left swipe gesture.
// Dismisses via tap outside, swipe right, or chapter selection.
//
// Design: Feels like an index strip at the edge of a book
// - Tinted translucent scrim (not gray disabled state)
// - Parchment-toned panel with hairline edge
// - Subtle selection (not loud badge)

struct ChapterSidePanel: View {
    let book: Book?
    let currentChapter: Int
    @Binding var isPresented: Bool
    let onSelectChapter: (Int) -> Void

    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    @Environment(\.colorScheme) private var colorScheme

    private let panelWidth: CGFloat = 80
    private let dismissThreshold: CGFloat = 40

    static func selectedChapterFillName(for colorScheme: ColorScheme) -> String {
        "SelectionBackground"
    }

    static func selectedChapterTextName(for colorScheme: ColorScheme) -> String {
        "AppTextPrimary"
    }

    static func unselectedChapterTextName(for colorScheme: ColorScheme) -> String {
        "AppTextSecondary"
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Tinted scrim - text stays present but receded
            if isPresented {
                scrimLayer
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
                    .transition(.opacity)
            }

            // Panel - feels like a page edge / index card
            if isPresented {
                panelContent
                    .frame(width: panelWidth)
                    .background(Color("AppBackground"))
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.appDivider)
                            .frame(width: Theme.Stroke.hairline)
                    }
                    .offset(x: dragOffset)
                    .gesture(dismissGesture)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(Theme.Animation.settle, value: isPresented)
    }

    // MARK: - Scrim Layer
    // Content stays visible but receded - page still recognizable behind

    private var scrimLayer: some View {
        Group {
            if colorScheme == .dark {
                // Warm candlelit dimming - not neutral gray
                Color.warmCharcoal.opacity(0.4)
            } else {
                // Very light veil - page clearly visible through
                Color("AppBackground").opacity(0.55)
            }
        }
    }

    // MARK: - Panel Content

    private var panelContent: some View {
        VStack(spacing: 0) {
            // Header - provides context
            panelHeader

            // Chapter list
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: Theme.Spacing.xs) {
                        ForEach(1...(book?.chapters ?? 1), id: \.self) { chapter in
                            ChapterCell(
                                chapter: chapter,
                                isCurrent: chapter == currentChapter
                            )
                            .id(chapter)
                            .onTapGesture {
                                onSelectChapter(chapter)
                                dismiss()
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.md)
                }
                .onAppear {
                    // Scroll to current chapter centered in view
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(currentChapter, anchor: .center)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("ReaderChapterPanel")
        .accessibilityElement()
    }

    // MARK: - Panel Header
    // Simple book name only - chapter shown in selection below

    private var panelHeader: some View {
        Group {
            if let book = book {
                Text(book.name)
                    .font(Typography.Command.caption.weight(.medium))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Dismiss Gesture

    private var dismissGesture: some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                // Only allow dragging right (positive x)
                if value.translation.width > 0 {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                if value.translation.width > dismissThreshold {
                    dismiss()
                } else {
                    withAnimation(Theme.Animation.settle) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func dismiss() {
        withAnimation(Theme.Animation.settle) {
            isPresented = false
            dragOffset = 0
        }
    }
}

// MARK: - Chapter Cell
// Selection via typography weight + subtle fill - no loud borders

private struct ChapterCell: View {
    let chapter: Int
    let isCurrent: Bool

    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("\(chapter)")
            .font(Typography.Command.body.weight(isCurrent ? .semibold : .regular))
            .foregroundStyle(textColor)
            .frame(width: 56, height: 40)
            .background(
                Capsule()
                    .fill(isCurrent ? fillColor : Color.clear)
            )
            .contentShape(Rectangle())
            // swiftlint:disable:next hardcoded_scale_effect
            .scaleEffect(isPressed ? 0.94 : 1)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                withAnimation(Theme.Animation.settle) {
                    isPressed = pressing
                }
            }, perform: {})
    }

    private var textColor: Color {
        if isCurrent {
            return Color(ChapterSidePanel.selectedChapterTextName(for: colorScheme))
        }
        return Color(ChapterSidePanel.unselectedChapterTextName(for: colorScheme))
    }

    private var fillColor: Color {
        Color(ChapterSidePanel.selectedChapterFillName(for: colorScheme))
    }
}

// MARK: - Preview

#Preview("Chapter Panel - Genesis") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        @State private var selectedChapter = 12

        var body: some View {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                VStack {
                    Text("Genesis \(selectedChapter)")
                        .font(Typography.Scripture.title)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Spacer()
                }
                .padding()

                ChapterSidePanel(
                    book: Book.all.first { $0.name == "Genesis" },
                    currentChapter: selectedChapter,
                    isPresented: $isPresented,
                    onSelectChapter: { chapter in
                        selectedChapter = chapter
                    }
                )
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Chapter Panel - Psalms (150 chapters)") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        @State private var selectedChapter = 119

        var body: some View {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                VStack {
                    Text("Psalm \(selectedChapter)")
                        .font(Typography.Scripture.title)
                        .foregroundStyle(Color("AppTextPrimary"))

                    Spacer()
                }
                .padding()

                ChapterSidePanel(
                    book: Book.all.first { $0.name == "Psalms" },
                    currentChapter: selectedChapter,
                    isPresented: $isPresented,
                    onSelectChapter: { chapter in
                        selectedChapter = chapter
                    }
                )
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Chapter Panel - Obadiah (1 chapter)") {
    struct PreviewWrapper: View {
        @State private var isPresented = true

        var body: some View {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                ChapterSidePanel(
                    book: Book.all.first { $0.name == "Obadiah" },
                    currentChapter: 1,
                    isPresented: $isPresented,
                    onSelectChapter: { _ in }
                )
            }
        }
    }

    return PreviewWrapper()
}
