import SwiftUI

// MARK: - Legacy Insight Sheet View
// ⚠️ DEPRECATED: This view is being replaced by the new Inline Illumination UX.
// The new pattern uses:
//   - InlineInsightCard: Inline component that unfurls below the selected verse (80% use case)
//   - DeepStudySheet: Full "Scholar's Codex" experience for deep study (20% use case)
//
// This legacy sheet is kept for backwards compatibility and will be removed in a future update.
// See: /BibleStudy/Features/Read/Components/InlineInsightCard.swift
// See: /BibleStudy/Features/Read/InsightSheet/DeepStudySheet.swift

struct InsightSheetView: View {
    let verseRange: VerseRange
    var onNavigate: ((VerseRange) -> Void)?
    var onDismiss: (() -> Void)?
    var initialTab: InsightTab

    @State private var selectedTab: InsightTab = .insight
    @State private var viewModel: InsightViewModel

    init(
        verseRange: VerseRange,
        initialTab: InsightTab = .insight,
        onDismiss: (() -> Void)? = nil,
        onNavigate: ((VerseRange) -> Void)? = nil
    ) {
        self.verseRange = verseRange
        self.initialTab = initialTab
        self.onDismiss = onDismiss
        self.onNavigate = onNavigate
        _selectedTab = State(initialValue: initialTab)
        _viewModel = State(initialValue: InsightViewModel(verseRange: verseRange))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with verse reference and close button
            InsightHeader(verseRange: verseRange, onDismiss: onDismiss)

            // Consolidated Tab Bar (4 tabs)
            InsightTabBar(selectedTab: $selectedTab)

            // Tab Content (Consolidated)
            TabView(selection: $selectedTab) {
                // Insight Tab: Merged Explain + Understand + Interpretation
                ConsolidatedInsightTabContent(viewModel: viewModel)
                    .tag(InsightTab.insight)

                // Context Tab: Merged Context + Cross-refs
                MergedContextTabContent(viewModel: viewModel, onNavigate: onNavigate)
                    .tag(InsightTab.context)

                // Compare Tab: Translation comparison (unchanged)
                TranslationComparisonView(verseRange: verseRange)
                    .tag(InsightTab.compare)

                // Language Tab: Hebrew/Greek analysis (promoted)
                LanguageTabContent(viewModel: viewModel)
                    .tag(InsightTab.language)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.surfaceBackground)
        .task {
            await viewModel.loadContentForConsolidatedTab(selectedTab)
        }
        .onChange(of: selectedTab) { _, newTab in
            Task {
                await viewModel.loadContentForConsolidatedTab(newTab)
            }
        }
    }
}

// MARK: - Insight Header
struct InsightHeader: View {
    let verseRange: VerseRange
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack {
            // Spacer for balance
            Spacer()
                .frame(width: AppTheme.IconContainer.large)

            Spacer()

            // Verse reference centered
            Text(verseRange.reference)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            Spacer()

            // Close button
            Button {
                HapticService.shared.lightTap()
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(Typography.UI.iconSm)
                    .foregroundStyle(Color.secondaryText)
                    .frame(width: AppTheme.IconContainer.medium, height: AppTheme.IconContainer.medium)
                    .background(Color.surfaceBackground)
                    .clipShape(Circle())
            }
            .padding(.trailing, AppTheme.Spacing.xs)
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(Color.elevatedBackground)
    }
}

