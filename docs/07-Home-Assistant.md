# 07 - Home Assistant

Do this **after** Immich (`06`), with Docker already enabled.

Official overview: https://www.home-assistant.io/installation/

## Before you start

- Docker is enabled
- **Compose Manager Plus** is installed (chapter `05`)
- Share `appdata` exists on the GM7000
- `/mnt/user/appdata/compose-projects` exists

## Install type for this build

Use **Home Assistant Container** (no Supervisor / add-on store).

Optional later: Home Assistant OS as a VM if you need add-ons.

## Step 1 — Create directories

```bash
mkdir -p /mnt/user/appdata/homeassistant/config
mkdir -p /mnt/user/appdata/compose-projects/homeassistant
```

## Step 2 — Compose file

Copy from this repository:

```bash
cp /path/to/Brian-HomeServer/docker/homeassistant/compose.yaml \
  /mnt/user/appdata/compose-projects/homeassistant/compose.yaml
```

Or recreate the same content from `docker/homeassistant/compose.yaml`.

The template uses host networking, config at `/mnt/user/appdata/homeassistant/config`, and `privileged: true` as a practical Unraid start. Tighten later if needed.

## Step 3 — Start

From terminal:

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
```

Or use **Docker → Compose Manager Plus**: add/select the `homeassistant` stack and **Compose Up**.

Open `http://SERVER-IP:8123` and create the admin account.

## Step 4 — Networking and remote access

Do not expose port 8123 publicly. Use Tailscale for remote access.

## Step 5 — Zigbee USB (optional)

1. Use a USB extension cable.
2. Find a stable path under `/dev/serial/by-id/`.
3. Add it under `devices:` in compose (see commented example in the template).
4. Avoid `/dev/ttyUSB0` when a by-id path exists.

## Step 6 — Tuya / Smart Life

Use the official Tuya integration first: https://www.home-assistant.io/integrations/tuya/

Local-only control varies by device. Do not assume every Smart Life device works without cloud.

## Step 7 — Backup

Back up `/mnt/user/appdata/homeassistant/config`. Prefer Home Assistant’s built-in backup when available. Include that data in the weekly Exos job later.

## Step 8 — Updates

1. Read release notes: https://www.home-assistant.io/blog/categories/release-notes/
2. Back up config.
3. Update only this stack:

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
```

4. Check logs and automations.

## Security

- Separate users for household members.
- MFA for admin accounts.
- Never commit `secrets.yaml` to Git.

**Next:** chapter `14` Jellyfin.
