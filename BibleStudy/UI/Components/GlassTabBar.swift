import SwiftUI

// MARK: - Tab Bar
// Flat tab bar with pill-shaped segment control + Ask FAB
// Stoic-Existential Renaissance design with minimal glass effects

struct GlassTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var showAskModal: Bool
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Animation State
    @State private var tabBarAppeared = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Tab pill (left side) - segmented control
            GeometryReader { geometry in
                GlassSegmentedControl(
                    size: geometry.size,
                    selectedTab: $selectedTab
                )
                .background(
                    Capsule()
                        .fill(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
                )
                .overlay(
                    Capsule()
                        .stroke(Colors.Surface.divider(for: ThemeMode.current(from: colorScheme)), lineWidth: Theme.Stroke.hairline)
                )
            }

            // Ask FAB (right side) - accent with flat backing
            askButton
                .frame(width: 55, height: 55)
                .background(
                    Circle()
                        .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.divider))
                )
                .overlay(
                    Circle()
                        .stroke(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
                )
        }
        .frame(height: 55)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sheet)
                .fill(Colors.Surface.background(for: ThemeMode.current(from: colorScheme)))
        )
        .offset(y: tabBarAppeared ? 0 : 80)
        .opacity(tabBarAppeared ? 1 : 0)
        .onAppear {
            startEntranceAnimation()
        }
    }

    // MARK: - Ask Button

    private var askButton: some View {
        Button {
            HapticService.shared.mediumTap()
            showAskModal = true
        } label: {
            ZStack {
                // Icon with blur fade based on tab (like reference)
                Image("streamline-ask")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
        }
        .accessibilityLabel("Ask AI")
        .accessibilityHint("Opens AI chat assistant")
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        guard !tabBarAppeared else { return }

        if respectsReducedMotion {
            tabBarAppeared = true
            return
        }

        // Delay entrance after content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(Theme.Animation.settle) {
                tabBarAppeared = true
            }
        }
    }
}

// MARK: - Glass Segmented Control
// UISegmentedControl wrapped for native segment behavior with glass styling

private struct GlassSegmentedControl: UIViewRepresentable {
    var size: CGSize
    var activeTint: Color = .primary
    var inactiveTint: Color = .primary.opacity(Theme.Opacity.tertiary)
    var barTint: Color = Colors.Semantic.accentAction(for: .dark).opacity(Theme.Opacity.quarter)
    @Binding var selectedTab: Tab
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UISegmentedControl {
        let items = Tab.allCases.map(\.title)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = selectedTab.index

        // Render tab items as images for custom appearance
        for (index, tab) in Tab.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(for: tab))
            renderer.scale = 2
            if let image = renderer.uiImage {
                control.setImage(image, forSegmentAt: index)
            }
        }

        // Hide the default background image views
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }

        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(activeTint)
        ], for: .selected)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor(inactiveTint)
        ], for: .normal)

        control.addTarget(
            context.coordinator,
            action: #selector(context.coordinator.tabSelected(_:)),
            for: .valueChanged
        )

        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        // Update selection if changed externally
        if uiView.selectedSegmentIndex != selectedTab.index {
            uiView.selectedSegmentIndex = selectedTab.index
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UISegmentedControl,
        context: Context
    ) -> CGSize? {
        return size
    }

    // MARK: - Tab Item View

    @ViewBuilder
    private func tabItemView(for tab: Tab) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(tab.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)

            Text(tab.title)
                .font(Typography.Command.meta)
                .fontWeight(.medium)
        }
        .foregroundStyle(selectedTab == tab ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Colors.Surface.textSecondary(for: ThemeMode.current(from: colorScheme)))
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var parent: GlassSegmentedControl

        init(parent: GlassSegmentedControl) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            HapticService.shared.tabSwitch()
            withAnimation(Theme.Animation.slowFade) {
                parent.selectedTab = Tab.allCases[control.selectedSegmentIndex]
            }
        }
    }
}

// MARK: - Tab Extension

extension Tab {
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab: Tab = .home
        @State private var showAskModal = false

        var body: some View {
            VStack {
                Spacer()
                GlassTabBar(selectedTab: $selectedTab, showAskModal: $showAskModal)
            }
            .background(Color.appBackground)
        }
    }

    return PreviewWrapper()
}
