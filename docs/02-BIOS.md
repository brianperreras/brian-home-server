# 02 - Gigabyte BIOS Configuration

BIOS labels can move between firmware versions. Record the old value before changing a setting. Use the motherboard manual and BIOS search function when available.

Official Gigabyte BIOS setup overview: [Intel 700-series BIOS](https://www.gigabyte.com/WebPage/928/intel700-bios.html)

## 1. Update BIOS first

This build uses the **Gigabyte B760M DS3H DDR4 GEN5**. The i5-14400 requires firmware with 14th-generation CPU support. Download the BIOS for the **exact board name and revision printed on the motherboard**. Do not flash a BIOS intended for a similar but different DS3H model.

### Download pages

| Board | BIOS + drivers support page | Product / Q-Flash Plus page |
|---|---|---|
| B760M DS3H DDR4 GEN5 | [Support / BIOS](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5/support) | [Board page](https://www.gigabyte.com/Motherboard/B760M-DS3H-DDR4-GEN5) |

On the support page:

1. Open the **BIOS** tab.
2. Download the newest stable BIOS zip for your exact model.
3. Note the listed checksum if Gigabyte publishes one.
4. Extract the zip on another computer before copying files to USB.

As of August 2026, this build runs **F6a** on the B760M DS3H DDR4 GEN5. Always re-check the support page before flashing; do not hard-code an old zip URL.

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

## 10. Fan configuration with Smart Fan 6 (BIOS F6a)

The B760M DS3H DDR4 GEN5 uses **Smart Fan 6**. In F6a this lives under:

`Advanced Mode → Smart Fan 6 Settings`

If you are in Easy Mode (the simplified first screen), press **F2** to switch to Advanced Mode first.

---

### Step 1 — Enter Smart Fan 6

1. Boot into BIOS (press **Delete** at POST).
2. Press **F2** for Advanced Mode if not already there.
3. Navigate to **Smart Fan 6 Settings** (top menu bar → last tab, or use search with **Ctrl+F** and type `fan`).

---

### Step 2 — Set each header to PWM mode

For every fan header you have connected:

| Header label | Your fan | Mode to set |
|---|---|---|
| `CPU_FAN` | Peerless Assassin (CPU cooler) | **PWM** |
| `SYS_FAN1` | Arctic P12 Pro PST (rear exhaust ×1) | **PWM** |
| `SYS_FAN2` | Arctic P12 Pro PST (top exhaust ×2, daisy-chained via PST) | **PWM** |
| `SYS_FAN3` | Arctic P14 Pro PST (front intake ×2, daisy-chained via PST) | **PWM** |

Click the header name → change **Fan Speed Control** from `Voltage` or `Auto` to **PWM**.

---

### Step 3 — Set the temperature source

For **case fans** (SYS_FAN headers), change the temperature source from `CPU` to **`System`** (the motherboard sensor). CPU temp spikes briefly under load and causes unnecessary fan surges on a server that mostly idles.

- Click the header → **Temperature Source** → `System`

Leave the **CPU_FAN** header on `CPU` temperature.

---

### Step 4 — Set the fan curve

Click each header → select **Customize** mode → edit the curve points.

**Exhaust fans — SYS_FAN1 (rear P12) and SYS_FAN2 (top P12 ×2), System temp sensor:**

| System temp | Fan speed |
|---:|---:|
| 30 °C | 25% |
| 40 °C | 30% |
| 50 °C | 40% |
| 60 °C | 55% |
| 70 °C | 75% |
| 80 °C | 100% |

**Intake fans — SYS_FAN3 (front P14 ×2), System temp sensor:**

| System temp | Fan speed |
|---:|---:|
| 30 °C | 20% |
| 40 °C | 25% |
| 50 °C | 35% |
| 60 °C | 50% |
| 70 °C | 70% |
| 80 °C | 100% |

Intakes run slightly slower than exhausts to maintain gentle negative-to-neutral pressure — dust accumulates on filters rather than inside the case.

**CPU cooler — Peerless Assassin (CPU_FAN, CPU temp sensor):**

| CPU temp | Fan speed |
|---:|---:|
| 40 °C | 30% |
| 55 °C | 40% |
| 65 °C | 55% |
| 75 °C | 75% |
| 85 °C | 100% |

These are conservative starting values for a 24/7 server in a ~30–32 °C room. Adjust upward if temps run hot, downward if the server is in a cooler space.

---

### Step 5 — Enable fan smoothing / interval

In F6a, each header has a **Fan Control Use Temperature Input** interval or **Tolerance** setting. Set it to **2–3 °C** tolerance so small temperature fluctuations do not cause constant speed changes.

---

### Step 6 — Fan Stop

**Do not enable Fan Stop** for any SYS_FAN header connected to intake fans. The IronWolf HDD needs slow continuous airflow even at idle. Fan Stop is acceptable only for the CPU cooler if desired.

---

### Step 7 — Save and verify

1. Press **F10** → Save & Exit.
2. After boot, re-enter BIOS → Smart Fan 6 Settings and confirm each header shows the curve and mode you set (F6a sometimes resets headers to Auto on first save — re-apply if needed).
3. Under **PC Health Status** (same Advanced Mode tab area), confirm fan RPMs are reported for all connected headers at idle.

Expected idle RPMs for this build in a ~30 °C room:
- CPU cooler: ~400–600 RPM
- P14 intakes: ~350–500 RPM
- P12 exhausts: ~300–450 RPM

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
   Expected result: `Intel Core i5-14400` displayed at detected speed.

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
