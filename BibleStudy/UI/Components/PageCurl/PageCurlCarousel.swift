//
//  PageCurlCarousel.swift
//  BibleStudy
//
//  Reusable page curl carousel component for e-reader style navigation
//  Based on Balaji Venkatesh's implementation
//

import SwiftUI

// MARK: - Configuration

struct PageCurlCarouselConfig {
    var curlRadius: CGFloat
    var curlShadow: CGFloat = 0.3
    var underneathShadow: CGFloat = 0.1
    var roundedRectangle: RoundedRectangle = .init()
    var curlCenter: CGPoint = .init(x: 1, y: 0.4)
    var isCurledUpVisible: Bool = true

    struct RoundedRectangle {
        var topLeft: CGFloat = 0
        var topRight: CGFloat = 0
        var bottomLeft: CGFloat = 0
        var bottomRight: CGFloat = 0
    }
}

// MARK: - Page Curl Carousel

struct PageCurlCarousel<Content: View>: View {
    var config: PageCurlCarouselConfig
    @ViewBuilder var content: (CGSize) -> Content
    /// Scroll Progress
    @State private var scrollProgress: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    Group(subviews: content(size)) { collection in
                        ForEach(collection.indices, id: \.self) { index in
                            PageCurlItemView(
                                index: index,
                                size: size,
                                config: config,
                                scrollProgress: scrollProgress
                            ) {
                                collection[index]
                                    .frame(width: size.width, height: size.height)
                                    .compositingGroup()
                            }
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: config.roundedRectangle.topLeft,
                                    bottomLeadingRadius: config.roundedRectangle.bottomLeft,
                                    bottomTrailingRadius: config.roundedRectangle.bottomRight,
                                    topTrailingRadius: config.roundedRectangle.topRight
                                )
                            )
                            .visualEffect { content, proxy in
                                let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX

                                return content
                                    .offset(x: -minX)
                            }
                            /// Maintaining the same zIndex Order
                            .zIndex(Double(-index))
                        }
                    }
                }
            }
            .scrollTargetBehavior(.paging)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { _, newValue in
                let progress = newValue / size.width
                scrollProgress = progress
            }
        }
    }
}

// MARK: - Page Curl Item View

private struct PageCurlItemView<Content: View>: View {
    var index: Int
    var size: CGSize
    var config: PageCurlCarouselConfig
    var scrollProgress: CGFloat
    @ViewBuilder var content: Content
    /// View Progress
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        content
            .layerEffect(
                ShaderLibrary.pageCurlEffect(
                    .float(dragOffset),
                    .float2(size.width, size.height),
                    .float4(
                        config.roundedRectangle.topLeft,
                        config.roundedRectangle.topRight,
                        config.roundedRectangle.bottomLeft,
                        config.roundedRectangle.bottomRight
                    ),
                    .float2(
                        size.width * config.curlCenter.x,
                        size.height * config.curlCenter.y
                    ),
                    .float(config.curlRadius),
                    .float(config.curlShadow),
                    .float(config.underneathShadow),
                    .float(config.isCurledUpVisible ? 1 : 0)
                ),
                maxSampleOffset: size
            )
            .onChange(of: scrollProgress) { _, newValue in
                let range = CGFloat(index)...CGFloat(index + 1)
                if range.contains(newValue) {
                    let progress = newValue - range.lowerBound
                    dragOffset = progress * (size.width + (self.config.curlRadius * 2))
                }
            }
    }
}

// MARK: - Preview

#Preview {
    PageCurlCarouselPreview()
}

private struct PageCurlCarouselPreview: View {
    @State private var config: PageCurlCarouselConfig = .init(curlRadius: 60)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toggle("Page Curled Visible", isOn: $config.isCurledUpVisible)
                    .padding(Theme.Spacing.lg)
                    .background(.white.opacity(Theme.Opacity.subtle), in: .capsule)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .environment(\.colorScheme, .dark)

                GeometryReader {
                    let viewSize = $0.size
                    let pageSize = self.pageSize(viewSize)

                    PageCurlCarousel(config: config) { _ in
                        ForEach(0...5, id: \.self) { index in
                            ZStack {
                                Color(hue: Double(index) / 6.0, saturation: 0.3, brightness: 0.95)
                                Text("Page \(index + 1)")
                                    .font(Typography.Command.largeTitle)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .frame(width: pageSize.width, height: pageSize.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(\.colorScheme, .light)
                }
                .padding(Theme.Spacing.xl)
            }
            .navigationTitle("Page Curl Carousel")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                config.roundedRectangle = .init(topLeft: 0, topRight: 15, bottomLeft: 0, bottomRight: 15)
            }
            .background(.black)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    func pageSize(_ viewSize: CGSize) -> CGSize {
        let actualSize = CGSize(width: 411, height: 800)

        // Calculate aspect ratios
        let widthFactor = viewSize.width / actualSize.width
        let heightFactor = viewSize.height / actualSize.height
        let aspectScale = min(widthFactor, heightFactor)

        return CGSize(
            width: actualSize.width * aspectScale,
            height: actualSize.height * aspectScale
        )
    }
}
