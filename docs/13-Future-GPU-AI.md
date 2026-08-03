# 13 - Future GPU and Local AI

The i5-14400 iGPU is retained for media acceleration. A future discrete GPU can be dedicated to AI.

## Before buying

Check:

- Physical GPU length and thickness with HDD brackets installed.
- PSU connector requirements.
- Total power requirement and transient behavior.
- Unraid/Linux driver support.
- AI framework support, not only gaming benchmarks.
- VRAM capacity; local AI often benefits more from VRAM than raw gaming speed.

## PSU

The Seasonic SGX-650 is suitable for many mid-range GPUs using standard PCIe connectors. Re-evaluate the PSU if the selected GPU requires substantially higher wattage or a native 12V-2x6 connector.

## BIOS

Retain iGPU:

- Internal Graphics enabled.
- iGPU Multi-Monitor enabled when required.
- Above 4G Decoding enabled.
- Re-Size BAR enabled for supported GPUs.

## Unraid

Install the vendor driver plugin supported by the current Unraid release, then pass the GPU to the intended Docker containers or VM. Do not pass the same GPU to multiple consumers without understanding the driver's sharing limitations.
