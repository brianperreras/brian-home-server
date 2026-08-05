# 99 - Official Sources

These are the preferred references. Check them before major changes because menus and deployment files evolve.

## Unraid

| Resource | URL |
|---|---|
| Documentation home | https://docs.unraid.net/ |
| Download Unraid + USB Creator | https://unraid.net/download |
| Getting started guide | https://unraid.net/getting-started |
| Create bootable media | https://docs.unraid.net/unraid-os/getting-started/set-up-unraid/create-your-bootable-media/ |
| USB Creator for macOS | https://releases.unraid.net/dl/stable/usb-creator.dmg |
| USB Creator for Windows | https://releases.unraid.net/dl/stable/usb-creator.exe |
| USB Creator for Linux | https://releases.unraid.net/dl/stable/usb-creator.appimage |
| Unraid OS release archive | https://docs.unraid.net/go/download-list/ |
| Array configuration | https://docs.unraid.net/unraid-os/getting-started/set-up-unraid/configure-your-array/ |
| Cache pools | https://docs.unraid.net/unraid-os/using-unraid-to/manage-storage/cache-pools/ |
| Shares | https://docs.unraid.net/unraid-os/using-unraid-to/manage-storage/shares/ |
| Community Applications | https://unraid.net/community/apps |

## Gigabyte motherboard / BIOS

Verify the exact model and revision printed on the motherboard before downloading.

| Board | Support (BIOS downloads) | Product page |
|---|---|---|
| B760M DS3H DDR4 Rev. 1.0 | https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-rev-10/support | https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-rev-10 |
| B760M DS3H DDR4 GEN5 | https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5/support | https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5 |
| Intel 700-series BIOS guide | https://www.gigabyte.com/WebPage/928/intel700-bios.html | |

Do **not** use AX / Wi-Fi board BIOS files unless your PCB is that model.

## Immich

| Resource | URL |
|---|---|
| Documentation home | https://docs.immich.app/ |
| Docker Compose install guide | https://docs.immich.app/install/docker-compose |
| Hardware transcoding | https://docs.immich.app/features/hardware-transcoding |
| Latest `docker-compose.yml` | https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml |
| Latest `example.env` | https://github.com/immich-app/immich/releases/latest/download/example.env |
| GitHub releases | https://github.com/immich-app/immich/releases |
| Mobile apps / quick start | https://docs.immich.app/overview/quick-start |

## Home Assistant

| Resource | URL |
|---|---|
| Installation methods | https://www.home-assistant.io/installation/ |
| Container / alternative install | https://www.home-assistant.io/installation/alternative/ |
| Official container image | https://hub.docker.com/r/homeassistant/home-assistant |
| Tuya integration | https://www.home-assistant.io/integrations/tuya/ |
| Breaking changes / release notes | https://www.home-assistant.io/blog/categories/release-notes/ |

## Jellyfin

| Resource | URL |
|---|---|
| Documentation home | https://jellyfin.org/docs/ |
| Container installation | https://jellyfin.org/docs/general/installation/container/ |
| Hardware acceleration | https://jellyfin.org/docs/general/administration/hardware-acceleration/ |

## Docker / Compose on Unraid

| Resource | URL |
|---|---|
| Docker Compose documentation | https://docs.docker.com/compose/ |
| Compose file reference | https://docs.docker.com/compose/compose-file/ |
| **Compose Manager Plus** (current) | https://forums.unraid.net/topic/197334-plugin-compose-manager-plus/ |
| Compose Manager Plus (GitHub) | https://github.com/mstrhakr/compose_plugin |
| Compose Manager (deprecated) | https://forums.unraid.net/topic/114415-plugin-docker-compose-manager |

## Plugins used in this handbook

| Plugin | Notes |
|---|---|
| Compose Manager Plus | Replaces deprecated Compose Manager |
| Appdata Backup | CA name; successor to CA Backup / ca.backup2 |
| Unassigned Devices | Exos backup disk |
| User Scripts | Cron / scheduled jobs |
| Tailscale (Plugin) | Remote access; see Tailscale section below |

**Built into Unraid 7 (do not install old plugins):** Dynamix File Manager, GUI Search.

## Tailscale / remote access

| Resource | URL |
|---|---|
| Tailscale download | https://tailscale.com/download |
| Unraid Tailscale manual | https://docs.unraid.net/unraid-os/manual/security/tailscale/ |
| Plugin setup (EDACerton) | https://edac.dev/unraid/tailscale/plugin/ |
| Plugin support thread | https://forums.unraid.net/topic/136889-plugin-tailscale/ |
| Tailscale Unraid integration notes | https://tailscale.com/docs/integrations/unraid |

## General note

Community Applications templates and plugins are community-maintained. Read each application's support thread and use official project documentation as the final authority for application-specific deployment. Prefer official Immich Docker Compose over unofficial CA Immich templates.
