import SwiftUI

// MARK: - Scholar's Atrium Page
// Editorial Manuscript + Scholarly Study aesthetic
// Intellectual, revelatory light-mode design for daytime study

struct ScholarsAtriumPage: View {
    @Environment(\.settingsAction) private var settingsAction
    @State private var isVisible = false

    private let verse = HomeShowcaseMockData.dailyVerse
    private var user: MockUserData { SanctuaryDataAdapter.shared.userData }
    private let plan = HomeShowcaseMockData.activePlan

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)
                        .padding(.top, HomeShowcaseTheme.Spacing.lg)

                    Spacer()
                        .frame(height: HomeShowcaseTheme.Spacing.xxl)

                    // Today's Study Card
                    todayStudyCard
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                    Spacer()
                        .frame(height: HomeShowcaseTheme.Spacing.xxl)

                    // Deepen Understanding Section
                    deepenSection
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                    Spacer()
                        .frame(height: HomeShowcaseTheme.Spacing.lg)

                    // Feature Grid
                    featureGrid
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                    Spacer()
                        .frame(height: HomeShowcaseTheme.Spacing.xxl)

                    // Evening Practices
                    eveningSection
                        .padding(.horizontal, HomeShowcaseTheme.Spacing.xl)

                    Spacer()
                        .frame(height: HomeShowcaseTheme.Spacing.xxxl)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.vellumCream.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 1.0)) {
                isVisible = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BIBLESTUDY")
                    .font(HomeShowcaseTypography.Scholar.header)
                    .tracking(1.5)
                    .foregroundStyle(Color.scholarInk)

                Text(HomeShowcaseMockData.formattedDate)
                    .font(HomeShowcaseTypography.Scholar.date)
                    .foregroundStyle(Color.footnoteGray)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: isVisible)

            Spacer()

            HStack(spacing: 12) {
                Button(action: settingsAction) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.footnoteGray)
                }

                // Streak badge (dark variant for light mode)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.connectionAmber)
                    Text("\(user.currentStreak)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.scholarInk)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.connectionAmber.opacity(0.15))
                )
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.1), value: isVisible)
        }
    }

    // MARK: - Today's Study Card

    private var todayStudyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("TODAY'S STUDY")
                .font(HomeShowcaseTypography.Scholar.sectionHeader)
                .tracking(2.5)
                .foregroundStyle(Color.scholarIndigo)

            // Scripture card
            VStack(alignment: .leading, spacing: 12) {
                // Reference
                Text(plan.todayReference)
                    .font(HomeShowcaseTypography.Scholar.scriptureRef)
                    .foregroundStyle(Color.scholarInk)

                // Divider line
                Rectangle()
                    .fill(Color.scholarInk.opacity(0.1))
                    .frame(height: 1)

                // Scripture preview with underline hints
                Text(plan.previewQuote)
                    .font(HomeShowcaseTypography.Scholar.scriptureText)
                    .foregroundStyle(Color.inkWell)
                    .lineSpacing(8)
                    .overlay(alignment: .bottomLeading) {
                        // Underline hint on first phrase
                        Rectangle()
                            .fill(Color.greekBlue)
                            .frame(width: 120, height: 2)
                            .offset(y: 4)
                    }

                // Open Commentary CTA
                NavigationLink(destination: AIFeaturePlaceholderView(feature: .livingCommentary)) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 14))
                        Text("Open Commentary")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Color.scholarIndigo)
                    .padding(.top, 8)
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.scholarInk.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 1.0).delay(0.1), value: isVisible)
    }

    // MARK: - Deepen Understanding Section

    private var deepenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DEEPEN YOUR UNDERSTANDING")
                .font(HomeShowcaseTypography.Scholar.sectionHeader)
                .tracking(2)
                .foregroundStyle(Color.scholarIndigo)

            // Living Commentary marginalia card
            MarginaliaCard(
                color: .scholarIndigo,
                label: "CONNECTION",
                description: "Living Commentary reveals 4 insights in today's passage",
                tags: ["Greek", "Theology", "Personal"]
            )
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 1.0).delay(0.2), value: isVisible)
    }

    // MARK: - Feature Grid

    private var featureGrid: some View {
        HStack(spacing: HomeShowcaseTheme.Spacing.md) {
            // Memory Palace
            ScholarFeatureCard(
                feature: .memoryPalace,
                description: "Memorize Psalm 23",
                detail: "5 rooms",
                accentColor: .thresholdPurple
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 1.0).delay(0.3), value: isVisible)

            // Living Scripture
            ScholarFeatureCard(
                feature: .livingScripture,
                description: "Experience the Prodigal Son in first person",
                detail: "5 scenes",
                accentColor: .thresholdGold
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 1.0).delay(0.35), value: isVisible)
        }
    }

    // MARK: - Evening Practices Section

    private var eveningSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EVENING PRACTICES")
                .font(HomeShowcaseTypography.Scholar.sectionHeader)
                .tracking(2)
                .foregroundStyle(Color.footnoteGray)

            HStack(spacing: HomeShowcaseTheme.Spacing.md) {
                // Compline
                ScholarFeatureCard(
                    feature: .compline,
                    description: "Evening Prayer",
                    accentColor: .thresholdBlue
                )

                // Prayers from the Deep
                ScholarFeatureCard(
                    feature: .prayersFromDeep,
                    description: "from the Deep",
                    accentColor: .personalRose
                )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 1.0).delay(0.4), value: isVisible)
    }
}

