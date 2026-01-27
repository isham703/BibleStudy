import Foundation
import Supabase

// MARK: - Feature Flag Service
// Remote feature flags backed by Supabase with UserDefaults cache.
// Fail-open: features default to enabled if network unavailable.
// Fetched on app launch and foreground resume.

@MainActor
@Observable
final class FeatureFlagService {
    static let shared = FeatureFlagService()

    // MARK: - Public State

    /// Whether live captions feature is remotely enabled (kill switch)
    private(set) var isLiveCaptionsEnabled: Bool = true

    // MARK: - Private State

    private let supabase = SupabaseManager.shared
    private var lastFetchDate: Date?

    // Cache keys
    private enum CacheKeys {
        static let liveCaptionsKillSwitch = "featureFlag.liveCaptionsEnabled"
        static let lastFetchDate = "featureFlag.lastFetchDate"
    }

    /// Staleness threshold — refetch if cache is older than this
    private static let cacheStaleInterval: TimeInterval = 6 * 60 * 60 // 6 hours

    // MARK: - Init

    private init() {
        loadCachedFlags()
    }

    // MARK: - Public API

    /// Fetch feature flags from Supabase. Safe to call frequently — respects cache staleness.
    func fetchFlags() async {
        // Skip if cache is fresh
        if let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < Self.cacheStaleInterval {
            return
        }

        await forceFetchFlags()
    }

    /// Force-fetch flags regardless of cache staleness. Use on foreground resume.
    func forceFetchFlags() async {
        do {
            let flags: [FeatureFlagDTO] = try await supabase.client
                .from("feature_flags")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value

            // Apply flags
            for flag in flags {
                switch flag.key {
                case "live_captions_enabled":
                    isLiveCaptionsEnabled = flag.enabled
                default:
                    break
                }
            }

            // Update cache
            lastFetchDate = Date()
            persistFlags()

        } catch {
            // Fail-open: keep current cached values (default: enabled)
            print("[FeatureFlagService] Failed to fetch flags: \(error.localizedDescription)")
        }
    }

    // MARK: - Cache

    private func loadCachedFlags() {
        let defaults = UserDefaults.standard

        // Load cached live captions flag (default: true = fail-open)
        if defaults.object(forKey: CacheKeys.liveCaptionsKillSwitch) != nil {
            isLiveCaptionsEnabled = defaults.bool(forKey: CacheKeys.liveCaptionsKillSwitch)
        }

        // Load last fetch date
        if let date = defaults.object(forKey: CacheKeys.lastFetchDate) as? Date {
            lastFetchDate = date
        }
    }

    private func persistFlags() {
        let defaults = UserDefaults.standard
        defaults.set(isLiveCaptionsEnabled, forKey: CacheKeys.liveCaptionsKillSwitch)
        defaults.set(lastFetchDate, forKey: CacheKeys.lastFetchDate)
    }
}

// MARK: - Feature Flag DTO

private struct FeatureFlagDTO: Decodable {
    let key: String
    let enabled: Bool
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case key
        case enabled
        case isActive = "is_active"
    }
}
