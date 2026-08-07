# Unraid deploy guide — parking automation

Do this on **Unraid OS 7.3.2** with **Compose Manager Plus**. Transfer files with **SSH / `scp` from your Mac**, then finish setup in the Unraid Terminal (or SSH shell).

Goal: run evening SSO + midnight booking on your home server in a Docker container. Config and session live under `/mnt/user/appdata/parking/` so rebuilds do not wipe secrets.

Prefer this Docker path over an Ubuntu VM. Do **not** install Node, Playwright, or Java on the Unraid **host**. Do **not** add parking jobs under **Settings → User Scripts** — cron runs **inside** the `parking` container.

Handbook cross-refs (this repo): Docker → [`docs/05-Docker.md`](../docs/05-Docker.md); SSH enable → [`docs/09-Network-Security.md`](../docs/09-Network-Security.md) Part A (SSH).

---

## Before you start

| Check | Where (7.3.2) |
|-------|----------------|
| Array **Started** | **Main** |
| Share `appdata` Primary = `cache`, Secondary = **None** | **Shares → appdata** |
| Docker enabled | **Settings → Docker** (if path fields look missing: **Advanced View**, set Enable Docker = **No**, edit paths, then **Yes** — chapter `05`) |
| **Compose Manager Plus** installed (author **mstrhakr**) | **Plugins** |
| Projects Folder = `/mnt/user/appdata/compose-projects` | **Settings → Compose Manager Plus** (or **Settings → Compose**) |
| **SSH** = **Yes**, **Telnet** = **No** | **Settings → Management Access** |
| Mac can log in as root | `ssh root@192.168.0.10` (Unraid root password) |
| Phone ready for **PingID** | — |

Notes:

- SSH / WebGUI Terminal use **`root`**.
- Keep appdata on the always-on `cache` pool so midnight booking does not wait on array spin-up.
- Transfer `resource-scheduler-automation.zip` only (no secrets). Recreate config on Unraid; do **not** copy someone else’s `session.json`.

### Layout

```text
Mac (this repo)
  parking-scheduler/
    resource-scheduler-automation.zip
    config-examples/
    UNRAID.md

After deploy on Unraid
  /mnt/user/appdata/compose-projects/parking/   ← Compose stack (Dockerfile + **one .env**)
  /mnt/user/appdata/parking/                    ← runtime session, logs, generated config
    ├── config/       # auto-written from stack .env on container start (do not edit by hand)
    ├── home/
    ├── output/
    ├── logs-sso/
    └── logs-book/
```

Kit path on this Mac (example):

```text
$HOME/Desktop/My Files/Project X/Brian-HomeServer/parking-scheduler
```

---

## Step 1 — Copy the zip onto Unraid with SSH / scp

On your **Mac** Terminal (use the Unraid **root** password when prompted):

```bash
# Connectivity check
ssh root@192.168.0.10 'uname -a'

KIT="$HOME/Desktop/My Files/Project X/Brian-HomeServer/parking-scheduler"

ssh root@192.168.0.10 'mkdir -p /mnt/user/appdata/compose-projects/parking /tmp/parking-scheduler-staging'

scp "$KIT/resource-scheduler-automation.zip" \
  root@192.168.0.10:/tmp/parking-scheduler-staging/
```

Optional (examples also exist inside the zip):

```bash
scp -r "$KIT/config-examples" \
  root@192.168.0.10:/tmp/parking-scheduler-staging/
```

SSH keys are optional; password auth with the WebGUI root password is enough.

Confirm on the server:

```bash
ssh root@192.168.0.10 'ls -la /tmp/parking-scheduler-staging'
```

You should see `resource-scheduler-automation.zip`.

---

## Step 2 — Open a shell on Unraid

| Method | How |
|--------|-----|
| SSH from Mac | `ssh root@192.168.0.10` (or `ssh root@brian-server`) |
| WebGUI Terminal | Unraid WebGUI → top-right **>_** |

Editing files with `nano`: **Ctrl+O**, Enter to save; **Ctrl+X** to exit.

---

## Step 3 — Create directories

In the Unraid shell:

```bash
mkdir -p /mnt/user/appdata/parking/{config,home,output,logs-sso,logs-book}
mkdir -p /mnt/user/appdata/compose-projects/parking
```

