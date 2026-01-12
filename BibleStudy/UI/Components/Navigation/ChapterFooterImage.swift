import SwiftUI

// MARK: - Chapter Footer Image
// Full-bleed footer image for chapter endings with scroll-driven reveal.
//
// Design Philosophy:
// - FLAT layout (no curved masks) - eliminates edge-case visual artifacts
// - Scroll-progress reveal: image emerges gradually as user approaches chapter end
// - Theme-specific tinting: dark mode (warm charcoal), light mode (subtle parchment)
// - Subtle parallax effect makes image feel embedded, not pasted
//
// Reveal Behavior:
// - Image starts invisible when footer is below viewport
// - Gradually fades in over ~360pt of scroll distance
// - TopFadeHeight shrinks from 220pt to 160pt during reveal
// - Opacity caps at 0.9 (light) / 0.85 (dark) to maintain "printed" feel
//
// Usage:
//   ChapterFooterImage(imageName: "Genesis01")
//   ChapterFooterImage(book: "Genesis", chapter: 4)

struct ChapterFooterImage: View {
    // Image source - use one or the other
    var imageName: String?
    var imageURL: URL?
    var bottomSafeAreaInset: CGFloat? = nil

    // Callback when image fails to load (so parent can show fallback UI)
    var onImageFailed: (() -> Void)?

    @State private var imageLoadState: ImageLoadState = .loading
    @State private var bottomSafeArea: CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme

    enum ImageLoadState: Equatable {
        case loading
        case success
        case failed
    }

    // MARK: - Constants

    private let footerHeight: CGFloat = 280
    private let homeIndicatorFallback: CGFloat = 34

    // Reveal configuration
    private let revealWindow: CGFloat = 400      // Distance over which reveal occurs (after entering viewport)
    private let minTopFadeHeight: CGFloat = 160  // Fully revealed
    private let maxTopFadeHeight: CGFloat = 240  // Hidden/early reveal (larger = hides boundary better)

