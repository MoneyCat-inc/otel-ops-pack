# VR Tracking — Smol Slimes (Quest 3)

This folder contains the **authoritative setup and recovery docs** for the Quest 3 full-body tracking configuration using:

- 6× Smol Slimes V2-Q trackers (A/B/C groups)
- 3× nRF52840 USB dongles (EBYTE E104-BT5040U)
- SlimeVR Server (Windows)
- PCVR via Virtual Desktop → SteamVR → VRChat

No base stations. No DIY builds.

---

## 🚀 Start Here

If this is a fresh setup, open:

➡️ **`slimevr-smolslimes-quest3-setup.md`**

That document walks from:

- zero hardware
- to working full-body tracking in VRChat

---

## ✅ Quick Checklist

If you already know what you're doing and just want to sanity-check:

➡️ **`slimevr-smolslimes-checklist.md`**

Use this after:

- Windows updates
- USB changes
- SlimeVR updates
- "Why is my body twisted" moments

---

## 🧰 Utilities

Optional helper scripts:

- **`C:\otel\scripts\slimevr-usb-dongles.ps1`** — enumerate likely nRF52840 dongles (PnP, Hardware IDs, COM).

  Use if: dongles don't appear in the flasher, Windows stops seeing USB devices, or you want to confirm receivers are present.

<!-- markdownlint-disable-next-line MD013 -->
- **`C:\otel\scripts\slimevr-sanity-check.ps1`** — one-command readiness check (dongles + serial ports + SlimeVR Server port 6969). Prints **READY** / **NOT READY** and exits 0/1.

  Use if: quick "am I good to play?" check; also referenced in the checklist.

---

## 🧠 Design Notes (intent)

This setup intentionally prioritizes:

- reliability
- repeatability
- fast recovery

It is the **6-tracker sweet spot**:

- ankles ×2
- thighs ×2
- waist ×1
- chest ×1

Extra trackers are intentionally avoided unless doing mocap or performance capture.

---

## 🔄 Recovery Philosophy

If something breaks:

1. Follow **Recovery / Fast Reset** in the setup doc
2. Re-calibrate calmly
3. Do not add hardware variables mid-session

This system is stable when treated as a system.

---

_Last updated: keep this file aligned with the runbook._
