# 07 - Home Assistant

Do this **after** Immich (`06`). Steps are for **Unraid OS 7.3.2** with **Compose Manager Plus**.

Official overview: https://www.home-assistant.io/installation/

## Before you start

| Check | Where |
|---|---|
| Docker enabled | **Settings → Docker** |
| Compose Manager Plus installed | **Docker** tab → Compose section |
| Share `appdata` on `cache` | **Shares** |
| Parent folder exists | Terminal: `ls /mnt/user/appdata/compose-projects` |

## Install type for this build

Use **Home Assistant Container** (no Supervisor / add-on store).

Optional later: Home Assistant OS as a VM if you need add-ons.

Project path:

`/mnt/user/appdata/compose-projects/homeassistant/compose.yaml`

Config path:

`/mnt/user/appdata/homeassistant/config`

---

## Step 1 — Open Terminal

WebGUI → top-right **>_** (or SSH as root).

---

## Step 2 — Create directories

```bash
mkdir -p /mnt/user/appdata/homeassistant/config
mkdir -p /mnt/user/appdata/compose-projects/homeassistant
```

---

## Step 3 — Create the compose file

**Where:** `/mnt/user/appdata/compose-projects/homeassistant/compose.yaml`

With **Settings → Compose → Projects Folder** = `/mnt/user/appdata/compose-projects` (chapter `05`), a **`homeassistant`** stack appears on the **Docker** tab after this file exists. Do **not** click Add Stack unless no stack shows after a refresh.

### Create the file in Terminal

```bash
nano /mnt/user/appdata/compose-projects/homeassistant/compose.yaml
```

Paste:

```yaml
services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    volumes:
      - /mnt/user/appdata/homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
    # devices:
    #   - /dev/serial/by-id/usb-REPLACE_ME:/dev/ttyZigbee
```

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

(Or copy from this repo’s `docker/homeassistant/compose.yaml` via `scp`.)

No `.env` file is required for this basic stack.

---

## Step 4 — Confirm the stack, then start

1. **Docker** → Compose → **`homeassistant`** (one entry only).
2. Open it if you want: optional WebUI URL `http://brian-server:8123`.
3. Stack menu → **Compose Up**.

Or:

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
docker compose logs --tail=100
```

Open `http://brian-server:8123` (or your IP) and create the admin account.

---

## Step 4 — Networking and remote access

Do not expose port 8123 publicly. Use Tailscale (chapter `09`).

---

## Step 5 — Zigbee USB (optional)

1. Use a USB extension cable.
2. In Terminal, find a stable path:

```bash
ls -l /dev/serial/by-id/
```

3. Edit compose (`nano` or Compose Manager Plus **Compose** tab) and uncomment/add:

```yaml
devices:
  - /dev/serial/by-id/usb-YOUR_ACTUAL_ID:/dev/ttyZigbee
```

4. Avoid `/dev/ttyUSB0` when a by-id path exists.
5. **Compose Down** then **Compose Up**.

---

## Step 6 — Tuya / Smart Life

Use the official Tuya integration: https://www.home-assistant.io/integrations/tuya/

Local-only control varies by device.

---

## Step 7 — Backup

Back up `/mnt/user/appdata/homeassistant/config`. Prefer Home Assistant’s built-in backup when available. Include that folder in the weekly Exos job later.

Never commit `secrets.yaml` to Git.

---

## Step 8 — Updates

1. Read release notes: https://www.home-assistant.io/blog/categories/release-notes/
2. Back up config.
3. Compose Manager Plus → **Compose Up** / Update, or:

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
```

4. Check logs and automations.

## Security

- Separate users for household members.
- MFA for admin accounts when available.

**Next:** chapter `14` Jellyfin.
