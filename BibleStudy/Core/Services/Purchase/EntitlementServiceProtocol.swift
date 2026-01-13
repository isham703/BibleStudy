//
//  EntitlementServiceProtocol.swift
//  BibleStudy
//
//  Protocol abstraction for entitlement/quota management
//  Enables dependency injection and unit testing
//

import Foundation

// MARK: - Entitlement Manager Protocol

/// Protocol for feature access and quota management
/// Abstracts EntitlementService for dependency injection
@MainActor
protocol EntitlementServiceProtocol: Sendable {
    /// Check if user can use AI insights without side effects
    var canUseAIInsights: Bool { get }

    /// Remaining AI insight quota for today
    var remainingAIInsights: Int { get }

    /// Record AI insight usage, returns true if allowed
    @discardableResult
    func recordAIInsightUsage() -> Bool
}

// MARK: - Conformance

extension EntitlementService: EntitlementServiceProtocol {}
