# Brian's Home Server

A practical build and operations handbook for a 24/7 Unraid home server.

## Current hardware

| Component | Selected hardware |
|---|---|
| CPU | Intel Core i5-14400 |
| CPU cooler | Thermalright Peerless Assassin 120 SE |
| Motherboard | Gigabyte B760M DS3H DDR4 / DDR4 GEN5 variant |
| Memory | Kingston FURY Beast 32 GB (2 x 16 GB) DDR4-3200 CL16 |
| NVMe | Acer Predator GM7000 |
| Primary HDD | Seagate IronWolf 6 TB, always available |
| Backup HDD | Future 6 TB drive, mounted only for weekly backup and otherwise spun down |
| PSU | Seasonic Focus SGX-650, SSR-650SGX |
| Case | Jonsbo D33 |
| Intake fans | 2 x Arctic P14 Pro PST |
| Exhaust fans | Arctic P12 Pro PST, as purchased/installed |
| Host OS | Unraid OS |

## Phase 1 services

- Immich
- Home Assistant
- Docker workloads
- Cron and scheduled jobs
- SMB file shares
- Tailscale remote access
- Automated weekly backup to the second HDD

## Start here

1. Read [Pre-build checklist](docs/00-Start-Here.md).
2. Assemble the server using [Hardware and airflow](docs/01-Hardware-and-Airflow.md).
3. Configure firmware using [BIOS configuration](docs/02-BIOS.md).
4. Install Unraid using [Unraid installation](docs/03-Unraid.md).
5. Configure storage using [Storage layout](docs/04-Storage.md).
6. Enable Docker using [Docker on Unraid](docs/05-Docker.md).
7. Deploy [Immich](docs/06-Immich.md) and [Home Assistant](docs/07-Home-Assistant.md).
8. Configure [weekly backups](docs/10-Backup.md).

## Important design decisions

- There is **no parity drive**. A separate backup disk is used instead.
- The primary IronWolf HDD remains available 24/7.
- The backup HDD is expected to spin up only once or twice a week.
- The GM7000 NVMe stores Docker appdata, databases, thumbnails, metadata, and other latency-sensitive data.
- Original photos and large files live on the IronWolf HDD.
- Unraid boots from USB; it does **not** install onto the NVMe.

## Safety rule

Never place secrets, passwords, API keys, Tailscale auth keys, or real `.env` files in Git. The supplied `.gitignore` excludes common secret files, but review every commit before pushing.

## Source freshness

The instructions were prepared in August 2026. Unraid, Immich, and Home Assistant change regularly. Before a major upgrade, compare the relevant chapter with the official documentation and download links in [Sources](docs/99-Sources.md).

Quick links:

- BIOS downloads: [B760M DS3H DDR4 Rev. 1.0](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-rev-10/support) · [DDR4 GEN5](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5/support)
- Unraid USB Creator: [unraid.net/download](https://unraid.net/download)
- Immich compose files: [latest docker-compose.yml](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml) · [example.env](https://github.com/immich-app/immich/releases/latest/download/example.env)
