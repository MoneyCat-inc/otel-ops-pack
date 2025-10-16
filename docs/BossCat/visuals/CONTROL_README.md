# BossCat Visual Control Surface (Phase 2)

This is a self-contained HTML control surface using the Butterchurn (MilkDrop) engine.
It runs in any modern browser and lets you:

- Start mic/system audio
- Pick/advance presets
- Adjust blend time
- Auto-cycle presets every ~20s
- Toggle Low-Intensity mode for accessibility

## Open the Control Surface

- File: `docs/BossCat/visuals/control.html`
- From Windows Explorer, double-click to open in your default browser
- Or from PowerShell (repo root):

```powershell
start docs\BossCat\visuals\control.html
```

Tip: On Windows, choose the audio input named "Stereo Mix" to capture desktop audio.

Tetragram: MILK

## Low-Intensity Mode

**Purpose**: Reduces visual intensity for accessibility and comfort.

**Use Cases**:
- **Accessibility**: Users sensitive to rapid motion, bright flashes, or photosensitivity
- **Ambient Displays**: Non-distracting backgrounds for NOC/monitoring environments
- **Presentations**: Less overwhelming for demos and stakeholder reviews
- **Extended Viewing**: Reduces eye strain during long monitoring sessions

**Effects When Enabled**:
- Wave amplitudes capped at 50% (max alpha 0.5)
- Faster decay rate (+0.005, bounded ≤0.99) for smoother transitions
- Minimum blend time enforced (≥2.0s) during auto-cycling
- Auto-cycle interval extended to 30s (vs 20s normal)

**Usage**: Toggle the "Low-Intensity" checkbox in the control bar. Changes apply to the next preset load or immediately during auto-cycle.

**Accessibility Note**: Recommended for users with photosensitivity, motion sensitivity, or vestibular disorders.

---

## Intensity Slider (Phase-5)

**Purpose**: Fine-grained control over visual intensity beyond the Low-Intensity toggle.

**Range**: 0-100 (default: 0)

**Effects**:
- **Blend Time Floor**: `2s + (intensity × 0.02)` up to 4s max
  - 0 = no floor, 50 = 3s min, 100 = 4s min
- **Wave Alpha Cap**: `0.5 − (intensity × 0.003)` down to 0.2 min
  - 0 = 0.5 cap, 50 = 0.35 cap, 100 = 0.2 cap

**Interaction with Low-Intensity**:
- Low-Intensity toggle acts as a **hard floor** (takes precedence)
- When both enabled: most restrictive settings apply
- Example: Intensity=50 + Low-Intensity → 3s blend + halved wave_a + 0.35 cap

**Use Cases**:
- **Granular Control**: Fine-tune intensity for specific environments
- **Gradual Reduction**: Slowly reduce intensity over time
- **Per-Environment Settings**: Different intensity for day/night shifts

**Usage**: Adjust slider from 0-100; changes apply to next preset load.

---

## Minimal Automation Hook

The page listens for simple messages via `window.postMessage`:

```js
window.postMessage({ type: 'bosscat:visu', cmd: 'setBlendTime', arg: 2.0 }, '*');
window.postMessage({ type: 'bosscat:visu', cmd: 'next' }, '*');
window.postMessage({ type: 'bosscat:visu', cmd: 'prev' }, '*');
window.postMessage({ type: 'bosscat:visu', cmd: 'auto', arg: true }, '*');
```

## Next Steps

- Optional: drive this page from an Electron shell or a tiny Node controller
- Map BossCat signals to preset/auto-cycle parameters (Phase 3)