---

## Step 4 — Unpack into the Compose project folder

```bash
cd /tmp/parking-scheduler-staging
ls -la

unzip -o resource-scheduler-automation.zip
cp -a parking/. /mnt/user/appdata/compose-projects/parking/

cd /mnt/user/appdata/compose-projects/parking
ls -la
```

You should see at least:

```text
Dockerfile
docker-compose.yml
docker/
.env.example
resource-scheduler-sso-login/
resource-scheduler/
bin/
```

Create the **unified** stack `.env` from the example (Compose Manager Plus + entrypoint both read this one file). `-n` skips overwrite if `.env` already exists:

```bash
cd /mnt/user/appdata/compose-projects/parking
cp -n .env.example .env
chmod 600 .env
nano .env
```

Set at least `PARKING_APPDATA`, `RS_USERNAME`, `RS_PASSWORD`, and `PARKING_SLOTS` (see Step 6). Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

Do **not** replace this with a tiny `PARKING_APPDATA`-only file — the full boxed sections in `.env.example` are required.

---

## Step 5 — Single stack `.env` materializes app config

There is **one** config source: `/mnt/user/appdata/compose-projects/parking/.env`.

On container start, with `PARKING_MANAGE_FROM_STACK_ENV=1` (default), the entrypoint writes snapshots under `/mnt/user/appdata/parking/config/` (`.env`, `schedule.env`, `reservation.env`, `resources.txt`) and installs crontab.

- Edit the **stack** `.env` only (Compose → **parking** → **.ENV**, or `nano` in the project folder).
- Recreate/restart the stack so materialization runs again.
- Do **not** hand-edit files under `/mnt/user/appdata/parking/config/` — they are overwritten on start.

Runtime dirs from Step 3 (`config/`, `home/`, `output/`, logs) still need to exist so Docker bind-mounts correctly; you do **not** need to seed the four config files by hand.

---

## Step 6 — Required stack `.env` variables

This Unraid migration does **not** use AWS or SSM. Put the SSO password in the **stack** `.env` only.

| Variable | Purpose |
|----------|---------|
| `PARKING_APPDATA` | Host path for session/logs/generated config (`/mnt/user/appdata/parking`) |
| `RS_USERNAME` / `RS_PASSWORD` | SSO login (local only; no AWS) |
| `HEADED` | Keep `0` on Unraid (headless Chromium) |
| `RS_SCHEDULE_DAYS` / `RS_SCHEDULE_TIME` | Book cron DOW + Asia/Manila submit time |
| `RS_RESERVATION_DAYS_AHEAD` | Reservation date = run date + N (override with `parking book --date …`) |
| `RS_START_HR` / `RS_END_HR` | Reservation window on the booked day |
| `PARKING_SLOTS` | Comma-separated slot try order (e.g. `R405,R406,…`) |
| `TZ` / `SSO_SCHEDULE_*` | Container TZ + evening SSO cron hour/minute |
| `PARKING_MANAGE_FROM_STACK_ENV` | Keep `1` so entrypoint regenerates app config from this file |

Optional / advanced keys are commented in `.env.example` (boxed sections). Do not add AWS credentials, passphrase files, or `RS_CREDENTIALS_PASSPHRASE_FILE`.

Passwords with special characters: use quotes, e.g. `RS_PASSWORD='p@ss#word'`.

---

## Step 7 — Confirm the Compose Manager Plus stack

1. Open **Docker** in the Unraid top menu.
2. Find the **Compose** section.
3. You should see a stack named **`parking`**.

**Do not click Add Stack** — that creates a duplicate like `parking-001`.

If no stack appears: refresh; confirm Projects Folder = `/mnt/user/appdata/compose-projects`; confirm:

```bash
ls -la /mnt/user/appdata/compose-projects/parking/docker-compose.yml
```

### Optional stack Settings

**Docker** → Compose → **`parking`** → Settings:

| Field | Value |
|-------|--------|
| Name | `parking` |
| Description | optional, e.g. `Asurion parking automation` |
| WebUI URL | leave blank |
| Autostart | **On** (Compose **row** toggle — not only Settings) |

Project **.ENV** tab is the **full unified** stack file (same as `.env` beside `docker-compose.yml`) — paths, SSO, schedule, reservation window, and `PARKING_SLOTS`, not only `PARKING_APPDATA`. **Save All** if you edited anything.

