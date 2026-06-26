# MILK Phase-4: Low-Intensity Mode & Discoverability

**Status**: 📋 **READY FOR IMPLEMENTATION**  
**Priority**: P2 (Enhancement)  
**Lane**: MILK (MilkDrop Integration Layer & Kit)  
**Budget**: ≤10 files, ≤200 LOC (single job)  
**Assigned**: Next Cursor{Implementer} session

---

## 🎯 Phase Goal

Improve **accessibility and discoverability** of visuals with a **Low-Intensity mode** and better **hub filtering/previews** — small, lane-safe updates that keep gate **GREEN**.

---

## 📋 Scope & Constraints

**Lane**: MILK  
**Change Type**: docs/scripts only  
**Budgets**: 
- ≤10 files
- ≤200 LOC (single job)
- No secrets
- No external calls

**Safety**: 
- ✅ No preset file changes
- ✅ UI/DOM changes minimal (reuse existing elements)
- ✅ CSP compliance maintained
- ✅ Render loop unchanged (parameter adjustments only)

---

## 📦 Deliverables (5 items)

1. ✅ Low-Intensity toggle in `control.html`
2. ✅ Updated docs for the toggle (`CONTROL_README.md`)
3. ✅ Hub filter/tag polish for MILK (`index.html`)
4. ✅ Preset previews folder + capture guide
5. ✅ ECRR report and evidence logs

---

## 🔨 Implementation Tasks

### Task 1: Low-Intensity Mode Toggle

**File**: `docs/BossCat/visuals/control.html`  
**LOC Budget**: ≤30 lines  
**Changes**:

1. Add checkbox control (reuse existing UI bar):
   ```html
   <label>
     <input type="checkbox" id="lowIntensityMode" />
     Low-Intensity Mode
   </label>
   ```

2. Add JavaScript handler:
   ```javascript
   const lowIntensityToggle = document.getElementById('lowIntensityMode');
   let lowIntensityMode = false;
   
   lowIntensityToggle.addEventListener('change', (e) => {
     lowIntensityMode = e.target.checked;
     applyLowIntensitySettings();
   });
   
   function applyLowIntensitySettings() {
     if (!butterchurn) return;
     
     if (lowIntensityMode) {
       // Halve effective wave alpha (cap at 0.5)
       // Increase fDecay by ~0.005 (bounded ≤ 0.99)
       // Set minimum blend time to ≥ 2.0s when auto-cycling
       
       // Implementation: Adjust preset parameters before loading
       // Or: Add parameter override layer
     } else {
       // Restore original parameters
     }
   }
   ```

**Behavior When Enabled**:
- ✅ Halve effective wave alpha (cap at 0.5)
- ✅ Increase fDecay by ~0.005 (bounded ≤ 0.99)
- ✅ Set minimum blend time to ≥ 2.0s when auto-cycling

**Keep**: ≤20–30 LOC; reuse existing elements/state

---

### Task 2: Update Documentation

**File**: `docs/BossCat/visuals/CONTROL_README.md`  
**LOC Budget**: ≤20 lines  
**Changes**:

Add section after "Features":

```markdown
### Low-Intensity Mode

**Purpose**: Reduces visual intensity for:
- Accessibility (photosensitivity, motion sensitivity)
- Ambient displays (non-distracting backgrounds)
- Demos and presentations (less overwhelming)
- Extended viewing sessions

**Effect**:
- Wave amplitudes capped at 50% (max alpha 0.5)
- Faster decay rate (smoother transitions)
- Longer blend times (≥2s) during auto-cycling

**Usage**: Toggle checkbox in control surface. Changes apply to next preset or immediately if supported.

**Accessibility**: Recommended for users sensitive to rapid motion or bright flashes.
```

---

### Task 3: Hub Filter/Tag Polish

**File**: `index.html` (if needed)  
**LOC Budget**: ≤10 lines  
**Changes**:

1. Verify MILK visuals quick-link has `data-tags="MILK visuals"` (likely already present)
2. Add consolidated MILK report link beneath Quick Access if not present:
   ```html
   <a href="CHAR/ECRR/ECRR_REPORTS/ECRR_MILK_CONSOLIDATED_LATEST.md">
     📊 MILK Lane Consolidated Report
   </a>
   ```

**Validation**: No layout regressions, links work correctly

---

### Task 4: Preset Previews Folder

**Location**: `docs/BossCat/visuals/previews/`  
**Files**:
- `README_previews.md` (capture guide)
- Placeholder structure (no binaries this pass)

**File**: `docs/BossCat/visuals/previews/README_previews.md`  
**LOC Budget**: ≤50 lines  
**Content**:

```markdown
# Resonai Pack v1 - Preset Previews

**Purpose**: Visual previews of each preset for quick reference and selection.

---

## Capture Guide

### Tools (Windows 11)

**Option 1: Xbox Game Bar** (Built-in)
- Press `Win + G` to open
- Click "Capture" widget
- Click "Record" (or `Win + Alt + R`)
- Stop after 5-8 seconds
- GIF conversion: Use online tool or FFmpeg

**Option 2: ShareX** (Free, recommended)
- Download: https://getsharex.com/
- Configure: Hotkey Setup > Screen Recording
- Set output format to GIF
- Record 5-8 seconds per preset

**Option 3: OBS Studio** (Advanced)
- Download: https://obsproject.com/
- Add Window Capture source
- Record 5-8 seconds
- Convert to GIF with FFmpeg

---

## Capture Settings

**Duration**: 5-8 seconds per preset  
**Resolution**: 800x600 or 1024x768  
**FPS**: 30 fps (sufficient for preview)  
**Audio**: Muted (visuals only)

---

## Naming Convention

```
RN-001-CircuSpectra-preview.gif
RN-002-HaloBloom-preview.gif
RN-003-VectorGrid-preview.gif
RN-004-LiquiRing-preview.gif
RN-005-LineDancer-preview.gif
```

---

## FFmpeg Conversion (if needed)

```bash
# MP4 to GIF
ffmpeg -i input.mp4 -vf "fps=30,scale=800:-1:flags=lanczos" -loop 0 output.gif

# Optimize GIF size
ffmpeg -i input.gif -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output-optimized.gif
```

---

## Preview Specifications

- **Target Size**: ≤2MB per GIF
- **Dimensions**: 800x600 (4:3) or 1024x768
- **Loop**: Infinite
- **Compression**: Optimize with palette

---

## Future: Automated Capture

Phase-5 could add automated preview generation:
- Headless Butterchurn render
- Preset load → 8s record → GIF export
- Batch process entire pack

**Status**: Manual capture for Phase-4; automation deferred to Phase-5

---

## Preview Placeholders

**Current Status**: Folder structure ready, binaries deferred

```
docs/BossCat/visuals/previews/
├── README_previews.md (this file)
├── RN-001-CircuSpectra-preview.gif (placeholder)
├── RN-002-HaloBloom-preview.gif (placeholder)
├── RN-003-VectorGrid-preview.gif (placeholder)
├── RN-004-LiquiRing-preview.gif (placeholder)
└── RN-005-LineDancer-preview.gif (placeholder)
```

**Next**: Capture GIFs manually and add in follow-up commit

---

**Note**: Large binaries should be added separately to avoid bloating Git history. Consider Git LFS or external hosting for final previews.
```

**Placeholders**: Create empty `.gitkeep` or stub files, but **no large media** in this pass

---

### Task 5: ECRR Report & Evidence

**File**: `CHAR/ECRR/ECRR_REPORTS/ECRR_MILK_PHASE4_[YYYYMMDD].md`  
**LOC Budget**: ≤100 lines  
**Template**:

