# Unraid deploy guide — parking automation

Do this on **Unraid OS 7.3.2** with **Compose Manager Plus**. Steps use WebGUI labels, Mac Finder SMB and/or SSH, and the Unraid Terminal.

Goal: run evening SSO + midnight booking on your home server in a Docker container. Config and session live under `/mnt/user/appdata/parking/` so rebuilds do not wipe secrets.

Prefer this Docker path over an Ubuntu VM. Do **not** install Node, Playwright, or Java on the Unraid **host**. Do **not** add parking jobs under **Settings → User Scripts** — cron runs **inside** the `parking` container.

Handbook cross-refs (Brian-HomeServer repo on your Mac): Docker setup → chapter `05`; SSH enable → chapter `09`; SMB users/shares → chapter `15`.

---

## Before you start

| Check | Where (7.3.2) |
|-------|----------------|
| Array **Started** | **Main** |
| Share `appdata` Primary = `cache`, Secondary = **None** | **Shares → appdata** |
| Docker enabled | **Settings → Docker** (if path fields look missing: switch to **Advanced View**, set Enable Docker = **No**, edit paths, then **Yes** — chapter `05`) |
| **Compose Manager Plus** installed (author **mstrhakr**, not the old Compose Manager) | **Plugins** |
| Projects Folder = `/mnt/user/appdata/compose-projects` | **Settings → Compose Manager Plus** (may show as **Settings → Compose**) |
| Phone ready for **PingID** | — |

**If using Method A (Finder SMB)**

| Check | Where |
|-------|--------|
| SMB enabled; user `brian` can write `documents` | Chapter `15`; Finder ⌘K → `smb://192.168.0.10` |
| Share `documents` Export = **Yes** | **Shares → documents** |

**If using Method B (SSH / scp)**

| Check | Where |
|-------|--------|
| **SSH** = **Yes**, **Telnet** = **No** | **Settings → Management Access** (chapter `09`) |
| Mac can log in as root | `ssh root@192.168.0.10` (Unraid root password from the WebGUI) |

Notes:

- SMB day-to-day user is **`brian`**. SSH / WebGUI Terminal are **`root`**. Do not use `root` for Finder SMB.
- Keep appdata on the always-on `cache` pool so midnight booking does not wait on array spin-up.
- Transfer `resource-scheduler-automation.zip` only (no secrets). Recreate config on Unraid; do **not** copy someone else’s `session.json`.

### Layout

```text
Mac kit (example)
  <repo>/parking-scheduler/
    resource-scheduler-automation.zip
    config-examples/
    UNRAID.md

After deploy on Unraid
  /mnt/user/appdata/compose-projects/parking/   ← Compose Manager Plus stack (build context)
  /mnt/user/appdata/parking/                    ← runtime config, session, logs
    ├── config/
    ├── home/
    ├── aws/          # optional (SSM); omit if using RS_PASSWORD in .env
    ├── output/
    ├── logs-sso/
    └── logs-book/
```

---

## Step 1 — Get the zip onto Unraid (pick one)

Use **Method A** or **Method B**, then continue at Step 2.

### Method A — Finder SMB (no SSH)

`appdata` has SMB **Export = No**, so you cannot drag files straight into `/mnt/user/appdata/...` from Finder. Stage on `documents`, then move with Terminal in later steps.

1. On your Mac, open Finder → **Go → Connect to Server…** (⌘K).
2. Server address: `smb://192.168.0.10` or `smb://brian-server`.
3. Connect As: **Registered User**.
4. Name: `brian` (not root). Password: from your password manager.
5. Mount the **documents** share.
6. Create a folder named `parking-scheduler-staging`.
7. From this repo’s `parking-scheduler/` folder on your Mac, drag **`resource-scheduler-automation.zip`** into that share folder.

Optional: also copy the `config-examples/` folder into the same staging folder (examples also exist inside the zip).

On the server this path is:

`/mnt/user/documents/parking-scheduler-staging/`

### Method B — Mac Terminal SSH / scp

Prereq: SSH enabled (checklist above). Use the Unraid **root** password when prompted.

On your Mac:

```bash
# Connectivity check (optional)
ssh root@192.168.0.10 'uname -a'

ssh root@192.168.0.10 'mkdir -p /mnt/user/appdata/compose-projects/parking /tmp/parking-scheduler-staging'

scp "$HOME/Desktop/My Files/Project X/Brian-HomeServer/parking-scheduler/resource-scheduler-automation.zip" \
  root@192.168.0.10:/tmp/parking-scheduler-staging/
```

