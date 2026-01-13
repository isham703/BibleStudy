//
//  MockEntitlementService.swift
//  BibleStudyTests
//
//  Mock entitlement manager for unit testing
//

import Foundation
@testable import BibleStudy

// MARK: - Mock Entitlement Manager

@MainActor
final class MockEntitlementService: EntitlementManagerProtocol {
    // MARK: - Configuration

    var canUseAIInsights: Bool = true
    var remainingAIInsights: Int = 10

    // MARK: - Call Tracking

    var recordAIInsightUsageCallCount = 0
    var recordAIInsightUsageReturnValue = true

    // MARK: - Protocol Methods

    @discardableResult
    func recordAIInsightUsage() -> Bool {
        recordAIInsightUsageCallCount += 1
        return recordAIInsightUsageReturnValue
    }

    // MARK: - Test Helpers

    /// Simulate user at limit
    func simulateLimitReached() {
        canUseAIInsights = false
        remainingAIInsights = 0
        recordAIInsightUsageReturnValue = false
    }

    /// Simulate user with remaining quota
    func simulateQuotaAvailable(remaining: Int = 10) {
        canUseAIInsights = true
        remainingAIInsights = remaining
        recordAIInsightUsageReturnValue = true
    }

    /// Reset to default state
    func reset() {
        canUseAIInsights = true
        remainingAIInsights = 10
        recordAIInsightUsageReturnValue = true
        recordAIInsightUsageCallCount = 0
    }
}
