//
//  ContentView.swift
//  PageCurlView
//
//  Created by Balaji Venkatesh on 23/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var config: PageCurlCarouselConfig = .init(curlRadius: 60)
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Toggle("Page Curled Visible", isOn: $config.isCurledUpVisible)
                    .padding(15)
                    .background(.white.opacity(0.1), in: .capsule)
                    .padding(.horizontal, 25)
                    .environment(\.colorScheme, .dark)
                
                GeometryReader {
                    let viewSize = $0.size
                    let pageSize = self.pageSize(viewSize)
                    
                    PageCurlCarousel(config: config) { size in
                        ForEach(0...5, id: \.self) { index in
                            Image("Page \(index)")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                            // Optional Curl Border!
//                                .overlay {
//                                    UnevenRoundedRectangle(
//                                        topLeadingRadius: 0,
//                                        bottomLeadingRadius: 0,
//                                        bottomTrailingRadius: 15,
//                                        topTrailingRadius: 15
//                                    )
//                                    .stroke(.gray, lineWidth: 2)
//                                    .offset(x: -0.5)
//                                }
                        }
                    }
                    .frame(width: pageSize.width, height: pageSize.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(\.colorScheme, .light)
                }
                .padding(20)
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

#Preview {
    ContentView()
}
