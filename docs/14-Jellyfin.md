# 14 - Jellyfin on Unraid

Do this **after** Home Assistant (`07`).

Official docs: https://jellyfin.org/docs/general/installation/container/

## Before you start

- Docker is enabled
- **Compose Manager Plus** is installed (chapter `05`)
- Shares `appdata` and `media` exist
- Immich and Home Assistant are already running (or at least Docker is healthy)

## Layout

```text
Clients
   |
Jellyfin (:8096)
  /           \
config/cache   media
GM7000         IronWolf (/mnt/user/media)
```

## Step 1 — Create directories

```bash
mkdir -p /mnt/user/appdata/jellyfin/config
mkdir -p /mnt/user/appdata/jellyfin/cache
mkdir -p /mnt/user/media/movies
mkdir -p /mnt/user/media/tv
mkdir -p /mnt/user/media/music
mkdir -p /mnt/user/appdata/compose-projects/jellyfin
```

`media` should stay on the IronWolf (array), not the SSD cache.

## Step 2 — Compose file

Create `/mnt/user/appdata/compose-projects/jellyfin/compose.yaml` from `docker/jellyfin/compose.yaml` in this repo.

Paths used:

| Container | Host |
|---|---|
| `/config` | `/mnt/user/appdata/jellyfin/config` |
| `/cache` | `/mnt/user/appdata/jellyfin/cache` |
| `/media` | `/mnt/user/media` (read-only preferred) |

Quick Sync:

```yaml
devices:
  - /dev/dri:/dev/dri
```

Ports: `8096/tcp` (UI), optional `7359/udp` (discovery). Prefer published ports before host networking.

## Step 3 — Start

From terminal:

```bash
cd /mnt/user/appdata/compose-projects/jellyfin
docker compose pull
docker compose up -d
docker compose logs --tail=200
```

Or use **Docker → Compose Manager Plus**: add/select the `jellyfin` stack and **Compose Up**.

Open `http://SERVER-IP:8096` and finish the wizard. Point libraries at `/media/movies`, `/media/tv`, `/media/music`.

## Step 4 — Hardware acceleration

In Jellyfin Dashboard → Playback, enable Intel Quick Sync / VAAPI as offered by your version. Test a high-bitrate file.

Keep SQLite unless you have a strong reason to add MariaDB.

## Step 5 — Remote access

Prefer Tailscale. Do not expose `8096` publicly without TLS and auth review.

## Step 6 — Backup and updates

Back up `/mnt/user/appdata/jellyfin` and media as needed.

```bash
cd /mnt/user/appdata/compose-projects/jellyfin
docker compose pull
docker compose up -d
```

Update Jellyfin separately from Immich and Home Assistant.

**Next:** chapter `15` SMB / Git / cron.
