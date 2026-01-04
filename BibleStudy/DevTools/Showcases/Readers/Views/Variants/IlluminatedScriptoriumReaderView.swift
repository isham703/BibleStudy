import SwiftUI

// MARK: - Illuminated Scriptorium Reader View
// Meridian-based reader with verse-by-verse layout, drop caps, and golden accents

struct IlluminatedScriptoriumReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var selectedVerse: Int?

    private let passage = PlaceholderScripture.johnPrologue

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - reuse MeridianBackground
                MeridianBackground()

                // Main content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Chapter header
                        chapterHeader
                            .padding(.top, SanctuaryTheme.Spacing.xxxl)

                        // Ornamental divider
                        ScriptoriumDivider()
                            .padding(.vertical, SanctuaryTheme.Spacing.xl)
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)

                        // Verses
                        versesSection
                            .padding(.horizontal, SanctuaryTheme.Spacing.xl)

                        // Bottom spacing
                        Spacer()
                            .frame(height: SanctuaryTheme.Spacing.xxxl * 2)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(passage.reference)
                    .font(.custom("Cinzel-Regular", size: 12))
                    .tracking(2)
                    .foregroundStyle(Color.meridianSepia.opacity(0.7))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }

    // MARK: - Chapter Header

    private var chapterHeader: some View {
        VStack(spacing: SanctuaryTheme.Spacing.sm) {
            // Book name
            Text(passage.bookName.uppercased())
                .font(.custom("Cinzel-Regular", size: 11))
                .tracking(4)
                .foregroundStyle(Color.meridianIllumination)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: isVisible)

            // Chapter number
            Text("\(passage.chapter)")
                .font(.custom("Cinzel-Regular", size: 72))
                .foregroundStyle(Color.meridianGilded)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isVisible)
        }
    }

    // MARK: - Verses Section

    private var versesSection: some View {
        VStack(alignment: .leading, spacing: SanctuaryTheme.Spacing.lg) {
            ForEach(Array(passage.verses.enumerated()), id: \.element.id) { index, verse in
                ScriptoriumVerseText(
                    verse: verse,
                    isFirstVerse: index == 0,
                    isSelected: selectedVerse == verse.id,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedVerse = selectedVerse == verse.id ? nil : verse.id
                        }
                    }
                )
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8).delay(0.4 + Double(index) * 0.05),
                    value: isVisible
                )
            }
        }
    }
}

// MARK: - Scriptorium Verse Text

private struct ScriptoriumVerseText: View {
    let verse: PlaceholderScripture.Verse
    let isFirstVerse: Bool
    let isSelected: Bool
    let onTap: () -> Void

    @State private var showShimmer = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isFirstVerse {
                // Drop cap for first verse
                dropCap
            }

            // Verse content
            verseContent
        }
        .padding(.vertical, SanctuaryTheme.Spacing.sm)
        .padding(.horizontal, SanctuaryTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.small)
                .fill(isSelected ? Color.meridianIllumination.opacity(0.1) : Color.clear)
        )
        .overlay(
            // Gold shimmer on selection
            RoundedRectangle(cornerRadius: SanctuaryTheme.CornerRadius.small)
                .stroke(
                    isSelected ? Color.meridianGilded.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            HomeShowcaseHaptics.cardPress()
            onTap()
        }
    }

    // MARK: - Drop Cap

    private var dropCap: some View {
        let firstChar = String(verse.text.prefix(1))

        return Text(firstChar)
            .font(.custom("Cinzel-Regular", size: 72))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.meridianGilded, Color.meridianIllumination],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 60, alignment: .center)
            .padding(.trailing, SanctuaryTheme.Spacing.sm)
            .shadow(color: Color.meridianIllumination.opacity(0.3), radius: 8)
    }

    // MARK: - Verse Content

    private var verseContent: some View {
        let text = isFirstVerse ? String(verse.text.dropFirst()) : verse.text

        return HStack(alignment: .firstTextBaseline, spacing: SanctuaryTheme.Spacing.sm) {
            // Verse number (ornamental style)
            if !isFirstVerse {
                Text("\(verse.id)")
                    .font(.custom("Cinzel-Regular", size: 14))
                    .foregroundStyle(Color.meridianGilded)
                    .baselineOffset(4)
            }

            // Verse text
            Text(text)
                .font(.custom("CormorantGaramond-Regular", size: 20))
                .foregroundStyle(Color.meridianSepia)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Scriptorium Divider

private struct ScriptoriumDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left gradient line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.meridianGilded.opacity(0.3),
                            Color.meridianIllumination.opacity(0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)

            // Center ornament - sun/book motif
            Image(systemName: "book.fill")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.meridianIllumination, Color.meridianGilded],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Right gradient line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.meridianIllumination.opacity(0.5),
                            Color.meridianGilded.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        IlluminatedScriptoriumReaderView()
    }
}
