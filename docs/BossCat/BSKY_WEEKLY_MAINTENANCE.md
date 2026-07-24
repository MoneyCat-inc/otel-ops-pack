# Bluesky weekly maintenance — Resonai [OTel]

**Cadence:** every **7 days** (recommended: Monday morning)  
**Profile:** https://bsky.app/profile/resonai.bsky.social  
**Handle:** `@resonai.bsky.social` · **Owner:** Fubumaki (creator)  
**Automation home:** [MoneyCat-inc/socm](https://github.com/MoneyCat-inc/socm) (Pack 3B extract)  
**Agent cue:** run `pwsh -File scripts/bsky-weekly-reminder.ps1` when overdue

---

## Quick run

```powershell
# Check status (prints checklist if due) — stays in ops-pack
pwsh -File scripts/bsky-weekly-reminder.ps1

# After finishing the checklist
pwsh -File scripts/bsky-weekly-reminder.ps1 -MarkComplete

# Optional: re-sync bio + pinned post (clone MoneyCat-inc/socm; needs BSKY_* / .env.socm there)
npx tsx scripts/social/sync-bsky-profile.ts
```

Register a Windows weekly reminder (current user, Mondays 10:30 — after Patreon/Ko-fi):

```powershell
pwsh -File scripts/bsky-weekly-reminder.ps1 -RegisterScheduledTask
```

State file: `artifacts/bsky-maintenance-state.json` (local runtime; not tracked — last completed + next due).

---

## Weekly checklist (ECRR)

### Examine (5 min)

- [ ] Public profile loads — https://bsky.app/profile/resonai.bsky.social
- [ ] **Display name** still `BossCat` (or agreed project name)
- [ ] **Bio** mentions hub + GitHub + support links (Ko-fi, Patreon)
- [ ] **Pinned post** has current Hub, GitHub, Ko-fi, Patreon, Starter Pack URLs
- [ ] Starter Pack still resolves: https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t
- [ ] `portal.html` Bluesky button → same profile URL

### Clean (10 min)

- [ ] Reply to mentions/replies (target: within 24–48h when actionable)
- [ ] If links drifted: in **socm**, run `npx tsx scripts/social/sync-bsky-profile.ts`
- [ ] Align with README/portal/Ko-fi/Patreon URLs if monetization or hub paths changed
- [ ] Engagement playbook: `docs/BossCat/BSKY_ENGAGEMENT_PLAYBOOK.md` (2–3 posts + 5 replies/week)
- [ ] Refresh widget: in **socm**, `npm run social:export` (powers portal + docs hub)
- [ ] Optional: `post-week2-engagement.ts` / `post-progress-batch.ts` in **socm** when shipping news

### Report (5 min)

- [ ] Note follower/post counts in `artifacts/bsky-maintenance-state.json` (`notes` field) or BossCat log
- [ ] Run `-MarkComplete` so the next reminder is +7 days

### Role

- **Fubumaki:** tone, replies, app-password rotation at https://bsky.app/settings/app-passwords (`socm-actions` for Actions)
- **Agent:** scripted status check; sync/export from **socm**; link audit vs README/portal

---

## Canonical copy (bio + pin)

**Bio** (max 256 chars) — enforced by socm `scripts/social/sync-bsky-profile.ts`:

```
Evidence-first observability + truth literacy.
22 OTel features scored 0-100.
Hub: https://hub.resonai.uk/
GitHub: github.com/MoneyCat-inc/otel-ops-pack
Support: ko-fi.com/fubumaki · patreon.com/c/FaeMcLachlan
```

**Pinned post** — same script; includes Hub, GitHub, Ko-fi, Patreon, AntiClickbait Starter Pack.

Templates (in socm): `docs/social/pinned-post-template.txt`, `docs/social/BLUESKY_PROFILE_UPDATE_CHECKLIST.md`

---

## Alignment references

| Item | Canonical source |
|------|------------------|
| Profile URL | `README.md`, `portal.html`, `docs/anticlickbait/index.html` |
| API credentials | socm secrets / `.env.socm` (`BSKY_HANDLE`, `BSKY_APP_PASSWORD`, `BSKY_SERVICE`) |
| Sync script | [socm `scripts/social/sync-bsky-profile.ts`](https://github.com/MoneyCat-inc/socm) |
| Social compose | socm `docs/social/CONTENT_SEEDS.md`, `npm run social:*` |
| Creative | `docs/comfort-cat/` |

---

## Agent instruction

When `artifacts/bsky-maintenance-state.json` shows `next_due_utc` in the past, or the user mentions Bluesky upkeep:

1. Run `scripts/bsky-weekly-reminder.ps1`
2. Open the public profile in browser; verify pinned post links
3. If bio/pin stale, sync from a **MoneyCat-inc/socm** checkout (needs `BSKY_*`)
4. On completion, run with `-MarkComplete` and append a one-line note to `docs/BossCat/BOSSCAT_LOG.md` if anything changed
