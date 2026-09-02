# Drive cleanup for Windows 11 update

> **SUPERSEDED — do not run the reset step (2026-09-02).** The "Docker WSL reset" below deletes
> every image, container and volume, including the SigNoz ClickHouse data. The 2026-08-18 VHDX
> incident (516 GB) was closed with bounded retention and in-place compaction instead; follow
> `docs/DOCKER_VHDX_MAINTENANCE.md`. Kept as the record of the original one-off cleanup note.

Scan showed **Docker is ~202 GB** on C:. Other targets: Windows Update cache (~5 GB), Package Cache (~4 GB), user caches.

## Summary: What to run

| Action | Frees | How |
|--------|--------|-----|
| **Docker WSL reset** | **~202 GB** | Run `scripts\reset-docker-wsl-free-space.ps1` **as Administrator** (see below). |
| **Windows Update cache** | ~5 GB | Run `scripts\free-drive-space-admin.ps1` **as Administrator**. |
| **Storage / Disk Cleanup** | Variable | Settings → System → Storage → Temporary files → Remove files. Or run `cleanmgr` as admin and select all. |
| **Package Cache** | ~4 GB | After admin script, or: Disk Cleanup → Clean up system files → check "Windows Update Cleanup". |

---

## 1. Reduce Docker footprint by ~50% (actually ~100% → fresh disk)

Docker data is **~202 GB** in `C:\Users\fubum\AppData\Local\Docker\wsl\disk\docker_data.vhdx`.  
<!-- markdownlint-disable-next-line MD013 -->
Docker is not running correctly, so the only way to free this space is to **reset Docker’s WSL data**. That deletes all images, containers, and volumes and frees the whole disk; next start creates a new, small disk.

**Steps:**

1. **Right‑click PowerShell → Run as administrator.**
2. **Run:**

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   cd c:\otel\scripts
   .\reset-docker-wsl-free-space.ps1
   ```

3. When prompted, type **YES** and press Enter.
<!-- markdownlint-disable-next-line MD013 -->
1. After it finishes, start **Docker Desktop**. It will create a new small `docker_data.vhdx` (a few GB). You can pull images again as needed.

**Result:** ~202 GB freed; Docker footprint effectively reduced by 100% (then grows again as you use it).

---

## 2. Windows and system cleanups (~5–10+ GB)

**Run the admin cleanup script (Windows Update cache, Delivery Optimization, Windows Temp):**

1. **Right‑click PowerShell → Run as administrator.**
2. **Run:**

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   cd c:\otel\scripts
   .\free-drive-space-admin.ps1
   ```

**Then use Storage / Disk Cleanup for more:**

- **Settings → System → Storage → Temporary files** → select all → **Remove files**.
<!-- markdownlint-disable-next-line MD013 -->
- Or open **Disk Cleanup** (`cleanmgr`) as admin → **Clean up system files** → select **Windows Update Cleanup**, Temporary files, etc. → OK.

---

## 3. Optional: More space (advanced)

- **Hibernation:** If you don’t need hibernation, run in **Admin CMD**:  
  `powercfg /h off`  
  That removes `hiberfil.sys` (often several GB). To turn it back on: `powercfg /h on`.
<!-- markdownlint-disable-next-line MD013 -->
- **Package Cache (e.g. ~4 GB):** Often under `C:\ProgramData\Package Cache`. Disk Cleanup “Windows Update Cleanup” and “Temporary files” can clear some of it; deleting the folder by hand can break future repair/uninstall of some apps, so prefer Disk Cleanup.

---

## Drive scan results (reference)

| Location | Size (approx) |
|----------|----------------|
| `C:\Users\fubum\AppData\Local\Docker` | **201.64 GB** |
| `C:\Windows\SoftwareDistribution` | 5.24 GB |
| `C:\Windows\SoftwareDistribution\Download` | 5.17 GB |
| `C:\ProgramData\Package Cache` | 4.33 GB |
| `C:\ProgramData\Microsoft` | 12.36 GB |
| `C:\Users\fubum\AppData\Local\pnpm` | 0.66 GB |
| User Temp, Recycle Bin | (already cleaned) |

Largest single win: **Docker WSL reset (~202 GB)**. Then **admin script + Storage/Disk Cleanup** for another **~5–10+ GB**.
