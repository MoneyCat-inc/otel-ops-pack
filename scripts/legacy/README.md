# Legacy root scripts

Moved from repo root in Second Pass Q3 (2026-08-15). Selection: root `*.ps1` with zero code/CI references (`git grep` over `scripts/`, `BRAV/`, `.github/`, `package.json`, `lefthook.yml`). Run-cards/docs may still cite them — use `scripts/legacy/<name>`.

`canary-check.ps1` was measured zero-ref but left at root this batch (hygiene PSSA on Username/Password params); track under B4.

Do not add new scripts here; archive or delete when citations are gone.
