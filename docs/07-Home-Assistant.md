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

Open `http://192.168.0.10:8123` (or `http://brian-server:8123`) and create the admin account.

---

## Step 5 — Zigbee USB (optional)

Skip this if you only use Tuya / Smart Life (Wi‑Fi) devices. You need it only for a Zigbee USB dongle.

1. Use a USB extension cable.
2. In Terminal:

```bash
ls -l /dev/serial/by-id/
```

3. Edit compose (`nano` or Compose **Compose** tab) and add your real by-id path:

```yaml
devices:
  - /dev/serial/by-id/usb-YOUR_ACTUAL_ID:/dev/ttyZigbee
```

4. Avoid `/dev/ttyUSB0` when a by-id path exists.
5. Compose Down → Compose Up.

---

## Step 6 — Tuya / Smart Life (bring existing devices into HA)

Official integration: https://www.home-assistant.io/integrations/tuya/

Devices stay in the **Smart Life** (or Tuya Smart) app. Home Assistant links that same account and pulls them in over Tuya’s cloud. You are not “moving” them off Smart Life.

### Before you start

| Need | Notes |
|---|---|
| Smart Life (or Tuya Smart) app | Same account that already controls your devices |
| Devices online in that app | Add/fix any offline devices in Smart Life first |
| Phone + PC | HA shows a QR code; you scan it with the app |

### 6a — Get your User Code (phone)

In **Smart Life** (or Tuya Smart):

1. **Me** tab  
2. **⚙️** (top right)  
3. **Account and Security**  
4. Note **User Code** at the bottom  

### 6b — Add Tuya in Home Assistant (PC)

1. Open `http://192.168.0.10:8123`
2. **Settings → Devices & services → Add integration**
3. Search **Tuya** → select it  
4. Enter the **User Code** from the app when asked  
5. HA shows a **QR code**

### 6c — Link the account (phone)

1. Smart Life → **+** / **Add Device** → **Scan** (QR)  
2. Scan the QR code on the HA screen  
3. Approve the link in the app  

When setup finishes, your Smart Life devices should appear under **Settings → Devices & services → Tuya**.

### Afterward

- Keep using Smart Life if you want; HA controls the same cloud devices.
- New devices added later in Smart Life: **Settings → Devices & services → Tuya → ⋮ → Reload**.
- Some device features may be limited vs the app (Tuya’s SDK does not expose everything).
- Prefer HA automations going forward so you’re not dependent only on Smart Life scenes.

Do **not** factory-reset devices to “migrate” them unless a device never shows up and Tuya support/docs say to re-pair in Smart Life first.

## Step 7 — Backup and updates (Unraid)

Back up `/mnt/user/appdata/homeassistant/config`. Prefer HA’s built-in backup when available.

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
```

Never commit `secrets.yaml` to Git.

**Remote access** (after HA works on LAN — [09 Access](09-Network-Security.md)):

| Method | URL | Guide |
|---|---|---|
| LAN | `http://192.168.0.10:8123` | [09 Part A](09-Network-Security.md#part-a-lan) |
| Cloudflare Tunnel + Access | [`https://home.migulix.uk`](https://home.migulix.uk) | [09 D7b](09-Network-Security.md#d7b-home-assistant) |
| Tailscale | `http://100.x.y.z:8123` | [09 Part B](09-Network-Security.md#part-b-tailscale) |

Do not port-forward `8123`. Do not publish HA without Access on `home.migulix.uk` ([D7b](09-Network-Security.md#d7b-home-assistant)).

<a id="ha-trusted-proxies"></a>

### Before using `https://home.migulix.uk` — trust Cloudflare Tunnel (UI)

Home Assistant blocks tunnel traffic until you trust `cloudflared`. Configure this in the **HA UI only**.

**Do not** add an `http:` / `trusted_proxies` block to `configuration.yaml`. On current Home Assistant that YAML is ignored after migration and triggers the repair: *“HTTP YAML configuration is ignored after migration.”*

1. Find the `cloudflared` container IP (Unraid **Docker** tab, or Terminal):

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cloudflared
```

On this build it is typically `172.19.0.2` (confirm on your server).

2. Open HA on the LAN: `http://192.168.0.10:8123`
3. **Settings → System → Network**
4. Set:
   - **Trust X-Forwarded-For** = **On**
   - **Trusted proxies**:
     - `172.19.0.2` (or the IP from step 1)
     - `172.16.0.0/12` (Docker networks)
     - `127.0.0.1`
5. **Save**
6. Restart Home Assistant:
   - **Settings → System** → top-right **⋮** → **Restart Home Assistant**, or
   - Unraid Terminal: `docker restart homeassistant`
7. Finish tunnel + Access for `home.migulix.uk` ([09 D7b](09-Network-Security.md#d7b-home-assistant)), then open `https://home.migulix.uk`.

If you already added `http:` to `configuration.yaml`, delete that whole block, save, restart HA, and keep only the UI settings above. The repair warning should clear.

Official docs: https://www.home-assistant.io/integrations/http/#reverse-proxies

## Verify your setup

1. **Container running** — run from the compose directory:

   ```bash
   cd /mnt/user/appdata/compose-projects/homeassistant && docker compose ps
   ```

   Expected result: `homeassistant` shows `running` / `Up`.

2. **Web UI loads** — open a browser on a LAN machine.
   Expected result: `http://192.168.0.10:8123` shows the Home Assistant onboarding wizard or login page.

3. **Config directory exists on NVMe** — run:

   ```bash
   ls /mnt/user/appdata/homeassistant/config
   ```

   Expected result: directory exists and contains HA config files (e.g. `configuration.yaml`) after first startup.

4. **No fatal errors in recent logs** — run:

   ```bash
   cd /mnt/user/appdata/compose-projects/homeassistant && docker compose logs --tail=50
   ```

   Expected result: no lines with `ERROR` or `fatal` that block startup; normal integration warnings are acceptable.

5. **Cloudflare hostname (after D7b + trusted proxies)** — open `https://home.migulix.uk`.
   Expected result: Access login, then HA login — not `400: Bad Request`. No repeating `reverse proxy` errors in `docker logs homeassistant`.

**Next:** [14 Jellyfin](14-Jellyfin.md).  
**Remote HA URL:** [09 D7b — `home.migulix.uk`](09-Network-Security.md#d7b-home-assistant) (after [trusted proxies](#ha-trusted-proxies)).
