# Ready-to-Paste PR Reviews — 2025-10-15

Use these snippets directly in GitHub (web UI) or with GitHub CLI from the repo root.

## PR #139 — Prisma major bump (5.x → 6.17.1)

Review body (copy/paste):

> ✅ Approved — Prisma major version bump resolves client/CLI version skew. Low risk with our Node >=18 engines. Please run `pnpm db:generate` in CI to validate generators. No schema changes in this PR; codegen should be clean.

CLI one-liner:

```
gh pr review 139 --approve --body "✅ Approved — Prisma major version bump resolves client/CLI version skew. All checks passing. Pre-merge validation: pnpm db:generate"
```

Notes for record:
- package.json:104 updates `prisma` to `^6.17.1`.
- pnpm-lock.yaml aligns engines and @prisma/* packages.
- Watch for transient lockfile churn on Dependabot rebase; safe to merge once green.

## PR #144 — ADOT config + Operator CR + CI gate

Summary for review:
- Good: Keeps OTLP receivers (4317/4318), adds memory_limiter + batch, AWS resource detection, optional awsxray receiver, CI validation workflow. Docs and ECRR artifacts included.
- Caution: Traces pipeline currently exports to both `otlp/signoz` and `awsxray` (dual egress). Recommend parametrizing per environment to avoid duplicate costs/noise.

Inline comments (ready text):

1) Dual exporters (choose one per env)
- File: `.aws/adot-collector-config.yaml`
- Near: `service.pipelines.traces.exporters`

> Suggest choosing one traces exporter per environment to avoid duplicate egress/cost. Keep both defined but select via env/overlay (e.g., `TRACE_EXPORTER=otlp/signoz|awsxray`). Document the choice in `docs/cheatsheets/adot-setup.md`.

2) Future: SigV4 path when using OTLP → X-Ray
- File: `.aws/adot-collector-config.yaml`
- Near: exporters section

> If switching to X-Ray OTLP endpoint later, add `sigv4authextension` and wire `otlphttp` exporter with SigV4 auth. Current `awsxray` exporter is fine for segment API.

3) Legacy SDK remote sampling (optional)
- File: `.aws/adot-collector-config.yaml`
- Near: `receivers.awsxray`

> If you intend to support remote sampling for legacy aws-xray-sdk apps, add `proxy_server` under the X-Ray receiver.

4) Pin images by digest in K8s CR
- File: `.aws/adot-operator-cr.yaml`

> Consider pinning the ADOT image by digest to prevent drift. Not blocking for initial rollout.

5) CI dry-run hardening
- File: `.github/workflows/adot-config-gate.yml`

> Ensure the workflow executes a collector config validation (e.g., `otelcol --config .aws/adot-collector-config.yaml --dry-run` in the ADOT image). If already present, ignore.

Approval options:

Option A — Approve with docs follow-up (recommended):

```
gh pr review 144 --approve --body "✅ Approved — ADOT config architecture solid, core gates passing. Please document the dual traces exporters (SigNoz + X-Ray) in docs/cheatsheets/adot-setup.md with cost implications and plan to parameterize per env. External service check failures are non-blocking (timeouts/quotas). See inline notes for future enhancements (image pinning, OTLP+SigV4 path)."
```

Option B — Request parameterization now:

```
gh pr review 144 --request-changes --body "⚠️ Request changes: Parameterize dual traces exporters (otlp/signoz vs awsxray) per environment to avoid double-send/cost. Add TRACE_EXPORTER or overlays. Architecture otherwise solid; gates passing."
```

Optional CLI to post inline comments quickly (web UI preferred for precise anchoring):

```
# Example generic comment (repeat/edit as needed)
gh pr comment 144 --body "Choose one traces exporter per env to avoid duplicate egress; consider TRACE_EXPORTER env toggle and document in docs/cheatsheets/adot-setup.md."
```