// MARK: - Insight Tab Bar (Consolidated: 4 Primary Tabs)
// No more hidden "Advanced" section - all tabs are discoverable
struct InsightTabBar: View {
    @Binding var selectedTab: InsightTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(InsightTab.allTabs, id: \.self) { tab in
                    ConsolidatedTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(AppTheme.Animation.sacredSpring) {
                            selectedTab = tab
                            HapticService.shared.lightTap()
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .background(Color.elevatedBackground)
    }
}

// MARK: - Consolidated Tab Button
// Larger touch targets with icon + text for better discoverability
struct ConsolidatedTabButton: View {
    let tab: InsightTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(Typography.UI.caption1)
                Text(tab.title)
                    .font(Typography.UI.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? Color.accentGold : Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                isSelected ?
                Color.accentGold.opacity(AppTheme.Opacity.light) :
                Color.clear
            )
            .clipShape(Capsule())
            // Gold underline indicator for selected state
            .overlay(alignment: .bottom) {
                if isSelected {
                    Capsule()
                        .fill(Color.divineGold)
                        .frame(height: AppTheme.Border.regular)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .offset(y: AppTheme.Spacing.xxs)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: AppTheme.TouchTarget.minimum)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Insight Tab Enum (Consolidated: 7 → 4 tabs)
// Per UX evaluation: Reduces cognitive load per Hick's Law (~40% reduction)
enum InsightTab: String, CaseIterable {
    case insight    // Merged: Explain + Understand + Interpretation (with mode selector)
    case context    // Merged: Context + Cross-refs
    case compare    // Unchanged: Translation comparison
    case language   // Promoted: Hebrew/Greek analysis (high engagement value)

    var title: String {
        switch self {
        case .insight: return "Insight"
        case .context: return "Context"
        case .compare: return "Compare"
        case .language: return "Language"
        }
    }

    var icon: String {
        switch self {
        case .insight: return "sparkles"
        case .context: return "text.alignleft"
        case .compare: return "doc.on.doc"
        case .language: return "character.book.closed"
        }
    }

    /// All tabs are now primary - no more hidden "Advanced" section
    static var allTabs: [InsightTab] {
        [.insight, .context, .compare, .language]
    }
}

// MARK: - Insight Mode (Sub-modes within Insight tab)
// Provides access to merged functionality: Explain, Understand, Views (Interpretation)
enum InsightMode: String, CaseIterable {
    case explain        // AI explanation with summary, key points
    case understand     // Reading comprehension tools
    case views          // Different interpretations/perspectives

    var title: String {
        switch self {
        case .explain: return "Explain"
        case .understand: return "Understand"
        case .views: return "Views"
        }
    }

    var icon: String {
        switch self {
        case .explain: return "sparkles"
        case .understand: return "graduationcap"
        case .views: return "text.magnifyingglass"
        }
    }

    var description: String {
        switch self {
        case .explain: return "AI-powered explanation"
        case .understand: return "Comprehension tools"
        case .views: return "Different perspectives"
        }
    }
}

// MARK: - Consolidated Tab Content Views

// MARK: - Consolidated Insight Tab Content
// Merges Explain + Understand + Interpretation with mode selector
struct ConsolidatedInsightTabContent: View {
    @Bindable var viewModel: InsightViewModel
    @State private var selectedMode: InsightMode = .explain

    var body: some View {
        VStack(spacing: 0) {
            // Mode selector (pill tabs within the insight tab)
            InsightModeSelector(selectedMode: $selectedMode)

            // Content based on selected mode
            ScrollView {
                switch selectedMode {
                case .explain:
                    ExplainModeContent(viewModel: viewModel)
                case .understand:
                    UnderstandModeContent(viewModel: viewModel)
                case .views:
                    ViewsModeContent(viewModel: viewModel)
                }
            }
        }
        .task {
            await loadModeContent()
        }
        .onChange(of: selectedMode) { _, _ in
            Task {
                await loadModeContent()
            }
        }
    }

    private func loadModeContent() async {
        switch selectedMode {
        case .explain:
            await viewModel.loadExplanation()
        case .understand:
            await viewModel.loadPassageSummary()
        case .views:
            await viewModel.loadInterpretation()
        }
    }
}

// MARK: - Insight Mode Selector
struct InsightModeSelector: View {
    @Binding var selectedMode: InsightMode

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(InsightMode.allCases, id: \.self) { mode in
                InsightModePill(
                    mode: mode,
                    isSelected: selectedMode == mode
                ) {
                    withAnimation(AppTheme.Animation.quick) {
                        selectedMode = mode
                        HapticService.shared.lightTap()
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(Color.surfaceBackground)
    }
}

// MARK: - Insight Mode Pill
struct InsightModePill: View {
    let mode: InsightMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: mode.icon)
                    .font(Typography.UI.caption2)
                Text(mode.title)
                    .font(Typography.UI.caption1)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? Color.accentGold : Color.tertiaryText)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentGold.opacity(AppTheme.Opacity.light) : Color.elevatedBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentGold.opacity(AppTheme.Opacity.medium) : Color.cardBorder, lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Explain Mode Content
struct ExplainModeContent: View {
    @Bindable var viewModel: InsightViewModel
    @State private var showFullExplanation = false

    var body: some View {
        if viewModel.isLoadingExplain {
            AILoadingView(message: "Generating explanation")
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.xxxl)
        } else if let structured = viewModel.structuredExplanation {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                ExplanationSummaryCard(summary: structured.summary)

                if !structured.keyPoints.isEmpty {
                    KeyPointsSection(points: structured.keyPoints)
                }

                if structured.hasMoreContent || structured.details != nil {
                    ShowMoreSection(isExpanded: $showFullExplanation, details: structured.details)
                }

                if let reasoning = viewModel.explanationReasoning, !reasoning.isEmpty {
                    ShowWhyExpander(reasoning: reasoning)
                }

                if let notes = viewModel.explanationTranslationNotes, !notes.isEmpty {
                    TranslationNotesSection(notes: notes)
                }

                if !viewModel.explanationGroundingSources.isEmpty {
                    GroundingSourcesRow(sources: viewModel.explanationGroundingSources)
                }

                ReportIssueButton()
            }
            .padding()
        } else if viewModel.explanation != nil {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text(viewModel.explanation ?? "")
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(4)
                ReportIssueButton()
            }
            .padding()
        } else {
            EmptyStateView(
                icon: "sparkles",
                title: "Get AI Explanation",
                message: "Tap below to generate an explanation for this passage.",
                actionTitle: "Explain"
            ) {
                Task { await viewModel.loadExplanation() }
            }
        }
    }
}

// MARK: - Understand Mode Content
struct UnderstandModeContent: View {
    @Bindable var viewModel: InsightViewModel
    @State private var expandedSection: ComprehensionSection?