---

## Step 8 — Build and start

This stack **builds** a local image from `Dockerfile`. First build can take several minutes (Playwright + npm + JDK compile).

**Preferred:** **Docker** → Compose → **`parking`** → **Compose Up** (Build first if the UI offers it).

**Or SSH / Terminal:**

```bash
cd /mnt/user/appdata/compose-projects/parking
docker compose --env-file .env up -d --build
docker compose ps
docker compose logs --tail=100
```

| Check | Expected |
|-------|----------|
| Container name | `parking` |
| Status | running / started |
| Autostart (Compose row) | **On** |

---

## Step 9 — First SSO login (PingID)

```bash
docker exec -it parking parking login
```

Approve **PingID** on your phone within about two minutes.

```bash
docker exec -it parking parking status
docker exec -it parking parking crontab
ls -la /mnt/user/appdata/parking/output/session.json
```

You should see crontab lines with `CRON_TZ=Asia/Manila` (or equivalent) and a real `session.json` under `output/`.

---

## Step 10 — Day-to-day on Unraid

The container image includes the same `parking` CLI as the original kit (`bin/parking` on `PATH`). Use it with `docker exec`, or install the optional **host wrapper** below so Unraid SSH feels like the Mac/Linux install (`parking help`, `parking book`, …).

### Same commands as the original CLI

| Command | What it does |
|---------|----------------|
| `parking help` | Usage |
| `parking book` | Try all slots until one books |
| `parking book R405 R406` | Override slot list |
| `parking book-first` | First slot only |
| `parking login` | Full SSO + keep-alive (PingID) |
| `parking refresh` | Keep-alive once |
| `parking keepalive status` | Overnight loop `start` \| `stop` \| `status` |
| `parking scheduled-login` | Evening SSO cron entrypoint |
| `parking status` | Schedule, slots, session, cron |
| `parking book --date tomorrow` | Force reservation date |
| `parking dry-run` | Simulate booking (no submit) |
| `parking login --headed` | SSO with visible browser |
| `parking crontab` | Schedule in plain English (e.g. Tue–Fri at 9:00 PM) |
| `parking crontab --raw` | Human schedule + raw cron lines |
| `parking install --schedules` | Setup / reinstall cron inside the container |
| `parking uninstall` | Remove cron inside the container |

Without the host wrapper, prefix with `docker exec -it parking`:

```bash
docker exec -it parking parking help
docker exec -it parking parking book
docker exec -it parking parking book R405 R406
docker exec -it parking parking book-first
docker exec -it parking parking login
docker exec -it parking parking refresh
docker exec -it parking parking keepalive status
docker exec -it parking parking scheduled-login
docker exec -it parking parking status
docker exec -it parking parking crontab
docker exec -it parking parking install --schedules
docker exec -it parking parking uninstall
```

Extras that also work (flags preferred; env also forwarded by updated `host-parking`):

```bash
parking book --dry-run
parking dry-run --date tomorrow
parking book --date tomorrow
parking book --date 2026-8-8 --skip-sso
parking book --days-ahead 1
parking book-first --date tomorrow
parking login --headed
parking crontab --raw
# Env equivalents (host wrapper forwards these into the container):
RESERVATION_DATE=2026-8-8 parking book
HEADED=1 parking login
PARKING_CRON_RAW=1 parking crontab
```

### Host wrapper (optional — type `parking` on Unraid)

Install the env-forwarding wrapper from this repo (`parking-docker/host-parking`) so host flags/env reach the container:

```bash
mkdir -p /mnt/user/appdata/parking/bin
# After scp of this kit (or from compose-projects/parking if you copied it there):
cp /path/to/parking-docker/host-parking /mnt/user/appdata/parking/bin/parking
chmod +x /mnt/user/appdata/parking/bin/parking

# Current shell
export PATH="/mnt/user/appdata/parking/bin:$PATH"

# Persist for root SSH logins
grep -q 'appdata/parking/bin' /root/.bash_profile 2>/dev/null || \
  echo 'export PATH="/mnt/user/appdata/parking/bin:$PATH"' >> /root/.bash_profile
```

Then on Unraid:

