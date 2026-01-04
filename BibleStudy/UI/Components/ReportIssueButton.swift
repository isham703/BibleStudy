import SwiftUI

// MARK: - Report Issue Button
// Allows users to flag AI responses that may be incorrect

struct ReportIssueButton: View {
    @State private var showReportSheet = false
    @State private var showConfirmation = false

    var body: some View {
        Button {
            showReportSheet = true
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "flag")
                Text("Report issue")
            }
            .font(Typography.UI.caption1)
            .foregroundStyle(Color.tertiaryText)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportIssueSheet(
                onSubmit: { reason, details in
                    // TODO: Submit report
                    print("Report submitted: \(reason) - \(details)")
                    showReportSheet = false
                    showConfirmation = true
                }
            )
            .presentationDetents([.medium])
        }
        .alert("Report Submitted", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for helping us improve. We'll review your feedback.")
        }
    }
}

// MARK: - Report Issue Sheet
struct ReportIssueSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSubmit: (ReportReason, String) -> Void

    @State private var selectedReason: ReportReason = .inaccurate
    @State private var additionalDetails = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("What's wrong with this response?") {
                    ForEach(ReportReason.allCases, id: \.self) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason.title)
                                    .foregroundStyle(Color.primaryText)

                                Spacer()

                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.scholarAccent)
                                }
                            }
                        }
                    }
                }

                Section("Additional details (optional)") {
                    TextField("Describe the issue...", text: $additionalDetails, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Text("Your feedback helps us improve AI responses. Reports are anonymous.")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.secondaryText)
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        onSubmit(selectedReason, additionalDetails)
                    }
                }
            }
        }
    }
}

// MARK: - Report Reason
enum ReportReason: String, CaseIterable {
    case inaccurate
    case misleading
    case offensive
    case incomplete
    case other

    var title: String {
        switch self {
        case .inaccurate: return "Inaccurate or incorrect information"
        case .misleading: return "Misleading or biased interpretation"
        case .offensive: return "Offensive or inappropriate content"
        case .incomplete: return "Missing important context"
        case .other: return "Other issue"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        ReportIssueButton()

        ReportIssueSheet { reason, details in
            print("Submitted: \(reason) - \(details)")
        }
    }
}
