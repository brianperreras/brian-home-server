# check-compose

Review a Docker Compose stack for correctness and Unraid best practices.

Usage: `/check-compose <stack>` — where stack is `immich`, `jellyfin`, or `homeassistant`

Steps:
1. Read the relevant compose file in `docker/<stack>/`.
2. Read the accompanying README if one exists.
3. Check for:
   - Volume mounts pointing to the correct Unraid paths (`/mnt/user/appdata/...` for appdata, `/mnt/user/photos` etc. for data)
   - Ports not conflicting with other stacks (Immich 2283, Jellyfin 8096, HA 8123)
   - `restart: unless-stopped` on all services
   - No hardcoded secrets (use `.env` file references instead)
   - Quick Sync device passthrough for Jellyfin (`/dev/dri`)
   - Correct network mode for Home Assistant if host networking is needed
4. Report findings grouped as: Issues (must fix), Warnings (should fix), and OK.
