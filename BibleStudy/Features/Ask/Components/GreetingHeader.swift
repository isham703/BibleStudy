import SwiftUI

// MARK: - Greeting Header
// A personalized greeting component that shows time-aware welcome messages

struct GreetingHeader: View {
    let userName: String?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Welcome"
        }
    }

    private var displayName: String {
        if let name = userName, !name.isEmpty {
            return ", \(name)"
        }
        return ""
    }

    var body: some View {
        Text("\(greeting)\(displayName)")
            .font(Typography.Scripture.heading)
            .foregroundStyle(Color.primaryText)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.lg + 4) {
        GreetingHeader(userName: "Sarah")
        GreetingHeader(userName: nil)
        GreetingHeader(userName: "")
    }
    .padding()
    .background(Color.appBackground)
}
