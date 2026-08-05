# 14 - Jellyfin on Unraid

Do this **after** Home Assistant (`07`). Steps are for **Unraid OS 7.3.2** with **Compose Manager Plus**.

Official docs: https://jellyfin.org/docs/general/installation/container/

## Before you start

| Check | Where |
|---|---|
| Docker enabled | **Settings → Docker** |
| Compose Manager Plus installed | **Docker** → Compose section |
| Shares `appdata` and `media` | **Shares** (`media` Primary = Array) |
| Parent folder exists | `ls /mnt/user/appdata/compose-projects` |

## Layout

```text
Clients
   |
Jellyfin (:8096)
  /           \
config/cache   media
GM7000         IronWolf (/mnt/user/media)
```

Project path:

`/mnt/user/appdata/compose-projects/jellyfin/compose.yaml`

---

## Step 1 — Open Terminal

WebGUI → top-right **>_** (or SSH as root).

---

## Step 2 — Create directories

```bash
mkdir -p /mnt/user/appdata/jellyfin/config
mkdir -p /mnt/user/appdata/jellyfin/cache
mkdir -p /mnt/user/media/movies
mkdir -p /mnt/user/media/tv
mkdir -p /mnt/user/media/music
mkdir -p /mnt/user/appdata/compose-projects/jellyfin
```

`media` stays on the IronWolf (array), not the SSD `cache` pool.

---

## Step 3 — Create the compose file (where and how)

**Where:** `/mnt/user/appdata/compose-projects/jellyfin/compose.yaml`

### Option A — Copy from this repo

```bash
scp "/path/to/Brian-HomeServer/docker/jellyfin/compose.yaml" root@brian-server:/mnt/user/appdata/compose-projects/jellyfin/compose.yaml
```

### Option B — Create in Terminal

```bash
nano /mnt/user/appdata/compose-projects/jellyfin/compose.yaml
```

Paste:

```yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    ports:
      - "8096:8096/tcp"
      - "7359:7359/udp"
    volumes:
      - /mnt/user/appdata/jellyfin/config:/config
      - /mnt/user/appdata/jellyfin/cache:/cache
      - /mnt/user/media:/media:ro
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
    # Prefer published ports first. Switch to host networking only if LAN discovery fails:
    # network_mode: host
```

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

### Option C — Compose Manager Plus

Add stack (Step 4) → **Compose** tab → paste YAML → **Save All**.

No `.env` file is required for this basic Jellyfin stack.

### Path map

| Container path | Host path |
|---|---|
| `/config` | `/mnt/user/appdata/jellyfin/config` |
| `/cache` | `/mnt/user/appdata/jellyfin/cache` |
| `/media` | `/mnt/user/media` (read-only) |

---

## Step 4 — Add stack in Compose Manager Plus

1. **Docker** → Compose → **Add New Stack**.
2. Fill:

| Field | Value |
|---|---|
| Stack name | `jellyfin` |
| Description | `Jellyfin media server` (optional) |
| Advanced → Indirect Path | `/mnt/user/appdata/compose-projects/jellyfin` |

3. Create → confirm YAML on **Compose** tab.
4. Optional **Settings**: WebUI URL = `http://brian-server:8096`
5. **Save All**.

---

## Step 5 — Start Jellyfin

**Compose Manager Plus:** **Compose Up**.

**Or Terminal:**

```bash
cd /mnt/user/appdata/compose-projects/jellyfin
docker compose pull
docker compose up -d
docker compose logs --tail=200
```

Open:

`http://brian-server:8096`

or `http://YOUR-RESERVED-IP:8096`

Finish the setup wizard. When adding libraries, use container paths:

| Library | Folder inside Jellyfin |
|---|---|
| Movies | `/media/movies` |
| TV | `/media/tv` |
| Music | `/media/music` |

Put real files on the host under `/mnt/user/media/movies` (etc.); Jellyfin sees them under `/media/...`.

---

## Step 6 — Hardware acceleration

1. Confirm host devices: `ls -l /dev/dri`
2. Compose already maps `/dev/dri` (Step 3).
3. In Jellyfin: **Dashboard → Playback** → enable Intel Quick Sync / VAAPI as offered.
4. Test a high-bitrate file.

Keep SQLite unless you have a strong reason to add MariaDB.

---

## Step 7 — Remote access

Prefer Tailscale (chapter `09`). Do not expose `8096` publicly without TLS and auth review.

---

## Step 8 — Backup and updates

Back up `/mnt/user/appdata/jellyfin` and media as needed.

Update only this stack:

```bash
cd /mnt/user/appdata/compose-projects/jellyfin
docker compose pull
docker compose up -d
```

Or Compose Manager Plus → **Compose Up** / Update.

Update Jellyfin separately from Immich and Home Assistant.

**Next:** chapter `15` SMB / Git / cron.
