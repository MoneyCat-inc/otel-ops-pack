# SlimeVR + Smol Slimes V2-Q + Quest 3 — Full Setup Runbook

**Hardware:** 6× Smol Slimes V2-Q trackers · 3× nRF52840 USB dongles (EBYTE E104-BT5040U) · Meta Quest 3  
**Primary path:** Virtual Desktop → SteamVR → VRChat (PCVR, no base stations)

---

## 1. Prereqs

- **PC:** Windows 10/11, Bluetooth 4.0+ (or USB Bluetooth adapter). SlimeVR Server runs on the PC.
- **Quest 3:** Updated, charged. Used as HMD only; tracking comes from SlimeVR.
- **Hardware on hand:**
  - 6× Smol Slimes V2-Q trackers (charged)
  - 3× nRF52840 dongles (EBYTE E104-BT5040U)
  - USB cables for charging trackers and flashing dongles
- **Software:**
  - [SlimeVR Server](https://github.com/SlimeVR/SlimeVR-Server/releases) (latest stable)
- [SlimeVR Web Flasher](https://slimevr.dev/setup) (preferred) or Nordic’s **nRF Connect for Desktop** (vendor download;
some bots get HTTP 403) + **nRF Connect** app (for nRF52840)
  - Virtual Desktop (Quest Store) + Virtual Desktop Streamer (PC)
  - Steam + SteamVR
  - VRChat (Steam)
- **Environment:** Same room for PC and play space; minimal metal between dongles and trackers.

**Success criteria:** You have all hardware, cables, and software installers ready; PC and Quest 3 are on and updated.

---

## 2. Install SlimeVR Server

1. Download the latest **SlimeVR Server** Windows build from
   [releases](https://github.com/SlimeVR/SlimeVR-Server/releases).
2. Extract to a folder (e.g. `C:\SlimeVR`). Do **not** run from inside ZIP.
3. Run `SlimeVR.exe`. On first run, it may create `config` and `logs` under the install folder.
4. Confirm the SlimeVR Server window shows “Waiting for trackers…” (or similar) and that the system tray icon appears.
5. Optionally: enable “Launch at Windows startup” in SlimeVR settings if you use FBT often.

**Success criteria:** SlimeVR Server starts without errors, shows a GUI/tray icon, and indicates it is waiting for
trackers.

---

## 3. Flash Receiver Firmware to nRF52840 Dongles

Each of the **3** dongles must run the **SlimeVR nRF52840 receiver firmware** (not generic nRF firmware).

1. **Get the firmware:**  
Download the **nRF52840 dongle / receiver** build from [SlimeVR
firmware](https://github.com/SlimeVR/SlimeVR-OpenVR-Driver/wiki/Supported-hardware) or the SlimeVR Discord docs. The
file is typically a `.hex` or `.uf2` for nRF52840 USB dongles.

2. **Connect one dongle:**  
   Plug **one** E104-BT5040U into a USB port. Avoid hubs for flashing if you have flakiness.

3. **Flash via Web Flasher (recommended):**
   - Open [SlimeVR Web Flasher](https://slimevr.dev/setup) in Chrome/Edge.
   - Put the dongle in **bootloader mode** if required (see dongle docs; some
     E104-BT5040U use double-tap reset or a button).
   - Select the nRF52840 dongle when it appears. If it does **not** appear, see
     **Troubleshooting → Dongle not detected by web flasher**.
   - Choose the **receiver** firmware for nRF52840 and flash.
   - Wait until “Flash complete” or similar. Unplug, then repeat for the **other two** dongles.

4. **Alternative — nRF Connect for Desktop:**  
Install nRF Connect for Desktop, add the **nRF Connect** app, open “Programmer,” select the nRF52840 dongle, load the
`.hex`, and program. Repeat per dongle.

5. **Label dongles A, B, C** (e.g. small stickers) so you can match them to tracker groups later.

**Success criteria:** All three dongles are flashed with SlimeVR receiver firmware, and you can re-plug each and see it
enumerate as a USB device (and in SlimeVR once the server is running).

---

## 4. Power On + Verify Trackers

1. **Charge all 6 Smol Slimes V2-Q** until at least 50% (LED indication per manufacturer).
2. **Power on all 6 trackers.** Use the usual button/long-press method for Smol Slimes.
3. **Plug the 3 flashed dongles** into USB ports on your PC. Prefer direct motherboard USB over unpowered hubs.
4. **Start SlimeVR Server** if not already running.
5. **Wait 1–2 minutes.** Trackers pair to dongles automatically (each dongle handles 2 trackers). SlimeVR may show
“Tracker X connecting…” then “Tracker X connected.”
6. In the SlimeVR UI, verify you see **6 trackers** with connection status. If fewer appear, see **Troubleshooting →
Trackers not appearing**.

**Success criteria:** SlimeVR Server shows 6 trackers connected. All have green/active status.

---

## 5. Pairing Notes for A/B/C

- **Dongle A:** Trackers 1 & 2  
- **Dongle B:** Trackers 3 & 4  
- **Dongle C:** Trackers 5 & 6  

SlimeVR assigns tracker indices dynamically. The exact mapping (which physical tracker is “1” vs “6”) can change. What
matters is that **after** pairing you **Assign Body Parts** consistently. Use **Strap Placement** and **Calibration** to
lock in a repeatable setup.

- If you swap dongles or trackers, you may need to re-pair and re-assign. Prefer **same USB ports** and **same strap
positions** for stability.

**Success criteria:** You know which dongles correspond to which pair of trackers, and SlimeVR shows 6/6 connected.

---

## 6. Assign Body Parts (6-tracker layout)

Use the **6-tracker layout**:

| Tracker | Body part |
|--------|-----------|
| 1 | Left foot / ankle |
| 2 | Right foot / ankle |
| 3 | Left knee / thigh |
| 4 | Right knee / thigh |
| 5 | Waist / hip |
| 6 | Chest |

In SlimeVR Server:

1. Open the tracker list / configuration.
2. For each of the 6 trackers, assign the correct **body part** (left foot, right foot, left knee, right knee, waist,
chest). The UI may use “Left Lower Leg,” “Right Upper Leg,” etc.; map them to the table above.
3. Save configuration. SlimeVR persists this.

**Success criteria:** All 6 trackers have the correct body-part assignments. The skeleton preview (if available) shows
feet, knees, waist, and chest.

---

## 7. Strap Placement Guidelines

- **Ankles (×2):** Secure on the ankle or top of the foot, sensor facing forward. Same side each time (L/R).
- **Thighs (×2):** Above the knee, on the thigh. Avoid blocking IR or putting over loose fabric that shifts.
- **Waist (×1):** Centered on hip/waist, either belt clip or strap. Stable, not sliding.
- **Chest (×1):** Upper chest or sternum. Often via harness or high strap. Keep upright.

Consistent placement reduces **skeleton twisted** and **yaw drift** issues. See **Troubleshooting** if the avatar is
twisted or drifts.

**Success criteria:** Trackers are strapped in the same positions you will use every session; no loose or sliding units.

---

## 8. Calibration (SlimeVR + VRChat)

### SlimeVR calibration

1. Stand in your **normal T-pose** (arms out, feet shoulder-width).
2. In SlimeVR, start **Reset** or **Calibration** (depending on UI wording).
3. Follow the in-app prompts (e.g. hold pose, then relax). Some versions use “Reset” repeatedly for alignment.
4. Optional: **Mounting reset** if you changed how trackers are oriented on your body.

### VRChat

1. Ensure **SteamVR** is running and sees the SlimeVR trackers (SlimeVR driver feeds SteamVR).
2. Open **VRChat** via Steam. Put on the Quest 3 (Virtual Desktop) and enter a world.
3. Check **VRChat Settings → Tracking**. You should see additional trackers (feet, knees, etc.). If not, see
**Troubleshooting → VRChat not seeing trackers even though SlimeVR does**.
4. In VRChat, run **Calibrate FBT** (or equivalent) when prompted. Usually: stand in T-pose, then confirm.

**Success criteria:** SlimeVR skeleton looks correct in its preview; VRChat shows FBT trackers and your in-game avatar
reflects your movements without obvious twist or drift.

---

## 9. Quest 3 Connection Paths

**Primary (recommended):** **Virtual Desktop → SteamVR → VRChat**

1. **PC:** Virtual Desktop Streamer running, logged in. Steam running. SlimeVR Server running, 6 trackers connected.
2. **Quest 3:** Virtual Desktop app; connect to same PC.
3. **Quest 3:** Launch **SteamVR** from Virtual Desktop, then **VRChat** from the SteamVR dashboard.
4. Put on headset, calibrate FBT in VRChat if needed.

**Alternatives (same PC setup):**

- **Link (USB)** or **Air Link:** Oculus app + SteamVR + VRChat. SlimeVR still runs on PC and feeds SteamVR.
- **ALVR:** Similar idea—ALVR bridges Quest to PC SteamVR; SlimeVR remains on PC.

SlimeVR always runs on the **PC**. The Quest 3 is the HMD; tracker data goes PC → SteamVR → VRChat.

**Success criteria:** You can connect via Virtual Desktop, launch SteamVR and VRChat, and use full-body tracking in
VRChat.

---

## 10. Troubleshooting

### Trackers not appearing

- **Check power:** All 6 trackers on and charged. Try a full power-off/power-on cycle.
- **Check dongles:** All 3 plugged in, flashed with **receiver** firmware. Try different USB ports (direct to PC).
- **Restart SlimeVR Server.** Close fully, unplug dongles, plug back in, start server, then power trackers.
- **Distance / interference:** Bring trackers close to dongles, reduce obstacles. Avoid too many active Bluetooth
devices nearby.
- **Success criteria:** All 6 trackers show as connected in SlimeVR.

### Dongle not detected by web flasher

- **Bootloader mode:** Put dongle in bootloader (double-tap reset, hold button, etc. per E104-BT5040U docs).
- **Browser:** Use **Chrome** or **Edge**; grant WebUSB access when prompted.
- **USB:** Try another port; avoid hubs. Unplug other nRF devices temporarily.
- **Drivers:** On Windows, generic WinUSB is usually enough. If you used nRF Connect before, ensure no exclusive driver
is bound.
- **Run `C:\otel\scripts\slimevr-usb-dongles.ps1`** to confirm Windows sees the dongles (PnP, Hardware IDs). If nothing
nRF-related appears, the OS may not be enumerating them.
- **Success criteria:** Dongle appears in Web Flasher; flash completes.

### Skeleton twisted

- **Re-calibrate:** SlimeVR **Reset** / **Calibration** in T-pose. Do **Mounting reset** if you changed orientation.
- **Strap placement:** Match **Strap Placement Guidelines**; avoid swapping L/R or flipping sensors.
- **Assign body parts:** Confirm **Assign Body Parts** matches your physical layout (left/right, waist, chest).
- **Success criteria:** Skeleton preview in SlimeVR and avatar in VRChat are aligned with your real pose.

### Yaw drift / re-center

- **Reset in SlimeVR:** Use **Reset** (or “Recenter”) during use. Make a habit of recentering after long sessions.
- **Reduce magnetic interference:** Keep away from speakers, PCs, heavy metal. Same play space helps.
- **Strap consistency:** Same placement each time reduces drift.
- **VRChat:** Use in-game **Calibrate FBT** / re-center if the avatar rotates but SlimeVR looks fine.
- **Success criteria:** Yaw holds reasonably; recenter restores correct facing.

### Quest 3 drift tuning (yaw drift, "body slowly rotates", foot weirdness)

IMU-based tracking can drift a bit over time. The goal is to reset the *right* layer, in the *right* order, so you don't
fight yourself.

#### What to reset (in order)

1. **If your view/origin is wrong** (the whole world feels rotated/offset):
   - Recenter in **Quest / SteamVR / Virtual Desktop** first.
2. **If only the avatar body heading is wrong** (you're facing forward IRL, avatar slowly turns):
   - In **SlimeVR Server**, use **Reset yaw / Reset heading** if available.
   - If you don't see that option, do **Reset trackers** → quick **Full Body Calibration**.
3. **If VRChat's IK is wrong** (knees snapping, hips offset, legs feel "inside out"):
   - Re-run **VRChat Full-Body Calibration** after SlimeVR is correct.

#### Preventing drift (the boring stuff that actually works)

- **Keep dongles away from the PC case**: use short USB extension leads so receivers are out in the open.
- **Space dongles apart** a bit (even 10–20cm helps) to reduce 2.4GHz self-noise.
- **Avoid metal/magnets near trackers**: desk frames, speakers, big power bricks, radiator pipes, etc.
- **Straps must not rotate** (especially waist + chest). Rotation looks like drift.
- **Calibrate once you're in your normal play stance** (feet planted, relaxed posture).

#### 10-second "panic reset" mid-session

1. Stand still, feet planted.
2. SlimeVR: **Reset yaw / Reset trackers**.
3. SlimeVR: **Full Body Calibration** (hold still a few seconds).
4. VRChat: re-calibrate FBT if needed.

### VRChat not seeing trackers even though SlimeVR does

- **SteamVR:** Ensure SteamVR is running and shows **base stations** and **trackers**. SlimeVR driver adds them as
virtual trackers. Restart SteamVR.
- **SlimeVR → SteamVR:** Confirm SlimeVR is set to output to **SteamVR** (or OpenVR). Check SlimeVR settings.
- **VRChat:** **Settings → Tracking** (or **Calibration**). Enable “Use trackers” / FBT. Run **Calibrate FBT**.
- **Order of launch:** Start **SlimeVR Server** first, then **SteamVR**, then **VRChat**.
- **Success criteria:** VRChat tracking settings show trackers; FBT works in-world.

---

## 11. Recovery / Fast Reset

When something breaks (trackers missing, skeleton wrong, VRChat no FBT):

1. **Close VRChat** and **SteamVR**.
2. **Quit SlimeVR Server** completely (tray icon → exit).
3. **Power off all 6 trackers.**
4. **Unplug all 3 dongles.**
5. **Wait ~10 seconds.**
6. **Plug dongles** back into the **same** USB ports.
7. **Start SlimeVR Server.** Wait until it’s “waiting for trackers.”
8. **Power on all 6 trackers.** Wait 1–2 minutes for 6/6 connected.
9. **Start SteamVR**, then **VRChat**.
10. **Calibrate** in SlimeVR (Reset) and in VRChat (Calibrate FBT).

Avoid changing USB ports, strap positions, or hardware mid-session.
Use **`slimevr-smolslimes-checklist.md`** for a quick sanity check.

**Success criteria:** 6 trackers connected, correct body-part assignment, SlimeVR and VRChat calibrated; FBT works in
VRChat.

---

*Last updated: keep aligned with `docs/vr/README.md`.*
