# Reader Toolbar + Panel UI Tests Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add UI tests that enforce reader toolbar single-circle chrome and the absence of a header divider in the chapter panel, then update the UI (including chapter selection styling) to satisfy those tests.

**Architecture:** Create a UI test target and a deterministic UI-test launch path that opens the Bible reader. Add accessibility identifiers for toolbar buttons and panel divider (for test visibility), then adjust toolbar items, remove the panel header divider, and normalize chapter selection styling to match the visual spec.

**Tech Stack:** SwiftUI, XCTest/XCUITest, Xcode project file/scheme edits.

---

### Task 0: (If needed) Reset premature UI changes to allow test-first workflow

**Files:**
- Modify: `BibleStudy/Features/Bible/Views/BibleReaderView.swift`
- Modify: `BibleStudy/Features/Bible/Components/ChapterSidePanel.swift`
- Modify: `BibleStudy/Features/Bible/Views/BibleTabView.swift`

**Step 1: Remove any untested toolbar chrome changes**
- Ensure the reader toolbar still uses the pre-test styling (no custom circle button style, no custom back button).
- Ensure the chapter panel divider is not already full-bleed (remove any padding changes you added).

**Step 2: No test run here**
- This task is only a rollback if the code was modified before tests.

---

### Task 1: Add a UI test target scaffold

**Files:**
- Create: `BibleStudyUITests/BibleStudyUITests.swift`
- Create: `BibleStudyUITests/ReaderChromeUITests.swift`
- Create: `BibleStudyUITests/Info.plist`
- Modify: `BibleStudy.xcodeproj/project.pbxproj`
- Modify: `BibleStudy.xcodeproj/xcshareddata/xcschemes/BibleStudy.xcscheme`

**Step 1: Create UI test files**

`BibleStudyUITests/BibleStudyUITests.swift`
```swift
import XCTest

final class BibleStudyUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_testing_reader"]
        app.launch()
        XCTAssertTrue(app.state == .runningForeground)
    }
}
```

`BibleStudyUITests/ReaderChromeUITests.swift`
```swift
import XCTest

final class ReaderChromeUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["-ui_testing_reader"]
        app.launch()
    }

    func testReaderToolbarButtonsUseSingleCircleSizing() {
        let backButton = app.buttons["ReaderToolbarBackButton"]
        let menuButton = app.buttons["ReaderToolbarReadingMenuButton"]
        let chapterButton = app.buttons["ReaderToolbarChapterButton"]

        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        XCTAssertTrue(chapterButton.waitForExistence(timeout: 5))

        let expectedSize: CGFloat = 44
        XCTAssertEqual(backButton.frame.size.width, expectedSize, accuracy: 1)
        XCTAssertEqual(backButton.frame.size.height, expectedSize, accuracy: 1)
        XCTAssertEqual(menuButton.frame.size.width, expectedSize, accuracy: 1)
        XCTAssertEqual(menuButton.frame.size.height, expectedSize, accuracy: 1)
        XCTAssertEqual(chapterButton.frame.size.width, expectedSize, accuracy: 1)
        XCTAssertEqual(chapterButton.frame.size.height, expectedSize, accuracy: 1)
    }

    func testChapterPanelHeaderDividerIsHidden() {
        let chapterButton = app.buttons["ReaderToolbarChapterButton"]
        XCTAssertTrue(chapterButton.waitForExistence(timeout: 5))
        chapterButton.tap()

        let panel = app.otherElements["ReaderChapterPanel"]
        XCTAssertTrue(panel.waitForExistence(timeout: 5))

        let divider = app.otherElements["ReaderChapterPanelHeaderDivider"]
        XCTAssertFalse(divider.exists)
    }
}
```

