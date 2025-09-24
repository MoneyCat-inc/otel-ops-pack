# CI Single Source of Truth — Deterministic vs Nightly

## Deterministic PR Lane
- **Browser**: Firefox (fake media, sendBeacon stub)
- **Workers**: 1
- **Retries**: 0
- **Suites**: `smoke`, `isolation`, `mic-flow`, `a11y-min`
- **Stubs**: microphone requests short-circuited, `navigator.sendBeacon` buffered for inspection

## Nightly Matrix & Quarantine
- **Browsers**: Chromium, Firefox, WebKit
- **Retries**: 2 (per project)
- **Suites**: Full Playwright tree (`tests/**/*.spec.ts`)
- **Objective**: Burn down flaky cross-browser specs while keeping PR signal deterministic

## Top Flakiest Specs (rolling 14 days)
| Rank | Spec | Failure rate | Notes |
| --- | --- | --- | --- |
| 1 | _(none observed)_ | 0% | All tracked specs passing in nightly matrix |

## Operational Notes
- Nightly workflow uploads Playwright reports for postmortems.
- Update this file when quarantining additional specs or when a flaky test graduates back into the PR lane.
