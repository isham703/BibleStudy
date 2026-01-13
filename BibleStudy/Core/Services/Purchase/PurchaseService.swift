import Foundation
import StoreKit

// MARK: - Product Identifiers

enum ProductID: String, CaseIterable {
    case premiumYearly = "com.biblestudy.premium.yearly"
    case scholarYearly = "com.biblestudy.scholar.yearly"

    var displayName: String {
        switch self {
        case .premiumYearly: return "Premium"
        case .scholarYearly: return "Scholar"
        }
    }

    var features: [String] {
        switch self {
        case .premiumYearly:
            return [
                "All Bible translations",
                "Unlimited notes",
                "Unlimited AI insights",
                "Full memorization features",
                "Priority support"
            ]
        case .scholarYearly:
            return [
                "Everything in Premium",
                "Hebrew & Greek word study",
                "Audio Bible (when available)",
                "Visual insight cards",
                "Advanced search filters"
            ]
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Comparable, Sendable {
    case free
    case premium
    case scholar

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        let order: [SubscriptionTier] = [.free, .premium, .scholar]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .scholar: return "Scholar"
        }
    }

    var icon: String {
        switch self {
        case .free: return "book"
        case .premium: return "star.fill"
        case .scholar: return "crown.fill"
        }
    }
}

// MARK: - Store Manager

@MainActor
@Observable
final class PurchaseService {
    // MARK: - Singleton
    static let shared = PurchaseService()

    // MARK: - Properties
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var error: StoreError?

    // Transaction listener task
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Computed Properties

    var currentTier: SubscriptionTier {
        if purchasedProductIDs.contains(ProductID.scholarYearly.rawValue) {
            return .scholar
        } else if purchasedProductIDs.contains(ProductID.premiumYearly.rawValue) {
            return .premium
        }
        return .free
    }

    var isPremiumOrHigher: Bool {
        currentTier >= .premium
    }

    var isScholar: Bool {
        currentTier == .scholar
    }

    var premiumProduct: Product? {
        products.first { $0.id == ProductID.premiumYearly.rawValue }
    }

    var scholarProduct: Product? {
        products.first { $0.id == ProductID.scholarYearly.rawValue }
    }

    // MARK: - Initialization

    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load products and check entitlements
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    // Note: As a singleton, deinit is not called during app lifecycle.
    // The updateListenerTask will be cancelled when the app terminates.

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.checkVerified(result)
                    await self?.updatePurchasedProducts()
                    await transaction?.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)

            // Sort by price
            products.sort { $0.price < $1.price }
        } catch {
            self.error = .productLoadFailed(error.localizedDescription)
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchasedProducts()
                await transaction.finish()

                // Post notification
                NotificationCenter.default.post(
                    name: .subscriptionStatusChanged,
                    object: nil,
                    userInfo: ["tier": currentTier]
                )

                return transaction

            case .userCancelled:
                return nil

            case .pending:
                // Transaction is pending (e.g., Ask to Buy)
                return nil

            @unknown default:
                return nil
            }
        } catch {
            self.error = .purchaseFailed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            NotificationCenter.default.post(
                name: .subscriptionStatusChanged,
                object: nil,
                userInfo: ["tier": currentTier]
            )
        } catch {
            self.error = .restoreFailed(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if the subscription is still valid
                if let expirationDate = transaction.expirationDate,
                   expirationDate < Date() {
                    continue
                }

                purchased.insert(transaction.productID)
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }

        purchasedProductIDs = purchased
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw StoreError.verificationFailed(error.localizedDescription)
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Subscription Status

    func subscriptionStatus(for product: Product) async -> Product.SubscriptionInfo.Status? {
        guard let subscription = product.subscription else { return nil }

        do {
            let statuses = try await subscription.status
            return statuses.first { status in
                switch status.state {
                case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                    return true
                default:
                    return false
                }
            }
        } catch {
            return nil
        }
    }

    // MARK: - Check Trial Eligibility

    func isEligibleForTrial(_ product: Product) async -> Bool {
        guard let subscription = product.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    // MARK: - Manage Subscription

    @available(iOS 15.0, *)
    func showManageSubscriptions() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            print("Failed to show manage subscriptions: \(error)")
        }
    }
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case productLoadFailed(String)
    case purchaseFailed(String)
    case restoreFailed(String)
    case verificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .productLoadFailed(let message):
            return "Failed to load products: \(message)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .verificationFailed(let message):
            return "Verification failed: \(message)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

// MARK: - Entitlement Checking Extensions

extension PurchaseService {
    // Feature-level checks

    var canAccessAllTranslations: Bool {
        isPremiumOrHigher
    }

    var canAccessUnlimitedHighlights: Bool {
        isPremiumOrHigher
    }

    var canAccessUnlimitedAI: Bool {
        isPremiumOrHigher
    }

    var canAccessFullMemorization: Bool {
        isPremiumOrHigher
    }

    var canAccessHebrewGreek: Bool {
        isScholar
    }

    var canAccessAudioBible: Bool {
        isScholar
    }

    var canAccessVisualCards: Bool {
        isScholar
    }
}

// MARK: - Usage Limits for Free Tier

struct FreeTierLimits {
    static let dailyAIInsights = 3
    static let maxMemorizationVerses = 1
    static let maxHighlightsPerDay = 3
    static let maxNotesPerDay = 50  // Generous limit to prevent abuse while supporting real usage
    static let dailyPrayers = 10  // Free tier: 10 prayers/day
    static let dailyPrayersPremium = 100  // Premium tier: 100 prayers/day

    // Translations available in free tier
    static let freeTranslations = ["KJV"]
}