    enum ComprehensionSection: String, CaseIterable {
        case simplify, questions, clarify
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "graduationcap")
                        .foregroundStyle(Color.accentGold)
                    Text("Reading Comprehension")
                        .font(Typography.Display.headline)
                        .foregroundStyle(Color.primaryText)
                }
                Text("Tools to help you understand Scripture more deeply.")
                    .font(Typography.UI.warmSubheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            // Passage Summary
            if let summary = viewModel.passageSummary {
                PassageSummaryCard(summary: summary)
            } else if viewModel.isLoadingComprehension {
                AILoadingView(message: "Getting summary")
                    .frame(height: 80)
            } else {
                Button {
                    Task { await viewModel.loadPassageSummary() }
                } label: {
                    HStack {
                        Image(systemName: "text.bubble")
                        Text("Get One-Sentence Summary")
                    }
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.accentGold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle))
                    )
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Comprehension Tools
            VStack(spacing: AppTheme.Spacing.sm) {
                ComprehensionAccordion(
                    icon: "text.redaction",
                    title: "Simplify",
                    description: "Adjust reading level",
                    color: .accentBlue,
                    isExpanded: expandedSection == .simplify
                ) {
                    withAnimation(AppTheme.Animation.quick) {
                        expandedSection = expandedSection == .simplify ? nil : .simplify
                    }
                } content: {
                    SimplifyInlineContent(viewModel: viewModel)
                }

                ComprehensionAccordion(
                    icon: "questionmark.circle",
                    title: "Questions",
                    description: "Test understanding",
                    color: .accentRose,
                    isExpanded: expandedSection == .questions
                ) {
                    withAnimation(AppTheme.Animation.quick) {
                        expandedSection = expandedSection == .questions ? nil : .questions
                    }
                } content: {
                    QuestionsInlineContent(viewModel: viewModel)
                }

                ComprehensionAccordion(
                    icon: "text.magnifyingglass",
                    title: "Clarify",
                    description: "Get word definitions",
                    color: .highlightPurple,
                    isExpanded: expandedSection == .clarify
                ) {
                    withAnimation(AppTheme.Animation.quick) {
                        expandedSection = expandedSection == .clarify ? nil : .clarify
                    }
                } content: {
                    ClarifyInlineContent(viewModel: viewModel)
                }
            }
        }
        .padding()
        .animation(AppTheme.Animation.standard, value: expandedSection)
    }
}

