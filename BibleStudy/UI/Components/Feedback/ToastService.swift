import SwiftUI

// MARK: - Toast Manager
// Observable singleton for managing toast notifications
// Handles queueing, presentation, and dismissal of toasts

@MainActor
@Observable
final class ToastService {
    static let shared = ToastService()

    // MARK: - Toast State

    /// Currently displayed toast (nil = no toast visible)
    private(set) var currentToast: ToastItem?

    /// Queue of pending toasts
    private var toastQueue: [ToastItem] = []

    /// Whether a toast is currently being displayed
    var isShowingToast: Bool { currentToast != nil }

    // MARK: - Timing Constants

    /// Default duration before auto-dismiss (seconds)
    static let defaultDuration: TimeInterval = 4.0

    /// Minimum time between toasts (seconds)
    static let minimumInterval: TimeInterval = 0.3

    // MARK: - Private State

    private var dismissTask: Task<Void, Never>?
    private var lastDismissTime: Date?

    private init() {}

    // MARK: - Public API

    /// Show a highlight action toast with undo capability
    func showHighlightToast(
        color: HighlightColor,
        reference: String,
        onUndo: @escaping () async -> Void
    ) {
        let toast = ToastItem(
            id: UUID(),
            type: .highlight(color: color, reference: reference),
            undoAction: onUndo,
            duration: Self.defaultDuration
        )
        enqueue(toast)
    }

    /// Show a generic success toast
    func showSuccess(message: String, duration: TimeInterval? = nil) {
        let finalDuration = duration ?? Self.defaultDuration
        let toast = ToastItem(
            id: UUID(),
            type: .success(message: message),
            undoAction: nil,
            duration: finalDuration
        )
        enqueue(toast)
    }

    /// Show a generic info toast
    func showInfo(message: String, duration: TimeInterval? = nil) {
        let finalDuration = duration ?? Self.defaultDuration
        let toast = ToastItem(
            id: UUID(),
            type: .info(message: message),
            undoAction: nil,
            duration: finalDuration
        )
        enqueue(toast)
    }

    /// Show a sermon deleted toast
    func showSermonDeleted(title: String) {
        let toast = ToastItem(
            id: UUID(),
            type: .sermonDeleted(title: title),
            undoAction: nil,
            duration: Self.defaultDuration
        )
        enqueue(toast)
    }

    /// Show a batch sermons deleted toast
    func showSermonsDeleted(count: Int) {
        let toast = ToastItem(
            id: UUID(),
            type: .sermonsDeleted(count: count),
            undoAction: nil,
            duration: Self.defaultDuration
        )
        enqueue(toast)
    }

    /// Show a delete error toast
    func showDeleteError(message: String) {
        let toast = ToastItem(
            id: UUID(),
            type: .deleteError(message: message),
            undoAction: nil,
            duration: Self.defaultDuration
        )
        enqueue(toast)
    }

    /// Dismiss the current toast immediately
    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil

        withAnimation(Theme.Animation.fade) {
            currentToast = nil
        }

        lastDismissTime = Date()

        // Show next toast after minimum interval
        Task {
            try? await Task.sleep(for: .seconds(Self.minimumInterval))
            showNextIfAvailable()
        }
    }

    /// Trigger undo action and dismiss
    func triggerUndo() {
        guard let toast = currentToast, let undoAction = toast.undoAction else { return }

        // Haptic feedback
        HapticService.shared.success()

        // Execute undo
        Task {
            await undoAction()
        }

        // Dismiss with confirmation
        dismiss()
    }

    // MARK: - Private Methods

    private func enqueue(_ toast: ToastItem) {
        if currentToast == nil {
            show(toast)
        } else {
            // Replace queue with new toast (don't stack multiple)
            toastQueue = [toast]
        }
    }

    private func show(_ toast: ToastItem) {
        // Cancel any pending dismiss
        dismissTask?.cancel()

        // Animate in
        withAnimation(Theme.Animation.settle) {
            currentToast = toast
        }

        // Schedule auto-dismiss
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(toast.duration))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    private func showNextIfAvailable() {
        guard currentToast == nil, let next = toastQueue.first else { return }
        toastQueue.removeFirst()
        show(next)
    }
}

// MARK: - Toast Item

struct ToastItem: Identifiable, Equatable {
    let id: UUID
    let type: ToastType
    let undoAction: (() async -> Void)?
    let duration: TimeInterval

    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Type

enum ToastType: Equatable {
    case highlight(color: HighlightColor, reference: String)
    case success(message: String)
    case info(message: String)
    case bookmark(reference: String)
    case note(reference: String)
    case sermonDeleted(title: String)
    case sermonsDeleted(count: Int)
    case deleteError(message: String)

    var icon: String {
        switch self {
        case .highlight: return "sparkle"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .bookmark: return "bookmark.fill"
        case .note: return "note.text"
        case .sermonDeleted, .sermonsDeleted: return "trash.fill"
        case .deleteError: return "exclamationmark.triangle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .highlight(let color, _): return color.solidColor
        case .success: return Color("FeedbackSuccess")
        case .info: return Color("FeedbackInfo")
        case .bookmark: return Color("AccentBronze")
        case .note: return Color("AccentBronze")
        case .sermonDeleted, .sermonsDeleted: return Color("FeedbackWarning")
        case .deleteError: return Color("FeedbackError")
        }
    }
}

// MARK: - Environment Key

private struct ToastServiceKey: EnvironmentKey {
    static let defaultValue = ToastService.shared
}

extension EnvironmentValues {
    var toastManager: ToastService {
        get { self[ToastServiceKey.self] }
        set { self[ToastServiceKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Presents toasts from the shared ToastService
    func toastPresenter() -> some View {
        self.modifier(ToastPresenterModifier())
    }
}

// MARK: - Toast Presenter Modifier

struct ToastPresenterModifier: ViewModifier {
    @State private var toastManager = ToastService.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = toastManager.currentToast {
                    AppToastView(
                        toast: toast,
                        onDismiss: { toastManager.dismiss() },
                        onUndo: { toastManager.triggerUndo() }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .padding(.bottom, Theme.Spacing.xl)
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            .environment(\.toastManager, toastManager)
    }
}
