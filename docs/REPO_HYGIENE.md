# 🔧 Repo Hygiene (OTel Ops Pack)

## 1) Structure & metadata

* `README.md` (60-sec quickstart, supported OS, ports 4317/4318/… , env vars, "Run & Verify", Rollback link)
* `LICENSE` • `SECURITY.md` • `CONTRIBUTING.md` • `CODE_OF_CONDUCT.md`
* `.editorconfig` • `.gitattributes` (normalize line endings) • `.gitignore`
* `docs/` (RUN_AND_VERIFY.md, ROLLBACK.md, TROUBLESHOOTING.md, ALERTS_SIGNOZ.md)
* `configs/otel/*.yaml` (collectors) • `compose/*.yml` (SigNoz, etc.)
* `scripts/` (PowerShell/Bash) • `artifacts/` (git-ignored; script outputs)
* `.github/ISSUE_TEMPLATE/*.yml` • `.github/PULL_REQUEST_TEMPLATE.md`

## 2) PowerShell quality (Windows-first)

* Every script: `Set-StrictMode -Version Latest` and `$ErrorActionPreference='Stop'`
* Parameterized (`[Parameter(Mandatory=$true)]`) + `#requires -RunAsAdministrator` if needed
* Idempotent installers/services/scheduled tasks; safe re-runs don't duplicate
* Logging: `Start-Transcript` to `artifacts\logs\*.txt`; structured Write-Host levels
* Defensive paths (`Join-Path`), quotes for spaces, retry/backoff on network ops
* Uninstall/cleanup counterparts (`remove-*.ps1`) for every install script

## 2a) YAML fix-it playbook (priority files)

* `ai-assistant-config.yaml` — run `pwsh .\tools\fix-yaml.ps1`, then fold long multi-line strings with `>` if yamllint still warns on line length.
* `config*.yaml` (OTel pipelines) — keep list entries under `processors:`/`exporters:` on their own lines and watch for duplicate keys when cloning pipelines.
* `docker-compose.yml` — stick to two-space indents, quote port maps ("4318:4318"), and normalize `environment:` blocks:

  ```yaml
  environment:
    - OTLP_ENDPOINT=http://otel-collector:4318
  ```

* Fast format: run `pwsh .\tools\fix-yaml.ps1` or `pre-commit run --all-files` before committing.

## 3) OTel correctness gates

* Config lint: `otelcol --config configs/otel/collector.yaml --dry-run`
* Compose lint: `docker compose -f compose/signoz.yml config`
* Canary: scheduled script that emits **traces + logs**; one-click `verify-canary.ps1`
* Health probes: check ports, `/healthz`, and backend ingestion; write PASS/FAIL to `artifacts/verify.txt`

## 4) Security & secrets

* No real secrets in repo; include `.env.example` with comments
* Use GitHub OIDC or repo secrets (no plaintext tokens)
* Dependabot updates (Actions + Docker + npm/nuget as applicable)
* CodeQL workflow + container scan (e.g., Trivy) + pin critical images by digest

## 5) CI/CD minimal but strict

* **CI** jobs:
  * PSScriptAnalyzer (`Invoke-ScriptAnalyzer`) with zero warnings
  * `yamllint` for YAML; `actionlint` for GH Actions
  * `otelcol --dry-run` on all `configs/otel/*.yaml`
  * Optional: Pester unit tests for utility functions
* **Release** job:
  * Build an **air-gapped bundle**: `configs/`, `scripts/`, `docs/quickstart.md`, checksums
  * Tag SemVer + generate `CHANGELOG.md` (Keep a Changelog)

## 6) Docs that save on-call time

* `RUN_AND_VERIFY.md`: start → verify → common failures → exact commands
* `ROLLBACK.md`: stop services, remove tasks/containers, restore previous config
* `TROUBLESHOOTING.md`: port conflicts, certs, Windows service gotchas, WSL notes
* **Port map table** and **data flow diagram** (agent → collector → backend)

## 7) Governance & safety rails

* Branch protection on `main` (PR required, CI required, linear history optional)
* Required reviewers for `configs/otel/*` and `compose/*`
* PR template with: summary, risks, verification steps, rollback plan, screenshots/logs
* Small, labeled issues: **feat/chore/fix/docs/ops** with acceptance criteria

---

## 🔎 Quick self-audit commands (copy/paste)

**PowerShell (from repo root):**

```powershell
# structure snapshot
Get-ChildItem -Recurse -File | Select-Object FullName | Out-File artifacts\tree.txt

# pwsh lint
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path scripts -Recurse -EnableExit

# otel config dry-run (adjust path/file names)
otelcol --config configs\otel\collector.yaml --dry-run

# docker compose sanity
docker compose -f compose\signoz.yml config

# canary verify (your script)
.\scripts\verify-canary.ps1
```

**Secret scan (optional, local):**

```powershell
# if you use gitleaks
gitleaks detect --source . --report-path artifacts\gitleaks.json
```

## ✅ What "good" looks like (pass/fail gates)

* ✅ CI green: PSScriptAnalyzer/yamllint/actionlint/otelcol dry-run all pass
* ✅ verify-canary.ps1 writes PASS with counts for traces/logs in last 5–10 min
* ✅ artifacts/ contains logs, verification output, and PDF/HTML quickstart where useful
* ✅ No secrets committed; .env.example present and clear
* ✅ Rollback doc verified (actually tested once per release)## Branch Protection & Required Checks

Run the following once (requires repo admin):

```bash
# Set branch protection with required statuses (update owner/repo if forked)
gh api \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/fubumaki/otel-ops-pack/branches/main/protection \
  -f required_pull_request_reviews='{"required_approvals":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
  -f required_status_checks='{"strict":true,"contexts":["Hygiene","CodeQL","Gitleaks","Pester"]}' \
  -f enforce_admins=true \
  -f restrictions='null' \
  -f required_linear_history=true \
  -f allow_force_pushes=false \
  -f allow_deletions=false \
  -f block_creations=true

# Optional: require signed commits
gh api -X PUT \
  /repos/fubumaki/otel-ops-pack/branches/main/protection \
  -f required_signatures=true

# Seed labels for triage
gh label create "hygiene" --color 0366d6 --description "Repo hygiene & lint fixes" || true
gh label create "otel" --color 0e8a16 --description "OpenTelemetry configs & pipelines" || true
gh label create "yaml" --color c2e0c6 --description "YAML schema/format issues" || true
gh label create "powershell" --color d4c5f9 --description "PowerShell scripts" || true
gh label create "good first issue" --color 7057ff --description "Low-risk starter task" || true
```

## Local Hooks

Install Lefthook and enable the quick hygiene gate:

```bash
# macOS/Linux
brew install lefthook || curl -s https://raw.githubusercontent.com/evilmartians/lefthook/master/scripts/install.sh | bash
lefthook install

# Windows (Scoop example)
scoop bucket add main
scoop install lefthook
lefthook install

# Run fast hygiene locally
pwsh ./tools/hygiene-fast.ps1

# Full suite remains
npm run hygiene
```
