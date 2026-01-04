//
//  PageCurlCarousel.swift
//  PageCurlView
//
//  Created by Balaji Venkatesh on 24/12/25.
//

import SwiftUI

struct PageCurlCarouselConfig {
    var curlRadius: CGFloat
    var curlShadow: CGFloat = 0.3
    var underneathShadow: CGFloat = 0.1
    var roundedRectangle: Self.RoundedRectangle = .init()
    var curlCenter: CGPoint = .init(x: 1, y: 0.4)
    var isCurledUpVisible: Bool = true
    
    struct RoundedRectangle {
        var topLeft: CGFloat = 0
        var topRight: CGFloat = 0
        var bottomLeft: CGFloat = 0
        var bottomRight: CGFloat = 0
    }
}

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
            } action: { oldValue, newValue in
                let progress = newValue / size.width
                scrollProgress = progress
            }
        }
    }
}

fileprivate struct PageCurlItemView<Content: View>: View {
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
            .onChange(of: scrollProgress) { oldValue, newValue in
                let range = CGFloat(index)...CGFloat(index + 1)
                if range.contains(newValue) {
                    let progress = newValue - range.lowerBound
                    dragOffset = progress * (size.width + (self.config.curlRadius * 2))
                }
            }
    }
}

#Preview {
    ContentView()
}
