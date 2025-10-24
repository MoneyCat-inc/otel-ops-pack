# Gate #013B - Native Audio Bridge - PLAN

**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Date:** 2025-10-24  
**Job:** 1 (Native PCM Bridge)  
**TTL:** 90 minutes  
**Start:** 2025-10-24T18:00:00Z

## Objective
Deliver a native C++ audio bridge that feeds PCM from `/audio` API → FIFO → libprojectM to achieve full audio-reactivity.

## Success Criteria (GREEN)
- [ ] Audio bridge compiled and linked to libprojectM
- [ ] PCM feed working (FIFO → bridge → ProjectM)
- [ ] Blackout ≤ 20% (on ≥1 preset with audio)
- [ ] Motion Δluma > 0
- [ ] Reactivity r ≥ 0.35 (Pearson correlation)
- [ ] Preset swap ≤ 1.5s (maintain current 0.2-0.35s)
- [ ] Evidence bundle complete (JSONL + snapshots + stats)

## Budget Constraints (HARD)
- Files: ≤ 3
- LOC: ≤ 120 (core changes)
- TTL: ≤ 90 minutes
- Retries: ≤ 3
- Single-writer (A only)

## Technical Approach
1. **Native Bridge** (`pm-audio-bridge.cpp`, ~90 LOC)
   - Open FIFO `/tmp/pm-audio.pcm` (16-bit LE, 44.1 kHz, mono/stereo)
   - Convert int16 → float [-1, 1]
   - Feed to libprojectM PCM ingress API
   - Print stats (RMS/peak) every 500ms

2. **Dockerfile Updates** (~10 LOC)
   - Install libprojectm-dev, build-essential
   - Compile bridge: `g++ -O2 pm-audio-bridge.cpp -lprojectM`
   - Install to `/usr/local/bin/pm-audio-bridge`

3. **Startup Script Updates** (`pm-run.sh`, ~12 LOC)
   - Create FIFO `/tmp/pm-audio.pcm`
   - Launch `pm-audio-bridge` alongside projectMSDL
   - Trap for clean shutdown

## Files to Modify (3 total)
1. `viz-engine-projectm/pm-audio-bridge.cpp` (new, ~90 LOC)
2. `viz-engine-projectm/Dockerfile` (+~10 LOC)
3. `viz-engine-projectm/pm-run.sh` (+~12 LOC)

**Total LOC:** ~112 (under ≤120 budget)

## Test Plan (Changed-Paths Only)
1. Rebuild pm-engine container
2. Start container: `docker-compose -f docker-compose.viz.yml up -d pm-engine`
3. Feed audio: `pwsh scripts/validate-gate-013.ps1 -Seconds 20 -BPM 128`
4. Validate:
   - GET /pm/metrics → blackout, luma, Δluma
   - GET /audio/stats → RMS/EMA rising
   - POST /pm/preset → cycle 3 presets, time switch (<1.5s)
   - GET /snap.jpg → 3 frame captures
5. Evidence: JSONL + snapshots + docker logs excerpt

## Rollback Plan
If any target fails after ≤3 retries:
1. Stop container
2. Revert 3 file edits
3. Rebuild without bridge
4. Restore Gate #013 AMBER state
5. Emit ECRR report (exit code 10 AMBER / 20 RED)

## ECRR Discipline
- **Evidence:** `.agent/EVIDENCE.log` with plan→preflight→edit→test→exit
- **Contain:** Changed-paths only; surgical edits
- **Rollback:** First-class; preserve AMBER baseline
- **Report:** `artifacts/pm/gate-013b-validation-<ts>.json` + BOSSCAT_LOG entry

## Safety Guards
- Two-agent (A writes, B verifies)
- Single-writer lock (`.agent/JOB.lock`)
- Kill-switch respected (`.agent/LOCK`)
- Budget enforcement (≤3 files, ≤120 LOC)
- TTL enforcement (90 min)

**Start:** 2025-10-24T18:00:00Z  
**Target:** GREEN with full audio-reactivity
