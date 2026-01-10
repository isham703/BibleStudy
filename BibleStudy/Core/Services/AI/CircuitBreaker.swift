import Foundation

// MARK: - Circuit Breaker
// Prevents cascading failures during OpenAI outages by failing fast
// Standard closed/open/halfOpen state machine pattern

actor CircuitBreaker {
    // MARK: - State

    enum State {
        case closed      // Normal operation - requests flow through
        case open        // Circuit tripped - fail fast without calling service
        case halfOpen    // Testing recovery - allow single trial request
    }

    // MARK: - Configuration

    /// Number of consecutive failures before opening circuit
    private let failureThreshold: Int

    /// Time to wait before attempting recovery
    private let resetTimeout: TimeInterval

    /// Maximum failures to track for threshold
    private let maxTrackedFailures: Int = 100

    // MARK: - Tracking

    private var state: State = .closed
    private var consecutiveFailures: Int = 0
    private var lastFailureTime: Date?
    private var lastStateChange: Date = Date()
    private var trialRequestInFlight: Bool = false

    // MARK: - Singleton

    static let shared = CircuitBreaker()

    // MARK: - Initialization

    init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 60) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }

    // MARK: - Public Interface

    /// Check if request should be allowed through
    /// - Returns: true if request can proceed, false if circuit is open
    func shouldAllowRequest() -> Bool {
        switch state {
        case .closed:
            return true

        case .open:
            // Check if enough time has passed to try recovery
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) >= resetTimeout,
               !trialRequestInFlight {
                state = .halfOpen
                trialRequestInFlight = true
                lastStateChange = Date()
                print("⚡️ CircuitBreaker: transitioning to halfOpen (testing recovery)")
                return true  // Allow single trial request
            }
            return false

        case .halfOpen:
            // In half-open, reject additional requests while trial is in flight
            return false
        }
    }

    /// Record a successful request - resets failure count
    func recordSuccess() {
        trialRequestInFlight = false  // Always reset trial flag

        switch state {
        case .halfOpen:
            // Recovery successful - close circuit
            state = .closed
            consecutiveFailures = 0
            lastFailureTime = nil
            lastStateChange = Date()
            print("⚡️ CircuitBreaker: recovery successful, circuit CLOSED")

        case .closed:
            // Normal operation - reset failure count
            consecutiveFailures = 0

        case .open:
            // Shouldn't happen, but handle gracefully
            break
        }
    }

    /// Record a failed request - may trip circuit
    func recordFailure() {
        trialRequestInFlight = false  // Always reset trial flag
        consecutiveFailures += 1
        lastFailureTime = Date()

        switch state {
        case .closed:
            if consecutiveFailures >= failureThreshold {
                state = .open
                lastStateChange = Date()
                print("⚡️ CircuitBreaker: threshold reached (\(failureThreshold) failures), circuit OPEN")
            }

        case .halfOpen:
            // Trial request failed - reopen circuit
            state = .open
            lastStateChange = Date()
            print("⚡️ CircuitBreaker: trial request failed, circuit reopened")

        case .open:
            // Already open - nothing to do
            break
        }
    }

    /// Get current circuit state for monitoring/debugging
    var currentState: State {
        state
    }

    /// Get consecutive failure count
    var failureCount: Int {
        consecutiveFailures
    }

    /// Time until circuit may attempt recovery (if open)
    var timeUntilRetry: TimeInterval? {
        guard state == .open, let lastFailure = lastFailureTime else {
            return nil
        }
        let elapsed = Date().timeIntervalSince(lastFailure)
        let remaining = resetTimeout - elapsed
        return remaining > 0 ? remaining : 0
    }

    /// Reset circuit breaker to closed state (for testing/admin)
    func reset() {
        state = .closed
        consecutiveFailures = 0
        lastFailureTime = nil
        lastStateChange = Date()
        trialRequestInFlight = false
        print("⚡️ CircuitBreaker: manually reset to CLOSED")
    }
}

// MARK: - Circuit Breaker Error

enum CircuitBreakerError: LocalizedError {
    case circuitOpen(retryAfter: TimeInterval?)

    var errorDescription: String? {
        switch self {
        case .circuitOpen(let retryAfter):
            if let seconds = retryAfter {
                return "Service temporarily unavailable. Please try again in \(Int(seconds)) seconds."
            }
            return "Service temporarily unavailable. Please try again later."
        }
    }
}
