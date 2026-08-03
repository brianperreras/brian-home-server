# 07 - Home Assistant

## Choose the installation type deliberately

### Home Assistant Container

Best when you want a lightweight Docker deployment and are comfortable managing integrations and companion containers yourself. It does not include the Home Assistant Supervisor or add-on store.

### Home Assistant OS virtual machine

Best when you want Supervisor, add-ons, snapshots, and the most appliance-like experience. It uses more resources but is often easier for Zigbee2MQTT, Mosquitto, ESPHome, and similar add-ons.

For your developer-oriented Unraid server, start with **Home Assistant Container** if you prefer Docker discipline. Choose an HA OS VM instead if add-ons are important.

## Container installation

Create:

```bash
mkdir -p /mnt/user/appdata/homeassistant/config
```

Use the compose template in `docker/homeassistant/compose.yaml`.

Start:

```bash
cd /mnt/user/appdata/compose-projects/homeassistant
docker compose up -d
```

Access:

`http://SERVER-IP:8123`

## Networking

Home Assistant often benefits from host networking for device discovery protocols such as mDNS/SSDP. The provided template uses host mode. Review the security implications and do not expose port 8123 publicly.

## USB devices and Zigbee

When adding a Zigbee coordinator:

1. Plug it into a USB extension cable to reduce RF interference.
2. Identify the stable path under `/dev/serial/by-id/`.
3. Pass that stable path into the container or VM.
4. Do not use a changing path such as `/dev/ttyUSB0` when a by-id path is available.

## Tuya / Smart Life

Use the official Home Assistant Tuya integration first. Local-only control varies by device and firmware. Do not assume all Smatrul or Lasco devices can be locally controlled without cloud dependencies.

## Backups

For Container installations, back up the entire config directory:

`/mnt/user/appdata/homeassistant/config`

Stop the container or ensure a consistent backup process before copying SQLite database files. Consider using the built-in backup functionality available in current Home Assistant versions, where supported.

## Updates

- Read Home Assistant breaking changes each month.
- Back up configuration before updating.
- Update Home Assistant separately from Unraid and other stacks.
- After update, inspect logs and test critical automations.

## Security

- Create separate user accounts for household members.
- Enable multi-factor authentication for administrator accounts.
- Use Tailscale for remote access initially.
- Never commit `secrets.yaml` to Git.
