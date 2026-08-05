# 14 - Jellyfin on Unraid

Official container docs: [Jellyfin container installation](https://jellyfin.org/docs/general/installation/container/)

Deploy Jellyfin after Immich and Home Assistant are stable. Media libraries live on the IronWolf; config and transcode cache live on the GM7000.

## Architecture for this server

```text
Clients (browser / apps)
        |
   Jellyfin (:8096)
    /           \
 config/cache    media libraries
 GM7000 SSD      IronWolf (/mnt/user/media)
```

## 1. Create directories and share

```bash
mkdir -p /mnt/user/appdata/jellyfin/config
mkdir -p /mnt/user/appdata/jellyfin/cache
mkdir -p /mnt/user/media/movies
mkdir -p /mnt/user/media/tv
mkdir -p /mnt/user/media/music
mkdir -p /mnt/user/appdata/compose-projects/jellyfin
```

Confirm the `media` share primary storage is the IronWolf array disk ([`04-Storage.md`](04-Storage.md)).

## 2. Compose file

Create `/mnt/user/appdata/compose-projects/jellyfin/compose.yaml` using the template in `docker/jellyfin/compose.yaml`, or start from the official example and apply these host paths:

| Container path | Host path | Notes |
|---|---|---|
| `/config` | `/mnt/user/appdata/jellyfin/config` | GM7000 |
| `/cache` | `/mnt/user/appdata/jellyfin/cache` | GM7000 |
| `/media` | `/mnt/user/media` | IronWolf; prefer `:ro` |

Pass Intel Quick Sync:

```yaml
devices:
  - /dev/dri:/dev/dri
```

Published ports (preferred starting point):

- `8096/tcp` web UI
- `7359/udp` optional client discovery

Use host networking only if LAN discovery fails with bridge/published ports.

## 3. Start

```bash
cd /mnt/user/appdata/compose-projects/jellyfin
docker compose pull
docker compose up -d
docker compose logs --tail=200
```

Open:

`http://SERVER-IP:8096`

Complete the setup wizard. Create libraries pointing at `/media/movies`, `/media/tv`, and `/media/music` inside the container.

## 4. Hardware acceleration

In Jellyfin Dashboard → Playback:

1. Enable hardware acceleration.
2. Choose Intel Quick Sync / VAAPI according to the installed Jellyfin version.
3. Test playback of a high-bitrate file while watching CPU/`intel_gpu_top` if available.

Confirm `/dev/dri` exists on the host first ([`05-Docker.md`](05-Docker.md)).

## 5. Database note

Keep Jellyfin on its default SQLite database unless you have a concrete reason to externalize MariaDB. If you later move to MariaDB, store it under `/mnt/user/appdata/jellyfin/mariadb` on the GM7000 ([`08-Databases.md`](08-Databases.md)).

## 6. Remote access and security

- Prefer Tailscale over public port forwarding.
- Create separate Jellyfin users for household members.
- Do not expose `8096` to the internet without a reverse proxy, TLS, and authentication review.

## 7. Backup and updates

Back up:

- `/mnt/user/appdata/jellyfin`
- Media libraries on `/mnt/user/media` as part of the weekly Exos job if those files are not already duplicated elsewhere

Update separately from Immich and Home Assistant:

```bash
cd /mnt/user/appdata/compose-projects/jellyfin
docker compose pull
docker compose up -d
```

Read Jellyfin release notes before upgrading across major versions.
