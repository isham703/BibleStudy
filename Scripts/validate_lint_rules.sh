#!/bin/bash
# validate_lint_rules.sh
# Validates that SwiftLint custom rules are working correctly
# Run from project root: ./Scripts/validate_lint_rules.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Validating SwiftLint design system rules..."
echo ""

# Use test-specific config without path restrictions
TEST_CONFIG="Scripts/LintTests/.swiftlint-test.yml"

# Test GoodExamples.swift - should have 0 violations
echo "Testing GoodExamples.swift (expecting 0 violations)..."
GOOD_OUTPUT=$(swiftlint lint Scripts/LintTests/GoodExamples.swift --config "$TEST_CONFIG" 2>&1)
GOOD_COUNT=$(echo "$GOOD_OUTPUT" | grep -c "warning:" || true)

if [ "$GOOD_COUNT" -eq 0 ]; then
    echo "✓ GoodExamples.swift: 0 violations (PASS)"
else
    echo "✗ GoodExamples.swift: $GOOD_COUNT violations (FAIL)"
    echo "$GOOD_OUTPUT" | grep "warning:"
fi

echo ""

# Test BadExamples.swift - should have violations
echo "Testing BadExamples.swift (expecting violations)..."
BAD_OUTPUT=$(swiftlint lint Scripts/LintTests/BadExamples.swift --config "$TEST_CONFIG" 2>&1)
BAD_COUNT=$(echo "$BAD_OUTPUT" | grep -c "warning:" || true)

if [ "$BAD_COUNT" -gt 0 ]; then
    echo "✓ BadExamples.swift: $BAD_COUNT violations detected (PASS)"
else
    echo "✗ BadExamples.swift: 0 violations detected (FAIL - rules may be broken)"
fi

echo ""

# Summary
if [ "$GOOD_COUNT" -eq 0 ] && [ "$BAD_COUNT" -gt 0 ]; then
    echo "================================"
    echo "✓ All lint rule tests PASSED"
    echo "================================"
    exit 0
else
    echo "================================"
    echo "✗ Lint rule tests FAILED"
    echo "================================"
    exit 1
fi
