# Cat Nap Control Room — Creative Pack v1

_A serene observability story built for quick production and crisp proof points._

---

## 1) Logline & Promise
**Logline:** While the cat naps, a lean Windows→SigNoz pipeline keeps perfect watch—logs, metrics, and traces flowing in sub‑second harmony.

**Audience Promise:** "Sleep easy. We've got the signal." Minimalist cockpit visuals + concrete, reproducible metrics.

---

## 2) Core Narrative Structure (60–75s film)
1. **Opening — The Lull (0–6s)**
   - Visual: Dim control room; soft LED wash. Cat silhouette curls beside a low-glow panel.
   - SFX: Airy room tone, slow synth pad.
   - On‑screen: _Cat Nap Control Room._

2. **Logs — Snap‑to‑Action (6–18s)**
   - Visual: Left panel of triptych expands. Recent WARN events flicker at ~15s cadence; canary breadcrumbs filter to the top (`message contains "canary test"`).
   - Motion: Subtle ticker left→right; highlight wipes at event arrival.
   - On‑screen micro‑copy: _"Filtered Windows events in instantly."_

3. **Metrics — Heartbeat (18–36s)**
   - Visual: Center panel surfaces `otelcol_*` metrics: accepted / filtered / export errors. Clean sparklines + stacked bar for 200 ms batching.
   - Motion: 200 ms pulse glows on batch closure; exporter health dot idles green.
   - On‑screen: _"200 ms rhythm. Exporter steady."_

4. **Traces — Pulse Check (36–54s)**
   - Visual: Right panel reveals p95/p99 ribbons; stable, flat contours.
   - Motion: Tiny shimmer when percentile updates; cat ear twitches once.
   - On‑screen: _"p95/p99 stay calm under load."_

5. **Close — Assurance (54–72s)**
   - Visual: Triptych re‑combines. Cat snores (one tiny Z) as the control board hums.
   - CTA Card: _"Sleep easy. We've got the signal."_ + import prompts.

---