```markdown
# ECRR Report — MILK Phase-4: Low-Intensity & Discoverability

**Date**: YYYY-MM-DD  
**Lane**: MILK  
**Phase**: Phase-4 (Low-Intensity Mode & Discoverability)  
**Status**: COMPLETE

---

## E — Examine

**Baseline**: MILK Lane Phases 1-4 (Presets) complete and gate GREEN  
**Goal**: Improve accessibility and discoverability without breaking changes

**Requirements**:
- Low-Intensity mode for accessibility
- Better hub navigation (filters/tags)
- Preset preview capture guide

---

## C — Clean

**Changes Implemented**:
1. Low-Intensity toggle in control.html (XX LOC)
2. CONTROL_README updated with toggle docs (XX lines)
3. Hub filter/tag polish (XX LOC if any)
4. Previews folder + README_previews.md (XX lines)

**Total**: XX LOC (within ≤200 LOC budget)  
**Files**: X files (within ≤10 files budget)

---

## R — Report

**Artifacts**:
- control.html (modified)
- CONTROL_README.md (modified)
- previews/README_previews.md (new)
- index.html (modified if needed)
- MILK_PHASE4_PLAN.md (this plan)

**Validation**:
- ✅ Gate verification: READY
- ✅ Low-Intensity toggle functional
- ✅ Documentation complete
- ✅ No CSP violations
- ✅ No layout regressions

**Evidence**: .agent/EVIDENCE.log entry added

---

## R — Role

**Implementer**: Cursor{Implementer}  
**Reviewer**: BossCat OEM  
**Status**: COMPLETE

---

**Gate**: ✅ READY (local)
```

**Evidence Log**: Append to `.agent/EVIDENCE.log` (create if needed):

```json
{
  "timestamp": "YYYY-MM-DDTHH:MM:SSZ",
  "lane": "MILK",
  "mission": "Phase-4 Low-Intensity & Discoverability",
  "artifacts": [
    "control.html (modified)",
    "CONTROL_README.md (modified)",
    "previews/README_previews.md (new)",
    "MILK_PHASE4_PLAN.md (plan)",
    "ECRR_MILK_PHASE4_YYYYMMDD.md (report)"
  ],
  "budget": {
    "files": "X/10",
    "loc": "XX/200"
  },
  "status": "READY",
  "gate": "GREEN"
}
```

---

## ✅ Acceptance Criteria

- [ ] `control.html` shows Low-Intensity toggle
- [ ] When toggled, visual intensity reduces correctly
- [ ] Auto-cycle blends respect floor (≥2.0s)
- [ ] `CONTROL_README.md` documents the toggle
- [ ] Hub retains MILK link(s) and filter tags
- [ ] No layout regressions in hub
- [ ] `previews/` folder created with capture guide
- [ ] No large media binaries added (placeholders only)
- [ ] Gate verdict: READY (local)
- [ ] ECRR report written
- [ ] Evidence appended to `.agent/EVIDENCE.log`

---

## 🧪 Validation Commands

### 1. Gate Verification

```powershell
pwsh -File scripts/verify-iona-gate.ps1 `
  -Gate IONA `
  -Site local `
  -OutputJson DELT/ARTF/gate-verification-results.json `
  -PrCommentPath PR_COMMENT_IONA_GATE_002_FINAL.md
```

**Expected**: Exit 0, verdict READY

---

### 2. Control Surface Test

```powershell
start docs\BossCat\visuals\control.html
```

**Manual Tests**:
1. Load any preset
2. Toggle "Low-Intensity Mode" checkbox
3. Verify visual intensity reduces
4. Start auto-cycle
5. Verify blend times ≥2.0s

---

### 3. Preset Validation (Unchanged)

```powershell
pwsh -File scripts/visuals/Validate-Preset.ps1 `
  -PresetPath "docs/BossCat/visuals/presets/Resonai Pack v1/RN-001 CircuSpectra.milk"
```

**Expected**: 100/100 (no preset changes, should still pass)

---

### 4. Hub Navigation Test

```powershell
start index.html
```

**Manual Tests**:
1. Find MILK visuals quick-link
2. Verify tags/filters work
3. Verify consolidated report link
4. No layout regressions

---

## 📝 Commit Messages (Suggested)

```bash
# Commit 1: Low-Intensity mode
feat(milk): add Low-Intensity mode to control.html (docs-only)

