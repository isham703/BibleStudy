import XCTest
@testable import BibleStudy

final class ChapterFooterImageLayoutTests: XCTestCase {

    // MARK: - Reveal Progress Tests
    // Reveal STARTS when footer enters viewport, ENDS after scrolling revealWindow distance

    func testRevealProgressZeroWhenFooterBelowViewport() {
        // Footer hasn't entered viewport yet (minY > screenHeight)
        let progress = ChapterFooterImage.Layout.revealProgress(
            minY: 900,
            screenHeight: 800,
            revealWindow: 400
        )
        XCTAssertEqual(progress, 0.0)
    }

    func testRevealProgressZeroWhenFooterJustEntersViewport() {
        // Footer just entering viewport (minY = screenHeight) - reveal STARTS here
        let progress = ChapterFooterImage.Layout.revealProgress(
            minY: 800,
            screenHeight: 800,
            revealWindow: 400
        )
        XCTAssertEqual(progress, 0.0)
    }

    func testRevealProgressPartialAsFooterScrollsIntoView() {
        // Footer has scrolled 200pt into viewport (halfway through 400pt window)
        let progress = ChapterFooterImage.Layout.revealProgress(
            minY: 600,  // 800 - 600 = 200pt into viewport
            screenHeight: 800,
            revealWindow: 400
        )
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testRevealProgressFullAfterScrollingRevealWindow() {
        // Footer has scrolled 400pt into viewport - fully revealed
        let progress = ChapterFooterImage.Layout.revealProgress(
            minY: 400,  // 800 - 400 = 400pt into viewport
            screenHeight: 800,
            revealWindow: 400
        )
        XCTAssertEqual(progress, 1.0)
    }

    func testRevealProgressClampsToOne() {
        // Footer scrolled well past reveal window
        let progress = ChapterFooterImage.Layout.revealProgress(
            minY: 100,
            screenHeight: 800,
            revealWindow: 400
        )
        XCTAssertEqual(progress, 1.0)
    }

    // MARK: - Interpolation Tests

    func testInterpolateAtZeroProgress() {
        let result = ChapterFooterImage.Layout.interpolate(from: 220, to: 160, progress: 0)
        XCTAssertEqual(result, 220)
    }

    func testInterpolateAtFullProgress() {
        let result = ChapterFooterImage.Layout.interpolate(from: 220, to: 160, progress: 1)
        XCTAssertEqual(result, 160)
    }

    func testInterpolateAtHalfProgress() {
        let result = ChapterFooterImage.Layout.interpolate(from: 220, to: 160, progress: 0.5)
        XCTAssertEqual(result, 190, accuracy: 0.01)
    }

    // MARK: - Easing Tests

    func testEaseInCubicStartsSlowly() {
        // At 50% progress, easeInCubic should be much less than 50%
        let eased = ChapterFooterImage.Easing.easeInCubic(0.5)
        XCTAssertEqual(eased, 0.125, accuracy: 0.001)  // 0.5^3 = 0.125
    }

    func testEaseOutCubicStartsFast() {
        // At 50% progress, easeOutCubic should be much more than 50%
        let eased = ChapterFooterImage.Easing.easeOutCubic(0.5)
        XCTAssertEqual(eased, 0.875, accuracy: 0.001)  // 1 - (1-0.5)^3 = 0.875
    }

    func testEasingFunctionsBoundaries() {
        // Both functions should return 0 at t=0 and 1 at t=1
        XCTAssertEqual(ChapterFooterImage.Easing.easeInCubic(0), 0)
        XCTAssertEqual(ChapterFooterImage.Easing.easeInCubic(1), 1)
        XCTAssertEqual(ChapterFooterImage.Easing.easeOutCubic(0), 0)
        XCTAssertEqual(ChapterFooterImage.Easing.easeOutCubic(1), 1)
    }

    // MARK: - Overscroll Tests

    func testOverscrollUsesGapBelowFooter() {
        let overscroll = ChapterFooterImage.Layout.overscrollAmount(maxY: 760, screenHeight: 800)
        XCTAssertEqual(overscroll, 40)
    }

    func testOverscrollZeroWhenFooterBelowScreenBottom() {
        let overscroll = ChapterFooterImage.Layout.overscrollAmount(maxY: 820, screenHeight: 800)
        XCTAssertEqual(overscroll, 0)
    }

    // MARK: - Parallax Tests

    func testParallaxOffsetZeroWhenFooterAtScreenBottom() {
        let offset = ChapterFooterImage.Layout.parallaxOffset(
            maxY: 800,
            screenHeight: 800,
            factor: 0.08
        )
        XCTAssertEqual(offset, 0)
    }

    func testParallaxOffsetPositiveWhenScrolledUp() {
        // Footer scrolled up 100pt from bottom (footer is visible)
        let offset = ChapterFooterImage.Layout.parallaxOffset(
            maxY: 700,
            screenHeight: 800,
            factor: 0.08
        )
        // distanceFromBottom = 800 - 700 = 100
        // offset = max(0, 100) * 0.08 = 8
        XCTAssertEqual(offset, 8, accuracy: 0.001)
    }

    func testParallaxOffsetZeroDuringOverscroll() {
        // Footer below screen (overscroll/rubber-band state)
        let offset = ChapterFooterImage.Layout.parallaxOffset(
            maxY: 900,
            screenHeight: 800,
            factor: 0.08
        )
        XCTAssertEqual(offset, 0, accuracy: 0.001)
    }

    // MARK: - Bottom Inset Tests

    func testEffectiveBottomInsetPrefersOverride() {
        let inset = ChapterFooterImage.Layout.effectiveBottomInset(
            measured: 12,
            overrideInset: 28,
            fallback: 34
        )
        XCTAssertEqual(inset, 28)
    }

    func testEffectiveBottomInsetUsesMeasuredWhenOverrideMissing() {
        let inset = ChapterFooterImage.Layout.effectiveBottomInset(
            measured: 22,
            overrideInset: nil,
            fallback: 34
        )
        XCTAssertEqual(inset, 22)
    }

    func testEffectiveBottomInsetFallsBackWhenNoInsetsAvailable() {
        let inset = ChapterFooterImage.Layout.effectiveBottomInset(
            measured: 0,
            overrideInset: nil,
            fallback: 34
        )
        XCTAssertEqual(inset, 34)
    }

    // MARK: - Load State Tests

    func testInitialLoadStateUsesSuccessForLocalImage() {
        let state = ChapterFooterImage.LoadState.initial(imageName: "Genesis01", imageURL: nil)
        XCTAssertEqual(state, .success)
    }

    func testInitialLoadStateUsesLoadingForRemoteImage() {
        let state = ChapterFooterImage.LoadState.initial(
            imageName: nil,
            imageURL: URL(string: "https://example.com/image.webp")
        )
        XCTAssertEqual(state, .loading)
    }

    func testInitialLoadStateUsesFailedWhenNoSource() {
        let state = ChapterFooterImage.LoadState.initial(imageName: nil, imageURL: nil)
        XCTAssertEqual(state, .failed)
    }

    // MARK: - Scrim Spec Tests

    func testDarkScrimSpecUsesExpectedValues() {
        let spec = ChapterFooterImage.ScrimSpec.dark
        XCTAssertEqual(spec.topOpacity, 0.25, accuracy: 0.001)
        XCTAssertEqual(spec.midOpacity, 0.08, accuracy: 0.001)
        XCTAssertEqual(spec.bottomOpacity, 0.0, accuracy: 0.001)
    }

    func testLightScrimSpecUsesExpectedValues() {
        let spec = ChapterFooterImage.ScrimSpec.light
        XCTAssertEqual(spec.topOpacity, 0.08, accuracy: 0.001)
        XCTAssertEqual(spec.midOpacity, 0.03, accuracy: 0.001)
        XCTAssertEqual(spec.bottomOpacity, 0.0, accuracy: 0.001)
    }

    func testLightScrimIsSubtlerThanDark() {
        let dark = ChapterFooterImage.ScrimSpec.dark
        let light = ChapterFooterImage.ScrimSpec.light
        XCTAssertLessThan(light.topOpacity, dark.topOpacity)
        XCTAssertLessThan(light.midOpacity, dark.midOpacity)
    }

    // MARK: - Top Fade Spec Tests

    func testTopFadeSpecUsesExpectedStops() {
        let darkSpec = ChapterFooterImage.TopFadeSpec.dark
        XCTAssertEqual(darkSpec.topOpacity, 0.5, accuracy: 0.001)
        XCTAssertEqual(darkSpec.midOpacity, 0.12, accuracy: 0.001)
        XCTAssertEqual(darkSpec.bottomOpacity, 0.0, accuracy: 0.001)

        let lightSpec = ChapterFooterImage.TopFadeSpec.light
        XCTAssertEqual(lightSpec.topOpacity, 0.42, accuracy: 0.001)
        XCTAssertEqual(lightSpec.midOpacity, 0.12, accuracy: 0.001)
        XCTAssertEqual(lightSpec.bottomOpacity, 0.0, accuracy: 0.001)
    }
}
