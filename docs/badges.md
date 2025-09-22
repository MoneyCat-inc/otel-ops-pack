# 🏷️ Resonai Project Badges

This file contains ready-to-use status badges for the Resonai project.
Swap these into the root `README.md` or other docs as the project evolves.

---

## 📊 ECRR Status (Executive • Contributions • Risks • Readiness)

**Current:**
[![ECRR Status](https://img.shields.io/badge/ECRR-Cohort--Ready-green?style=flat-square)](docs/reports/ECRR_REPORT.md)

**Variants:**
- Research Phase  
  [![ECRR Status](https://img.shields.io/badge/ECRR-Research--Phase-lightgrey?style=flat-square)](docs/reports/ECRR_REPORT.md)
- Alpha Prototype  
  [![ECRR Status](https://img.shields.io/badge/ECRR-Alpha--Prototype-orange?style=flat-square)](docs/reports/ECRR_REPORT.md)
- Beta Cohort  
  [![ECRR Status](https://img.shields.io/badge/ECRR-Beta--Cohort-yellow?style=flat-square)](docs/reports/ECRR_REPORT.md)
- Cohort-Ready  
  [![ECRR Status](https://img.shields.io/badge/ECRR-Cohort--Ready-green?style=flat-square)](docs/reports/ECRR_REPORT.md)
- Production Ready  
  [![ECRR Status](https://img.shields.io/badge/ECRR-Production--Ready-brightgreen?style=flat-square)](docs/reports/ECRR_REPORT.md)
- Audit Complete  
  [![ECRR Status](https://img.shields.io/badge/ECRR-Audit--Complete-blue?style=flat-square)](docs/reports/ECRR_REPORT.md)
- Risks Pending  
  [![ECRR Status](https://img.shields.io/badge/ECRR-Risks--Pending-red?style=flat-square)](docs/reports/ECRR_REPORT.md)

---

## 🧭 ECRR Project Report (Cross-Project Summary)

Use this badge to link directly to the cross-project ECRR summary report:

```markdown
[![ECRR Project Report](https://img.shields.io/badge/ECRR%20Project%20Report-available-7c5cff?style=flat-square)](docs/ECRR_PROJECT_REPORT.md)
```

When placing inside a page under `docs/`, use this relative link instead:

```markdown
[![ECRR Project Report](https://img.shields.io/badge/ECRR%20Project%20Report-available-7c5cff?style=flat-square)](ECRR_PROJECT_REPORT.md)
```

---

## ⚙️ CI/CD Status

These badges track GitHub Actions workflows.
Replace `YOUR_REPO` with the actual repo slug (`owner/repo`).

- Build & Test (CI)  
  [![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
- E2E Tests (Windows)  
  [![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
- Nightly Tests  
  [![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)

---

## 🧪 Test Coverage & Quality

Use services like Codecov or Coveralls for coverage reporting.

- Coverage (Codecov example)  
  [![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)
- Lint & Type Check  
  [![Lint & Types](https://img.shields.io/badge/Lint%20%26%20Types-passing-brightgreen?style=flat-square)](docs/RUNBOOK_INDEX.md)

---

## 🔧 Usage

1. Copy the badge you want from this file.
2. Paste it into the destination Markdown (README or docs page).
3. Commit the change with a message like:

```bash
git add README.md
git commit -m "docs: update badges in README"
git push
```

📌 Link targets:
- When pasting into the root `README.md`, use `docs/reports/ECRR_REPORT.md` in links.
- When pasting into a page inside `docs/`, use `reports/ECRR_REPORT.md`.

---

## 📦 README Badge Bundle

Copy-paste this block at the top of `README.md` to show all key project status indicators:

```markdown
[![ECRR Status](https://img.shields.io/badge/ECRR-Cohort--Ready-green?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)
```

📌 Replace `YOUR_REPO` with the actual GitHub repo slug (for example `fubumaki/otel-ops-pack`).

---

## 🔄 Variant Rows (ECRR stages)

Each row below shows ECRR + CI + E2E + Nightly + Coverage.
Copy/paste the one matching your current project stage into the top of `README.md`.

```markdown
<!-- Research Phase -->
[![ECRR Status](https://img.shields.io/badge/ECRR-Research--Phase-lightgrey?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)

<!-- Alpha Prototype -->
[![ECRR Status](https://img.shields.io/badge/ECRR-Alpha--Prototype-orange?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)

<!-- Beta Cohort -->
[![ECRR Status](https://img.shields.io/badge/ECRR-Beta--Cohort-yellow?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)

<!-- Cohort-Ready -->
[![ECRR Status](https://img.shields.io/badge/ECRR-Cohort--Ready-green?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)

<!-- Production Ready -->
[![ECRR Status](https://img.shields.io/badge/ECRR-Production--Ready-brightgreen?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)

<!-- Audit Complete -->
[![ECRR Status](https://img.shields.io/badge/ECRR-Audit--Complete-blue?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)

<!-- Risks Pending -->
[![ECRR Status](https://img.shields.io/badge/ECRR-Risks--Pending-red?style=flat-square)](docs/reports/ECRR_REPORT.md)
[![CI](https://github.com/YOUR_REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/ci.yml)
[![E2E Windows](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-win.yml)
[![Nightly](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml/badge.svg)](https://github.com/YOUR_REPO/actions/workflows/e2e-nightly.yml)
[![codecov](https://codecov.io/gh/YOUR_REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/YOUR_REPO)
```

📌 Replace `YOUR_REPO` with the actual GitHub repo slug before committing.

---

## 🖼️ Visual Previews

Badges rendered for quick visual checks:

- `docs/Badges/README_Badge_Row_preview.png`
- `docs/Badges/README_Badge_Rows_AllVariants.png`

These PNGs are reference only; they are ignored by Git as they are regenerated locally.

---

📌 All badges should point to actionable docs or workflows:

- ECRR -> `docs/reports/ECRR_REPORT.md`
- CI/CD -> GitHub Actions workflows
- Coverage -> Codecov or Coveralls dashboards
- Lint & Types -> relevant local docs/runbooks
