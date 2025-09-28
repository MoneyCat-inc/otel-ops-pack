package codex.guardrails

default allow = true
default deny  = []

# Security: forbid dangerouslySetInnerHTML
deny[msg] {
  some i
  item := input.items[i]
  item.id == "dangerouslySetInnerHTML"
  msg := sprintf("dangerouslySetInnerHTML at %s:%v", [item.file, item.line])
}

# Budget: enforce per-run fix budgets
deny[msg] {
  input.summary.files_touched > input.policy.budget.files
  msg := sprintf("files_touched %v exceeds budget %v",
                  [input.summary.files_touched, input.policy.budget.files])
}

deny[msg] {
  input.summary.lines_touched > input.policy.budget.lines
  msg := sprintf("lines_touched %v exceeds budget %v",
                  [input.summary.lines_touched, input.policy.budget.lines])
}

# Global decision for CI
allow {
  count(deny) == 0
}
