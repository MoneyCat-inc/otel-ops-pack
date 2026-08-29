# Patreon weekly maintenance — Resonai [OTel]

**Cadence:** every **7 days** (recommended: Monday morning)  
**Page:** <https://www.patreon.com/c/FaeMcLachlan>  
**Owner:** Fubumaki (creator) · **Agent cue:** run `pwsh -File scripts/patreon-weekly-reminder.ps1` when overdue

---

## Quick run

```powershell
# Check status (prints checklist if due)
pwsh -File scripts/patreon-weekly-reminder.ps1

# After finishing the checklist
pwsh -File scripts/patreon-weekly-reminder.ps1 -MarkComplete
```

Register a Windows weekly reminder (current user, Mondays 10:00):

```powershell
pwsh -File scripts/patreon-weekly-reminder.ps1 -RegisterScheduledTask
```

State file: `artifacts/patreon-maintenance-state.json` (last completed + next due).

---

## Weekly checklist (ECRR)

### Examine (5 min)

- [ ] Open creator dashboard — page still **published** (no “unpublished” banner)
- [ ] Membership tab — all **3 tiers** visible: Verifier ($5), Signal Booster ($15), Gatekeeper ($50)
- [ ] Welcome post **free access** — public visitors can read it
- [ ] About/tagline still matches repo: evidence-first OTel, GitHub `MoneyCat-inc/otel-ops-pack`
- [ ] Payouts — no failed payouts or action-required alerts

### Clean (10 min)

- [ ] Reply to patron comments/DMs (target: within 24–48h)
- [ ] Fix broken links (GitHub, portal, README Patreon badge, Ko-fi cross-link in welcome post)
- [ ] Update tier copy only if project capabilities changed (anti-clickbait: no hype)
- [ ] Optional: upload/refine cover or profile image (Comfort Cat palette `#7C5CFF`)

### Report (5 min)

- [ ] Note patron count + MRR in `artifacts/patreon-maintenance-state.json` (`notes` field) or BossCat log
- [ ] If material change: add a short Patreon post or refresh welcome post date
- [ ] Run `-MarkComplete` so the next reminder is +7 days

### Role

- **Fubumaki:** payouts, patron comms, publish decisions, media uploads
- **Agent:** scripted status check, copy alignment with README/portal, ECRR note in artifacts

---

## Alignment references

| Item | Canonical source |
|------|------------------|
| Patreon URL | `README.md`, `portal.html` |
| Tier names/prices | This doc + `CHAR/ECRR/ECRR_REPORTS/ECRR_PATREON_SETUP_20251017.md` |
| Brand color | `#7C5CFF` (ECRR purple) |
| Creative | `docs/comfort-cat/` |

---

## Agent instruction

When `artifacts/patreon-maintenance-state.json` shows `next_due_utc` in the past, or the user mentions Patreon upkeep:

1. Run `scripts/patreon-weekly-reminder.ps1`
2. Offer to walk through the checklist in browser (logged-in creator session required)
3. On completion, run with `-MarkComplete` and append a one-line note to `docs/BossCat/BOSSCAT_LOG.md` if anything changed