## 3) Visual Language
- **Palette:** Calm, muted base (charcoal #1B1E22, slate #2A2F36, fog #A7B0B7) with a single neon accent for live signals (mint‑aqua #37FFC4 or magenta #FF3DBE). Background bloom kept under 8%.
- **Type:**
  - Headline: Söhne / Inter Tight / SF Pro Display (semi‑bold, -2 letterspacing for title cards).
  - Data: JetBrains Mono / IBM Plex Mono for logs & code elements.
- **Iconography:** Minimal glyphs (log file, heartbeat, trace ribbon); line icons at 1.5px stroke.
- **Layout:** Triptych dashboard (Logs | Metrics | Traces). 20px gutters; 12‑column grid. Cards with 16px radius, soft shadow 8/12.
- **Data Styling:** Sparklines (1.5px), percentiles as translucent ribbons with a crisp median line.

---

## 4) Motion & FX
- **WARN ticker:** Gentle 15s cadence animation; do not feel alarmist.
- **Batch pulse:** 200 ms glow tick on each batch window.
- **State changes:** Green→amber only on exporter hiccup; quick recovery easing (120ms).
- **Camera:** One parallax drift (~2% scale) across the dashboard for depth.
- **Cat:** Subtle chest rise, single ear twitch near trace update for charm.

---

## 5) Copy Pack
- **Primary CTA:** _Sleep easy. We've got the signal._
- **Secondary CTA:** _Import the dashboard & alerts. Watch the calm in real time._
- **Body Options:**
  - _Logs land instantly. Metrics breathe at 200 ms. Traces stay flat._
  - _Noise filtered. Signal foregrounded. Pipeline purrs._
- **Lower‑third Proof Points:** _200 ms batch / 256 record bursts • ~50% volume reduction • 7‑day log TTL._

---

## 6) Storyboard (Key Frames)
1. **KF‑1 (Title):** Wide of cockpit; neon accent glows. Title in.
2. **KF‑2 (Logs zoom):** Table animates; canary tag pill appears; WARN heartbeat ticks.
3. **KF‑3 (Metrics glide):** KPI trio tiles (accepted / filtered / errors). 200 ms batch markers sweep.
4. **KF‑4 (Trace ribbons):** p95/p99 bands stay level; micro‑particles drift.
5. **KF‑5 (Merge & CTA):** Triptych recombines; CTA card rises; import hints.

**Supers & Captions (timed):**
- 00:07 "Filtered Windows events in instantly."
- 00:22 "`otelcol_*` metrics—ingestion, filtering, exporter health."
- 00:40 "p95 / p99 flat under load."
- 00:58 "Sleep easy. We've got the signal."

---

## 7) Production Notes (How‑To demo the real thing)
- **Dashboard JSON:** `artifacts/optimized-pipeline-dashboard.json` (Import: SigNoz UI → Dashboards → Import JSON)
- **Alert bundle:** `artifacts/noise-pattern-alerts.json` (Import: SigNoz UI → Alerts → Import JSON)
- **Live CLI monitor:** `scripts/monitor-optimized-pipeline.ps1`
  - Capture loop/gifs: `pwsh -File scripts/monitor-optimized-pipeline.ps1 -Continuous`
- **Canary generator:** `scripts/schedule-canary-simple.ps1` (ensures `"canary test"` breadcrumbs)
- **Readiness probe:** `scripts/check-latency-readiness.ps1` (validates 200 ms batch, exporter health)

---

## 8) Proof Points (On‑screen & Deck)
- **Batching:** 200 ms batch windows / 256‑record bursts (validated by readiness + canary).
- **Noise filter:** ~50% volume reduction; signal preserved for WARN/ERROR.
- **Retention:** ClickHouse TTL trims—7‑day logs keep runway clear.

---

## 9) Hero Mockups — Creative Brief
- **Mock 1 (Desktop Triptych):** 3‑panel dashboard, neon accent only on recent live signals; include canary tag pill.
- **Mock 2 (Metrics Focus):** KPI tile grid with `otelcol_receiver_accepted`, `otelcol_processor_dropped`, `otelcol_exporter_send_failed`.
- **Mock 3 (Trace Calm):** Wide ribbons for p95/p99, flat trend line; ear‑twitch sticker in corner.
- **Mock 4 (CTA Card):** Full‑bleed cockpit, centered CTA, import instructions tucked bottom‑right.
- **Mock 5 (Mobile Cut):** Single‑column scroll: Logs → Metrics → Traces; thumb‑friendly cards.

**Export targets:**
- Web hero (2880×1620), YouTube (3840×2160), Twitter/X (1600×900), LinkedIn (1200×627), GIF loops (1080×1080, 6–8s).

---

## 10) Accessibility & Inclusivity
- Maintain 4.5:1 contrast minimum for body text; 3:1 for large headings.
- Provide burned‑in captions for social cuts + SRT.
- Motion‑sensitive version: disable ticker, keep only fade/pulse (toggle in edit).

---

## 11) Asset Map (from Repo)
- Dashboards → `artifacts/optimized-pipeline-dashboard.json`
- Alerts → `artifacts/noise-pattern-alerts.json`
- Scripts → `scripts/monitor-optimized-pipeline.ps1`, `scripts/schedule-canary-simple.ps1`, `scripts/check-latency-readiness.ps1`

---

## 12) Deliverables Checklist
- [ ] Mood board (palette, type, motion references, 3–5 frames)
- [ ] Five hero mockups (desktop, metrics focus, trace calm, CTA card, mobile)
- [ ] 60–75s master edit + 10s, 15s social cutdowns
- [ ] 6–8s looped GIF (logs ticker) + 6–8s looped GIF (trace ribbons)
- [ ] Thumbnail set (3 variants)
- [ ] Caption pack + alt text

---

## 13) Edit Script (VO + SFX)
**VO (soft, assured):**
- "When the room goes quiet… we listen harder."
- "Filtered Windows events, right when they happen."
- "`otelcol` heartbeats at 200 milliseconds."
- "p95, p99—steady as a cat's breath."
- "Sleep easy. We've got the signal."

**SFX:** airy pad, low mechanical hum, light chime on batch pulse, single cat purr near CTA.

---

## 14) Technical Callouts for Designers
- Use real, anonymized log lines; highlight canary with tag pill (mint/aqua).
- Metrics tiles include labels, unit suffixes, and micro‑trend (last 60s).
- Trace ribbons: 3‑layer stack (p50 line, p95 ribbon, p99 lighter ribbon).
- Grid spec: 12‑col, 20px gutter, 80/120 spacing rhythm.

---

## 15) Guardrails
- Avoid alarmist reds; warn state is calm amber.
- No live customer data; canary + synthetic only.
- Keep copy sparse; let motion carry the story.

---

## 16) Success Criteria (Review)
- Visuals match repo assets; on‑screen metrics reflect proof points.
- Motion reads as calm, not sluggish (snappy eases, subtle amplitude).
- CTA clear, import steps visible without pausing.

---

### End of Pack

