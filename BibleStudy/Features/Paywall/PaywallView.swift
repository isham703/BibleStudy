import SwiftUI
import StoreKit

// MARK: - Paywall View
// Soft paywall shown after free tier limits are reached

private let analytics = AnalyticsService.shared

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
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
                VStack(spacing: AppTheme.Spacing.xl) {
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
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxl)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Maybe Later") {
                        analytics.trackPaywallDismissed(trigger: trigger.analyticsValue)
                        dismiss()
                    }
                    .font(Typography.UI.subheadline)
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
        VStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentGold.opacity(AppTheme.Opacity.lightMedium))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(Typography.UI.largeTitle)
                    .foregroundStyle(Color.accentGold)
            }
            .padding(.top, AppTheme.Spacing.xl)

            // Title based on trigger
            Text(headerTitle)
                .font(Typography.Display.title2)
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Get unlimited access to all features")
                .font(Typography.UI.warmBody)
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
        case .manual:
            return "Upgrade to Premium"
        case .firstSession:
            return "Continue your journey"
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("What you'll get:")
                .font(Typography.Display.headline)
                .foregroundStyle(Color.primaryText)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                FeatureRow(icon: "text.book.closed", text: "All Bible translations")
                FeatureRow(icon: "brain.head.profile", text: "Unlimited AI insights")
                FeatureRow(icon: "note.text", text: "Unlimited notes")
                FeatureRow(icon: "memories", text: "Full memorization features")
                FeatureRow(icon: "headphones", text: "Priority support")
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
    }

    // MARK: - Products Section

    private var productsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if storeManager.isLoading && storeManager.products.isEmpty {
                ProgressView()
                    .tint(Color.accentGold)
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
                                .font(Typography.UI.buttonLabel)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(Color.accentGold)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                .disabled(selectedProduct == nil || isPurchasing)
                .opacity(selectedProduct == nil ? AppTheme.Opacity.disabled : 1)
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
        VStack(spacing: AppTheme.Spacing.sm) {
            if let product = selectedProduct {
                Text("7-day free trial, then \(product.displayPrice)/year")
                    .font(Typography.UI.footnote)
                    .foregroundStyle(Color.secondaryText)

                Text("Cancel anytime. No commitment.")
                    .font(Typography.UI.caption1)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.lg) {
                Button("Terms of Use") {
                    // Open terms URL
                }
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)

                Button("Privacy Policy") {
                    // Open privacy URL
                }
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)

                Button("Restore") {
                    Task { await restorePurchases() }
                }
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)
            }

            Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(Typography.UI.caption2)
                .foregroundStyle(Color.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.md)
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

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(Typography.UI.body)
                .foregroundStyle(Color.accentGold)
                .frame(width: AppTheme.IconContainer.small)

            Text(text)
                .font(Typography.UI.body)
                .foregroundStyle(Color.primaryText)

            Spacer()

            Image(systemName: "checkmark")
                .font(Typography.UI.caption1)
                .foregroundStyle(Color.success)
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    HStack {
                        Text(product.displayName)
                            .font(Typography.Display.headline)
                            .foregroundStyle(Color.primaryText)

                        if isScholar {
                            Text("BEST VALUE")
                                .font(Typography.UI.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, AppTheme.Spacing.xs)
                                .padding(.vertical, AppTheme.Spacing.xxs)
                                .background(Color.accentGold)
                                .clipShape(Capsule())
                        }
                    }

                    Text(product.description)
                        .font(Typography.UI.footnote)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
                    Text(product.displayPrice)
                        .font(Typography.UI.headline.monospacedDigit())
                        .foregroundStyle(Color.primaryText)

                    Text("/year")
                        .font(Typography.UI.caption1)
                        .foregroundStyle(Color.tertiaryText)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? Color.accentGold.opacity(AppTheme.Opacity.subtle) : Color.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? Color.accentGold : Color.cardBorder, lineWidth: isSelected ? 2 : 1)
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
    case firstSession
    case manual

    var analyticsValue: String {
        switch self {
        case .aiInsightsLimit: return "ai_insights_limit"
        case .memorizationLimit: return "memorization_limit"
        case .translationLimit: return "translation_limit"
        case .highlightLimit: return "highlight_limit"
        case .noteLimit: return "note_limit"
        case .firstSession: return "first_session"
        case .manual: return "manual"
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(trigger: .aiInsightsLimit)
}
