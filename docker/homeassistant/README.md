# Home Assistant Container

1. Create `/mnt/user/appdata/homeassistant/config`.
2. Copy `compose.yaml` to `/mnt/user/appdata/compose-projects/homeassistant/`.
3. Run `docker compose up -d`.
4. Open `http://SERVER-IP:8123`.

This is Home Assistant Container, not Home Assistant OS. Supervisor and add-ons are not included.

Official references:

- https://www.home-assistant.io/installation/alternative/
- https://hub.docker.com/r/homeassistant/home-assistant
