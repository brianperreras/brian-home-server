# 02 - Gigabyte BIOS Configuration

BIOS labels can move between firmware versions. Record the old value before changing a setting. Use the motherboard manual and BIOS search function when available.

Official Gigabyte BIOS setup overview: [Intel 700-series BIOS](https://www.gigabyte.com/WebPage/928/intel700-bios.html)

## 1. Update BIOS first

This build uses the **Gigabyte B760M DS3H DDR4 GEN5**. The i5-14400 requires firmware with 14th-generation CPU support. Download the BIOS for the **exact board name and revision printed on the motherboard**. Do not flash a BIOS intended for a similar but different DS3H model.

### Download pages

| Board | Role in this build | BIOS + drivers support page | Product / Q-Flash Plus page |
|---|---|---|---|
| B760M DS3H DDR4 GEN5 | **Selected board** | [Support / BIOS](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5/support) | [Board page](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5) |
| B760M DS3H DDR4 (Rev. 1.0) | Do not use unless PCB says this model | [Support / BIOS](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-rev-10/support) | [Board page](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-rev-10) |

On the support page:

1. Open the **BIOS** tab.
2. Download the newest stable BIOS zip for your exact model (not AX Wi-Fi variants unless that is what you own).
3. Note the listed checksum if Gigabyte publishes one.
4. Extract the zip on another computer before copying files to USB.

As of August 2026, Gigabyte listed **F5** for B760M DS3H DDR4 GEN5. Always re-check the support page before flashing; do not hard-code an old zip URL.

### Preferred method: Q-Flash inside BIOS

1. Download and extract the BIOS file from your board's support page above.
2. Copy the extracted BIOS file to a FAT32 USB drive.
3. Enter BIOS and launch Q-Flash.
4. Select the correct file and begin the update.
5. Do not power off the system during flashing.
6. After reboot, load Optimized Defaults once, save, reboot, then apply the settings below.

### Optional method: Q-Flash Plus

Q-Flash Plus can update without CPU/RAM/GPU when the board will not POST or normal Q-Flash is unavailable. Use only for your exact model:

1. Connect 24-pin and CPU 8-pin power to the motherboard.
2. Rename the extracted BIOS file to `gigabyte.bin` and save it on a FAT32 USB drive.
3. Insert the USB into the dedicated **Q-Flash Plus** rear USB port (see the board page / manual).
4. Press the Q-Flash Plus button and wait until the QFLED stops flashing.

More detail: [Q-Flash Plus on the GEN5 board page](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5)

## 2. Enable XMP

Typical path:

`Tweaker -> Extreme Memory Profile (X.M.P.) -> Profile 1`

Then verify:

- Memory frequency: DDR4-3200.
- Total memory: 32 GB.
- DRAM voltage and timings match the Kingston kit profile.

Do not manually overclock beyond the rated XMP profile. Stability is more important than a small performance gain on a server.

## 3. Storage mode

Set SATA operation to AHCI and disable Intel RST/VMD/RAID features that hide individual drives from Linux.

Look for settings such as:

- `SATA Mode -> AHCI`
- `Intel Rapid Storage Technology -> Disabled`
- `VMD Controller -> Disabled` unless specifically required for a future device

Unraid should see each physical disk separately.

## 4. Virtualization

Enable:

- Intel Virtualization Technology / VT-x.
- VT-d / Intel IOMMU.

These are useful for future VMs, device passthrough, and advanced container workloads.

## 5. Integrated graphics

Keep the Intel iGPU enabled even if a discrete GPU is installed later.

Look for:

- `Internal Graphics -> Enabled`
- `Initial Display Output -> IGFX` during initial setup, or leave Auto if a monitor works reliably
- `iGPU Multi-Monitor -> Enabled` when adding a discrete GPU and retaining Quick Sync

This allows Immich/Jellyfin to use Intel Quick Sync while a future GPU is reserved for AI.

## 6. PCIe and future GPU settings

Enable when available:

- Above 4G Decoding.
- Re-Size BAR Support, especially after installing a modern GPU.

Leave PCIe link speed on Auto unless troubleshooting.

## 7. Boot configuration

Recommended:

- Boot mode: UEFI.
- CSM: Disabled, unless the Unraid USB will not boot.
- Fast Boot: Disabled during setup.
- USB flash drive first in boot priority.
- Secure Boot: Disabled for the simplest Unraid boot path unless current Unraid documentation explicitly confirms your chosen secure-boot configuration.

## 8. Power and recovery

Recommended for a 24/7 server:

- Restore after AC power loss: `Power On` or `Last State`, according to preference.
- Wake-on-LAN: optional.
- ErP: Disable if it prevents Wake-on-LAN or USB behavior you need.
- Intel SpeedStep/Speed Shift and CPU C-states: Enabled/Auto for low idle power.

Do not disable CPU power-saving features unless troubleshooting latency or stability.

## 9. CPU power limits

Use Intel-default or motherboard `Normal` power behavior. Avoid unlimited power presets for a 24/7 server. The i5-14400 has ample performance without aggressive motherboard enhancement.

If the board exposes `Enhanced Multi-Core Performance`, use Disabled or an Intel-default option. Confirm full-load temperatures after setup.

## 10. Fan configuration with Smart Fan 6

Set each connected case fan header to PWM mode.

Suggested starting curve:

| Sensor temperature | Front P14 | Rear/top P12 |
|---:|---:|---:|
| 35 C | 30% | 25% |
| 50 C | 40% | 35% |
| 65 C | 60% | 55% |
| 75 C | 80% | 75% |
| 85 C | 100% | 100% |

Use a motherboard/system sensor for case fans when possible. CPU temperature can spike briefly, causing annoying fan surges. Add fan smoothing or interval delay if Smart Fan 6 provides it.

Do not enable Fan Stop for the front HDD intake fan. Maintain slow airflow over the primary HDD at all times.

## 11. Final verification

Save settings, reboot, then verify:

- DDR4-3200 is active.
- CPU and 32 GB RAM are detected.
- IronWolf and GM7000 are detected.
- USB boot entry appears as UEFI.
- LAN link is active.
- Virtualization is enabled.
- iGPU remains enabled.

After Unraid boots, run a memory test and monitor system logs for machine-check or IOMMU errors.

## Verify your setup

1. **CPU identified correctly** — check the POST screen or BIOS System Information page.
   Expected result: `Intel Core i5-14400` (or `i5-14400F` if you own that variant) displayed at detected speed.

2. **RAM at 3200 MHz with XMP active** — BIOS → Tweaker → Memory frequency.
   Expected result: `3200 MHz` shown, total `32768 MB` (32 GB).

3. **NVMe GM7000 visible in BIOS** — BIOS → Storage / M.2 device list.
   Expected result: Acer Predator GM7000 (or its model string) appears with correct capacity (~1 TB).

4. **AHCI mode confirmed, RST/VMD disabled** — BIOS → Peripherals / Storage → SATA Mode.
   Expected result: `AHCI` selected; no Intel RST or VMD entries shown as enabled.

5. **Boot order: USB first** — BIOS → Boot → Boot Option #1.
   Expected result: Unraid USB flash drive listed as the first UEFI boot entry.

6. **No POST errors on cold boot** — power cycle the system from off and watch the POST.
   Expected result: system reaches boot menu or Unraid console without error beeps or on-screen error codes.

7. **Virtualization enabled** — BIOS → CPU features.
   Expected result: Intel Virtualization Technology (VT-x) and VT-d both show `Enabled`.

8. **iGPU active** — BIOS → Chipset / Integrated Graphics.
   Expected result: Internal Graphics set to `Enabled` or `Auto`.

**Next:** chapter `03` Unraid.
