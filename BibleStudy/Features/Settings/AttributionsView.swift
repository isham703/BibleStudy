import SwiftUI

// MARK: - Attributions View
/// Displays data source attributions and licenses for compliance with open-source licenses

struct AttributionsView: View {
    @State private var dataSources: [DataSource] = []
    @State private var isLoading = true

    var body: some View {
        List {
            // Introduction
            Section {
                Text("This app uses the following open-source data and resources. We are grateful to the organizations and individuals who make this data freely available.")
                    .font(Typography.UI.warmBody)
                    .foregroundStyle(Color.secondaryText)
            }

            // Bible Text
            Section("Bible Text") {
                AttributionRow(
                    name: "King James Version",
                    license: "Public Domain",
                    description: "The 1769 Cambridge Edition of the King James Bible. No copyright restrictions.",
                    sourceUrl: nil
                )
            }

            // Cross-References (when available)
            Section("Cross-References") {
                AttributionRow(
                    name: "OpenBible.info Cross-References",
                    license: "CC BY 4.0",
                    description: "A dataset of cross-references between Bible verses, compiled by OpenBible.info.",
                    sourceUrl: URL(string: "https://www.openbible.info/labs/cross-references/")
                )
            }

            // Original Language Data (when available)
            Section("Original Language Data") {
                AttributionRow(
                    name: "STEP Bible Data",
                    license: "CC BY 4.0",
                    description: "Hebrew and Greek morphological data, Strong's numbers, and glosses. Created for www.STEPBible.org.",
                    sourceUrl: URL(string: "https://github.com/STEPBible/STEPBible-Data")
                )

                AttributionRow(
                    name: "Open Scriptures Hebrew Bible",
                    license: "CC BY 4.0",
                    description: "Morphological tagging of the Westminster Leningrad Codex.",
                    sourceUrl: URL(string: "https://hb.openscriptures.org/")
                )
            }

            // Licenses
            Section("License Information") {
                LicenseInfoRow(
                    licenseName: "Public Domain",
                    description: "No restrictions on use, modification, or distribution."
                )

                LicenseInfoRow(
                    licenseName: "CC BY 4.0",
                    description: "Creative Commons Attribution 4.0 International. You may share and adapt the material with appropriate credit."
                )

                if let ccUrl = URL(string: "https://creativecommons.org/licenses/by/4.0/") {
                    Link(destination: ccUrl) {
                        HStack {
                            Text("View CC BY 4.0 License")
                                .font(Typography.UI.subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(Typography.UI.caption1)
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }
                }
            }

            // Data from database (dynamic sources)
            if !dataSources.isEmpty {
                Section("Installed Data Sources") {
                    ForEach(dataSources) { source in
                        AttributionRow(
                            name: source.name,
                            license: source.license,
                            description: source.attribution ?? "Version \(source.version)",
                            sourceUrl: source.sourceUrl.flatMap { URL(string: $0) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Attributions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDataSources()
        }
    }

    private func loadDataSources() async {
        do {
            dataSources = try await DataLoadingService.shared.getDataSources()
        } catch {
            print("Failed to load data sources: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Attribution Row
struct AttributionRow: View {
    let name: String
    let license: String
    let description: String
    let sourceUrl: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(name)
                    .font(Typography.UI.bodyBold)

                Spacer()

                Text(license)
                    .font(Typography.UI.caption2)
                    .foregroundStyle(Color.scholarAccent)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.scholarAccent.opacity(AppTheme.Opacity.light))
                    )
            }

            Text(description)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)

            if let url = sourceUrl {
                Link(destination: url) {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Text("View Source")
                            .font(Typography.UI.caption2)
                        Image(systemName: "arrow.up.right")
                            .font(Typography.UI.caption2)
                    }
                    .foregroundStyle(Color.accentBlue)
                }
                .padding(.top, AppTheme.Spacing.xxs)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - License Info Row
struct LicenseInfoRow: View {
    let licenseName: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(licenseName)
                .font(Typography.UI.bodyBold)

            Text(description)
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AttributionsView()
    }
}
