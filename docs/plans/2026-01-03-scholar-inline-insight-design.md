# Scholar Inline Insight (Verse-Row Accordion)

Date: 2026-01-03

## Summary
Shift the Scholar tab Study action from a floating popover to an inline accordion that expands within the selected verse row. Keep the AI insight content and loading behavior intact, but render it as part of the verse block to feel like marginalia rather than a separate card.

## Goals
- Make Study feel inline and editorial, not like a detached popover.
- Preserve current AI insight content, loading, and limits behavior.
- Keep insight pinned to the user-selected verse while future voice mode highlights spoken verses independently.

## Non-Goals
- Rebuild the AI insight content model or prompt system.
- Change study limits, paywall, or entitlement logic.
- Implement voice mode; only avoid blocking it.

## UX + Visual Design
- The verse row becomes a two-state container: collapsed (verse text) and expanded (verse + embedded insight panel).
- Insight panel appears below verse text inside the same rounded rectangle.
- Add a thin divider and a subtle vellum tint to separate verse and insight content.
- Keep the indigo accent as a slim inset bar on the insight panel, not the whole row edge.
- Chips and expanded sections remain but align to the verse text width for a tight editorial grid.
- Daily limit state renders inline in the same panel; no additional popover.
- Motion: soft spring expand/collapse; stagger chips after panel reveal.

## Architecture
- Continue using ScholarsReaderViewModel state for selection and inline insight.
- Move insight rendering into the verse row itself instead of inserting a separate card below.
- Extract reusable insight content from ScholarInsightCard into a new view:
  - ScholarInsightContent (header, summary, chips, expanded sections, actions)
- ScholarInsightCard can reuse ScholarInsightContent to avoid duplication.

## Components
- ScholarVerseRow (or new ScholarVerseBlock)
  - Shows verse text
  - Conditionally renders insight panel inline when selection + showInlineInsight
- ScholarInsightContent (new, extracted)
  - Header
  - Hero summary / loading / limit reached
  - Chips row and expanded sections
  - Bottom action bar (copy/share/highlights)

## Data Flow
1. User selects verse -> context menu appears.
2. Study action -> openInlineInsight() sets selected range, creates InsightViewModel, starts loadExplanation().
3. Verse row that matches range.verseEnd renders inline insight panel.
4. Chips trigger async loads for context/words/cross-refs (existing InsightViewModel methods).
5. Dismiss collapses panel and clears selection.

## Error Handling
- If InsightViewModel load fails, show a concise inline error message inside the panel.
- Keep selection intact until the user dismisses or re-tries.

## Voice Mode Considerations
- Add a future-friendly isSpokenVerse flag to ScholarVerseRow.
- Spoken highlight uses a distinct, low-weight indicator (e.g., thin underline) that does not change layout.
- Insight remains pinned to the user-selected verse while audio highlight moves independently.

## Testing
- Manual: select single verse, range selection, Study -> inline expansion
- Limit reached state inside inline panel
- Dismiss behavior clears selection and collapses panel
- Ensure context menu hides when insight opens
- Regression: selection, highlights, share/copy still work

## Files Likely Touched
- BibleStudy/Features/ReaderShowcase/Views/Variants/ScholarsMarginalilaReaderView.swift
- BibleStudy/Features/ReaderShowcase/Components/ScholarInsightCard.swift
- BibleStudy/Features/ReaderShowcase/ViewModels/ScholarsReaderViewModel.swift
- BibleStudy/Features/ReaderShowcase/Components/ScholarContextMenu.swift
