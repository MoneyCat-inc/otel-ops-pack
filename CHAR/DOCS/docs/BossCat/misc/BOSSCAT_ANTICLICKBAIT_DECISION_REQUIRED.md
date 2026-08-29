# BossCat OEM – Funding Decision Needed

**Date:** 2025-10-16  
**Prepared by:** Cursor{Implementer}

<!-- markdownlint-disable-next-line MD013 -->
The AntiClickbait transparency bundle is technically complete (5 files, 108 non-empty LOC, 22 cards scored). Launch is blocked until a funding approach is agreed so we can expose donation controls without violating the AntiClickbait ethos.

## Decisions Requested

Please choose one option for each item and reply in this format:

```text
1. Placement: <Hero | Sidebar | Card | Footer>
2. Platform: <GitHub Sponsors | Ko-fi | Patreon | Custom>
3. Messaging: <Transparent | Value | Gratitude | Minimal>
4. Visibility: <High | Medium | Low>
```

### 1. Donation placement

- **Hero:** prominent banner at the top of the page.
- **Sidebar:** fixed column that remains visible while scrolling.
- **Card-level:** contextual buttons tied to individual feature cards.
- **Footer:** discrete link only at the bottom.

### 2. Primary platform

- **GitHub Sponsors:** already scaffolded via `.github/FUNDING.yml`.
- **Ko-fi:** one-off donations, very low friction.
- **Patreon:** recurring tiers and community tools.
- **Custom:** Stripe or another direct integration (longer build-out).

### 3. Message tone

- **Transparent:** explain the current loss and cash needs directly.
- **Value:** focus on how funding accelerates development.
- **Gratitude:** thank supporters for keeping the project free.
- **Minimal:** provide buttons with limited accompanying text.

### 4. Visibility level

- **High:** banner plus repeated calls to action throughout the page.
- **Medium:** single dedicated section plus footer reminder.
- **Low:** footer only.

## After the Decision

1. Implement selected funding UI (estimate: +30 LOC, still within budget headroom).
2. Re-run the lane verification and capture fresh ECRR evidence.
3. Execute `pnpm run agent:ready-for-gate:local` and prepare the BossCat comment.
4. Submit PR for approval.

The development team is standing by; a response from BossCat OEM unblocks the launch within the same working day.
