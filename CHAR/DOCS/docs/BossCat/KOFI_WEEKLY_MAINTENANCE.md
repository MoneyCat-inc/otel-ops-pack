# Ko-fi weekly maintenance — Resonai [OTel]

**Cadence:** every **7 days** (recommended: Monday morning, offset from Patreon if both run same day)  
**Page:** <https://ko-fi.com/fubumaki>  
**Owner:** Fubumaki (creator) · **Agent cue:** run `pwsh -File scripts/kofi-weekly-reminder.ps1` when overdue

---

## Quick run

```powershell
# Check status (prints checklist if due)
pwsh -File scripts/kofi-weekly-reminder.ps1

# After finishing the checklist
pwsh -File scripts/kofi-weekly-reminder.ps1 -MarkComplete
```

Register a Windows weekly reminder (current user, Mondays 10:15 — shortly after Patreon):

```powershell
pwsh -File scripts/kofi-weekly-reminder.ps1 -RegisterScheduledTask
```

State file: `artifacts/kofi-maintenance-state.json` (last completed + next due).

---

## Weekly checklist (ECRR)

### Examine (5 min)

- [ ] Public page loads — profile visible at <https://ko-fi.com/fubumaki>
- [ ] **About** still describes Resonai [OTel] / evidence-first observability (not stale generic copy)
- [ ] **One-time** donations enabled with sensible default amounts
- [ ] **Monthly / membership** (if enabled) — tiers and prices match intent
- [ ] **Social links** — GitHub `MoneyCat-inc/otel-ops-pack`, Patreon cross-link
- [ ] **Cover + profile image** — live on page (source asset: `artifacts/kofi-cover-1200x400.png` if re-upload needed)
- [ ] **Payouts** — Stripe/PayPal connected; no action-required banners

### Clean (10 min)

- [ ] Thank new supporters (Ko-fi messages / email notifications)
- [ ] Post a short update or pin if something shipped (optional, monthly is fine)
- [ ] Fix broken links; align README Ko-fi badge with live URL
- [ ] `portal.html` and README both link **Ko-fi** — keep URLs in sync

### Report (5 min)

- [ ] Note supporter count / monthly total in `artifacts/kofi-maintenance-state.json` (`notes` field) or BossCat log
- [ ] Run `-MarkComplete` so the next reminder is +7 days

### Role

- **Fubumaki:** payouts, supporter thanks, profile media, tier pricing
- **Agent:** scripted status check, README/portal link audit, ECRR note in artifacts

---

## Alignment references

| Item | Canonical source |
|------|------------------|
| Ko-fi URL | `README.md` → <https://ko-fi.com/fubumaki> |
| Patreon (structured tiers) | <https://www.patreon.com/c/FaeMcLachlan> |
| Portal tip jar | `portal.html` → <https://ko-fi.com/fubumaki> |
| Creative | `docs/comfort-cat/` · brand accent `#7C5CFF` |

---

## Agent instruction

When `artifacts/kofi-maintenance-state.json` shows `next_due_utc` in the past, or the user mentions Ko-fi upkeep:

1. Run `scripts/kofi-weekly-reminder.ps1`
2. Offer to walk through the checklist in browser (logged-in creator session required)
3. On completion, run with `-MarkComplete` and append a one-line note to `docs/BossCat/BOSSCAT_LOG.md` if anything changed
