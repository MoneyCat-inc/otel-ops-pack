# Resonai Default Visualization (Neon Pulse)

This package ships a single, tasteful default MilkDrop preset and a tiny helper script for Windows 11. It reacts to system audio via WASAPI loopback (MilkDrop/ProjectM handle this themselves), so no extra audio wiring is required.

- Tetragram: MILK

## What’s Included

- Preset: `Resonai - Default (Neon Pulse).milk`
- Helper: `scripts/visuals/Install-ResonaiDefault.ps1`

## Quick Start (Windows 11)

### Install Single Default Preset

1) Install MilkDrop 3 (portable EXE) or compatible ProjectM build
2) Run installer:
   ```powershell
   pwsh -File scripts/visuals/Install-ResonaiDefault.ps1 -Launch
   ```
3) In MilkDrop 3, press `L` and load "Resonai - Default (Neon Pulse)"

### Install Complete Pack v1 (5 Presets)

1) Run pack installer:
   ```powershell
   pwsh -File scripts/visuals/Install-PresetPack.ps1 -Launch -Validate
   ```
2) Script auto-detects MilkDrop3 folder (or prompts)
3) Validates all presets for safety (optional `-Validate` flag)
4) Launches MilkDrop3 if `-Launch` specified
5) Press `L` in MilkDrop3 to browse pack (RN-001 through RN-005)

### Handy Keys (MilkDrop 3)

- `F7`: Always-on-top window
- `F3`: Auto-transition seconds (set high to hold the default)
- `C`: Randomize colors
- `S`: Save any variant

## Notes

- The preset avoids custom GPU shaders for maximum compatibility (MilkDrop 2/3, ProjectM).
- It uses per-frame/per-pixel equations and a custom circular spectrum wave, tuned for clean response on both music and voice.