// MARK: - Marginalia Card

private struct MarginaliaCard: View {
    let feature: AIFeature
    let color: Color
    let label: String
    let description: String
    let tags: [String]

    @State private var isPressed = false

    init(
        feature: AIFeature = .livingCommentary,
        color: Color,
        label: String,
        description: String,
        tags: [String]
    ) {
        self.feature = feature
        self.color = color
        self.label = label
        self.description = description
        self.tags = tags
    }

    var body: some View {
        NavigationLink(destination: feature.destinationView) {
            HStack(spacing: 0) {
                // Vertical accent bar
                Rectangle()
                    .fill(color)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 10) {
                    // Header
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(color)

                        Text(label)
                            .font(HomeShowcaseTypography.Scholar.marginLabel)
                            .tracking(2.5)
                            .foregroundStyle(color)
                    }

                    // Description
                    Text(description)
                        .font(HomeShowcaseTypography.Scholar.marginBody)
                        .foregroundStyle(Color.inkWell)
                        .lineSpacing(4)

                    // Tags
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(HomeShowcaseTypography.Scholar.chipText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(color.opacity(0.1))
                                )
                                .foregroundStyle(color)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.scholarInk.opacity(0.08), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(isPressed ? 0.02 : 0.05),
                radius: isPressed ? 2 : 6,
                y: isPressed ? 1 : 3
            )
            .offset(y: isPressed ? 2 : 0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 1.0), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                HomeShowcaseHaptics.scholarlyPress()
            }
        }, perform: {})
    }
}

// MARK: - Scholar Feature Card

private struct ScholarFeatureCard: View {
    let feature: AIFeature
    let icon: String
    let label: String
    let description: String
    let detail: String?
    let accentColor: Color

    @State private var isPressed = false

    init(
        feature: AIFeature,
        icon: String? = nil,
        label: String? = nil,
        description: String? = nil,
        detail: String? = nil,
        accentColor: Color
    ) {
        self.feature = feature
        self.icon = icon ?? feature.icon
        self.label = label ?? feature.cardLabel
        self.description = description ?? feature.cardSubtitle
        self.detail = detail
        self.accentColor = accentColor
    }

    var body: some View {
        NavigationLink(destination: feature.destinationView) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(accentColor)

                // Label
                Text(label)
                    .font(HomeShowcaseTypography.Scholar.marginLabel)
                    .tracking(1.5)
                    .foregroundStyle(accentColor)

                // Divider
                Rectangle()
                    .fill(accentColor.opacity(0.3))
                    .frame(height: 1)

                // Description
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.inkWell)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Detail (optional)
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.footnoteGray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.scholarInk.opacity(0.08), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(isPressed ? 0.02 : 0.05),
                radius: isPressed ? 2 : 6,
                y: isPressed ? 1 : 3
            )
            .offset(y: isPressed ? 2 : 0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 1.0), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
            if pressing {
                HomeShowcaseHaptics.scholarlyPress()
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScholarsAtriumPage()
    }
}
