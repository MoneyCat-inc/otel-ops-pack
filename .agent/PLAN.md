# Gate #016 - Preset Library Curation - PLAN

**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Date:** 2025-10-24  
**Job:** 1 (Curation + Scoring)

## Objective
Curate 12-20 high-quality ProjectM presets into a "Starter Pack v1" with metadata index and visual metrics.

## Success Criteria (GREEN)
- [ ] 12-20 presets in `presets-projectm/curated/`
- [ ] Metadata index: `presets-projectm/curated/index.json`
- [ ] Blackout ≤ 50% (AMBER audio assumption)
- [ ] Motion Δluma > 0
- [ ] Preset swap ≤ 1.5s (target <0.5s)
- [ ] Evidence JSONL + snapshots captured
- [ ] Status report: `GATE_016_COMPLETE.md`

## Budget Constraints
- Files: ≤ 10
- LOC: ≤ 200 total
- Single-writer (A only)

## Approach
1. **Source:** Use existing local presets + create variations
2. **Organize:** `presets-projectm/curated/` folder
3. **Metadata:** JSON index with tags (bright, low-blackout, motion, etc.)
4. **Score:** Run authoring loop for 2 passes, collect metrics
5. **Evidence:** JSONL + snapshots to `artifacts/pm/`
6. **Report:** GREEN/AMBER/RED status document

## ECRR Discipline
- Lock acquired: `.agent/JOB.lock`
- Evidence trail: `.agent/EVIDENCE.log`
- Rollback: Remove curated folder, restore state
- Report: Complete status in `GATE_016_COMPLETE.md`

## Changed Paths Only
- `presets-projectm/curated/*.milk` (new)
- `presets-projectm/curated/index.json` (new)
- `scripts/score-presets.ps1` (optional helper, ≤100 LOC)
- `GATE_016_COMPLETE.md` (new)
- `docs/BossCat/BOSSCAT_LOG.md` (append 1 line)

**Start:** 2025-10-24 (Gate #015 complete)  
**Target:** GREEN with 12-20 curated presets
