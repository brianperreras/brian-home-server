# 03 - Install and Configure Unraid

These steps target **Unraid OS 7.3.2** (paid / registered key). Menu labels match the 7.3.x WebGUI. Unraid boots from a USB flash drive and loads the OS into RAM. The USB holds the license identity and persistent configuration. Use a high-quality 4–32 GB flash drive with a unique GUID.

## 1. Create the USB on macOS

1. Download the Unraid USB Flash Creator:
   - Download hub: https://unraid.net/download
   - macOS creator: https://releases.unraid.net/dl/stable/usb-creator.dmg
   - Install steps: https://docs.unraid.net/unraid-os/getting-started/set-up-unraid/create-your-bootable-media/
2. Insert an 8–32 GB USB drive. Everything on it will be erased.
3. In the creator, fill:

| Field | Value |
|---|---|
| Unraid version | **7.3.2** (or latest 7.3.x stable) |
| Server name | `brian-server` |
| Network | **DHCP** (first boot) |
| Allow UEFI boot | **Yes** / enabled |

4. Write the image and safely eject the drive.

Keep the USB in a protected rear port or on an internal USB-header adapter. Maintain a current backup of the boot-device configuration.

If the creator tool is unavailable, use the [manual install method](https://docs.unraid.net/unraid-os/getting-started/set-up-unraid/create-your-bootable-media/) and the [Unraid OS release archive](https://docs.unraid.net/go/download-list/).

## 2. First boot

1. Connect Ethernet.
2. Boot from the UEFI USB entry in the BIOS boot menu.
3. From another computer, open `http://tower`, `http://brian-server`, or the IP shown on the console.
4. Set a strong **root** password when prompted.
5. Open **Settings → Date & Time** and fill:

| Field | Value |
|---|---|
| Time zone | Your actual location (example: `Asia/Manila`) |
| Use NTP | **Yes** |
| NTP server(s) | Unraid default, or your preferred NTP |

6. Open **Settings → Identification** and fill:

| Field | Value |
|---|---|
| Server name | `brian-server` |
| Description | `Brian Home Server` (optional) |
| Model | optional |
| SSL / Management | leave defaults for LAN-only first setup |

7. Install / activate your **paid registration key** only after disks and NIC appear correctly on **Main** and **Dashboard**.

**Local access now:** from another PC on your LAN, open `http://brian-server` or `http://YOUR-RESERVED-IP` and log in as root. Full local + remote (Tailscale) instructions are in chapter `09`.

Do not expose the Unraid web UI via router port forwarding.

## 3. Network configuration

1. Open **Settings → Network Settings**.
2. Suggested fill for first setup:

| Field | Value |
|---|---|
| Enable bonding | **No** (single NIC) |
| Enable bridging | Unraid default (usually **Yes** for Docker later) |
| IPv4 address assignment | **Automatic: DHCP** |
| IPv4 DNS server | Router IP, or a trusted local resolver |
| IPv6 | **Disable** unless you intentionally use it |

3. In your **router**, create a DHCP reservation:

| Field | Value |
|---|---|
| Device / MAC | Unraid NIC MAC from **Settings → Network Settings** or **Dashboard** |
| Reserved IP | example `192.168.1.10` (match your LAN) |
| Hostname (if asked) | `brian-server` |

4. Click **Apply** on Unraid, then reboot or renew DHCP if the reserved address does not appear.

Prefer router reservation over typing a static IP only on Unraid (avoids conflicts).

## 4. Plugins to install first

1. Open the **Apps** tab.
2. If prompted, install **Community Applications**, then return to **Apps**.
3. Search and install only what you need, one at a time:

| Plugin | Why |
|---|---|
| **Compose Manager** (or another maintained Compose method) | Immich / Home Assistant / Jellyfin stacks |
| **Appdata Backup** (or current maintained equivalent) | App config backups |
| **Unassigned Devices** | Exos weekly backup disk |
| **Dynamix File Manager** | Browse shares in the UI (if not already included) |
| **Tailscale** (plugin or container) | Remote access without port forwards |
| **User Scripts** | Scheduled shell jobs (backup, dumps) |

4. After each install, open **Plugins** and confirm it appears and is enabled.
5. Record why each plugin was added.

Avoid installing many plugins during initial setup. Do **not** enable Docker or create app stacks in this chapter yet.

## 5. Notifications

1. Open **Settings → Notifications**.
2. Under **Notification Settings**, set at least:

| Field | Value |
|---|---|
| Display notifications in header / browser | **Yes** (recommended) |
| Severity / categories | enable System, Disk SMART, Docker, and Array alerts |

3. Under **Notification Agents**, configure one agent you will actually use (email, Discord, Telegram, etc.), then send a **Test**.
4. Ensure alerts cover at least:

- SMART errors
- High HDD/SSD temperatures
- Filesystem errors
- Docker image utilization (after Docker is enabled)
- Backup job failure
- Unclean shutdown

## 6. Updates

1. Open **Tools → Update OS** (or the update banner when shown).
2. Stay on **stable** releases.
3. Before upgrading:

   1. Read the release notes.
   2. Back up the boot device (section 7).
   3. Back up appdata and databases (after apps exist).
   4. Confirm critical containers support the target release.
   5. Upgrade during a maintenance window.

Do not update Unraid and every container at the same time. Change one layer, test, then continue.

## 7. Boot device backup (Unraid 7.3.x)

In Unraid **7.3.0 and later**, the WebGUI labels the USB as **Boot Device** (older versions said Flash).

1. Open the **Main** tab.
2. Select the **Boot Device**.
3. Open the **Boot Device** settings / detail view.
4. Click **Boot Device Backup**.
5. Download the ZIP to your Mac (and later also copy a ZIP to the weekly backup disk).

Create a boot-device backup after initial configuration and after meaningful changes. Do not keep the only copy on the server itself.

**Note (7.3.x):** files on the boot device can no longer get execute permission. When you run custom scripts from `/boot/...`, invoke them with an interpreter, for example `bash /boot/config/custom/backup/weekly-backup.sh`.

**Next:** chapter `04` Storage (disks and shares before Docker).
