import SwiftUI

// MARK: - Sermon Viewing Phase
// Hub & Spoke architecture: Landing page hub with three spoke views
// pushed via NavigationLink(value: SermonDestination).
//
// .navigationDestination is registered on the stable ZStack in SermonView
// (not inside this @ViewBuilder-switched child) so it survives body
// re-evaluations without invalidating pushed spoke views.

struct SermonViewingPhase: View {
    @Bindable var flowState: SermonFlowState
    var viewModel: SermonViewingViewModel
    @Bindable var notesViewModel: SermonNotesViewModel
    var bookmarks: [SermonBookmark]
    @Binding var showShareSheet: Bool
    @Binding var showDeleteConfirmation: Bool
    @Binding var showQuickCapture: Bool

    @State private var isAwakened = false
    @State private var isKeyboardVisible = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Computed

    private var isSampleSermon: Bool {
        flowState.isViewingSample
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            if isAwakened {
                landingScrollView
                    .transition(.opacity)
            } else {
                loadingView
                    .transition(.opacity)
            }
        }
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Theme.Spacing.sm) {
                    // Share button
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color("AccentBronze"))
                    }
                    .accessibilityLabel("Share")

                    // Overflow menu
                    Menu {
                        Button {
                            copyTranscript()
                        } label: {
                            Label("Copy Transcript", systemImage: "doc.on.doc")
                        }
                        .disabled(flowState.currentTranscript == nil)

                        Button {
                            flowState.reset()
                        } label: {
                            Label("New Sermon", systemImage: "plus")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Sermon", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(Typography.Icon.sm)
                            .foregroundStyle(Color("AccentBronze"))
                    }
                    .accessibilityLabel("More options")
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Theme.Animation.settle) {
                    isAwakened = true
                }
            }
        }
        .task {
            if let sermonId = flowState.currentSermon?.id {
                await SermonEngagementService.shared.loadEngagements(sermonId: sermonId)
            }
        }
        // Note: cleanup is handled by SermonViewingViewModel.deinit,
        // NOT .onDisappear — which fires when pushing spoke views.
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }

    // MARK: - Landing Scroll View

    private var landingScrollView: some View {
        ScrollView(showsIndicators: false) {
            SermonLandingContent(
                flowState: flowState,
                viewModel: viewModel,
                notesViewModel: notesViewModel,
                bookmarks: bookmarks,
                isAwakened: isAwakened,
                onQuickCapture: { showQuickCapture = true }
            )
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl * 2)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color("AppBackground")
            .ignoresSafeArea()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color("AccentBronze").opacity(Theme.Opacity.subtle))
                    .frame(width: 80, height: 80)

                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color("AccentBronze"))
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(flowState.currentSermon?.displayTitle ?? "Loading...")
                    .font(Typography.Scripture.title)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let duration = flowState.currentSermon?.formattedDuration {
                    Text(duration)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.xxl)

            LoadingDotsView()
                .padding(.top, Theme.Spacing.md)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers

    private func copyTranscript() {
        guard let transcript = flowState.currentTranscript else { return }
        UIPasteboard.general.string = transcript.content
        HapticService.shared.success()
        ToastService.shared.showSuccess(message: "Transcript copied")
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    @Previewable @State var flowState = SermonFlowState()
    @Previewable @State var showShareSheet = false
    @Previewable @State var showDeleteConfirmation = false
    @Previewable @State var showQuickCapture = false

    SermonViewingPhase(
        flowState: flowState,
        viewModel: SermonViewingViewModel(),
        notesViewModel: SermonNotesViewModel(),
        bookmarks: [],
        showShareSheet: $showShareSheet,
        showDeleteConfirmation: $showDeleteConfirmation,
        showQuickCapture: $showQuickCapture
    )
    .preferredColorScheme(.dark)
    .onAppear {
        flowState.currentSermon = Sermon(
            userId: UUID(),
            title: "The Power of Grace",
            speakerName: "Pastor John",
            recordedAt: Date(),
            durationSeconds: 2700
        )

        flowState.currentTranscript = SermonTranscript(
            sermonId: flowState.currentSermon!.id,
            content: "So today we're going to be talking about grace. What is grace? Grace is unmerited favor from God.",
            wordTimestamps: []
        )

        flowState.currentStudyGuide = SermonStudyGuide(
            sermonId: flowState.currentSermon!.id,
            content: StudyGuideContent(
                title: "The Power of Grace",
                summary: "This sermon explores the foundational Christian concept of grace as unmerited favor from God, transforming our identity and relationship with Him.",
                keyThemes: ["Grace", "Identity", "Faith", "Transformation"],
                centralThesis: "Grace is not merely God's response to our failure - it is the foundation upon which our entire identity in Christ is built.",
                keyTakeaways: [
                    AnchoredInsight(
                        title: "Grace Transforms Identity",
                        insight: "The believer's identity shifts from performance to position - not what we do, but who we are in Christ.",
                        supportingQuote: "When you understand grace, you stop trying to earn what you have already received.",
                        timestampSeconds: 154,
                        references: ["John 3:16", "Ephesians 2:8-9"]
                    ),
                    AnchoredInsight(
                        title: "Rest in Finished Work",
                        insight: "The cross declares 'It is finished' - our striving adds nothing to Christ's completed work.",
                        supportingQuote: "We do not work for acceptance; we work from acceptance.",
                        timestampSeconds: 423,
                        references: ["Romans 5:1"]
                    )
                ],
                outline: [
                    OutlineSection(title: "Introduction to Grace", startSeconds: 0, endSeconds: 120, summary: nil),
                    OutlineSection(title: "Biblical Foundation", startSeconds: 120, endSeconds: 300, summary: nil),
                    OutlineSection(title: "Application", startSeconds: 300, endSeconds: 450, summary: nil)
                ],
                bibleReferencesMentioned: [
                    SermonVerseReference(reference: "John 3:16", bookId: 43, chapter: 3, verseStart: 16, isMentioned: true, timestampSeconds: 120),
                    SermonVerseReference(reference: "Romans 8:28", bookId: 45, chapter: 8, verseStart: 28, isMentioned: true, timestampSeconds: 340),
                    SermonVerseReference(reference: "Ephesians 2:8-9", bookId: 49, chapter: 2, verseStart: 8, verseEnd: 9, isMentioned: true, timestampSeconds: 520)
                ],
                bibleReferencesSuggested: [
                    SermonVerseReference(
                        reference: "Romans 5:1-2",
                        bookId: 45, chapter: 5, verseStart: 1, verseEnd: 2,
                        isMentioned: false,
                        rationale: "Justification by faith leads to peace with God - a direct connection to the sermon's theme of grace-based identity.",
                        verificationStatus: .verified,
                        relation: .supports
                    ),
                    SermonVerseReference(
                        reference: "Galatians 2:16",
                        bookId: 48, chapter: 2, verseStart: 16,
                        isMentioned: false,
                        rationale: "Clarifies that no one is justified by works of the law, but through faith in Christ.",
                        verificationStatus: .partial,
                        relation: .clarifies
                    )
                ],
                discussionQuestions: [
                    StudyQuestion(question: "How does understanding grace change your relationship with God?", type: .application)
                ],
                reflectionPrompts: ["Consider how you might extend grace to others this week."],
                applicationPoints: [],
                anchoredApplicationPoints: [
                    AnchoredInsight(
                        title: "Practice Sabbath Rest",
                        insight: "This week, set aside one day to disconnect from work and practice intentional rest.",
                        supportingQuote: "Reclaim the gift of Sabbath in our hustle culture.",
                        timestampSeconds: 2112
                    )
                ]
            )
        )
    }
}
