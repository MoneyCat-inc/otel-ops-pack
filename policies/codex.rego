package codex.guardrails

import rego.v1

# Security violations that should always be denied
security_violations := [
    "dangerouslySetInnerHTML",
    "eval(",
    "innerHTML",
    "document.write",
    "setTimeout(",
    "setInterval("
]

# Accessibility violations that should be flagged
accessibility_violations := [
    "missing-alt-text",
    "missing-button-label",
    "missing-input-label",
    "missing-aria-label"
]

# Performance violations that should be monitored
performance_violations := [
    "inline-styles",
    "large-images",
    "unminified-js",
    "unminified-css"
]

# Policy budgets for automated fixes
budget := {
    "files": 10,
    "lines": 200,
    "violations": 50
}

# Check if a violation is a security violation
is_security_violation(violation) {
    some pattern in security_violations
    violation.rule contains pattern
}

# Check if a violation is an accessibility violation
is_accessibility_violation(violation) {
    some pattern in accessibility_violations
    violation.rule contains pattern
}

# Check if a violation is a performance violation
is_performance_violation(violation) {
    some pattern in performance_violations
    violation.rule contains pattern
}

# Get all security violations
security_violations_found := [v | 
    some i
    v := input.items[i]
    is_security_violation(v)
]

# Get all accessibility violations
accessibility_violations_found := [v | 
    some i
    v := input.items[i]
    is_accessibility_violation(v)
]

# Get all performance violations
performance_violations_found := [v | 
    some i
    v := input.items[i]
    is_performance_violation(v)
]

# Check if budget is exceeded
budget_exceeded := {
    "files": input.summary.files_touched > budget.files,
    "lines": input.summary.lines_touched > budget.lines,
    "violations": input.summary.violations > budget.violations
}

# Deny rules - these will cause the policy check to fail
deny[msg] {
    count(security_violations_found) > 0
    msg := sprintf("Security violation detected: %v", [security_violations_found])
}

deny[msg] {
    budget_exceeded.files
    msg := sprintf("File budget exceeded: %d > %d", [input.summary.files_touched, budget.files])
}

deny[msg] {
    budget_exceeded.lines
    msg := sprintf("Line budget exceeded: %d > %d", [input.summary.lines_touched, budget.lines])
}

deny[msg] {
    budget_exceeded.violations
    msg := sprintf("Violation budget exceeded: %d > %d", [input.summary.violations, budget.violations])
}

# Warn rules - these will generate warnings but not fail the policy check
warn[msg] {
    count(accessibility_violations_found) > 0
    msg := sprintf("Accessibility violations found: %v", [accessibility_violations_found])
}

warn[msg] {
    count(performance_violations_found) > 0
    msg := sprintf("Performance violations found: %v", [performance_violations_found])
}

# Policy summary
policy_summary := {
    "total_violations": count(input.items),
    "security_violations": count(security_violations_found),
    "accessibility_violations": count(accessibility_violations_found),
    "performance_violations": count(performance_violations_found),
    "budget_status": budget_exceeded,
    "policy_version": "1.0.0",
    "evaluated_at": time.now_ns()
}

# Compliance status
compliant := count(deny) == 0

# Risk assessment
risk_level := "low" if count(security_violations_found) == 0 else
              "medium" if count(security_violations_found) < 3 else
              "high"

# Recommendations
recommendations := [
    "Review security violations immediately" if count(security_violations_found) > 0 else null,
    "Address accessibility issues" if count(accessibility_violations_found) > 0 else null,
    "Optimize performance violations" if count(performance_violations_found) > 0 else null,
    "Consider increasing budget limits" if budget_exceeded.files or budget_exceeded.lines else null
]