Optional:

```bash
scp -r "$HOME/Desktop/My Files/Project X/Brian-HomeServer/parking-scheduler/config-examples" \
  root@192.168.0.10:/tmp/parking-scheduler-staging/
```

SSH keys are optional; password auth with the WebGUI root password is enough for this guide.

---

## Step 2 — Open a shell on Unraid

Either method works; later commands are the same.

| Method | How |
|--------|-----|
| WebGUI Terminal | Unraid WebGUI → top-right **>_** |
| SSH from Mac | `ssh root@192.168.0.10` (or `ssh root@brian-server` if name resolution works) |

Editing files with `nano`: **Ctrl+O**, Enter to save; **Ctrl+X** to exit.

---

## Step 3 — Create directories

In the Unraid shell:

```bash
mkdir -p /mnt/user/appdata/parking/{config,home/.config/resource-scheduler,aws,output,logs-sso,logs-book}
mkdir -p /mnt/user/appdata/compose-projects/parking
```

If you used Method B, some of these may already exist — that is fine.

---

## Step 4 — Unpack into the Compose project folder

### 4a — Go to the staging folder

**After Method A:**

```bash
cd /mnt/user/documents/parking-scheduler-staging
ls -la
```

**After Method B:**

```bash
cd /tmp/parking-scheduler-staging
ls -la
```

You should see `resource-scheduler-automation.zip`.

### 4b — Unzip and copy into the stack folder

```bash
unzip -o resource-scheduler-automation.zip
cp -a parking/. /mnt/user/appdata/compose-projects/parking/
```

### 4c — Verify and set project `.env`

```bash
cd /mnt/user/appdata/compose-projects/parking
ls -la
```

You should see at least:

```text
Dockerfile
docker-compose.yml
docker/
resource-scheduler-sso-login/
resource-scheduler/
bin/
```

Create the Compose project env file (Compose Manager Plus substitutes `${PARKING_APPDATA}` from this):

```bash
cat > /mnt/user/appdata/compose-projects/parking/.env <<'EOF'
PARKING_APPDATA=/mnt/user/appdata/parking
EOF
```

---

## Step 5 — Seed config files on the host

Create real config **files** before the first container start. If a bind-mounted path is missing, Docker may create a **directory** instead of a file — avoid that by seeding first.

```bash
APPDATA=/mnt/user/appdata/parking
SRC=/mnt/user/appdata/compose-projects/parking

cp "$SRC/resource-scheduler-sso-login/.env.example" "$APPDATA/config/.env"
cp "$SRC/resource-scheduler/schedule.env.example" "$APPDATA/config/schedule.env"
cp "$SRC/resource-scheduler/resources.txt.example" "$APPDATA/config/resources.txt"
cp "$SRC/resource-scheduler/reservation.env.example" "$APPDATA/config/reservation.env"

ls -la "$APPDATA/config/"
```

Confirm those four paths are **files**, not directories:

```bash
file "$APPDATA/config/.env" "$APPDATA/config/schedule.env" \
  "$APPDATA/config/resources.txt" "$APPDATA/config/reservation.env"
```

---

## Step 6 — Edit config (happy path: local password)

Default for first-time Unraid setup: put the SSO password in `config/.env` and skip AWS SSM. (SSM is Appendix B.)

### What to edit

| File | Set |
|------|-----|
| `/mnt/user/appdata/parking/config/.env` | `RS_USERNAME=…`, uncomment/set `RS_PASSWORD=…`, keep `HEADED=0`, timezone fields as needed |
| `…/config/schedule.env` | `RS_SCHEDULE_DAYS`, `RS_SCHEDULE_TIME` (Asia/Manila book time) |
| `…/config/resources.txt` | Slot try order (see comments in the example) |
| `…/config/reservation.env` | Start/end window on the booked day (`RS_START_HR` / `RS_END_HR`) |

### How to edit on Unraid 7.3.2

| Method | How |
|--------|-----|
| Terminal / SSH | `nano /mnt/user/appdata/parking/config/.env` (and the other three files) |
| Compose Manager Plus | **Docker** → Compose → **`parking`** → **Compose** / **.ENV** tabs edit only files under `compose-projects/parking/` (project compose + project `.env`). App secrets under `appdata/parking/config/` still need Terminal/`nano` |

Example (Terminal):

```bash
nano /mnt/user/appdata/parking/config/.env
```

Minimal happy-path changes in `.env`:

```bash
RS_USERNAME=your.username
RS_PASSWORD=your-password
HEADED=0
```

