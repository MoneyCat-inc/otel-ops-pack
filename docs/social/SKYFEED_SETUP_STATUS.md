# SkyFeed Custom Feeds — Setup Status

**Owner:** Fae McLachlan / Resonai  
**Rules reference:** [CUSTOM_FEED_RULES.md](./CUSTOM_FEED_RULES.md)  
**Last updated:** 2026-06-13

---

## Status: Use interactive wizard

```powershell
npm run social:skyfeed-wizard
```

When all 3 feeds are published in SkyFeed + added to the Starter Pack:

```powershell
npm run social:skyfeed-finalize
```

| Feed | Generator slug | Status |
|------|----------------|--------|
| Fact-Check Firehose | `factcheck-firehose` | ⬜ Not created |
| OSINT + Verification | `osint-verification` | ⬜ Not created |
| AntiClickbait HQ | `anticlickbait-hq` | ⬜ Not created |

Live URIs (auto-generated): `docs/social/skyfeed-feeds-live.json`

---

## Prerequisites

- [x] Bluesky account: [@resonai.bsky.social](https://bsky.app/profile/resonai.bsky.social)
- [x] Starter Pack live: [AntiClickbait pack](https://bsky.app/starter-pack/resonai.bsky.social/3m3rct677yo2t)
- [ ] SkyFeed account linked to same Bluesky DID
- [ ] Feed rules copied from `CUSTOM_FEED_RULES.md` (Simple mode first)

---

## Step-by-step (per feed)

1. Open [skyfeed.app](https://skyfeed.app/) → **Create feed**
2. Paste display name + description from `CUSTOM_FEED_RULES.md`
3. Add rules (authors, hashtags, text contains `hub.resonai.uk`)
4. **Publish** → copy `at://did:plc:…/app.bsky.feed.generator/<slug>`
5. Pin feed URI in `docs/social/pinned-post-template.txt` when ready
6. Post once on Bluesky: *"New custom feed: [name] — [one-line purpose]"*

---

## AntiClickbait HQ (start here)

Minimum rules:

```
Include if ANY:
  - Author is @resonai.bsky.social
  - Text contains "hub.resonai.uk"
  - Text contains "otel-ops-pack"
  - Hashtag #OpenTelemetry
  - Hashtag #AntiClickbait
```

---

## After publish

```powershell
# Update pinned post + profile links
npm run social:sync-bsky
npm run social:export
git add docs/widgets/bluesky-latest.json docs/social/
git commit -m "chore(social): SkyFeed feeds live"
```

Mark complete in weekly Bluesky maintenance:

```powershell
pwsh -File scripts/bsky-weekly-reminder.ps1 -MarkComplete -Notes "SkyFeed feeds published"
```
