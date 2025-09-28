param(
  [string]$BranchPrefix = "fix/codex-local",
  [string]$Title = "codex-local autofix: guardrails & docs",
  [string]$BodyFile = ".agent/_autopr_body.md",
  [string]$Label = "codex-auto"
)
$ErrorActionPreference = "Stop"

# guard: nothing to commit
$st = (git status --porcelain)
if (-not $st) { Write-Host "No changes to commit."; exit 0 }

$branch = "$BranchPrefix-$(Get-Date -Format yyyyMMdd-HHmmss)"
git checkout -b $branch
git add -A
git commit -m "$Title"

# create body
$body = @(
  "# codex-local autofix",
  "",
  "* Automated guardrails/doc refresh.",
  "* See attached artifacts in CI for details.",
  ""
) -join "`n"
$body | Set-Content $BodyFile -Encoding UTF8

gh pr create --title "$Title" --body-file "$BodyFile" --label "$Label" --fill
Write-Host "Opened PR from $branch"
