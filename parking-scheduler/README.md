# Brian Home Server — parking on Unraid 7.3.2

Deploy kit for Asurion parking automation on your personal Unraid box.

**Main guide:** [UNRAID.md](UNRAID.md) — Unraid OS **7.3.2** + Compose Manager Plus; transfer files with **SSH / `scp`**.

Kit location in this repo:

`parking-scheduler/`

## What’s inside

| Path | Purpose |
|------|---------|
| `UNRAID.md` | **Start here** — Docker deploy on Unraid 7.3.2 |
| `INSTALL.md` | Generic Linux / Ubuntu VM install (use only if not Docker) |
| `PARKING-README.md` | Project overview |
| `parking-docker/` | Readable copy of `Dockerfile`, `docker-compose.yml`, entrypoint |
| `config-examples/` | Example configs (no secrets) |
| `resource-scheduler-automation.zip` | Full app + Docker files to `scp` onto Unraid |

## Quick start

1. Open [UNRAID.md](UNRAID.md).
2. Complete **Before you start**, then **Steps 1–10**.
3. `scp` the zip to Unraid (Step 1).
4. Build/start with Compose Manager Plus; run `parking login` and approve PingID.

Prefer Docker over a VM. Do **not** install Playwright on the Unraid host via User Scripts. Cron runs **inside** the `parking` container.