Leave `RS_CREDENTIALS_PASSPHRASE_FILE=...` as-is if unused; with local `RS_PASSWORD` you do not need the passphrase file or `aws/` credentials for login.

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**. Repeat for `schedule.env`, `resources.txt`, and `reservation.env`.

Optional lockdown:

```bash
chmod 600 /mnt/user/appdata/parking/config/.env
```

---

## Step 7 — Confirm the Compose Manager Plus stack

1. Open **Docker** in the Unraid top menu.
2. Find the **Compose** section.
3. You should see a stack named **`parking`** (Compose Manager Plus picks up `/mnt/user/appdata/compose-projects/parking/`).

**Do not click Add Stack** — that creates a duplicate like `parking-001`.

If no stack appears:

1. Refresh the Docker page.
2. Confirm **Settings → Compose Manager Plus** (or **Compose**) → Projects Folder = `/mnt/user/appdata/compose-projects`.
3. Confirm `docker-compose.yml` exists:

```bash
ls -la /mnt/user/appdata/compose-projects/parking/docker-compose.yml
```

### Optional stack Settings

Open **Docker** → Compose → **`parking`** → editor tabs.

| Field | Value |
|-------|--------|
| Name | `parking` (leave if already set) |
| Description | optional, e.g. `Asurion parking automation` |
| WebUI URL | leave blank (no published host port) |
| Autostart | **On** (so the stack starts with the array) |

Project **.ENV** tab should show `PARKING_APPDATA=/mnt/user/appdata/parking`. **Save All** if you edited anything.

---

## Step 8 — Build and start

This stack **builds** a local image from `Dockerfile` (unlike Immich, which mostly pulls prebuilt images). First build can take several minutes (Playwright + npm + JDK compile).

### Compose Manager Plus (preferred)

1. **Docker** → Compose → **`parking`** (only one).
2. Open the stack menu.
3. Run **Compose Up** (or **Update Stack** if your plugin build shows that label for rebuild+up). If the UI offers a separate **Build** action, run Build first, then Compose Up.
4. Wait until the container is running.

### Terminal fallback (WebGUI **>_** or SSH)

```bash
cd /mnt/user/appdata/compose-projects/parking
docker compose --env-file .env up -d --build
docker compose ps
docker compose logs --tail=100
```

### Confirm on the Docker tab

| Check | Expected |
|-------|----------|
| Container name | `parking` |
| Status | running / started |
| Restart policy | `unless-stopped` (from compose) |
| Autostart (Compose row) | **On** |

---

## Step 9 — First SSO login (PingID)

Cron will login around 9 PM Asia/Manila; for a daytime test, from Unraid shell (**>_** or SSH):

```bash
docker exec -it parking parking login
```

Approve **PingID** on your phone within about two minutes.

Verify:

```bash
docker exec -it parking parking status
docker exec -it parking parking crontab
ls -la /mnt/user/appdata/parking/output/session.json
```

You should see crontab lines with `CRON_TZ=Asia/Manila` (or equivalent schedule) and a real `session.json` file under `output/`.

---

## Step 10 — Day-to-day on Unraid

| Task | Where / command |
|------|-----------------|
| View logs | **Docker** → `parking` → logs, or `cd /mnt/user/appdata/compose-projects/parking && docker compose logs -f` |
| Manual book | `docker exec -it parking parking book` |
| Dry-run book | `docker exec -it parking parking book --dry-run` |
| Refresh session | `docker exec -it parking parking refresh` |
| Keep-alive status | `docker exec -it parking parking keepalive status` |
| Change schedule / slots | `nano` files under `/mnt/user/appdata/parking/config/`, then `docker exec -it parking parking install --schedules` |
| Shell from Mac | `ssh root@192.168.0.10` then the `docker exec` commands above |
| Stop / start stack | **Docker** → Compose → **`parking`** → Compose Stop / Compose Up |
| Rebuild after code update | Re-copy zip (Method A or B) → replace files under `compose-projects/parking` → Compose Up / `docker compose up -d --build` (appdata persists) |
| Cleanup staging (Method A) | Delete Finder folder `documents/parking-scheduler-staging`, or `rm -rf /mnt/user/documents/parking-scheduler-staging` |
| Cleanup staging (Method B) | `rm -rf /tmp/parking-scheduler-staging` |

Example rebuild from Terminal after updating the unzipped tree:

```bash
cd /mnt/user/appdata/compose-projects/parking
docker compose --env-file .env up -d --build
```

---

## Verify your setup

