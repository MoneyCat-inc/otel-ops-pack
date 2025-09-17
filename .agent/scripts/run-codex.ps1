# 1) Pick next task
$queue = Get-Content ".\.agent\state\queue.jsonl" -Raw | Out-String
if (-not $queue) { Write-Host "No tasks."; exit 0 }
$lines = Get-Content ".\.agent\state\queue.jsonl"
$next = $lines | Select-Object -First 1
$task = $next | ConvertFrom-Json

# 2) Ask codex-local to plan/implement/test (Cursor chat with codex.prompt.md loaded)
# (In Cursor: open a new chat with system prompt set to .agent/codex.prompt.md and paste $task)
Write-Host ">>> Feed this task to codex-local:"
$task | ConvertTo-Json -Depth 10

# 3) After codex returns, apply DIFF and run smoke
# (Alternatively let codex return a PR and you review with cursor-local)

