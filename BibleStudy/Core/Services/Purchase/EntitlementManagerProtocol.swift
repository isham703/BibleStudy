//
//  EntitlementManagerProtocol.swift
//  BibleStudy
//
//  Protocol abstraction for entitlement/quota management
//  Enables dependency injection and unit testing
//

import Foundation

// MARK: - Entitlement Manager Protocol

/// Protocol for feature access and quota management
/// Abstracts EntitlementManager for dependency injection
@MainActor
protocol EntitlementManagerProtocol: Sendable {
    /// Check if user can use AI insights without side effects
    var canUseAIInsights: Bool { get }

    /// Remaining AI insight quota for today
    var remainingAIInsights: Int { get }

    /// Record AI insight usage, returns true if allowed
    @discardableResult
    func recordAIInsightUsage() -> Bool
}

// MARK: - Conformance

extension EntitlementManager: EntitlementManagerProtocol {}