- Add checkbox toggle for Low-Intensity mode
- Halve wave alpha (cap 0.5), increase fDecay (+0.005)
- Set min blend time ≥2.0s for auto-cycle
- Improves accessibility (photosensitivity, motion)

Budget: XX/200 LOC, X/10 files
Lane: MILK (docs/scripts only)
ECRR: ECRR_MILK_PHASE4_YYYYMMDD.md

# Commit 2: Previews guide
docs(visuals): add previews folder + capture guide

- Create previews/ folder structure
- Add README_previews.md with capture guide
- Placeholder structure (no binaries this pass)
- Tools: Xbox Game Bar, ShareX, OBS + FFmpeg

Budget: XX/200 LOC, X/10 files
Lane: MILK (docs-only)

# Commit 3: ECRR report
docs(ecrr): add MILK Phase-4 ECRR report

- ECRR_MILK_PHASE4_YYYYMMDD.md
- Evidence log entry added
- Gate: READY (local)
```

---

## ⚠️ Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| **UI regressions** | Keep DOM+CSS changes minimal; reuse existing bar; verify CSP unaffected |
| **Overreach** | Do NOT alter preset files; only container behavior changes |
| **Latency** | Keep render loop unchanged; only adjust parameters |
| **CSP violations** | Inline styles/scripts forbidden; use existing patterns |
| **Scope creep** | Stick to ≤200 LOC, ≤10 files; defer automation to Phase-5 |

---

## 📊 Budget Tracking

**Target**: ≤200 LOC, ≤10 files

| Task | Files | Est. LOC | Status |
|------|-------|----------|--------|
| Low-Intensity toggle | 1 | ~30 | ⏳ Pending |
| CONTROL_README update | 1 | ~20 | ⏳ Pending |
| Hub polish | 1 | ~10 | ⏳ Pending |
| Previews guide | 1 | ~50 | ⏳ Pending |
| ECRR report | 1 | ~100 | ⏳ Pending |
| **Total** | **5** | **~210** | ⚠️ **Slightly over; optimize** |

**Note**: Aim for ~180-190 LOC to stay within budget. ECRR report can be concise (~80 lines).

---

## 🚀 Implementation Order

1. **Setup**: Read existing `control.html` and `CONTROL_README.md`
2. **Task 1**: Add Low-Intensity toggle to `control.html`
3. **Task 2**: Update `CONTROL_README.md` with toggle docs
4. **Task 3**: Verify/polish hub filters in `index.html`
5. **Task 4**: Create `previews/` folder and `README_previews.md`
6. **Task 5**: Write ECRR report and update evidence log
7. **Validation**: Run all validation commands
8. **Commit**: Stage and commit with proper messages

---

## 📞 Handoff Notes

**Prerequisites**:
- MILK Lane Phases 1-4 (Presets) complete ✅
- Gate status: GREEN ✅
- All previous phases reviewed and approved ✅

**Context**:
- This is a **docs/scripts-only** enhancement
- No breaking changes to presets or core functionality
- Focus on **accessibility** and **discoverability**
- Stay within **lane budgets** (≤200 LOC, ≤10 files)

**Success Criteria**:
- Gate remains GREEN
- Low-Intensity mode functional
- Documentation complete
- No regressions

**Timeline**: Single session (~60-90 minutes)

---

## 🐾 BossCat Notes

**Approval**: Plan reviewed and approved for implementation  
**Lane**: MILK (within scope)  
**Risk Level**: LOW (docs/scripts only, no preset changes)  
**Gate Impact**: NONE (should remain GREEN)

**Next Implementer**: Pick up this plan and execute Phase-4. All artifacts from Phases 1-4 are staged and ready. Gate is GREEN. Proceed with confidence.

---

**Plan Created**: 2025-10-16  
**Status**: 📋 **READY FOR IMPLEMENTATION**  
**Assigned**: Next Cursor{Implementer} session

🐾 **BossCat Approved** — Clear for Phase-4 implementation


