# Brian Home Server — parking on Unraid 7.3.2

Deploy kit for Asurion parking automation on your personal Unraid box.

**Main guide:** [UNRAID.md](UNRAID.md) — numbered Unraid OS **7.3.2** + Compose Manager Plus steps (Finder SMB **or** Mac SSH/`scp`).

Kit location in this repo:

`parking-scheduler/` (under Brian-HomeServer)

## What’s inside

| Path | Purpose |
|------|---------|
| `UNRAID.md` | **Start here** — Docker deploy on Unraid 7.3.2 |
| `INSTALL.md` | Generic Linux / Ubuntu VM install (use only if not Docker) |
| `PARKING-README.md` | Project overview |
| `parking-docker/` | Readable copy of `Dockerfile`, `docker-compose.yml`, entrypoint (same files are inside the zip under `parking/`) |
| `config-examples/` | Example configs (no secrets) |
| `resource-scheduler-automation.zip` | Full app + Docker files to unzip on Unraid (secrets excluded) |

## Quick start

1. Open [UNRAID.md](UNRAID.md).
2. Complete **Before you start**, then **Steps 1–10**.
3. Get the zip onto Unraid with **Method A (Finder SMB)** or **Method B (SSH/`scp`)**.
4. Build/start with Compose Manager Plus; run `parking login` and approve PingID.

Prefer Docker over a VM (saves CPU/RAM/disk). Do **not** install Playwright on the Unraid host via User Scripts. Cron runs **inside** the `parking` container — not under **Settings → User Scripts**.

On Unraid, use [UNRAID.md](UNRAID.md) first. [INSTALL.md](INSTALL.md) is for a normal Linux/VM install only.
