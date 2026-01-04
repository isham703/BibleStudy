# Scholar Inline Insight Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the Scholar reader insight popover with an inline accordion that expands inside the selected verse row.

**Architecture:** Extract reusable insight content from `ScholarInsightCard` into a shared view (`ScholarInsightContent`) and render it inside an inline panel embedded within `ScholarVerseRow`. Keep `ScholarsReaderViewModel` state and `InsightViewModel` loading unchanged; only move presentation logic.

**Tech Stack:** SwiftUI, UIKit, existing ScholarPalette/Theme.

### Task 1: Make insight summary formatting testable

**Files:**
- Create: `BibleStudy/Features/ReaderShowcase/Components/ScholarInsightSummary.swift`
- Modify: `BibleStudy/Features/ReaderShowcase/Components/ScholarInsightCard.swift`
- Test: `BibleStudyTests/ScholarInsightSummaryTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import BibleStudy

final class ScholarInsightSummaryTests: XCTestCase {
    func testSummaryReturnsFirstTwoSentences() {
        let text = "First sentence. Second sentence. Third sentence."
        let summary = ScholarInsightSummary.heroSummary(from: text)
        XCTAssertEqual(summary, "First sentence. Second sentence.")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme BibleStudy -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: FAIL (current baseline) with "Scheme BibleStudy is not currently configured for the test action."

**Step 3: Write minimal implementation**

```swift
enum ScholarInsightSummary {
    static func heroSummary(from text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        let heroSentences = sentences.prefix(2)
        return heroSentences.joined(separator: ". ") + (heroSentences.count >= 2 ? "." : "")
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme BibleStudy -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: FAIL (baseline issue persists). Proceed with manual verification.

**Step 5: Commit**

Skip (user requested no commits).

### Task 2: Extract reusable insight content view

**Files:**
- Create: `BibleStudy/Features/ReaderShowcase/Components/ScholarInsightContent.swift`
- Modify: `BibleStudy/Features/ReaderShowcase/Components/ScholarInsightCard.swift`

**Step 1: Write the failing test**

No automated UI tests available; use preview/manual check.

**Step 2: Run test to verify it fails**

Skip (no UI test harness).

**Step 3: Write minimal implementation**

Create `ScholarInsightContent` that contains:
- Accent bar
- Header, hero summary, chips, expanded content, deep study button, bottom action bar
- Internal state for `expandedSection`, `chipsRevealed`, `isRevealed`

Update `ScholarInsightCard` to wrap `ScholarInsightContent` with card background, border, shadow, and padding.

**Step 4: Run test to verify it passes**

Manual: use `#Preview("Scholar Insight Card")` to verify appearance.

**Step 5: Commit**

Skip (user requested no commits).

### Task 3: Inline accordion inside verse row

**Files:**
- Modify: `BibleStudy/Features/ReaderShowcase/Views/Variants/ScholarsMarginalilaReaderView.swift`
- Create: `BibleStudy/Features/ReaderShowcase/Components/ScholarInlineInsightPanel.swift`
- Modify: `BibleStudy/Features/ReaderShowcase/Theme/ScholarPalette.swift`

**Step 1: Write the failing test**

No automated UI tests available; use manual verification.

**Step 2: Run test to verify it fails**

Skip (no UI test harness).

**Step 3: Write minimal implementation**

- Add `ScholarInlineInsightPanel` that embeds `ScholarInsightContent` with inline styling:
  - Subtle vellum background
  - Thin divider above
  - Inset accent bar (narrower)
  - No outer shadow
- Update `ScholarVerseRow` to render the inline panel inside the row when its verse matches the selected range end.
- Remove the separate `ScholarInsightCard` insertion below the row.
- Add a future-friendly `isSpokenVerse` flag to `ScholarVerseRow` with a thin underline style (no layout shift).
- Add `ScholarPalette.InlineInsight` colors if needed for background/divider.

**Step 4: Run test to verify it passes**

Manual:
- Select verse in Scholar tab and tap Study.
- Inline panel expands inside the verse row (no popover).
- Limit reached state renders inline.
- Dismiss collapses and clears selection.

**Step 5: Commit**

Skip (user requested no commits).

## Manual Verification Checklist
- Scholar tab: select single verse -> Study -> inline accordion expands in row
- Multi-verse selection: panel appears only after last verse in range
- Limit reached state displays inline
- Copy/share/highlight buttons still work
- Context menu dismisses on Study

