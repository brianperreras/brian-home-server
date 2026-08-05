# 00 - Start Here

This chapter is the build-day checklist for the **Unraid** build. Do not configure services until the hardware is stable.

Planning snapshot: [Brian_Home_Server_v4.0.md](reference/Brian_Home_Server_v4.0.md)

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

## Do not do these

- Do not mix modular PSU cables from another PSU, even if the connectors fit.
- Do not enable motherboard RAID or Intel RST.
- Do not format the IronWolf from another OS after placing data on it.
- Do not expose Unraid, Immich, Home Assistant, or Jellyfin directly to the internet during initial setup.
- Do not configure the Exos backup disk as parity; it is a separately mounted weekly backup target.
- Do not install Ubuntu or another OS onto the GM7000 for this build; Unraid boots from USB.

## Recommended build order

1. Install CPU, NVMe, and RAM on the motherboard outside the case.
2. Install the CPU cooler backplate and brackets.
3. Test-fit the motherboard and PSU in the case.
4. Install the front intake fans.
5. Install the motherboard.
6. Install the CPU cooler and connect both cooler fans.
7. Install the IronWolf and route SATA power/data (label cables `PRIMARY` / `BACKUP`).
8. Connect front-panel, USB, audio, and fan headers.
9. Perform a cable inspection before applying power.
10. Enter BIOS and complete the settings in [`02-BIOS.md`](02-BIOS.md). Use the **GEN5** Gigabyte support page (or [`99-Sources.md`](99-Sources.md)).
11. Install Unraid from [`03-Unraid.md`](03-Unraid.md).

## First-boot success criteria

Before installing Unraid, verify:

- CPU is detected as Intel Core i5-14400.
- Memory total is 32 GB.
- XMP runs at DDR4-3200 without errors.
- GM7000 and IronWolf appear in BIOS.
- CPU temperature in BIOS is reasonable for a 30-32 C room; typically below about 55 C after a few minutes is a sensible initial target.
- All fans spin and respond to PWM control.
- The 2.5 GbE port establishes a network link.

## Suggested burn-in before adding personal photos

- Run a memory test for at least one complete pass; overnight is better.
- Run an extended SMART test on the IronWolf.
- Perform a CPU stress test from a temporary Linux live USB or after Unraid is installed.
- Confirm there are no machine-check errors, unexpected reboots, or thermal throttling.

Do not copy your only photo collection to the server until the disk has passed its initial tests and you have a second copy elsewhere.
