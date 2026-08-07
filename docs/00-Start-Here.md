# 00 - Start Here

Follow the chapters **in number order**. Do not skip ahead to Immich or Jellyfin until storage and Docker are done.

This build uses **Unraid OS 7.3.2** (paid). UI click paths in the chapters match that WebGUI (for example **Settings → Identification**, **Shares → Add Share**, **Main → Boot Device**).

**If a setting from the docs is missing:** use **Advanced View** (top-right on the page), stop Docker before editing **Settings → Docker** paths, and remember **Enable Copy-on-write** does not appear on **xfs** shares. Details are at the top of chapter `03`.

## Why this order

| Step | Chapter | What you do | Why first |
|---|---|---|---|
| 1 | `01` Hardware | Assemble PC and fans | Machine must power on |
| 2 | `02` BIOS | Firmware and boot settings | Unraid USB must boot |
| 3 | `03` Unraid | Install OS, network, plugins | Host is ready |
| 4 | `04` Storage | Disks, pool, empty shares | Apps need folders on disk |
| 5 | `05` Docker | Turn Docker on | Apps run as containers |
| 6 | `06` Immich | Photo stack | First app |
| 7 | `07` Home Assistant | Smart home | Second app |
| 8 | `14` Jellyfin | Media server | Third app |
| 9 | `15` SMB / Git / cron | File shares and schedules | Users and jobs |
| 10 | `10` Backup | Weekly Exos backup | Protect data last |

**Storage before Docker:** Unraid must know where `appdata` and data shares live before Docker starts.  
**Docker before Immich/Jellyfin/HA:** those services are containers; enabling Docker is only the engine, not the apps.

**Access from other computers:** use LAN URLs in chapter `09` Part A while installing apps (`http://192.168.0.10`, Immich `:2283`, etc.). Optional remote: Tailscale (`09` Part B) or browser WebGUI via Cloudflare Tunnel + Access (`09` Part D, domain `migulix.uk`) — after apps work on the LAN.

## Before assembly

Confirm that you have:

- Intel Core i5-14400, **non-F**, so Intel UHD graphics and Quick Sync are available.
- Gigabyte **B760M DS3H DDR4 GEN5** motherboard.
- Two matched 16 GB DDR4-3200 modules (32 GB total).
- Peerless Assassin 120 SE with LGA1700 mounting hardware.
- Acer Predator GM7000 **1 TB** NVMe.
- Seagate IronWolf 6 TB SATA drive (primary).
- Seagate Exos 6 TB SATA drive when ready (weekly backup; not required on day one).
- Seasonic SGX-650 and all original modular cables.
- Jonsbo D33 and required fan screws.
- Two Arctic P14 Pro PST intake fans.
- Arctic P12 Pro PST exhaust fans: rear plus planned dual top.
- A high-quality 8-32 GB USB drive with a unique GUID for **Unraid**.
- Ethernet cable connected to the router or switch.

Planning snapshot (optional): `docs/reference/Brian_Home_Server_v4.0.md`

## Do not do these

- Do not mix modular PSU cables from another PSU, even if the connectors fit.
- Do not enable motherboard RAID or Intel RST.
- Do not format the IronWolf from another OS after placing data on it.
- Do not expose Unraid or apps to the internet during initial setup.
- Do not configure the Exos as parity; it is a separate weekly backup disk.
- Do not install Ubuntu onto the GM7000; Unraid boots from USB.
- Do not install Immich/Jellyfin/Home Assistant until chapters `04` and `05` are finished.

## Build-day hardware order

1. Install CPU, NVMe, and RAM on the motherboard outside the case.
2. Install the CPU cooler backplate and brackets.
3. Test-fit the motherboard and PSU in the case.
4. Install the front intake fans.
5. Install the motherboard.
6. Install the CPU cooler and connect both cooler fans.
7. Install the IronWolf and route SATA power/data (label cables `PRIMARY` / `BACKUP`).
8. Connect front-panel, USB, audio, and fan headers.
9. Cable inspection, then power on.
10. Finish chapter `02` BIOS, then chapter `03` Unraid.

## First-boot success criteria (before Unraid install)

- CPU is detected as Intel Core i5-14400.
- Memory total is 32 GB.
- XMP runs at DDR4-3200 without errors.
- GM7000 and IronWolf appear in BIOS.
- CPU temperature is reasonable for a 30-32 C room (often below ~55 C after a few minutes).
- Fans spin and respond to PWM.
- 2.5 GbE link is up.

## Burn-in before personal photos

- Memory test: at least one full pass (overnight is better).
- Extended SMART test on the IronWolf.
- CPU stress test after Unraid is installed.
- No unexpected reboots or thermal throttling.

Do not copy your only photo collection until the disk has passed tests and you still have another copy elsewhere.

**Next:** chapter `01` Hardware and airflow.
