# Resonai Pack v1 - Preset Previews

**Purpose**: Visual previews of each preset for quick reference and selection.

**Status**: 📋 Capture guide provided; GIF binaries deferred to follow-up

---

## 🎬 Capture Guide

### Recommended Tools (Windows 11)

#### Option 1: Xbox Game Bar (Built-in) ⭐ Easiest

1. Press `Win + G` to open Game Bar
2. Click "Capture" widget → "Record" button (or `Win + Alt + R`)
3. Load preset in control.html
4. Record for 5-8 seconds
5. Stop recording (`Win + Alt + R` again)
6. Find video in `C:\Users\<username>\Videos\Captures\`
7. Convert to GIF using online tool or FFmpeg (see below)

#### Option 2: ShareX (Free, Recommended for GIF) ⭐ Best Quality

1. Download: https://getsharex.com/
2. After install: `Task settings → Screen recorder → Screen recording options`
3. Set `Screen recorder` to **FFmpeg**
4. Output: Set to **GIF** in encoder settings
5. Configure hotkey (e.g., `Ctrl + Shift + Print Screen`)
6. Record 5-8 seconds per preset
7. Output automatically saved to ShareX folder

#### Option 3: OBS Studio (Advanced)

1. Download: https://obsproject.com/
2. Add `Window Capture` source → select browser window
3. Configure Settings → Output → Recording Quality
4. Record 5-8 seconds
5. Convert MP4 to GIF with FFmpeg (see below)

---

## 📐 Capture Settings

| Setting | Value | Notes |
|---------|-------|-------|
| **Duration** | 5-8 seconds | Long enough to show pattern |
| **Resolution** | 800x600 or 1024x768 | 4:3 aspect ratio |
| **FPS** | 30 fps | Sufficient for preview |
| **Audio** | Muted | Visuals only |
| **Target Size** | ≤2MB per GIF | Optimize with palette |

---

## 📋 Naming Convention

```
RN-001-CircuSpectra-preview.gif
RN-002-HaloBloom-preview.gif
RN-003-VectorGrid-preview.gif
RN-004-LiquiRing-preview.gif
RN-005-LineDancer-preview.gif
```

**Pattern**: `RN-<ID>-<PresetName>-preview.gif`

---

## 🛠️ FFmpeg Conversion (if needed)

### Install FFmpeg

**Windows** (via Chocolatey):
```powershell
choco install ffmpeg
```

**Or download**: https://ffmpeg.org/download.html

### Convert MP4 to GIF

```bash
# Basic conversion
ffmpeg -i input.mp4 -vf "fps=30,scale=800:-1:flags=lanczos" -loop 0 output.gif

# Optimized with palette (smaller file size, better quality)
ffmpeg -i input.mp4 -vf "fps=30,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif
```

### Optimize Existing GIF

```bash
# Reduce file size
ffmpeg -i input.gif -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output-optimized.gif
```

---

## 📝 Step-by-Step Workflow

### 1. Prepare Control Surface

```powershell
# From repo root
start docs\BossCat\visuals\control.html
```

- Click "Start Mic" (or use Stereo Mix for desktop audio)
- Load first preset: RN-001 CircuSpectra

### 2. Record Each Preset

1. **Start recording** (Xbox Game Bar: `Win + Alt + R`)
2. **Wait 5-8 seconds** (let pattern establish)
3. **Stop recording** (`Win + Alt + R`)
4. **Load next preset** (`Next ▶` button)
5. **Repeat** for all 5 presets

### 3. Convert & Optimize

```bash
# Batch convert all MP4s to GIF (PowerShell)
Get-ChildItem *.mp4 | ForEach-Object {
  $out = $_.BaseName + ".gif"
  ffmpeg -i $_.FullName -vf "fps=30,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $out
}
```

### 4. Rename & Move

```powershell
# Rename to convention
Rename-Item "capture1.gif" "RN-001-CircuSpectra-preview.gif"
Rename-Item "capture2.gif" "RN-002-HaloBloom-preview.gif"
# ... etc

# Move to previews folder
Move-Item *-preview.gif docs\BossCat\visuals\previews\
```

---

## 📦 Preview Folder Structure

```
docs/BossCat/visuals/previews/
├── README_previews.md (this file)
├── RN-001-CircuSpectra-preview.gif (placeholder)
├── RN-002-HaloBloom-preview.gif (placeholder)
├── RN-003-VectorGrid-preview.gif (placeholder)
├── RN-004-LiquiRing-preview.gif (placeholder)
└── RN-005-LineDancer-preview.gif (placeholder)
```

**Current Status**: Folder structure ready, GIF binaries deferred to follow-up commit

---

## 🚀 Future: Automated Capture

**Phase-5 Enhancement** (Deferred):
- Headless Butterchurn render (Puppeteer/Playwright)
- Preset load → 8s record → GIF export
- Batch process entire pack automatically
- CI/CD integration for preset updates

**Rationale**: Manual capture sufficient for Phase-4; automation adds complexity

---

## ⚠️ Git Considerations

**Note**: GIF files are **binary and relatively large** (≤2MB each = ~10MB total for 5 presets)

**Options**:
1. **Add to Git** (current approach): Simple, but increases repo size
2. **Git LFS**: Better for binary files, requires LFS setup
3. **External Hosting**: CDN/S3, keep repo lean

**Recommendation**: Add to Git for Phase-4 (simplicity), consider LFS/CDN if library grows significantly (>20 presets).

---

## 📊 Quality Checklist

Before committing GIFs, verify:

- [ ] Duration: 5-8 seconds ✅
- [ ] Resolution: 800x600 or 1024x768 ✅
- [ ] File size: ≤2MB each ✅
- [ ] Loop: Infinite ✅
- [ ] Pattern visible: Preset characteristics clear ✅
- [ ] Naming: Follows convention ✅
- [ ] Placement: In `previews/` folder ✅

---

## 🐾 BossCat Notes

**Phase-4 Scope**: Documentation and folder structure only  
**Binaries**: Deferred to follow-up commit to keep Phase-4 lean  
**Budget**: This guide ~140 lines (within ≤200 LOC limit)

**Next**: Capture GIFs manually and add in separate commit

---

**Created**: 2025-10-16  
**Lane**: MILK  
**Phase**: Phase-4 (Low-Intensity & Discoverability)  
**Status**: ✅ Guide complete, awaiting captures

