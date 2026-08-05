# 01 - Hardware Assembly and Airflow

## Airflow objective

The room can reach 30-32 C, so the server needs steady airflow rather than aggressive fan speeds. The intended airflow path is front-to-back and bottom-to-top.

```text
FRONT                                  REAR

[P14 intake] --->                     [P12 exhaust] --->
[P14 intake] --->  CPU dual tower     
                    ||||||             TOP: P12 exhaust(s) ^
                    ||||||

Primary HDD should receive direct or nearby intake airflow.
```

## Fan placement

v4.0 planned layout:

| Position | Fan | Direction | Purpose |
|---|---|---|---|
| Front lower | Arctic P14 Pro PST | Intake | HDD and motherboard airflow |
| Front upper | Arctic P14 Pro PST | Intake | CPU and VRM airflow |
| Rear | Arctic P12 Pro PST | Exhaust | Removes CPU heat |
| Top rear | Arctic P12 Pro PST | Exhaust | Removes rising heat |
| Top front | Arctic P12 Pro PST | Exhaust at low RPM | Second top exhaust from the v4.0 plan |

**Commissioning tip:** Bring the system up with two front intakes, one rear exhaust, and one top-rear exhaust first. Measure IronWolf and CPU temperatures under Immich import / Jellyfin transcode load. Add the second top exhaust only if measurements show a clear benefit. Two aggressive top exhausts can pull fresh intake air out before it reaches the CPU and HDD.

## Peerless Assassin orientation

Orient the cooler so that its fans push air toward the rear exhaust. Connect both cooler fans to `CPU_FAN` using the included splitter. Confirm the front cooler fan does not press hard against the RAM.

## Positive pressure

Run the two 140 mm intake fans slightly faster in total airflow than the exhaust fans. This reduces dust entering through unfiltered gaps. A practical starting point:

- Front P14 fans: 30-40% at low temperature.
- Rear/top P12 fans: 25-35% at low temperature.
- Increase all fans gradually above 55-60 C CPU temperature.

## HDD mounting

Use the native mounts for the primary and backup HDD whenever possible. A future third HDD should use a rigid metal or purpose-built fan-mount bracket with vibration isolation. Never place a bare HDD loose on the case floor.

Keep SATA connectors accessible and avoid sharp bends directly at the drive. Secure the drive with all practical screws and ensure airflow reaches its top and sides.

## Cable plan

- Route 24-pin and EPS CPU power before installing all fans.
- Keep SATA power wiring away from fan blades.
- Use only the Seasonic cables supplied with the SGX-650.
- Leave a service loop for the HDD cables, but do not coil excess cable against the front intake.
- Label the SATA data cables `PRIMARY` and `BACKUP` at both ends.

## Temperature targets

These are operational targets, not guarantees:

| Component | Preferred normal range | Investigate |
|---|---:|---:|
| IronWolf HDD | 30-45 C | sustained 50 C or higher |
| GM7000 NVMe | below 70 C under sustained load | throttling or 80 C+ |
| i5-14400 | below 80 C under sustained workloads | repeated thermal throttling |

The GM7000 is a high-performance NVMe and should use the motherboard M.2 heatsink if available. Remove the protective film from the thermal pad before installation.

## Cleaning interval

Inspect filters and fan blades monthly for the first three months. After learning the dust rate in the room, set a practical cleaning interval, usually every two or three months.

**Next:** chapter `02` BIOS.