```bash
parking help
parking book
parking login
parking status
parking crontab
```

Edit slots / schedule in the stack `.env` (Compose **.ENV** or `nano`), then recreate/restart the stack so the entrypoint rematerializes config and crontab (`parking install --schedules` also works inside the container).

| Task | Command / where |
|------|-----------------|
| Shell from Mac | `ssh root@192.168.0.10` |
| View logs | `cd /mnt/user/appdata/compose-projects/parking && docker compose logs -f` |
| Stop / start stack | Compose Stop / Compose Up, or `docker compose` in the project dir |
| Rebuild after code update | `scp` a new zip → unzip/replace under `compose-projects/parking` → `docker compose --env-file .env up -d --build` |
| Cleanup staging | `rm -rf /tmp/parking-scheduler-staging` |

Example rebuild after updating files:

```bash
cd /mnt/user/appdata/compose-projects/parking
docker compose --env-file .env up -d --build
```

---

## Verify your setup

1. **Stack `parking` appears once** — **Docker** → Compose. No `parking-001`.
2. **Container stays up** — `parking` running after a refresh.
3. **Crontab inside the container** — `docker exec -it parking parking crontab` shows evening SSO + book schedule (Asia/Manila).
4. **`session.json` exists** — after a successful login.
5. **No User Scripts parking job** — scheduling is inside the container only.
6. **Appdata on cache** — **Shares → appdata** Primary = `cache`.

---

## Troubleshooting (Unraid 7.3.2)

| Problem | Fix |
|---------|-----|
| `Permission denied` on SSH | **Settings → Management Access → SSH = Yes**; log in as **`root`** |
| `scp` hangs / timeout | Confirm LAN IP, array **Started**; for remote use Tailscale ([09](../docs/09-Network-Security.md)) |
| Bind mount became a directory | Rare with stack `.env` materialization; remove mistaken dirs under `appdata/parking/config/`, recreate stack |
| Stack missing on Docker tab | Refresh; Projects Folder; `docker-compose.yml` under `compose-projects/parking` |
| Duplicate stack (`parking-001`) | Remove duplicate; keep folder-backed `parking` |
| Build fails / Docker vDisk full | Increase Docker vDisk size; free images |
| Container exits immediately | `docker compose logs`; fix stack `.env`; ensure `PARKING_APPDATA` dirs from Step 3 exist |
| Cron not firing overnight | `docker exec parking crontab -l`; Autostart **On**; container stayed up |
| Wrong book time | `TZ=Asia/Manila` + `RS_SCHEDULE_*` in stack `.env`, then recreate; check `parking crontab` |
| PingID timeout | Approve within ~2 minutes; retry `parking login` |
| SSO fails | Check `/mnt/user/appdata/parking/logs-sso/`; keep `HEADED=0` |
| Asks for AWS / SSM | Rebuild from the updated zip (AWS removed); set `RS_PASSWORD` in the stack `.env` |
| Missing password | Ensure both `RS_USERNAME` and `RS_PASSWORD` are set in the stack `.env`, then recreate/restart |

---

## Appendix A — Ubuntu VM (not preferred)

Use Docker above when possible. If you still want a VM:

1. Unraid **VMs** → Ubuntu 22.04/24.04 (2 vCPU, **2 GB RAM** min, 20+ GB disk).
2. Enable autostart; set guest timezone or rely on `CRON_TZ`.
3. `scp` the zip into the VM over SSH, then follow [INSTALL.md](INSTALL.md).

Do not also run the Docker stack’s cron on the same nights. Prefer the Docker path above; it never uses AWS.

---

## Files in this kit (Docker)

| Path | Role |
|------|------|
| `resource-scheduler-automation.zip` → `parking/Dockerfile` | Playwright base + JDK + cron + app install (no AWS) |
| `…/.env.example` | Unified stack env template (copy to `.env`) |
| `…/docker-compose.yml` | `env_file: .env`; Unraid appdata via `PARKING_APPDATA` |
| `…/docker/entrypoint.sh` | Materialize config from stack `.env`, install crontab, run cron |
| `parking-docker/` | Readable mirror of the same Docker files outside the zip |

Full generic install reference: [INSTALL.md](INSTALL.md) (Linux/VM; not used for this Unraid Docker migration).
