# 07 - Home Assistant

## Choose the installation type deliberately

Official overview: [Home Assistant installation methods](https://www.home-assistant.io/installation/)

### Home Assistant Container (chosen for this Unraid build)

Best when you want a lightweight Docker deployment and are comfortable managing integrations and companion containers yourself. It does not include the Home Assistant Supervisor or add-on store.

Guide: [Alternative / container installation](https://www.home-assistant.io/installation/alternative/)  
Image: [homeassistant/home-assistant](https://hub.docker.com/r/homeassistant/home-assistant) / `ghcr.io/home-assistant/home-assistant`

### Home Assistant OS virtual machine (optional later)

Best when you want Supervisor, add-ons, snapshots, and the most appliance-like experience. It uses more resources but is often easier for Zigbee2MQTT, Mosquitto, ESPHome, and similar add-ons.

For this Unraid server, start with **Home Assistant Container**. Revisit an HA OS VM only if add-ons become a hard requirement.

## Container installation on Unraid

1. Ensure Docker is enabled and `appdata` lives on the GM7000 pool.
2. Create directories:

```bash
mkdir -p /mnt/user/appdata/homeassistant/config
mkdir -p /mnt/user/appdata/compose-projects/homeassistant
```

3. Copy the repository template:

```bash
cp /path/to/Brian-HomeServer/docker/homeassistant/compose.yaml \
  /mnt/user/appdata/compose-projects/homeassistant/compose.yaml
```

Or recreate the same content from `docker/homeassistant/compose.yaml` in this repository.

4. Start:

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
```

5. Access:

`http://SERVER-IP:8123`

Complete the onboarding wizard and create the admin account immediately.

The provided template uses:

- Host networking for mDNS/SSDP discovery.
- Config bind-mount at `/mnt/user/appdata/homeassistant/config`.
- `privileged: true` as a practical starting point on Unraid; tighten later if you understand the device requirements.

## Networking

Do not expose port 8123 publicly. Use Tailscale for remote access initially ([`09-Network-Security.md`](09-Network-Security.md)).

## USB devices and Zigbee

When adding a Zigbee coordinator:

1. Plug it into a USB extension cable to reduce RF interference.
2. Identify the stable path under `/dev/serial/by-id/`.
3. Pass that stable path into the container (see commented `devices:` example in `docker/homeassistant/compose.yaml`).
4. Do not use a changing path such as `/dev/ttyUSB0` when a by-id path is available.

## Tuya / Smart Life

Use the official [Home Assistant Tuya integration](https://www.home-assistant.io/integrations/tuya/) first. Local-only control varies by device and firmware. Do not assume all Smatrul or Lasco devices can be locally controlled without cloud dependencies.

## Backups

Back up the entire config directory:

`/mnt/user/appdata/homeassistant/config`

Stop the container or use Home Assistant's built-in backup feature before relying on a raw SQLite copy. Include HA backups in the weekly Exos job ([`10-Backup.md`](10-Backup.md)).

## Updates

- Read [Home Assistant release notes / breaking changes](https://www.home-assistant.io/blog/categories/release-notes/) each month.
- Back up configuration before updating.
- Update Home Assistant separately from Unraid and other stacks.
- After update, inspect logs and test critical automations.

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose pull
docker compose up -d
```

## Security

- Create separate user accounts for household members.
- Enable multi-factor authentication for administrator accounts.
- Use Tailscale for remote access initially.
- Never commit `secrets.yaml` to Git.
