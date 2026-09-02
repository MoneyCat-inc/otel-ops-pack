# AntiClickbait Portal Notes

**Date:** 2025-10-16  
**Author:** Cursor{Implementer}

> **Record (2025-10-16).** `portal.html` and `.github/FUNDING.yml` are still in this repo, but the
> public site and social lanes moved to `moneycat-site` and `socm` in Pack 3B (2026-07-24) —
> check those repos before extending the portal here.

Portal assets provide a simple public landing page that mirrors the transparency
bundle and surfaces donation links once approved.

## Files

- `.github/FUNDING.yml` – enables the GitHub Sponsors button (placeholders for Ko-fi and Patreon are commented out).
- `portal.html` – single-page portal that summarises the project, features, getting-started steps, and donation section.

## Structure Highlights

`portal.html` is self-contained (HTML + inline CSS) to minimise deployment friction.
It shares the Comfort Cat design tokens used elsewhere in the repo and includes:

- Hero section with value proposition and quick links.
- Honest summary of what the project can and cannot do.
- Feature grid grouped by automation, observability, governance, and design.
- Getting-started steps with copy-paste commands for Windows environments.
- Support section that will host donation buttons once BossCat OEM approves the strategy.

## Next Steps

- Update the support section once the funding decision is recorded in `docs/BossCat/misc/BOSSCAT_ANTICLICKBAIT_DECISION_REQUIRED.md`.
- Capture screenshots or metrics to reinforce claims when presenting the portal publicly.
- Add integration tests if the portal becomes part of the automated release lane.