// MARK: - Views Mode Content (Interpretation)
struct ViewsModeContent: View {
    @Bindable var viewModel: InsightViewModel

    var body: some View {
        if viewModel.isLoadingInterpretation {
            AILoadingView(message: "Analyzing interpretations")
                .frame(maxWidth: .infinity)
                .padding(.top, AppTheme.Spacing.xxxl)
        } else if let interpretation = viewModel.interpretation {
            InterpretationCard(interpretation: interpretation)
                .padding()
        } else {
            EmptyStateView(
                icon: "text.magnifyingglass",
                title: "Different Perspectives",
                message: "View various interpretations of this passage.",
                actionTitle: "Show Views"
            ) {
                Task { await viewModel.loadInterpretation() }
            }
        }
    }
}

// MARK: - Merged Context Tab Content
// Combines Context info + Cross-references in one scrollable view
struct MergedContextTabContent: View {
    @Bindable var viewModel: InsightViewModel
    var onNavigate: ((VerseRange) -> Void)?

    @State private var selectedCrossRef: CrossReferenceDisplay?

    private var outgoingRefs: [CrossReferenceDisplay] {
        viewModel.crossRefs.filter { !$0.isIncoming }
    }

    private var incomingRefs: [CrossReferenceDisplay] {
        viewModel.crossRefs.filter { $0.isIncoming }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                // Context Section
                contextSection

                // Cross-References Section
                crossRefsSection
            }
            .padding()
        }
        .sheet(item: $selectedCrossRef) { crossRef in
            CrossRefPeekSheet(
                crossRef: crossRef,
                onNavigate: {
                    if let range = crossRef.targetRange {
                        onNavigate?(range)
                    }
                },
                onLoadWhyLinked: makeWhyLinkedLoader(for: crossRef)
            )
        }
        .task {
            await viewModel.loadContext()
        }
    }

    // MARK: - Context Section
    @ViewBuilder
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(Color.accentGold)
                Text("Passage Context")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)
            }

            if viewModel.isLoadingContext {
                AILoadingView(message: "Analyzing context")
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            } else if let context = viewModel.contextInfo {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    ContextSection(title: "Before", content: context.before)
                    ContextSection(title: "After", content: context.after)
                    if let people = context.keyPeople, !people.isEmpty {
                        ContextSection(title: "Key People", content: people.joined(separator: ", "))
                    }
                    if let places = context.keyPlaces, !places.isEmpty {
                        ContextSection(title: "Key Places", content: places.joined(separator: ", "))
                    }
                }
            } else {
                Button {
                    Task { await viewModel.loadContext() }
                } label: {
                    HStack {
                        Image(systemName: "text.alignleft")
                        Text("Load Context")
                    }
                    .font(Typography.UI.subheadline)
                    .foregroundStyle(Color.accentGold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.accentGold.opacity(AppTheme.Opacity.subtle))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Cross-Refs Section
    @ViewBuilder
    private var crossRefsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Section header
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(Color.accentBlue)
                Text("Cross-References")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)
            }

            if viewModel.crossRefs.isEmpty {
                Text("No cross-references found for this passage.")
                    .font(Typography.UI.warmSubheadline)
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                            .fill(Color.elevatedBackground)
                    )
            } else {
                // Peek hint
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "hand.tap")
                        .font(Typography.UI.caption1)
                    Text("Tap to preview • Navigate from the preview sheet")
                        .font(Typography.UI.caption2)
                }
                .foregroundStyle(Color.tertiaryText)

                // Outgoing references
                if !outgoingRefs.isEmpty {
                    sectionSubheader("References from this passage", icon: "arrow.right.circle")
                    ForEach(outgoingRefs, id: \.id) { crossRef in
                        CrossRefCard(crossRef: crossRef) {
                            selectedCrossRef = crossRef
                        }
                    }
                }

                // Incoming references
                if !incomingRefs.isEmpty {
                    sectionSubheader("References to this passage", icon: "arrow.left.circle")
                        .padding(.top, outgoingRefs.isEmpty ? 0 : AppTheme.Spacing.sm)
                    ForEach(incomingRefs, id: \.id) { crossRef in
                        CrossRefCard(crossRef: crossRef) {
                            selectedCrossRef = crossRef
                        }
                    }
                }
            }
        }
    }

    private func sectionSubheader(_ title: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.UI.caption1)
            Text(title)
                .font(Typography.UI.caption1)
        }
        .foregroundStyle(Color.secondaryText)
    }

    private func makeWhyLinkedLoader(for crossRef: CrossReferenceDisplay) -> (() async -> String)? {
        guard crossRef.whyLinked == nil else { return nil }
        return {
            await self.viewModel.loadWhyLinked(for: crossRef)
        }
    }
}

