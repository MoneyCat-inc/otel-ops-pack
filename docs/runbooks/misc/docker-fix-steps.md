# Docker Desktop failing to start – fix steps

## What’s going on
- **Privileged helper service** is not running (Docker needs admin to start it).
- **Engine never finishes starting** (stuck “starting”, HTTP 500 on _ping).
- **docker-desktop-data** is missing from `wsl -l -v`; the data disk may be broken after VHDX compact.

---

## Step 1: Use Docker’s “Start service” (elevated)

1. Open **Docker Desktop**.
2. When the dialog says **“Privileged helper service is not running”**, click **“Start service”**.
3. Approve the **UAC (admin)** prompt.
4. Wait for Docker to finish starting.

If the engine still never becomes ready, go to Step 2.

---

## Step 2: Restart Docker service as admin

1. **Quit Docker Desktop** (tray icon → Quit).
2. Open **PowerShell as Administrator** and run:

```powershell
Restart-Service com.docker.service -Force
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

3. Wait 1–2 minutes and see if Docker shows “Engine running”.

If it’s still stuck, go to Step 3.

---

## Step 3: Reset WSL Docker distros (fixes broken data disk)

This **deletes all images, containers, and volumes** and lets Docker create a new data disk. Only do this if you’re OK losing that data.

1. **Quit Docker Desktop** (tray → Quit).
2. Open **PowerShell or CMD as Administrator**:

```powershell
wsl --shutdown
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data
```

3. Start **Docker Desktop** again. It will recreate `docker-desktop` and `docker-desktop-data` and a new `docker_data.vhdx`.
4. Wait for the first start to finish (can take a few minutes).

After this, Docker should start normally. The new VHDX will be small and will grow again as you use Docker. To avoid it growing too much in the future:

- Regularly run: `docker system prune -a -f` (and optionally `docker volume prune -f`).
- Then quit Docker, run `wsl --shutdown`, and compact the VHDX (as before) **only when you’re sure the compact completed successfully**.

---

## If you still see “Privileged helper service” after Step 3

- Run **Docker Desktop** once by **right‑click → Run as administrator**.
- Or repair/reinstall Docker Desktop from **Settings → Apps → Docker Desktop → Modify/Repair**.
