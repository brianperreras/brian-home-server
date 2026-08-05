# Home Assistant Container

Unraid Container install for this build (not Home Assistant OS).

1. Create `/mnt/user/appdata/homeassistant/config`.
2. Copy `compose.yaml` to `/mnt/user/appdata/compose-projects/homeassistant/`.
3. Run `docker compose pull && docker compose up -d`.
4. Open `http://SERVER-IP:8123`.

Official references:

- https://www.home-assistant.io/installation/alternative/
- Full steps: `docs/07-Home-Assistant.md`
