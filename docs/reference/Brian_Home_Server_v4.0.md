# Brian's Home Server Documentation

> Planning snapshot aligned to the Unraid build. Detailed steps live in the numbered chapters under `docs/`.

## Build Version

v4.0

## Hardware

- CPU: Intel Core i5-14400
- CPU Cooler: Thermalright Peerless Assassin 120 SE
- Motherboard: Gigabyte B760M DS3H DDR4 GEN5
- RAM: Kingston Fury Beast 32GB (2x16GB) DDR4-3200 CL16
- SSD: Acer Predator GM7000 1TB
- Primary HDD: Seagate IronWolf 6TB
- Backup HDD: Seagate Exos 6TB (planned)
- PSU: Seasonic Focus SGX-650 (SSR-650SGX)
- Case: Jonsbo D33

## Cooling

- Front: 2x Arctic P14 Pro PST (Intake)
- Top: 2x Arctic P12 Pro PST (Planned Exhaust)
- Rear: 1x Arctic P12 Pro PST (Planned Exhaust)

## Storage Strategy

- GM7000: Docker, AppData, Home Assistant, PostgreSQL, MariaDB, Immich DB, Cache
- IronWolf 6TB: Primary 24/7 storage
- Exos 6TB: Weekly backup, spins down after backup

## Operating System

- **Chosen: Unraid OS**
- Not used for this build: Ubuntu Server 24.04 LTS (kept only as a historical alternative from earlier planning)

## Services

| Service | Host / placement | Guide order |
|---|---|---|
| Docker | Unraid built-in, data on GM7000 | After storage (`05`) |
| Immich | Compose; library on IronWolf; DB on GM7000 | After Docker (`06`) |
| Home Assistant | Container on Unraid | After Immich (`07`) |
| PostgreSQL | Per-app on GM7000 (Immich) | With Immich |
| MariaDB | Only if an app needs it | Later (`08`) |
| Jellyfin | Media on IronWolf; config on GM7000 | After HA (`14`) |
| SMB | Unraid user shares | After apps (`15`) |
| Git | Handbook on Mac; optional Gitea later | (`15`) |
| Cron / schedules | User Scripts plugin | (`15`) then backup (`10`) |

## Future

- Intel Arc or RTX xx60/xx70 GPU
- Third HDD if needed

## Estimated Power

- Idle: 35-45W
- Normal: 50-70W
- Heavy: 90-140W