1. **Stack `parking` appears once** — **Docker** → Compose. No `parking-001` duplicate.
2. **Container stays up** — **Docker** tab shows `parking` running after a refresh.
3. **Crontab inside the container** — `docker exec -it parking parking crontab` shows evening SSO + book schedule (Asia/Manila).
4. **`session.json` exists** — `ls -la /mnt/user/appdata/parking/output/session.json` after a successful login.
5. **No User Scripts parking job** — **Settings → User Scripts** has no Playwright/parking cron (scheduling is inside the container only).
6. **Appdata on cache** — **Shares → appdata** Primary = `cache`.

---

## Troubleshooting (Unraid 7.3.2)

| Problem | Fix |
|---------|-----|
| Bind mount became a directory | Remove the mistaken directory under `/mnt/user/appdata/parking/config/`, recreate the **file**, recreate/restart the container |
| Stack missing on Docker tab | Refresh; confirm Projects Folder; confirm `docker-compose.yml` under `compose-projects/parking` |
| Duplicate stack (`parking-001`) | You clicked **Add Stack** — remove the duplicate; keep the folder-backed `parking` stack |
| Build fails / Docker vDisk full | **Settings → Docker** (stop Docker to edit) → increase Docker vDisk size; free images |
| Container exits immediately | `docker compose logs` in the project dir; fix config files; confirm seed files are files not dirs |
| Cron not firing overnight | `docker exec parking crontab -l`; confirm container stayed up; Autostart **On** |
| Wrong book time | Check `TZ=Asia/Manila` in compose, `schedule.env`, and `parking crontab` |
| Missed midnight after array sleep | Keep appdata on `cache`; container `unless-stopped` |
| PingID timeout | Approve within ~2 minutes; retry `parking login` |
| SSO fails, Node/Java look fine | Check `/mnt/user/appdata/parking/logs-sso/`; keep `HEADED=0` in the container |
| `Permission denied` on SSH | **Settings → Management Access → SSH = Yes**; log in as **`root`**, not SMB user `brian` |
| `scp` hangs / timeout | Confirm LAN IP, array **Started**; for remote access use Tailscale after chapter `09` |
| Cannot write into `appdata` from Finder | Expected (Export = **No**) — use Method A via `documents` + Terminal, or Method B as root |

---

## Appendix A — Ubuntu VM (not preferred)

Use Docker above when possible (less CPU/RAM/disk). If you still want a VM:

1. Unraid **VMs** → create **Ubuntu 22.04 or 24.04** (2 vCPU, **2 GB RAM** minimum, 20+ GB disk).
2. Enable autostart; set guest timezone to **Asia/Manila** (or rely on `CRON_TZ` after install).
3. Install SSH in the guest if you will administer it from the LAN.
4. Copy `resource-scheduler-automation.zip` into the VM (SMB into a shared folder, or `scp` to the guest).
5. Unzip and follow [INSTALL.md](INSTALL.md) (`./install.sh --schedules`).

Do not also run the Docker stack’s cron on the same nights — one machine should own booking.

---

## Appendix B — Optional AWS SSM (instead of `RS_PASSWORD`)

Only if you are **not** putting the password in `config/.env`:

1. Create `/mnt/user/appdata/parking/aws/credentials` and `config` (standard AWS CLI files).
2. Create passphrase file:

```bash
nano /mnt/user/appdata/parking/home/.config/resource-scheduler/sso-passphrase
```

(single line passphrase; chmod 600 recommended)

3. In `config/.env`, leave `RS_PASSWORD` unset/commented; keep:

```bash
RS_CREDENTIALS_PASSPHRASE_FILE=$HOME/.config/resource-scheduler/sso-passphrase
```

(`HOME` inside the container is `/data/home`.)

4. Restart the stack after edits: **Docker** → Compose → **`parking`** → Compose Up / restart, or `docker compose up -d` from the project dir.

Prefer SSM + passphrase when you can — a password in `.env` on disk is easier to leak if appdata is ever shared.

---

## Files in this kit (Docker)

| Path | Role |
|------|------|
| `resource-scheduler-automation.zip` → `parking/Dockerfile` | Playwright base + JDK + cron + AWS CLI + app install |
| `…/docker-compose.yml` | Unraid appdata volume map via `PARKING_APPDATA` |
| `…/docker/entrypoint.sh` | Link config, install crontab, run cron |
| `parking-docker/` | Readable mirror of the same Docker files outside the zip |

Full generic install reference: [INSTALL.md](INSTALL.md).
