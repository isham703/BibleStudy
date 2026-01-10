import SwiftUI

// MARK: - Plans Tab View
// Reading plans and progress tracking

struct PlansTabView: View {
    @State private var viewModel = PlansViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.plans.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "Reading Plans",
                        message: "Create a reading plan to track your daily Bible study.",
                        actionTitle: "Browse Plans",
                        action: { viewModel.showPlanPicker = true },
                        animation: .noPlans
                    )
                } else {
                    plansList
                }
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showPlanPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPlanPicker) {
                PlanPickerSheet(onSelect: { plan in
                    viewModel.addPlan(plan)
                })
            }
            .sheet(item: $viewModel.selectedPlan) { plan in
                PlanDetailSheet(plan: plan, viewModel: viewModel)
            }
        }
        .task {
            viewModel.loadPlans()
        }
    }

    // MARK: - Plans List
    private var plansList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                // Today's Reading Card
                if let todayPlan = viewModel.plans.first(where: { !$0.isCompleted }) {
                    TodayReadingCard(plan: todayPlan) {
                        viewModel.selectedPlan = todayPlan
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }

                // All Plans
                Text("Your Plans")
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)

                ForEach(viewModel.plans) { plan in
                    PlanCard(plan: plan) {
                        viewModel.selectedPlan = plan
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .padding(.vertical, Theme.Spacing.md)
        }
    }
}

// MARK: - Today Reading Card
struct TodayReadingCard: View {
    let plan: PlanWithProgress
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    Text("Today's Reading")
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }

                Text(plan.title)
                    .font(Typography.Scripture.heading)
                    .foregroundStyle(Color.primaryText)

                if let reading = plan.todayReading {
                    Text(reading.reference)
                        .font(Typography.Command.body)
                        .foregroundStyle(Color.secondaryText)
                }

                // Progress bar
                ProgressView(value: plan.progressPercentage)
                    .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                HStack {
                    Text("\(Int(plan.progressPercentage * 100))%")
                        .font(Typography.Command.meta.monospacedDigit())
                        .foregroundStyle(Color.tertiaryText)

                    Spacer()

                    Text("Continue")
                        .font(Typography.Command.caption.weight(.semibold))
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    Image(systemName: "arrow.right")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                }
            }
            .padding(Theme.Spacing.lg)
            .background(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: PlanWithProgress
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(plan.title)
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                Text("Day \(plan.currentDay) of \(plan.totalDays)")
                    .font(Typography.Command.caption.monospacedDigit())
                    .foregroundStyle(Color.secondaryText)

                ProgressView(value: plan.progressPercentage)
                    .tint(plan.isCompleted ? Color.success : Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(Theme.Spacing.md)
            .background(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }
}

// MARK: - Plan Picker Sheet
struct PlanPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onSelect: (ReadingPlan) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(ReadingPlan.samplePlans) { plan in
                        Button {
                            onSelect(plan)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text(plan.title)
                                    .font(Typography.Scripture.heading)
                                    .foregroundStyle(Color.primaryText)

                                if let description = plan.description {
                                    Text(description)
                                        .font(Typography.Command.body)
                                        .foregroundStyle(Color.secondaryText)
                                }

                                Text("\(plan.totalDays) days")
                                    .font(Typography.Command.caption.monospacedDigit())
                                    .foregroundStyle(Color.tertiaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Theme.Spacing.md)
                            .background(Colors.Surface.surface(for: ThemeMode.current(from: colorScheme)))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Choose a Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Plan Detail Sheet
struct PlanDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let plan: PlanWithProgress
    @Bindable var viewModel: PlansViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg, pinnedViews: .sectionHeaders) {
                    // Progress header
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Progress")
                            .font(Typography.Scripture.heading)

                        ProgressView(value: plan.progressPercentage)
                            .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))

                        Text("\(plan.completedDays) of \(plan.totalDays) days completed")
                            .font(Typography.Command.caption.monospacedDigit())
                            .foregroundStyle(Color.secondaryText)
                    }

                    // Today's reading
                    if let reading = plan.todayReading {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Day \(reading.day)")
                                .font(Typography.Scripture.heading.monospacedDigit())

                            Text(reading.reference)
                                .font(Typography.Command.body)
                                .foregroundStyle(Color.secondaryText)

                            Button {
                                viewModel.markDayComplete(plan: plan, day: reading.day)
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Mark as Complete")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Spacing.md)
                                .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                .foregroundStyle(.white)
                                .font(Typography.Command.body.weight(.semibold))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                            }
                        }
                    }

                    // Schedule section with lazy loading for 365-day plans
                    Section {
                        ForEach(plan.plan.schedule) { day in
                            ScheduleDayRow(
                                day: day,
                                isCompleted: plan.progress.contains { $0.dayNumber == day.day && $0.isCompleted }
                            )
                        }
                    } header: {
                        Text("Full Schedule")
                            .font(Typography.Scripture.heading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Color.appBackground)
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Schedule Day Row
// Extracted for lazy loading performance with long reading plans (e.g., 365-day)
struct ScheduleDayRow: View {
    let day: DayReading
    let isCompleted: Bool

    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCompleted ? Color.success : Color.tertiaryText)

            VStack(alignment: .leading) {
                Text("Day \(day.day)")
                    .font(Typography.Command.body.weight(.semibold))
                    .foregroundStyle(isCompleted ? Color.secondaryText : Color.primaryText)

                Text(day.reference)
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
        .padding(Theme.Spacing.sm)
    }
}

// MARK: - Plans View Model
@Observable
@MainActor
final class PlansViewModel {
    var plans: [PlanWithProgress] = []
    var showPlanPicker: Bool = false
    var selectedPlan: PlanWithProgress?

    func loadPlans() {
        // Load from UserDefaults or database
        // For now, use sample data
    }

    func addPlan(_ plan: ReadingPlan) {
        let planWithProgress = PlanWithProgress(plan: plan, progress: [])
        plans.append(planWithProgress)
    }

    func markDayComplete(plan: PlanWithProgress, day: Int) {
        guard let index = plans.firstIndex(where: { $0.id == plan.id }) else { return }

        let progress = ReadingProgress(
            userId: UUID(), // Would use actual user ID
            planId: plan.id,
            dayNumber: day,
            completedAt: Date()
        )

        plans[index].progress.append(progress)
    }
}

#Preview {
    PlansTabView()
}
