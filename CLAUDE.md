# Brian's Home Server — Claude Context

This repo is an ops handbook and config store for a 24/7 Unraid 7.3.2 home server.

## What lives here
- `docs/` — setup chapters (00–15), follow in order
- `docker/` — Compose stacks for Immich, Jellyfin, Home Assistant
- `scripts/` — Weekly backup scripts (rsync snapshot with hardlinks)
- `diagrams/` — Architecture overview
- `docs/reference/` — Planning snapshot

## Key facts
- OS: Unraid 7.3.2 on USB boot (NVMe is NOT the OS disk)
- NVMe (GM7000 1 TB) → appdata, DBs, thumbnails, cache
- IronWolf 6 TB → photos, media, documents (always mounted)
- Exos 6 TB → weekly backup only (spins down; mounted via Unassigned Devices)
- No parity drive — Exos is a backup disk, not parity
- Services: Immich (2283), Jellyfin (8096), Home Assistant (8123)
- SMB, cron, and Git run on the Unraid host — not in containers
- Tailscale installed as Unraid plugin, LAN-only during initial setup

## Safety rules
- Never commit `.env` files, passwords, API keys, or Tailscale auth keys
- Always review `git diff` before pushing
- Scripts use `set -Eeuo pipefail` — keep it that way

## Available slash commands
- `/doc-update` — edit or extend a docs chapter
- `/check-compose` — review a Docker Compose stack
- `/backup-audit` — audit the backup scripts
- `/new-service` — scaffold a new Compose service

## Custom agent
Use the `homeserver` agent (`.claude/agents/homeserver.md`) for deep Unraid/Docker/backup questions.