`BibleStudyUITests/Info.plist`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.yourorg.BibleStudyUITests</string>
</dict>
</plist>
```

**Step 2: Add UI test target to the Xcode project**
- In `BibleStudy.xcodeproj/project.pbxproj`, add a new target named `BibleStudyUITests` with `productType = "com.apple.product-type.bundle.ui-testing"`.
- Add the new files above to the target’s Sources build phase.
- Set build settings for the UI test target:
  - `INFOPLIST_FILE = BibleStudyUITests/Info.plist`
  - `PRODUCT_BUNDLE_IDENTIFIER = com.yourorg.BibleStudyUITests`
  - `TEST_HOST = $(BUILT_PRODUCTS_DIR)/BibleStudy.app/BibleStudy`
  - `BUNDLE_LOADER = $(TEST_HOST)`
- Add the new target as a dependency of the app target if needed for testing.

**Step 3: Add UI test target to scheme**
- In `BibleStudy.xcodeproj/xcshareddata/xcschemes/BibleStudy.xcscheme`, add a new `<TestableReference>` for `BibleStudyUITests` under `<TestAction><Testables>`.

**Step 4: Run UI tests and verify failure**
Run:
```bash
xcodebuild test -scheme BibleStudy -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:BibleStudyUITests/ReaderChromeUITests
```
Expected: FAIL because `ReaderToolbarBackButton` / `ReaderToolbarReadingMenuButton` / `ReaderToolbarChapterButton` do not exist yet, and the divider still exists once identifiers are added.

---

### Task 1b: Add a chapter selection style unit test

**Files:**
- Create: `BibleStudyTests/ChapterSidePanelStyleTests.swift`
- Modify: `BibleStudy/Features/Bible/Components/ChapterSidePanel.swift`

**Step 1: Write the failing test**

`BibleStudyTests/ChapterSidePanelStyleTests.swift`
```swift
import XCTest
@testable import BibleStudy

final class ChapterSidePanelStyleTests: XCTestCase {
    func testSelectedFillUsesSelectionBackgroundInBothModes() {
        XCTAssertEqual(ChapterSidePanel.selectedChapterFillName(for: .light), "SelectionBackground")
        XCTAssertEqual(ChapterSidePanel.selectedChapterFillName(for: .dark), "SelectionBackground")
    }

    func testSelectedTextUsesPrimaryInBothModes() {
        XCTAssertEqual(ChapterSidePanel.selectedChapterTextName(for: .light), "AppTextPrimary")
        XCTAssertEqual(ChapterSidePanel.selectedChapterTextName(for: .dark), "AppTextPrimary")
    }

    func testUnselectedTextUsesSecondaryInBothModes() {
        XCTAssertEqual(ChapterSidePanel.unselectedChapterTextName(for: .light), "AppTextSecondary")
        XCTAssertEqual(ChapterSidePanel.unselectedChapterTextName(for: .dark), "AppTextSecondary")
    }
}
```

**Step 2: Run tests to verify failure**
Run:
```bash
xcodebuild test -scheme BibleStudy -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:BibleStudyTests/ChapterSidePanelStyleTests
```
Expected: FAIL because the selection style helpers return the old accent-based values.

---

### Task 2: Add UI-test launch hook and accessibility identifiers

**Files:**
- Modify: `BibleStudy/BibleStudyApp.swift`
- Modify: `BibleStudy/Features/MainTabView.swift`
- Modify: `BibleStudy/Features/Bible/Views/BibleTabView.swift`
- Modify: `BibleStudy/Features/Bible/Views/BibleReaderView.swift`
- Modify: `BibleStudy/Features/Bible/Components/ChapterSidePanel.swift`

**Step 1: Add UI-test launch hook in App + Tab views**

In `BibleStudy/BibleStudyApp.swift`, add a helper:
```swift
private var isUITestingReader: Bool {
    ProcessInfo.processInfo.arguments.contains("-ui_testing_reader")
}
```
Call it early (e.g., in `.task` for the root view) to:
- set `hasCompletedOnboarding = true`
- set `appState.isAuthenticated = true`

In `BibleStudy/Features/MainTabView.swift`, add:
```swift
private var isUITestingReader: Bool {
    ProcessInfo.processInfo.arguments.contains("-ui_testing_reader")
}
```
Then in `.onAppear`, force `selectedTab = .bible` when `isUITestingReader` is true.

In `BibleStudy/Features/Bible/Views/BibleTabView.swift`, add a one-time flag and onAppear:
```swift
@State private var didHandleUITestNavigation = false

