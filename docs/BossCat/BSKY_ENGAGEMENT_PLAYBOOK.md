# Bluesky engagement playbook — Resonai [OTel]

**Profile:** https://bsky.app/profile/resonai.bsky.social  
**Cadence:** 2–3 posts/week + 5–10 value-add replies/week  
**Companion:** `docs/BossCat/BSKY_WEEKLY_MAINTENANCE.md`  
**Automation:** [MoneyCat-inc/socm](https://github.com/MoneyCat-inc/socm) (Pack 3B)

---

## Weekly rhythm (≈2 hours)

| When | Action | Tool (run in **socm**) |
|------|--------|------------------------|
| **Mon** | 1 original post (ship, tip, or myth-buster) | `post-progress-batch.ts` / `post-week2-engagement.ts` |
| **Wed** | 3–5 replies on `#OpenTelemetry` `#Observability` `#Windows` | Manual; use reply macros below |
| **Fri** | Quote-post + 1 line of context; export widget JSON | `npm run social:export` |
| **Any** | Follow 3–5 suggested accounts | `npm run social:recommend-follows` → `follow-top-suggestions.ts` |

After each week (ops-pack): `pwsh -File scripts/bsky-weekly-reminder.ps1 -MarkComplete -Notes "followers=N replies=N"`

---

## Funnel (one spine everywhere)

```
Bluesky → pinned post → hub.resonai.uk → GitHub → Ko-fi / Patreon
```

| Surface | Must link |
|---------|-----------|
| Pinned post | Hub, GitHub, Ko-fi, Patreon, Starter Pack |
| Bio | Same (via socm `sync-bsky-profile.ts`) |
| `portal.html` | Support row + Bluesky widget |
| `README.md` | Badges + Contact section |
| `docs/index.html` | Community card |

---

## Reply macros

### CHECKLIST (trigger: reply "CHECKLIST")

```
🔍 Verification Checklist — before you repost:

□ Two independent sources
□ Original source named + linked
□ Date/context clear (not old news)
□ Reverse-image if visuals matter

Full guide: https://hub.resonai.uk/
```

Post as **reply to pinned post** when someone asks; refresh quarterly via socm `post-week2-engagement.ts`.

### Source request

```
Good catch. We cite two independent outlets before calling something verified.

Method + hub: https://hub.resonai.uk/
```

### OTel question

```
Windows path we use: Event Logs → OTel Collector → SigNoz (~200ms batches).

Quick health check: github.com/MoneyCat-inc/otel-ops-pack (scripts/quick-monitor.ps1)
```

---

## Scripts (MoneyCat-inc/socm)

```powershell
# From a socm clone with BSKY_* / .env.socm

# Sync bio + pin
npx tsx scripts/social/sync-bsky-profile.ts

# Progress / marketing posts (edit before re-run)
npx tsx scripts/social/post-progress-batch.ts
npx tsx scripts/social/post-week2-engagement.ts

# CHECKLIST thread on pinned post
npx tsx scripts/social/post-week2-engagement.ts

# Follow suggestions (top 5, rate-limited)
npx tsx scripts/social/follow-top-suggestions.ts

# Widget JSON for hub/portal
npm run social:export
```

---

## Metrics (notes field only)

Track in ops-pack `artifacts/bsky-maintenance-state.json` → `notes` (local runtime, untracked):

- Followers, following, posts count
- Replies received / sent this week
- GitHub stars (manual)

**Early goals:** 5–10 meaningful interactions/week > raw follower count.

---

## Agent instruction

When user asks for visibility/engagement:

1. In **socm**, run `social:export` and verify widget on ops-pack `portal.html` / `docs/index.html`
2. Queue 1–3 posts via socm engagement scripts (do not spam >6/day)
3. Run `recommend-follows` + `follow-top-suggestions` if following <30 accounts
4. Audit README / portal / pinned post link parity
