import SwiftUI

// MARK: - Glass Tab Bar
// Liquid Glass tab bar with pill-shaped segment control + Ask FAB
// Uses iOS 26 glass effect APIs for modern material design

struct GlassTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var showAskModal: Bool

    // MARK: - Animation State
    @State private var tabBarAppeared = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: AppTheme.Spacing.md) {
                // Tab pill (left side) - segmented glass control
                GeometryReader { geometry in
                    GlassSegmentedControl(
                        size: geometry.size,
                        selectedTab: $selectedTab
                    )
                    .glassEffect(.regular.interactive(), in: .capsule)
                }

                // Ask FAB (right side) - gold accent with glass backing
                askButton
                    .frame(width: 55, height: 55)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
        }
        .frame(height: 55)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
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
                    .foregroundStyle(Color.divineGold)
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
            withAnimation(AppTheme.Animation.sacredSpring) {
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
    var inactiveTint: Color = .primary.opacity(AppTheme.Opacity.midHeavy)
    var barTint: Color = Color.accentGold.opacity(AppTheme.Opacity.quarter)
    @Binding var selectedTab: Tab

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
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(tab.icon)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)

            Text(tab.title)
                .font(Typography.UI.tabLabel)
                .fontWeight(.medium)
        }
        .foregroundStyle(selectedTab == tab ? Color.accentGold : Color.secondaryText)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var parent: GlassSegmentedControl

        init(parent: GlassSegmentedControl) {
            self.parent = parent
        }

        @objc func tabSelected(_ control: UISegmentedControl) {
            HapticService.shared.tabSwitch()
            withAnimation(AppTheme.Animation.reverent) {
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
