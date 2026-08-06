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
| Host OS | **Unraid OS 7.3.2** |

## Structure

Not everything runs in Docker. Only the app stacks do. SMB, Git, and cron stay on Unraid itself.

```
Unraid (host OS on USB → RAM)
├── Storage
│   ├── GM7000 (SSD pool) → Docker, appdata, DBs, cache; photos write cache
│   ├── IronWolf 6TB → photos (after mover), media, documents (primary data)
│   └── Exos 6TB → weekly backup (spins down)
│
├── Docker (enabled in ch. 05)
│   ├── Immich (+ Postgres)     ← container
│   ├── Home Assistant          ← container
│   └── Jellyfin                ← container
│
└── Host / Unraid built-ins (ch. 15)
    ├── SMB          → Unraid user shares (not Docker)
    ├── Git          → handbook on your Mac; optional Gitea later
    └── Cron         → User Scripts plugin (not Linux crontab / not Docker)
```

| Service | Where it runs |
|---|---|
| Immich | Docker Compose via **Compose Manager Plus** |
| Home Assistant | Docker Compose via **Compose Manager Plus** |
| Jellyfin | Docker Compose via **Compose Manager Plus** |
| Postgres / MariaDB | Docker (with the apps that need them) |
| SMB | Unraid native shares |
| Git | Mac + GitHub for Phase 1 (Gitea container only if you add it later) |
| Cron / schedules | Unraid **User Scripts** plugin |
| Tailscale | Remote access (see network chapter) |
| Weekly backup | Scripts + Exos HDD |

## Start here (one chapter at a time)

Follow this order. Do not skip Storage or Docker.

1. [00 Start Here](docs/00-Start-Here.md) — checklist and why this order
2. [01 Hardware](docs/01-Hardware-and-Airflow.md)
3. [02 BIOS](docs/02-BIOS.md)
4. [03 Unraid](docs/03-Unraid.md)
5. [04 Storage](docs/04-Storage.md) — disks and empty shares only
6. [05 Docker](docs/05-Docker.md) — enable Docker only
7. [06 Immich](docs/06-Immich.md)
8. [07 Home Assistant](docs/07-Home-Assistant.md)
9. [14 Jellyfin](docs/14-Jellyfin.md)
10. [15 SMB / Git / cron](docs/15-SMB-Git-Cron.md)
11. [10 Weekly backup](docs/10-Backup.md)

**Storage comes before Docker. Docker comes before Immich / HA / Jellyfin.**

Planning snapshot: [Brian Home Server v4.0](docs/reference/Brian_Home_Server_v4.0.md).

## Important design decisions

- Host OS is **Unraid**, not Ubuntu.
- There is **no parity drive**. A separate Exos backup disk is used instead.
- The primary IronWolf HDD remains available 24/7.
- The Exos backup HDD is expected to spin up only once or twice a week.
- The GM7000 NVMe stores Docker appdata, databases, thumbnails, metadata, and other latency-sensitive data.
- Original photos land on the GM7000 cache share then mover (`cache→array`) places them on the IronWolf; large media stays on the IronWolf.
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