.onAppear {
    guard !didHandleUITestNavigation else { return }
    if ProcessInfo.processInfo.arguments.contains("-ui_testing_reader") {
        navigationPath = NavigationPath()
        navigationPath.append(BibleLocation.genesis1)
        didHandleUITestNavigation = true
    }
}
```

**Step 2: Add accessibility identifiers**

In `BibleStudy/Features/Bible/Views/BibleReaderView.swift`:
- Add `.accessibilityIdentifier("ReaderToolbarBackButton")` to the back button.
- Add `.accessibilityIdentifier("ReaderToolbarReadingMenuButton")` to the AA button.
- Add `.accessibilityIdentifier("ReaderToolbarChapterButton")` to the chapter badge/X button.

In `BibleStudy/Features/Bible/Components/ChapterSidePanel.swift`:
- Add `.accessibilityIdentifier("ReaderChapterPanel")` to the panel container.
- Add `.accessibilityIdentifier("ReaderChapterPanelHeaderDivider")` to the header divider rectangle (so the UI test can detect it before removal).

**Step 3: Run UI tests and verify they still fail**
Run the same UI test command and confirm failure (divider still inset + toolbar chrome not yet standardized).

---

### Task 3: Standardize reader toolbar chrome + remove panel header divider + neutralize selection

**Files:**
- Modify: `BibleStudy/Features/Bible/Views/BibleReaderView.swift`
- Modify: `BibleStudy/Features/Bible/Views/BibleTabView.swift`
- Modify: `BibleStudy/Features/Bible/Components/ChapterSidePanel.swift`

**Step 1: Split toolbar items so Back + AA are independent**
- Replace the leading `HStack` with two separate `ToolbarItem(placement: .topBarLeading)` entries, one for Back and one for AA.
- Ensure there is no shared container background around both.

**Step 2: Apply shared single-circle toolbar button style**
Add a local `ReaderToolbarCircleButtonStyle` in `BibleReaderView`:
```swift
private struct ReaderToolbarCircleButtonStyle: ButtonStyle {
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
            .background(Circle().fill(background))
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? Theme.Opacity.pressed : 1)
            .animation(Theme.Animation.fade, value: configuration.isPressed)
    }
}
```
Use it for:
- Back button
- AA button
- Chapter badge/X button

Ensure all three use the same foreground tier (e.g., `Color("AppTextPrimary")`).

**Step 3: Use a custom back button and hide system back**
- Add `.navigationBarBackButtonHidden(true)` for the reader view.
- Wire Back button to `dismiss()`.

**Step 4: Remove the chapter panel header divider**
- Remove the header divider from `ChapterSidePanel` entirely.

**Step 5: Neutralize chapter selection styling**
- Update `ChapterCell` to use `SelectionBackground` as the selected fill in both modes.
- Use `AppTextPrimary` for selected text in both modes (unselected stays `AppTextSecondary`).
  - Implement helpers on `ChapterSidePanel`:
    - `static func selectedChapterFillName(for:) -> String`
    - `static func selectedChapterTextName(for:) -> String`
    - `static func unselectedChapterTextName(for:) -> String`
  - Use these helpers in `ChapterCell` for fill and text.

**Step 6: Run UI tests and verify pass**
Run:
```bash
xcodebuild test -scheme BibleStudy -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:BibleStudyUITests/ReaderChromeUITests
```
Expected: PASS.

**Step 7: Commit**
```bash
git add BibleStudy/Features/Bible/Views/BibleReaderView.swift \
  BibleStudy/Features/Bible/Views/BibleTabView.swift \
  BibleStudy/Features/Bible/Components/ChapterSidePanel.swift \
  BibleStudy/BibleStudyApp.swift \
  BibleStudy/Features/MainTabView.swift \
  BibleStudyTests/ChapterSidePanelStyleTests.swift \
  BibleStudyUITests/BibleStudyUITests.swift \
  BibleStudyUITests/ReaderChromeUITests.swift \
  BibleStudyUITests/Info.plist \
  BibleStudy.xcodeproj/project.pbxproj \
  BibleStudy.xcodeproj/xcshareddata/xcschemes/BibleStudy.xcscheme

git commit -m "test: add UI coverage for reader toolbar + panel divider"
```

---

Plan complete and saved to `docs/plans/2026-01-11-reader-toolbar-panel-ui-tests.md`.

Two execution options:
1. Subagent-Driven (this session) - I dispatch a fresh subagent per task, review between tasks.
2. Parallel Session (separate) - Open a new session with executing-plans for batch execution.

Which approach?