// MARK: - Supporting Component Views

// MARK: - Explanation Summary Card

struct ExplanationSummaryCard: View {
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "text.quote")
                    .foregroundStyle(Color.accentGold)
                Text("Summary")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.accentGold)
            }

            Text(summary)
                .font(Typography.UI.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.primaryText)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.elevatedBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .stroke(Color.accentGold.opacity(AppTheme.Opacity.lightMedium), lineWidth: AppTheme.Border.thin)
        )
    }
}

// MARK: - Key Points Section

struct KeyPointsSection: View {
    let points: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "list.bullet")
                    .foregroundStyle(Color.accentBlue)
                Text("Key Points")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.accentBlue)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(Color.accentBlue)
                            .frame(width: AppTheme.ComponentSize.dotSmall, height: AppTheme.ComponentSize.dotSmall)
                            .padding(.top, AppTheme.Spacing.sm)

                        Text(point)
                            .font(Typography.UI.body)
                            .foregroundStyle(Color.primaryText)
                            .lineSpacing(2)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.surfaceBackground)
        )
    }
}

// MARK: - Show More Section

struct ShowMoreSection: View {
    @Binding var isExpanded: Bool
    let details: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button {
                withAnimation(AppTheme.Animation.quick) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.UI.caption1)
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(Typography.UI.subheadline)
                    Spacer()
                }
                .foregroundStyle(Color.accentBlue)
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.plain)

            if isExpanded, let details = details {
                Text(details)
                    .font(Typography.UI.body)
                    .foregroundStyle(Color.primaryText)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppTheme.Animation.standard, value: isExpanded)
    }
}

struct ContextSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(Typography.Display.headline)
                .foregroundStyle(Color.secondaryText)

            Text(content)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)
        }
    }
}

struct LanguageTabContent: View {
    @Bindable var viewModel: InsightViewModel

    var body: some View {
        ScrollView {
            if viewModel.isLoadingLanguage {
                AILoadingView(message: "Loading word analysis")
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppTheme.Spacing.xxxl + AppTheme.Spacing.md)
            } else if viewModel.languageTokens.isEmpty {
                EmptyStateView(
                    icon: "character.book.closed",
                    title: "Language Analysis",
                    message: "Hebrew and Greek word analysis for this passage.",
                    actionTitle: "Show Words"
                ) {
                    Task {
                        await viewModel.loadLanguageTokens()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    // Header explaining the feature
                    LanguageTabHeader()

                    // Token cards with AI explanation capability
                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(viewModel.languageTokens, id: \.id) { token in
                            TermCard(token: token) {
                                // On tap - could navigate to word study in future
                            } onExplain: {
                                // AI-powered contextual explanation
                                await viewModel.explainTermInContext(token: token)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Language Tab Header
struct LanguageTabHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "character.book.closed")
                    .foregroundStyle(Color.accentGold)
                Text("Original Language Analysis")
                    .font(Typography.Display.headline)
                    .foregroundStyle(Color.primaryText)
            }
            Text("Explore Hebrew and Greek words with plain-English explanations of grammar and meaning.")
                .font(Typography.UI.warmSubheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.bottom, AppTheme.Spacing.sm)
    }
}

// MARK: - Comprehension Accordion

struct ComprehensionAccordion<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: onToggle) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: icon)
                        .font(Typography.UI.title3)
                        .foregroundStyle(color)
                        .frame(width: AppTheme.IconContainer.medium)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text(title)
                            .font(Typography.UI.bodyBold)
                            .foregroundStyle(Color.primaryText)

