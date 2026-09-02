# Milkdrop Preset Authoring Guide

> **Split-lane note (2026-09-02).** The visualizer lane was extracted to `viz-engine` in Pack 3B
> (2026-07-24), but preset tooling still ships here (`scripts/author-loop.ps1`,
> `scripts/score-curated-presets.ps1`, `scripts/bedrock-coauthor.ts`). This guide is unrelated to
> the telemetry pipeline and is kept as a crib sheet for that tooling.

**Authority:** BossCat OEM - Cat Nap Control Room  
**Purpose:** Codex-friendly crib sheet for authoring .milk presets  
**Reference:** Geisswerks Milkdrop authoring guide

---

## Quick Start

A Milkdrop preset is a text file (`.milk`) with three main sections:

1. **preset init** - Set initial constants
2. **per_frame** - Update variables each frame (beat-reactive logic)
3. **per_pixel** - Transform each pixel's position/color

---

## Basic Template

```milk
[preset00]

/* preset init */
wave_r = 0; wave_g = 0; wave_b = 0;
decay = 0.98;
gamma = 2.0;
echo_zoom = 1.0;
echo_alpha = 0.5;
video_echo_zoom = 1.0;

/* per_frame */
time = time + 0.0167;  // Increment time (~60fps)
beat = (bass + mid + treb) * 0.33;  // Beat intensity
zoom = 1.0 + 0.02*sin(time*0.7) + 0.03*beat;
rot  = 0.02*sin(time*0.31);
cx = 0.5 + 0.1*sin(time*0.43);
cy = 0.5 + 0.1*cos(time*0.37);
q1 = beat;  // Pass to per_pixel

/* per_pixel */
zoom = zoom + rad * 0.08 * sin(time*0.9);
ang  = ang  + q1  * 0.02 * (1 - rad);
```

---

## Essential Variables

### Audio Input (read-only)

- `bass` - Low frequency intensity (0-1)
- `mid` - Mid frequency intensity (0-1)
- `treb` - High frequency intensity (0-1)
- `bass_att` - Bass attenuated (smoothed)
- `mid_att` - Mid attenuated
- `treb_att` - Treble attenuated

### Time

- `time` - Elapsed time (manually incremented)
- `frame` - Frame counter (if available)

### Warp Effects (per_frame)

- `zoom` - Zoom factor (1.0 = no zoom)
- `rot` - Rotation in radians
- `cx`, `cy` - Center point (0.5, 0.5 = screen center)
- `dx`, `dy` - Translation offsets
- `warp` - Warp intensity
- `sx`, `sy` - Stretch X/Y

### Color & Decay (per_frame)

- `decay` - Frame persistence (0.9-0.99 typical)
- `gamma` - Brightness curve (1.0-4.0)
- `wave_r`, `wave_g`, `wave_b` - Wave colors (0-1)
- `ob_r`, `ob_g`, `ob_b` - Outer border colors
- `ib_r`, `ib_g`, `ib_b` - Inner border colors

### Per-Pixel Variables

- `x`, `y` - Current pixel position (0-1)
- `rad` - Distance from center
- `ang` - Angle from center
- `zoom`, `rot` - Inherited from per_frame (can modify)

### Q Variables (data passing)

- `q1` through `q8` - General-purpose variables
- Set in `per_frame`, read in `per_pixel`

---

## Common Patterns

### 1. **Beat-Reactive Zoom**

```milk
/* per_frame */
beat = (bass + mid + treb) * 0.33;
zoom = 1.0 + 0.05 * beat;
```

### 2. **Smooth Rotation**

```milk
/* per_frame */
rot = rot + 0.01 * sin(time * 0.5);
```

### 3. **Radial Warp (per_pixel)**

```milk
/* per_frame */
q1 = bass * 0.5;

/* per_pixel */
zoom = zoom + rad * q1 * sin(ang * 4);
```

### 4. **Color Cycling**

```milk
/* per_frame */
wave_r = 0.5 + 0.5 * sin(time * 0.7);
wave_g = 0.5 + 0.5 * sin(time * 0.9);
wave_b = 0.5 + 0.5 * cos(time * 1.1);
```

### 5. **Pulse on Beat**

```milk
/* per_frame */
bass_impact = max(0, bass - bass_att);
zoom = 1.0 + 0.1 * bass_impact;
```

---

## Math Functions

- `sin(x)`, `cos(x)`, `tan(x)`
- `sqrt(x)`, `pow(x, y)`
- `abs(x)`, `min(x, y)`, `max(x, y)`
- `log(x)`, `exp(x)`
- `rand(n)` - Random 0-n
- `if(cond, true_val, false_val)` - Conditional

---

## Scorebot Quality Checks

Our Scorebot will flag:

- [FAIL] **Aspect skew** - Canvas/DPR mismatch
- [FAIL] **Black frames** - Decay too low or no motion
- [FAIL] **Low motion** - Boring static visuals
- [FAIL] **Frame drops** - Too expensive per_pixel
- [PASS] **Good beat sync** - Audio correlation high
- [PASS] **Smooth blend** - No jarring transitions

---

## Authoring Tips

1. **Start simple** - Test with basic zoom/rot before complex per_pixel
2. **Use q1-q8** - Pass computed values from per_frame to per_pixel
3. **Smooth with sin/cos** - Avoid hard edges in motion
4. **Test beat response** - Clap or play music with strong bass
5. **Decay balance** - Too low = trails too short, too high = muddy
6. **Keep per_pixel cheap** - Expensive math here kills FPS

---

## Hot Reload from Cursor

Save your `.milk` file, then trigger reload:

```bash
# From Cursor integrated terminal
curl -X POST http://localhost:7001/preset \
  -H "Content-Type: application/json" \
  -d @my_preset.json

# Or use PowerShell
pwsh scripts/reload-preset.ps1 -PresetFile my_preset.milk -Blend 2.5
```

The engine will blend to your new preset over 2.5 seconds.

---

## Advanced: Custom Shapes & Waves

```milk
[preset00]
/* ... preset init ... */

shapecode_0_enabled=1
shapecode_0_sides=64
shapecode_0_x=0.5
shapecode_0_y=0.5
shapecode_0_rad=0.3
shapecode_0_r=1; shapecode_0_g=0; shapecode_0_b=0;
shapecode_0_a=0.8;

per_frame_1=shapecode_0_rad = 0.2 + 0.1 * bass;
```

Shapes render at specified `(x, y)` with `sides` (3=triangle, 64=circle), size `rad`, and color `(r,g,b,a)`.

---

## ECRR Integration

Every preset change:

1. [E] **Examine** - Capture current FPS, motion, aspect
2. [C] **Clean** - Load preset with blend
3. [R] **Report** - Scorebot emits metrics
4. [R] **Role** - If FAIL, rollback to last-known-good

Logged to `docs/BossCat/BOSSCAT_LOG.md` and `artifacts/viz-engine/`.

---

**Reference:** [Geisswerks Milkdrop Authoring Guide](https://www.geisswerks.com/milkdrop/milkdrop_preset_authoring.html)

**BossCat Mission:** Fast iterate -> score -> refine visual loop  
**Status:** READY for Codex-driven authoring

