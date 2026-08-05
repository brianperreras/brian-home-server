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

## Step 3 — Create the compose file (where and how)

**Where:** `/mnt/user/appdata/compose-projects/homeassistant/compose.yaml`

### Option A — Copy from this handbook repo on your Mac

1. On your Mac, open the Brian-HomeServer repo.
2. Copy `docker/homeassistant/compose.yaml` to the server, for example with SCP:

```bash
scp "/path/to/Brian-HomeServer/docker/homeassistant/compose.yaml" root@brian-server:/mnt/user/appdata/compose-projects/homeassistant/compose.yaml
```

### Option B — Create it in the Unraid Terminal

```bash
nano /mnt/user/appdata/compose-projects/homeassistant/compose.yaml
```

Paste this exact content (from `docker/homeassistant/compose.yaml`):

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
    # Add a stable Zigbee/USB device mapping when needed, for example:
    # devices:
    #   - /dev/serial/by-id/usb-REPLACE_ME:/dev/ttyZigbee
```

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

### Option C — Compose Manager Plus editor

1. Add the stack first (Step 4).
2. Open **Compose** tab → paste the YAML → **Save All**.

This template uses **host** networking (port **8123** on the host), config on GM7000, and `privileged: true` for a practical Unraid start. Tighten later if needed.

No `.env` file is required for this basic HA stack.

---

## Step 4 — Add stack in Compose Manager Plus

1. **Docker** → Compose section → **Add New Stack**.
2. Fill:

| Field | Value |
|---|---|
| Stack name | `homeassistant` |
| Description | `Home Assistant Container` (optional) |
| Advanced → Indirect Path | `/mnt/user/appdata/compose-projects/homeassistant` |

3. Create → confirm **Compose** tab shows the YAML.
4. Optional **Settings**: WebUI URL = `http://brian-server:8123`
5. **Save All**.

---

## Step 5 — Start Home Assistant

**Compose Manager Plus:** stack menu → **Compose Up**.

**Or Terminal:**

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
docker compose logs --tail=100
```

Open:

`http://brian-server:8123`

or `http://YOUR-RESERVED-IP:8123`

Create the admin account in the onboarding wizard.

---

## Step 6 — Networking and remote access

Do not expose port 8123 publicly. Use Tailscale (chapter `09`).

---

## Step 7 — Zigbee USB (optional)

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

## Step 8 — Tuya / Smart Life

Use the official Tuya integration: https://www.home-assistant.io/integrations/tuya/

Local-only control varies by device.

---

## Step 9 — Backup

Back up `/mnt/user/appdata/homeassistant/config`. Prefer Home Assistant’s built-in backup when available. Include that folder in the weekly Exos job later.

Never commit `secrets.yaml` to Git.

---

## Step 10 — Updates

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