                        Text(description)
                            .font(Typography.UI.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .fill(Color.elevatedBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .stroke(isExpanded ? color.opacity(AppTheme.Opacity.medium) : Color.cardBorder, lineWidth: AppTheme.Border.thin)
                )
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    content()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                        .fill(Color.surfaceBackground)
                )
                .padding(.top, -8) // Overlap slightly with header
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Inline Content Views

struct SimplifyInlineContent: View {
    let viewModel: InsightViewModel
    @State private var showSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Adjust the reading level of this passage to make it easier to understand.")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            Button {
                showSheet = true
            } label: {
                HStack {
                    Image(systemName: "text.redaction")
                    Text("Open Simplify Tool")
                }
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.accentBlue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.accentBlue.opacity(AppTheme.Opacity.subtle))
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSheet) {
            SimplifyPassageView(
                verseRange: viewModel.verseRange,
                verseText: viewModel.verseText,
                onClose: { showSheet = false }
            )
        }
    }
}

struct QuestionsInlineContent: View {
    let viewModel: InsightViewModel
    @State private var showSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Test your understanding with AI-generated comprehension questions.")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            Button {
                showSheet = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Generate Questions")
                }
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.accentRose)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.accentRose.opacity(AppTheme.Opacity.subtle))
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSheet) {
            ComprehensionQuestionsView(
                verseRange: viewModel.verseRange,
                verseText: viewModel.verseText,
                onClose: { showSheet = false }
            )
        }
    }
}

struct ClarifyInlineContent: View {
    let viewModel: InsightViewModel
    @State private var showSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Tap any word or phrase to get a quick definition or explanation.")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            Button {
                showSheet = true
            } label: {
                HStack {
                    Image(systemName: "text.magnifyingglass")
                    Text("Open Clarify Tool")
                }
                .font(Typography.UI.subheadline)
                .foregroundStyle(Color.highlightPurple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(Color.highlightPurple.opacity(AppTheme.Opacity.subtle))
                )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSheet) {
            PhraseSelectorSheet(
                verseRange: viewModel.verseRange,
                verseText: viewModel.verseText,
                onClose: { showSheet = false }
            )
        }
    }
}

// MARK: - Passage Summary Card

struct PassageSummaryCard: View {
    let summary: PassageSummaryOutput

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(Color.accentGold)
                Text("In One Sentence")
                    .font(Typography.UI.caption1Bold)
                    .foregroundStyle(Color.accentGold)
                Spacer()
                Text(summary.theme)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.secondaryText)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.surfaceBackground)
                    )
            }

            Text(summary.summary)
                .font(Typography.UI.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.primaryText)

            if let whatHappened = summary.whatHappened, !whatHappened.isEmpty {
                Text(whatHappened)
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                .fill(Color.elevatedBackground)
        )
    }
}

// MARK: - Comprehension Tool Card

struct ComprehensionToolCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Typography.UI.title1)
                    .foregroundStyle(color)

                VStack(spacing: AppTheme.Spacing.xxs) {
                    Text(title)
                        .font(Typography.UI.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    Text(description)
                        .font(Typography.UI.caption2)
                        .foregroundStyle(Color.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .fill(Color.elevatedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card)
                    .stroke(color.opacity(AppTheme.Opacity.medium), lineWidth: AppTheme.Border.thin)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    InsightSheetView(verseRange: .genesis1_1)
}
