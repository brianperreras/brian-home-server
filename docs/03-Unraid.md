# 03 - Install and Configure Unraid

Unraid boots from a USB flash drive and loads the operating system into RAM. The USB contains the license identity and persistent configuration. The official guidance calls for a high-quality 4-32 GB flash drive with a unique GUID.

## 1. Create the USB on macOS

1. Download the current Unraid USB Flash Creator:
   - Download hub: https://unraid.net/download
   - macOS creator: https://releases.unraid.net/dl/stable/usb-creator.dmg
   - Windows creator: https://releases.unraid.net/dl/stable/usb-creator.exe
   - Install steps: https://docs.unraid.net/unraid-os/getting-started/set-up-unraid/create-your-bootable-media/
2. Insert an 8-32 GB USB drive. Everything on it will be erased.
3. Select the current stable Unraid release.
4. Server name suggestion: `brian-server`.
5. Use DHCP initially. Reserve a fixed address in the router later.
6. Enable UEFI boot.
7. Write the image and safely eject the drive.

Keep the USB in a protected rear port or on an internal USB-header adapter. Maintain a current backup of the flash configuration.

If the creator tool is unavailable, use the [manual install method](https://docs.unraid.net/unraid-os/getting-started/set-up-unraid/create-your-bootable-media/) and the [Unraid OS release archive](https://docs.unraid.net/go/download-list/).

## 2. First boot

1. Connect Ethernet.
2. Boot from the UEFI USB entry.
3. From another computer, open `http://tower`, `http://brian-server`, or the IP shown on the console.
4. Set a strong root password immediately.
5. Set timezone to your actual location.
6. Configure NTP and verify correct time.
7. Install a trial or purchased license only after confirming hardware detection.

## 3. Network configuration

Use DHCP initially, then create a DHCP reservation in your router for the server MAC address. A router reservation is usually safer than manually assigning an address that could conflict.

Suggested naming:

- Hostname: `brian-server`
- Management address: e.g. `192.168.1.10`
- Primary DNS: router or trusted local resolver

Do not expose the Unraid web interface via router port forwarding. Use Tailscale or a VPN for remote administration.

## 4. Plugins to install first

Install the [Community Applications](https://unraid.net/community/apps) plugin using the current official/community instructions. Then install only the tools you need:

- Compose Manager (or another maintained Compose method) for Immich / Home Assistant / Jellyfin stacks.
- Appdata Backup or the currently maintained equivalent.
- Unassigned Devices (required for the Exos weekly backup disk).
- Dynamix File Manager, if not already included.
- Tailscale plugin or container.
- User Scripts for scheduled shell jobs.

Avoid installing many plugins during initial setup. Add one at a time and record why it is needed.

After plugins and Docker are ready, follow the service bring-up order in [`05-Docker.md`](05-Docker.md).

## 5. Notifications

Configure email, browser, Discord, Telegram, or another supported notification target. Enable alerts for:

- SMART errors.
- High HDD/SSD temperatures.
- Filesystem errors.
- Docker image utilization.
- Backup job failure.
- Unclean shutdown.

## 6. Updates

Use stable releases. Before upgrading:

1. Read the release notes.
2. Back up the USB flash configuration.
3. Back up appdata and databases.
4. Confirm critical containers support the target release.
5. Upgrade during a maintenance window.

Do not update Unraid, Immich, Home Assistant, Jellyfin, and every container simultaneously. Change one layer, test, then continue.

## 7. USB backup

From the Unraid web UI, create a flash backup after initial configuration and after meaningful changes. Store the backup on your Mac and on the weekly backup disk. Do not store the only copy on the server itself.
