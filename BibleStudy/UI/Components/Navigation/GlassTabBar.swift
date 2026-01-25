import SwiftUI

// MARK: - Tab Bar
// Flat tab bar with pill-shaped segment control + Ask FAB
// Transforms into mini player when audio is active
// Stoic-Existential Renaissance design with minimal glass effects

struct GlassTabBar: View {
    @Binding var selectedTab: Tab
    @Binding var showAskModal: Bool
    let audioService: AudioService
    let onMiniPlayerTap: () -> Void
    let onMiniPlayerClose: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Animation State
    @State private var tabBarAppeared = false

    private var respectsReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private var isAudioActive: Bool {
        audioService.playbackState != .idle
    }

    var body: some View {
        Group {
            if isAudioActive {
                miniPlayerContent
            } else {
                tabBarContent
            }
        }
        .offset(y: tabBarAppeared ? 0 : 80)
        .opacity(tabBarAppeared ? 1 : 0)
        .animation(Theme.Animation.fade, value: isAudioActive)
        .onAppear {
            startEntranceAnimation()
        }
    }

    // MARK: - Tab Bar Content

    private var tabBarContent: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Tab pill (left side) - segmented control
            GeometryReader { geometry in
                GlassSegmentedControl(
                    size: geometry.size,
                    selectedTab: $selectedTab
                )
                .background(
                    Capsule()
                        .fill(Color.appSurface)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.appDivider, lineWidth: Theme.Stroke.hairline)
                )
            }

            // Ask FAB (right side) - accent with flat backing
            askButton
                .frame(width: 55, height: 55)
                .background(
                    Circle()
                        .fill(Color("AppAccentAction").opacity(Theme.Opacity.divider))
                )
                .overlay(
                    Circle()
                        .stroke(Color("AppAccentAction").opacity(Theme.Opacity.subtle), lineWidth: Theme.Stroke.hairline)
                )
        }
        .frame(height: 55)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Mini Player Content

    private var miniPlayerContent: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Play/Pause button
            if audioService.isLoading {
                ProgressView()
                    .tint(Color("AppAccentAction"))
                    .frame(width: 36, height: 36)
            } else {
                Button {
                    HapticService.shared.lightTap()
                    audioService.togglePlayPause()
                } label: {
                    Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color("AppAccentAction"))
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel(audioService.isPlaying ? "Pause" : "Play")
            }

            // Chapter info and progress
            VStack(alignment: .leading, spacing: 1) {
                if let chapter = audioService.currentChapter {
                    Text("\(chapter.bookName) \(chapter.chapterNumber)")
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)

                    Text("\(audioService.formattedCurrentTime) / \(audioService.formattedDuration)")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(Color("TertiaryText"))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onMiniPlayerTap)

            // Skip backward
            Button {
                HapticService.shared.lightTap()
                audioService.skipBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 16))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Skip backward 15 seconds")

            // Skip forward
            Button {
                HapticService.shared.lightTap()
                audioService.skipForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 16))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Skip forward 15 seconds")

            // Close
            Button {
                HapticService.shared.lightTap()
                onMiniPlayerClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("TertiaryText"))
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Close audio")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Color.appDivider.opacity(0.5), lineWidth: Theme.Stroke.hairline)
        )
        .overlay(alignment: .bottom) {
            // Progress bar
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color("AppAccentAction"))
                    .frame(width: geometry.size.width * audioService.progress, height: 2)
            }
            .frame(height: 2)
            .clipShape(RoundedRectangle(cornerRadius: 1))
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Audio player")
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
                    .frame(width: Theme.Size.iconSize, height: Theme.Size.iconSize)
                    .foregroundStyle(Color("AppAccentAction"))
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
    var inactiveTint: Color = .primary.opacity(Theme.Opacity.textTertiary)
    var barTint: Color = Color("AppAccentAction").opacity(Theme.Opacity.overlay)
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
        .foregroundStyle(selectedTab == tab ? Color("AppAccentAction") : Color("AppTextSecondary"))
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
                GlassTabBar(
                    selectedTab: $selectedTab,
                    showAskModal: $showAskModal,
                    audioService: AudioService.shared,
                    onMiniPlayerTap: {},
                    onMiniPlayerClose: {}
                )
            }
            .background(Color.appBackground)
        }
    }

    return PreviewWrapper()
}
