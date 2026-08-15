<!-- markdownlint-disable MD013 MD034 MD060 -->
# B2 Measurement — lychee link rot (live docs)

**Date:** 2026-08-15  
**Authority:** BossCat OEM · Second Pass Wave 2 B2  
**Actor:** Cursor{Implementer}  
**Grounded against:** archive-phase closeout branch (`docs/b1-archive-batch3-closeout`)  
**Tool:** lychee **0.20.1** (same major pin as docs_gate) with `.lychee.toml`

**Canonical command** (run from repo root; added on OEM verify — numbers without commands are claims):

```bash
lychee --config .lychee.toml --no-progress --max-redirects 5 --max-retries 2   --retry-wait-time 2 --max-concurrency 10 --format detailed   "docs/**/*.md" "README.md"   --exclude-path docs/archive --exclude-path docs/gate/archive   --exclude-path "docs/BossCat/Research"
```

## Scope

| Input | Count |
|-------|-------|
| Live markdown (`docs/**/*.md` + `README.md`) | **234** |
| Excluded | `docs/archive/**`, `docs/gate/archive/**`, `docs/BossCat/Research/**` (path-encoding / filed history) |

Measurement only — **no link fixes** in this commit.

## Results (aggregated chunked run)

| Class | Count |
|-------|------:|
| HTTP **404** hits (line events) | 10 |
| HTTP **403** hits (line events) | 8 |
| Relative / `file://` missing targets | 74 |
| Docs files with ≥1 error section | 23 |
| Unique broken `http(s)` URLs | **15** |

lychee process exit was non-zero (expected with failures). Detailed chunk logs retained under `.artifacts/` locally; unique broken HTTP URLs:

```text
https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/18463803215
https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/18629010288
https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/27414026380
https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/27414081486
https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/27414150700
https://github.com/MoneyCat-inc/otel-ops-pack/security/dependabot
https://github.com/MoneyCat-inc/otel-ops-pack/settings/pages
https://ko-fi.com/fubumaki
https://ko-fi.com/post/welcome-to-resonai-otel-v3e2219nlh
https://moneycat-inc.github.io/otel-ops-pack/status/LATEST.json
https://signoz.io/docs/instrumentation/otlp/
https://www.cvedetails.com/
https://www.nordicsemi.com/Products/Development-tools/nrf-connect-for-desktop
https://www.npmjs.com/package/@aws/bedrock-agentcore-mcp
https://www.patreon.com/posts/welcome-to-otel-141476152
```

## Notes for fix batches (not done here)

- Many `file://` errors are **relative links that resolved against the wrong directory** after moves (including pointers at archived `docs/gate/2025-10/…` paths) — fold with B1 cite updates.
- **403** on Ko-fi / Patreon / Nordic may be bot-blocking; prefer `#494` verify-live before replace, or annotate.
- Stale **Actions run** URLs are expected rot; replace with workflow badge / latest-run links or archive annotation.
- Re-run lychee after B1 fix batches before claiming zero unannotated 404s.

## Next

Fix/annotate in ≤10-file docs batches; every replacement URL verified live before use.

## Fix batch 1 (2026-08-15)

**Command** (same as measurement; re-run after this batch before claiming zero):

```bash
lychee --config .lychee.toml --no-progress --max-redirects 5 --max-retries 2 \
  --retry-wait-time 2 --max-concurrency 10 --format detailed \
  "docs/**/*.md" "README.md" \
  --exclude-path docs/archive --exclude-path docs/gate/archive \
  --exclude-path "docs/BossCat/Research"
```

| Class | Action (verified live before replace) |
|-------|----------------------------------------|
| Stale Actions run URLs | Point at workflow/Actions list; keep run ids as prose (`ENABLE_GATE_SITE_PROTECTION`, `RELEASE_NOTES`, `FOLLOWUP_SBOM_BLOCKING`) |
| `signoz.io/.../otlp/` 404 | → https://signoz.io/docs/instrumentation/ (200) in `adot-setup.md` |
| `cvedetails.com` 403/rot | → https://www.cve.org/ (200) in `DEPENDABOT_SECURITY_GUIDE.md` |
| Dead `@aws/bedrock-agentcore-mcp` | → AWS docs + awslabs MCP page (both 200); mcp.json examples use `uvx awslabs.amazon-bedrock-agentcore-mcp-server@latest` |
| `/settings/pages` private 404 | Annotate + link public Pages docs (200) in `HUB_GO_LIVE_RUNBOOK.md` |
| Nordic nRF URL bot-403 | Prefer SlimeVR web flasher link (200); drop direct Nordic href in VR setup |

**Deferred (bot-403 / auth / generated):** Ko-fi, Patreon, npmjs.com HTML, Dependabot UI links (already annotated private in places), `docs/BossCat/AGENTS.md` LATEST.json (generated registry).

## Fix batch 2 (2026-08-15)

| Action | Detail |
|--------|--------|
| `.lychee.toml` excludes | Bot-403: `ko-fi.com`, `patreon.com`; private UI: `…/security/dependabot`, `…/settings/` |
| Archive path cites | `README.md`, `GATE_MILESTONES.md`, `runbooks/signoz-api-proofs.md` → `docs/archive/gate/2025-10/…` |
| Own-the-debt | Touched markdown cleared to **0** under markdownlint (Summary match count) |

Still deferred: generated `AGENTS.md` LATEST.json; human re-verify of Ko-fi/Patreon when convenient (excluded from lychee, not deleted).
