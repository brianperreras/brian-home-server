# Brian's Home Server

A practical build and operations handbook for a 24/7 **Unraid** home server.

## Current hardware

| Component | Selected hardware |
|---|---|
| CPU | Intel Core i5-14400 (non-F, for Quick Sync) |
| CPU cooler | Thermalright Peerless Assassin 120 SE |
| Motherboard | Gigabyte B760M DS3H DDR4 GEN5 |
| Memory | Kingston FURY Beast 32 GB (2 x 16 GB) DDR4-3200 CL16 |
| NVMe | Acer Predator GM7000 1 TB |
| Primary HDD | Seagate IronWolf 6 TB, always available |
| Backup HDD | Seagate Exos 6 TB (planned), mounted only for weekly backup |
| PSU | Seasonic Focus SGX-650, SSR-650SGX |
| Case | Jonsbo D33 |
| Intake fans | 2 x Arctic P14 Pro PST |
| Exhaust fans | 1 x rear + 2 x top Arctic P12 Pro PST (planned) |
| Host OS | **Unraid OS** |

## Phase 1 services

- Immich
- Home Assistant
- Jellyfin
- Docker workloads (including per-app PostgreSQL / MariaDB when required)
- SMB file shares
- Git (documentation repo on Mac; optional Gitea later)
- Cron / User Scripts schedules
- Tailscale remote access
- Automated weekly backup to the Exos HDD

## Planning snapshot

High-level hardware, services, and future plans: [Brian Home Server v4.0](docs/reference/Brian_Home_Server_v4.0.md).

## Start here

1. Read [Pre-build checklist](docs/00-Start-Here.md).
2. Assemble the server using [Hardware and airflow](docs/01-Hardware-and-Airflow.md).
3. Configure firmware using [BIOS configuration](docs/02-BIOS.md).
4. Install Unraid using [Unraid installation](docs/03-Unraid.md).
5. Configure storage using [Storage layout](docs/04-Storage.md).
6. Enable Docker using [Docker on Unraid](docs/05-Docker.md).
7. Deploy [Immich](docs/06-Immich.md), [Home Assistant](docs/07-Home-Assistant.md), then [Jellyfin](docs/14-Jellyfin.md).
8. Configure [SMB / Git / cron](docs/15-SMB-Git-Cron.md) and [weekly backups](docs/10-Backup.md).

## Important design decisions

- Host OS is **Unraid**, not Ubuntu.
- There is **no parity drive**. A separate Exos backup disk is used instead.
- The primary IronWolf HDD remains available 24/7.
- The Exos backup HDD is expected to spin up only once or twice a week.
- The GM7000 NVMe stores Docker appdata, databases, thumbnails, metadata, and other latency-sensitive data.
- Original photos and large media live on the IronWolf HDD.
- Unraid boots from USB; it does **not** install onto the NVMe.

## Safety rule

Never place secrets, passwords, API keys, Tailscale auth keys, or real `.env` files in Git. The supplied `.gitignore` excludes common secret files, but review every commit before pushing.

## Source freshness

The instructions were prepared in August 2026. Unraid, Immich, Home Assistant, and Jellyfin change regularly. Before a major upgrade, compare the relevant chapter with the official documentation and download links in [Sources](docs/99-Sources.md).

Quick links:

- BIOS (this board): [B760M DS3H DDR4 GEN5 support](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5/support)
- Unraid USB Creator: [unraid.net/download](https://unraid.net/download)
- Immich compose files: [latest docker-compose.yml](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml) · [example.env](https://github.com/immich-app/immich/releases/latest/download/example.env)
- Jellyfin container docs: [jellyfin.org container install](https://jellyfin.org/docs/general/installation/container/)