    /// Screen height computed from connected window scenes (iOS 26+ compatible)
    private var screenHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return 844 // Default fallback (iPhone 14 height)
        }
        return windowScene.screen.bounds.height
    }
    private let parallaxFactor: CGFloat = 0.08   // 8% parallax

    // Opacity caps (prevent "pasted photo" look)
    private var maxOpacity: Double {
        colorScheme == .dark ? 0.85 : 0.9
    }

    var body: some View {
        Group {
            if shouldRenderFooter {
                footerContent
            } else if imageLoadState == .loading, imageURL != nil {
                loadingState
            }
            // If failed, show nothing (parent will show fallback)
        }
        .onAppear { resetLoadState() }
        .onChange(of: imageName) { _, _ in resetLoadState() }
        .onChange(of: imageURL) { _, _ in resetLoadState() }
    }

    // MARK: - Computed Properties

    private var shouldRenderFooter: Bool {
        imageName != nil || imageLoadState == .success
    }

    private var effectiveBottomInset: CGFloat {
        Layout.effectiveBottomInset(
            measured: bottomSafeArea,
            overrideInset: bottomSafeAreaInset,
            fallback: homeIndicatorFallback
        )
    }

    private func resetLoadState() {
        imageLoadState = LoadState.initial(imageName: imageName, imageURL: imageURL)
    }

    // MARK: - Footer Content

    private var footerContent: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            let maxY = geometry.frame(in: .global).maxY
            let currentScreenHeight = screenHeight

            // Calculate reveal progress (0 = hidden, 1 = fully revealed)
            let revealProgress = Layout.revealProgress(
                minY: minY,
                screenHeight: currentScreenHeight,
                revealWindow: revealWindow
            )

            // Apply easing to progress
            let easedOpacityProgress = Easing.easeInCubic(revealProgress)
            let easedFadeProgress = Easing.easeOutCubic(revealProgress)

            // Derived values from reveal progress
            let imageOpacity = easedOpacityProgress * maxOpacity
            let currentTopFadeHeight = Layout.interpolate(
                from: maxTopFadeHeight,
                to: minTopFadeHeight,
                progress: easedFadeProgress
            )
            let currentContrast = Layout.interpolate(
                from: 0.92,
                to: colorScheme == .light ? 0.95 : 1.0,
                progress: easedFadeProgress
            )

            // Overscroll for rubber-band stretch
            let overscroll = Layout.overscrollAmount(maxY: maxY, screenHeight: currentScreenHeight)

            // Parallax offset
            let parallaxOffset = Layout.parallaxOffset(
                maxY: maxY,
                screenHeight: currentScreenHeight,
                factor: parallaxFactor
            )

            ZStack(alignment: .top) {
                // Footer image with scroll-driven reveal
                imageContent
                    .contrast(currentContrast)
                    .frame(width: geometry.size.width)
                    .frame(minHeight: footerHeight + effectiveBottomInset + overscroll)
                    .offset(y: parallaxOffset)
                    .overlay(alignment: .top) {
                        imageScrim(height: currentTopFadeHeight)
                    }
                    .clipped()
                    .opacity(imageOpacity)

                // Top fade to blend into reader surface
                topFade(height: currentTopFadeHeight)
                    .frame(width: geometry.size.width)
            }
        }
        .frame(height: footerHeight + effectiveBottomInset)
        .ignoresSafeArea(edges: .bottom)
        .background(safeAreaReader)
    }

    // MARK: - Scrim and Fade (now with dynamic height)

    private func imageScrim(height: CGFloat) -> some View {
        let spec = colorScheme == .dark ? ScrimSpec.dark : ScrimSpec.light
        let tintColor = colorScheme == .dark ? Color.warmCharcoal : Color.appBackground

        return LinearGradient(
            stops: [
                .init(color: tintColor.opacity(spec.topOpacity), location: 0.0),
                .init(color: tintColor.opacity(spec.midOpacity), location: spec.midLocation),
                .init(color: tintColor.opacity(spec.bottomOpacity), location: spec.bottomLocation)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
    }

    private func topFade(height: CGFloat) -> some View {
        let spec = colorScheme == .dark ? TopFadeSpec.dark : TopFadeSpec.light

        return LinearGradient(
            stops: [
                .init(color: Color.appBackground.opacity(spec.topOpacity), location: 0.0),
                .init(color: Color.appBackground.opacity(spec.midOpacity), location: spec.midLocation),
                .init(color: Color.appBackground.opacity(spec.bottomOpacity), location: spec.bottomLocation)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
    }

    // MARK: - Safe Area Reader

    private var safeAreaReader: some View {
        GeometryReader { proxy in
            Color.clear.onAppear {
                bottomSafeArea = proxy.safeAreaInsets.bottom
            }
        }
    }

    // MARK: - Image Content

    @ViewBuilder
    private var imageContent: some View {
        if let imageName = imageName {
            // Local asset
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let imageURL = imageURL {
            // Remote URL
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Color("AppSurface")
                }
            }
        } else {
            Color("AppSurface")
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        Color.clear
            .frame(height: 1)
            .overlay(
                AsyncImage(url: imageURL) { phase in
                    Color.clear
                        .onChange(of: phase.image != nil) { _, hasImage in
                            if hasImage {
                                withAnimation(Theme.Animation.slowFade) {
                                    imageLoadState = .success
                                }
                            }
                        }
                        .onChange(of: phase.error != nil) { _, hasError in
                            if hasError {
                                imageLoadState = .failed
                                onImageFailed?()
                            }
                        }
                        .task {
                            switch phase {
                            case .success:
                                withAnimation(Theme.Animation.slowFade) {
                                    imageLoadState = .success
                                }
                            case .failure:
                                imageLoadState = .failed
                                onImageFailed?()
                            default:
                                break
                            }
                        }
                }
                .frame(width: 1, height: 1)
                .opacity(0)
            )
    }

}

// MARK: - Easing Functions

extension ChapterFooterImage {
    struct Easing {
        /// Ease-in cubic: slow start, accelerates toward end
        /// Good for opacity reveal (stays subtle early, faster late)
        static func easeInCubic(_ t: Double) -> Double {
            t * t * t
        }

        /// Ease-out cubic: fast start, decelerates toward end
        /// Good for fade height (settles calmly)
        static func easeOutCubic(_ t: Double) -> Double {
            1 - pow(1 - t, 3)
        }

        /// Ease-in-out cubic: smooth acceleration and deceleration
        static func easeInOutCubic(_ t: Double) -> Double {
            t < 0.5
                ? 4 * t * t * t
                : 1 - pow(-2 * t + 2, 3) / 2
        }
    }
}

// MARK: - Layout Helpers

extension ChapterFooterImage {
    struct Layout {
        /// Calculate reveal progress based on footer position within viewport
        /// Reveal STARTS when footer enters viewport, ENDS after scrolling revealWindow distance
        /// This ensures the image emerges gradually AFTER "NEXT" row has been processed
        static func revealProgress(minY: CGFloat, screenHeight: CGFloat, revealWindow: CGFloat) -> Double {
            // How far footer has scrolled INTO the viewport (positive = visible)
            let positionInViewport = screenHeight - minY

            // Footer hasn't entered viewport yet - not revealed
            if positionInViewport <= 0 {
                return 0.0
            }

            // Footer has been in viewport for full reveal window - fully revealed
            if positionInViewport >= revealWindow {
                return 1.0
            }

            // Linear interpolation: reveal progresses as user scrolls deeper
            return Double(positionInViewport / revealWindow)
        }

        /// Linear interpolation between two values
        static func interpolate(from: CGFloat, to: CGFloat, progress: Double) -> CGFloat {
            from + (to - from) * CGFloat(progress)
        }

        static func overscrollAmount(maxY: CGFloat, screenHeight: CGFloat) -> CGFloat {
            max(0, screenHeight - maxY)
        }

        /// Parallax offset: positive when footer is visible (image lags behind scroll)
        static func parallaxOffset(maxY: CGFloat, screenHeight: CGFloat, factor: CGFloat) -> CGFloat {
            let distanceFromBottom = screenHeight - maxY
            return max(0, distanceFromBottom) * factor
        }

        static func effectiveBottomInset(measured: CGFloat, overrideInset: CGFloat?, fallback: CGFloat) -> CGFloat {
            if let overrideInset, overrideInset > 0 {
                return overrideInset
            }

            if measured > 0 {
                return measured
            }

            return fallback
        }
    }
}

// MARK: - Scrim Helpers

extension ChapterFooterImage {
    struct ScrimSpec: Equatable {
        let topOpacity: Double
        let midOpacity: Double
        let bottomOpacity: Double
        let midLocation: Double
        let bottomLocation: Double

        // Dark mode: warm charcoal tint for "candlelit" atmosphere
        static let dark = ScrimSpec(
            topOpacity: 0.25,
            midOpacity: 0.08,
            bottomOpacity: 0.0,
            midLocation: 0.5,
            bottomLocation: 1.0
        )

        // Light mode: subtle parchment tint to harmonize varying image tones
        static let light = ScrimSpec(
            topOpacity: 0.08,
            midOpacity: 0.03,
            bottomOpacity: 0.0,
            midLocation: 0.5,
            bottomLocation: 1.0
        )
    }
}

// MARK: - Top Fade Helpers

extension ChapterFooterImage {
    struct TopFadeSpec: Equatable {
        let topOpacity: Double
        let midOpacity: Double
        let bottomOpacity: Double
        let midLocation: Double
        let bottomLocation: Double

        static let dark = TopFadeSpec(
            topOpacity: 0.5,
            midOpacity: 0.12,
            bottomOpacity: 0.0,
            midLocation: 0.5,
            bottomLocation: 1.0
        )

        static let light = TopFadeSpec(
            topOpacity: 0.42,
            midOpacity: 0.12,
            bottomOpacity: 0.0,
            midLocation: 0.7,
            bottomLocation: 1.0
        )
    }
}

// MARK: - Load State Helpers

extension ChapterFooterImage {
    struct LoadState {
        static func initial(imageName: String?, imageURL: URL?) -> ImageLoadState {
            if imageName != nil {
                return .success
            }

            if imageURL != nil {
                return .loading
            }

            return .failed
        }
    }
}

// MARK: - Convenience Initializers

extension ChapterFooterImage {
    /// Initialize with a local asset name
    init(imageName: String, bottomSafeAreaInset: CGFloat? = nil, onImageFailed: (() -> Void)? = nil) {
        self.imageName = imageName
        self.imageURL = nil
        self.bottomSafeAreaInset = bottomSafeAreaInset
        self.onImageFailed = onImageFailed
    }

    /// Initialize with a remote URL (for Supabase Storage)
    init(imageURL: URL?, bottomSafeAreaInset: CGFloat? = nil, onImageFailed: (() -> Void)? = nil) {
        self.imageName = nil
        self.imageURL = imageURL
        self.bottomSafeAreaInset = bottomSafeAreaInset
        self.onImageFailed = onImageFailed
    }

    /// Initialize with Supabase Storage path
    init(storagePath: String, bucket: String = "chapter-images", bottomSafeAreaInset: CGFloat? = nil, onImageFailed: (() -> Void)? = nil) {
        self.imageName = nil
        let baseURL = AppConfiguration.Supabase.url.absoluteString
        self.imageURL = URL(string: "\(baseURL)/storage/v1/object/public/\(bucket)/\(storagePath)")
        self.bottomSafeAreaInset = bottomSafeAreaInset
        self.onImageFailed = onImageFailed
    }

    /// Convenience initializer for book/chapter pattern
    init(book: String, chapter: Int, bottomSafeAreaInset: CGFloat? = nil, onImageFailed: (() -> Void)? = nil) {
        self.imageName = nil
        let baseURL = AppConfiguration.Supabase.url.absoluteString
        let paddedChapter = String(format: "%02d", chapter)
        self.imageURL = URL(string: "\(baseURL)/storage/v1/object/public/chapter-images/\(book.lowercased())/\(paddedChapter).webp")
        self.bottomSafeAreaInset = bottomSafeAreaInset
        self.onImageFailed = onImageFailed
    }
}

// MARK: - Preview

#Preview("Chapter Footer - Dark Mode") {
    ScrollView {
        VStack(spacing: 0) {
            // Simulate chapter content to enable scrolling
            ForEach(0..<15) { _ in
                Text("In the beginning God created the heavens and the earth. Now the earth was formless and empty, darkness was over the surface of the deep, and the Spirit of God was hovering over the waters.")
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    .padding(.vertical, Theme.Spacing.md)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            ChapterFooterImage(imageName: "SermonHero")
        }
    }
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}

#Preview("Chapter Footer - Light Mode") {
    ScrollView {
        VStack(spacing: 0) {
            // Simulate chapter content to enable scrolling
            ForEach(0..<15) { _ in
                Text("In the beginning God created the heavens and the earth. Now the earth was formless and empty, darkness was over the surface of the deep, and the Spirit of God was hovering over the waters.")
                    .font(Typography.Scripture.body)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineSpacing(Typography.Scripture.bodyLineSpacing)
                    .padding(.vertical, Theme.Spacing.md)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            ChapterFooterImage(imageName: "SermonHero")
        }
    }
    .background(Color.appBackground)
    .preferredColorScheme(.light)
}
