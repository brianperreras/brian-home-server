# 09 - Access the Server (Local and Remote)

**Unraid OS 7.3.2.** This build’s LAN IP is **`192.168.0.10`**.

- **While installing Immich / Home Assistant / Jellyfin:** use **Part A (LAN only)**.
- **Tailscale (Part B):** do this **after** apps work on the LAN. Do not mix Tailscale into app install chapters.

Do not open router port forwards to Unraid or apps.

## Before you start

| Check | Where | Value |
|---|---|---|
| Server name | **Settings → Identification** | `brian-server` |
| LAN IP | **Dashboard** or **Settings → Network Settings** | `192.168.0.10` |
| Client network | Phone / PC Wi‑Fi | Main LAN (not isolated guest Wi‑Fi) |
| Array | **Main** | Started |

---

# Part A — Local access (home LAN)

Use these URLs during and after app install.

## A1. Unraid WebGUI

```text
http://brian-server
http://192.168.0.10
```

Log in as **root**.

## A2. Apps (after each app chapter)

```text
Immich           http://192.168.0.10:2283
Home Assistant   http://192.168.0.10:8123
Jellyfin         http://192.168.0.10:8096
```

`http://brian-server:PORT` works if your PC/phone resolves the hostname.

## A3. SMB file shares (after chapter `15`)

Do not use `root` for SMB. Use your named user (example `brian`).

```text
macOS:    smb://192.168.0.10
Windows:  \\192.168.0.10
```

## A4. SSH (optional)

1. **Settings → Management Access**
2. Set **SSH** = **Yes** only if you need it; **Telnet** = **No**
3. Apply
4. From another PC:

```bash
ssh root@192.168.0.10
```

Do not publish port 22 on the router.

---

# Part B — Remote access with Tailscale (do later)

Tailscale connects your phone/laptop to Unraid over a private mesh VPN. No port forwarding.

Official references (if UI labels differ slightly by plugin version, use **Help** on the Tailscale settings page):

- Unraid manual: https://docs.unraid.net/unraid-os/manual/security/tailscale/
- Plugin setup: https://edac.dev/unraid/tailscale/plugin/
- Forum: https://forums.unraid.net/topic/136889-plugin-tailscale/

## B1. Create a Tailscale account (on your Mac/phone browser)

1. Open https://login.tailscale.com and sign up / sign in.
2. Enable MFA on that account.
3. Optional now: install Tailscale on your Mac or phone from https://tailscale.com/download and log in with the **same** account (you need at least one client later anyway).

## B2. Install the plugin on Unraid

1. Unraid → **Apps**
2. Search: `Tailscale`
3. Install **Tailscale (Plugin)** maintained for Unraid (author **EDACerton** / Derek Kaser).
4. Do **not** install random “Tailscale” Docker containers for Phase 1.
5. Click **Done** when install finishes.
6. Confirm under **Plugins** that Tailscale is listed.

## B3. Log Unraid into your Tailnet

The settings page is **not** under Docker. It is a system plugin page:

1. Open **Settings**
2. Under **Network Services**, open **Tailscale**  
   (If you do not see it: refresh; confirm the plugin is installed under **Plugins**; try the header search box for `Tailscale`.)
3. On that page, click **Login** or **Reauthenticate** (Unraid docs use both labels depending on version).
4. Sign in with your **Tailscale** account (not Unraid.net / not root).
5. If the popup is blocked, use the link shown on the page and open it manually.
6. When prompted, click **Connect** to add this server to your Tailnet.
7. Wait until the plugin page shows the server as connected / online.

**Do not turn on** “Use Tailscale Subnets” / subnet router for Phase 1 unless you know you need it (a common cause of WebGUI confusion).

Optional: click **Help** (?) on the Tailscale settings page for the real field descriptions for your plugin version.

## B4. Find Unraid’s Tailscale address

Still on Unraid:

1. **Settings → Tailscale** — note the **Tailscale IP** (`100.x.y.z`) and machine / MagicDNS name.
2. Also check **Settings → Management Access** — Unraid 7 often shows Tailscale WebGUI URL(s) there after connect.
3. Or open https://login.tailscale.com/admin/machines and find `brian-server` (approve the device if approval is required).

Write them down:

```text
Tailscale IP:     100.x.y.z
MagicDNS name:    brian-server.tailXXXX.ts.net   (example shape)
```

## B5. Install Tailscale on the device you use away from home

1. Install from https://tailscale.com/download (Mac / Windows / Linux / iOS / Android).
2. Log in with the **same** Tailscale account.
3. Allow VPN permission on phone/laptop.
4. Confirm both Unraid and this device are online in the admin console.

## B6. Open Unraid / apps over Tailscale

On that remote device, with Tailscale **Connected**, use the Tailscale IP (replace with yours):

```text
Unraid UI        http://100.x.y.z
Immich           http://100.x.y.z:2283
Home Assistant   http://100.x.y.z:8123
Jellyfin         http://100.x.y.z:8096
SMB (Mac)        smb://100.x.y.z
SMB (Windows)    \\100.x.y.z
```

Or use the MagicDNS name the same way.

For Immich / Home Assistant mobile apps while away: set the server URL to the Tailscale address (Tailscale must be on). At home, keep using `http://192.168.0.10:PORT`.

## B7. Phase 1: skip these Tailscale extras

| Skip for now | Why |
|---|---|
| Docker container **Use Tailscale** switch | App chapters use normal LAN ports; not needed yet |
| Exit node | Advanced |
| Subnet router / “Use Tailscale Subnets” | Often unnecessary; can break WebGUI access habits |
| Router port forwarding | Avoid |

---

# Part C — Do not do this

```text
Do not port-forward 80, 443, 2283, 8123, 8096, or 22 on the router.
Do not use root for SMB.
```

---

## Cheat sheet

**At home**

```text
http://192.168.0.10
http://192.168.0.10:2283
http://192.168.0.10:8123
http://192.168.0.10:8096
smb://192.168.0.10
```

**Away (Tailscale on)**

```text
http://100.x.y.z
http://100.x.y.z:2283
http://100.x.y.z:8123
http://100.x.y.z:8096
```

## Related

- Network IP: `03`
- SMB users: `15`
- Apps (LAN install only): `06`, `07`, `14`
