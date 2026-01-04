import SwiftUI

// MARK: - Greeting Header
// Time-aware personalized greeting for the Home screen

struct GreetingHeader: View {
    let userName: String?

    // Computed greeting based on time of day
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Peace be with you"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text("\(greeting),")
                .font(Typography.Display.title1)
                .foregroundStyle(Color.primaryText)
                .tracking(-0.5)

            if let name = userName, !name.isEmpty {
                Text(name)
                    .font(Typography.Display.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentGold)
                    .tracking(0.5)
                    // Subtle gold glow effect
                    .shadow(color: Color.accentGold.opacity(AppTheme.Opacity.medium), radius: 8, x: 0, y: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("With Name") {
    GreetingHeader(userName: "Sarah")
        .padding()
        .background(Color.appBackground)
}

#Preview("Without Name") {
    GreetingHeader(userName: nil)
        .padding()
        .background(Color.appBackground)
}
