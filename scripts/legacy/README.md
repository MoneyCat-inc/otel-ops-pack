# Legacy Scripts

Scripts relocated here from the repository root during the 2026-08-14 deep-clean pass.

## Why these moved

The repository root had accumulated **75 PowerShell scripts**, which made the project
look far more complex than it is to anyone opening it for the first time. Each script
in this directory was verified to have **zero references from live surfaces** before
being moved — that is, nothing in `package.json`, `.github/workflows/`, `scripts/`,
`BRAV/`, `compose/`, or the active runbooks under `docs/` invokes them.

Scripts that *are* still wired into live surfaces were deliberately **left at the root**
so that nothing breaks. See the "Still at root" section below.

## What is here

| Bucket | Contents |
|---|---|
| `setup/` | One-time environment, commit-template, and migration helpers |
| `test/` | Ad-hoc test harnesses and validation spot-checks |
| `verify/` | Pipeline and collector verification one-offs |
| `ops/` | Cleanup, monitoring, alert-import, GPU, and PR utilities |

`ops/run-gpu-analysis.ps1` resolves `gpu-voice-analysis.py` via `$PSScriptRoot`, so that
Python file was moved with it to keep the pair intact.

## Status

These are **kept, not endorsed**. They are historical operational tooling: useful as
reference, but unverified against the current stack. Before relying on one, check it
against the live system rather than assuming it still works.

If you find one of these is genuinely needed on an ongoing basis, promote it out of
`legacy/` into `scripts/` proper and wire it into `package.json` so it stops being
invisible.

## Still at root

39 root scripts were **not** moved because live references to them exist. The most
heavily referenced are `verify-pipeline.ps1`, `canary-test.ps1`, `health-check.ps1`,
`send-canary-trace-direct.ps1`, and the `gate-self-signal-*` pair.

Note that `verify-pipeline.ps1` and `verify-integration.ps1` each exist at **both** the
repository root and under `BRAV/SCPT/`, with **different contents**. That ambiguity
predates this cleanup and is called out in the deep-clean report rather than silently
resolved here.
