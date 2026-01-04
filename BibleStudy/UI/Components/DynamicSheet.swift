import SwiftUI

// MARK: - Dynamic Sheet
// A sheet wrapper that automatically adjusts its height based on content
// Smoothly animates height changes when content changes
// Requires iOS 17+ for onGeometryChange

struct DynamicSheet<Content: View>: View {
    var animation: Animation = .smooth(duration: 0.35, extraBounce: 0)
    @ViewBuilder var content: Content

    @State private var sheetHeight: CGFloat = 0
    @State private var isVisible: Bool = {
        if #available(iOS 18, *) {
            return true
        }
        return false
    }()

    var body: some View {
        ZStack {
            content
                // Fix size in vertical direction to measure natural height
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGSize.self) {
                    isVisible ? $0.size : .zero
                } action: { newValue in
                    guard newValue != .zero else { return }

                    let maxHeight = windowSize.height - 110
                    if sheetHeight == .zero {
                        // Initial measurement - no animation
                        sheetHeight = min(newValue.height, maxHeight)
                    } else {
                        // Content changed - animate height
                        withAnimation(animation) {
                            sheetHeight = min(newValue.height, maxHeight)
                        }
                    }
                }
                .task { isVisible = true }
        }
        .modifier(SheetHeightModifier(height: sheetHeight))
    }

    private var windowSize: CGSize {
        if let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size {
            return size
        }
        return .zero
    }
}

// MARK: - Sheet Height Modifier

private struct SheetHeightModifier: ViewModifier, Animatable {
    var height: CGFloat

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 26, *) {
                content
            } else {
                content
                    .clipShape(.rect(cornerRadius: 30, style: .continuous))
                    .background {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.background)
                            .frame(height: height)
                    }
                    .padding(.horizontal, 15)
                    .presentationBackground(.clear)
                    .presentationCornerRadius(0)
            }
        }
        .presentationDetents(height == .zero ? [.medium] : [.height(height)])
    }
}

// MARK: - View Extension

extension View {
    /// Wraps this view in a dynamic height sheet
    func asDynamicSheet(animation: Animation = .smooth(duration: 0.35, extraBounce: 0)) -> some View {
        DynamicSheet(animation: animation) {
            self
        }
    }
}

// MARK: - Preview

#Preview("Dynamic Sheet Demo") {
    struct PreviewContainer: View {
        @State private var showSheet = false
        @State private var showMore = false

        var body: some View {
            VStack {
                Button("Show Dynamic Sheet") {
                    showSheet = true
                }
            }
            .sheet(isPresented: $showSheet) {
                DynamicSheet(animation: .snappy(duration: 0.3)) {
                    VStack(spacing: 16) {
                        Text("Dynamic Height Sheet")
                            .font(.headline)

                        Text("The sheet automatically adjusts its height based on content.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)

                        if showMore {
                            VStack(spacing: 12) {
                                Text("Additional Content")
                                    .font(.subheadline.weight(.semibold))

                                ForEach(1...5, id: \.self) { item in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Item \(item)")
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Button(showMore ? "Show Less" : "Show More") {
                            withAnimation(.snappy(duration: 0.3)) {
                                showMore.toggle()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(24)
                }
                .presentationDragIndicator(.visible)
            }
        }
    }

    return PreviewContainer()
}
