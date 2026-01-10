import SwiftUI
import StoreKit

// MARK: - Paywall View
// Soft paywall shown after free tier limits are reached

private let analytics = AnalyticsService.shared

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var storeManager = StoreManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Context for why paywall was triggered
    let trigger: PaywallTrigger

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    headerSection

                    // Features list
                    featuresSection

                    // Product options
                    productsSection

                    // Trial info
                    trialInfoSection

                    // Legal
                    legalSection
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Maybe Later") {
                        analytics.trackPaywallDismissed(trigger: trigger.analyticsValue)
                        dismiss()
                    }
                    .font(Typography.Command.subheadline)
                    .foregroundStyle(Color.secondaryText)
                }
            }
            .onAppear {
                analytics.trackPaywallShown(trigger: trigger.analyticsValue)
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.lightMedium))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(Typography.Command.largeTitle)
                    .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
            }
            .padding(.top, Theme.Spacing.xl)

            // Title based on trigger
            Text(headerTitle)
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Get unlimited access to all features")
                .font(Typography.Command.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var headerTitle: String {
        switch trigger {
        case .aiInsightsLimit:
            return "You've unlocked 3 insights!"
        case .memorizationLimit:
            return "Ready to memorize more?"
        case .translationLimit:
            return "Unlock all translations"
        case .highlightLimit:
            return "Need more highlights?"
        case .noteLimit:
            return "Need more notes?"
        case .prayerLimit:
            return "Unlock unlimited prayers"
        case .manual:
            return "Upgrade to Premium"
        case .firstSession:
            return "Continue your journey"
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What you'll get:")
                .font(Typography.Scripture.heading)
                .foregroundStyle(Color.primaryText)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                FeatureRow(icon: "text.book.closed", text: "All Bible translations")
                FeatureRow(icon: "brain.head.profile", text: "Unlimited AI insights")
                FeatureRow(icon: "note.text", text: "Unlimited notes")
                FeatureRow(icon: "memories", text: "Full memorization features")
                FeatureRow(icon: "headphones", text: "Priority support")
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - Products Section

    private var productsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if storeManager.isLoading && storeManager.products.isEmpty {
                ProgressView()
                    .tint(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .padding()
            } else {
                ForEach(storeManager.products, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        onSelect: { selectedProduct = product }
                    )
                }

                // Purchase button
                Button(action: purchase) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(purchaseButtonText)
                                .font(Typography.Command.cta)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
                .disabled(selectedProduct == nil || isPurchasing)
                .opacity(selectedProduct == nil ? Theme.Opacity.disabled : 1)
            }
        }
        .onAppear {
            // Select first product by default
            if selectedProduct == nil {
                selectedProduct = storeManager.premiumProduct
            }
        }
    }

    private var purchaseButtonText: String {
        if selectedProduct != nil {
            return "Start Free Trial"
        }
        return "Select a plan"
    }

    // MARK: - Trial Info Section

    private var trialInfoSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let product = selectedProduct {
                Text("7-day free trial, then \(product.displayPrice)/year")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.secondaryText)

                Text("Cancel anytime. No commitment.")
                    .font(Typography.Command.caption)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.lg) {
                Button("Terms of Use") {
                    // Open terms URL
                }
                .font(Typography.Command.meta)
                .foregroundStyle(Color.tertiaryText)

                Button("Privacy Policy") {
                    // Open privacy URL
                }
                .font(Typography.Command.meta)
                .foregroundStyle(Color.tertiaryText)

                Button("Restore") {
                    Task { await restorePurchases() }
                }
                .font(Typography.Command.meta)
                .foregroundStyle(Color.tertiaryText)
            }

            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(Typography.Command.meta)
                .foregroundStyle(Color.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Actions

    private func purchase() {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        Task {
            do {
                // Track trial/purchase start
                analytics.trackTrialStarted(productId: product.id)

                let transaction = try await storeManager.purchase(product)
                if transaction != nil {
                    // Track successful purchase
                    analytics.trackSubscriptionPurchased(productId: product.id, price: product.price)
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }

    private func restorePurchases() async {
        isPurchasing = true
        do {
            try await storeManager.restorePurchases()
            if storeManager.isPremiumOrHigher {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.Command.body)
                .foregroundStyle(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                .frame(width: 24)

            Text(text)
                .font(Typography.Command.body)
                .foregroundStyle(Color.primaryText)

            Spacer()

            Image(systemName: "checkmark")
                .font(Typography.Command.caption)
                .foregroundStyle(Color.success)
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(product.displayName)
                            .font(Typography.Scripture.heading)
                            .foregroundStyle(Color.primaryText)

                        if isScholar {
                            Text("BEST VALUE")
                                .font(Typography.Command.meta)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Theme.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)))
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.description)
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(Typography.Command.headline.monospacedDigit())
                        .foregroundStyle(Color.primaryText)

                    Text("/year")
                        .font(Typography.Command.caption)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .fill(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)).opacity(Theme.Opacity.subtle) : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(isSelected ? Colors.Semantic.accentAction(for: ThemeMode.current(from: colorScheme)) : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var isScholar: Bool {
        product.id == ProductID.scholarYearly.rawValue
    }
}

// MARK: - Paywall Trigger

enum PaywallTrigger {
    case aiInsightsLimit
    case memorizationLimit
    case translationLimit
    case highlightLimit
    case noteLimit
    case prayerLimit  // Prayer generation daily limit reached
    case firstSession
    case manual

    var analyticsValue: String {
        switch self {
        case .aiInsightsLimit: return "ai_insights_limit"
        case .memorizationLimit: return "memorization_limit"
        case .translationLimit: return "translation_limit"
        case .highlightLimit: return "highlight_limit"
        case .noteLimit: return "note_limit"
        case .prayerLimit: return "prayer_limit"
        case .firstSession: return "first_session"
        case .manual: return "manual"
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(trigger: .aiInsightsLimit)
}
