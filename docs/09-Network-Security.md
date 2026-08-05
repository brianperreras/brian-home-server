# 09 - Access the Server (Local and Remote)

How to reach **brian-server** from another computer on your home LAN, and from outside the house. Steps match **Unraid 7.3.2**. Prefer **Tailscale** for remote access — do not open router port forwards to Unraid or apps during Phase 1.

Replace `192.168.1.10` with whatever IP your router reserved for the server (chapter `03`).

## Before you start

Confirm these once:

| Check | Where | Expected value |
|---|---|---|
| Server name | **Settings → Identification → Server name** | `brian-server` |
| LAN IP | Router DHCP reservation, or Unraid **Dashboard** / **Settings → Network Settings** | e.g. `192.168.1.10` |
| Same Wi‑Fi / LAN | Client PC or phone | Connected to your home network (not guest Wi‑Fi isolated from LAN) |
| Array started | **Main** | Started (shares and Docker need this) |

Guest / “IoT” Wi‑Fi that isolates clients from the LAN often cannot reach the server. Use the main LAN/SSID for admin and file access.

---

## Part A — Local access (same home network)

### A1. Unraid web UI

From any browser on the LAN:

| Method | URL |
|---|---|
| By name | `http://brian-server` |
| By IP | `http://192.168.1.10` |
| With port (if you changed it) | `http://brian-server:PORT` from **Settings → Management Access** |

Log in as **root** with the Unraid root password.

If the name does not resolve, use the IP. On some routers, `.local` works: `http://brian-server.local`.

### A2. File shares (SMB)

Do this after chapter `15` (SMB users exist). Do **not** use `root` for SMB.

#### macOS

1. Finder → **Go → Connect to Server…** (⌘K).
2. Fill:

| Field | Value |
|---|---|
| Server address | `smb://brian-server` or `smb://192.168.1.10` |
| Connect As | **Registered User** |
| Name | SMB user (example: `brian`) |
| Password | that user’s password |

3. Choose shares to mount (`documents`, `media`, etc.).

#### Windows

1. File Explorer address bar, or **Map network drive**.
2. Fill:

| Field | Value |
|---|---|
| Folder | `\\brian-server` or `\\192.168.1.10` |
| Connect using different credentials | Yes |
| Username | `brian` (or `brian-server\brian` if Windows asks for domain) |
| Password | that user’s password |

3. Open the share you need.

#### Linux

```bash
# Example browse / mount (adjust user and share)
smbclient -L //brian-server -U brian
# or: gio mount smb://brian@brian-server/documents
```

### A3. Apps on the LAN

After each app chapter is done, open these in a browser (or the mobile app for Immich / HA):

| Service | Local URL | Login |
|---|---|---|
| Immich | `http://brian-server:2283` or `http://192.168.1.10:2283` | Immich account |
| Home Assistant | `http://brian-server:8123` or `http://192.168.1.10:8123` | HA account |
| Jellyfin | `http://brian-server:8096` or `http://192.168.1.10:8096` | Jellyfin account |
| Unraid UI | `http://brian-server` | root |

Phone on home Wi‑Fi can use the same URLs (or Immich / Home Assistant apps pointed at the LAN IP).

### A4. SSH on the LAN (optional)

Only if you need a shell from another PC:

1. Open **Settings → Management Access**.
2. Fill:

| Field | Value |
|---|---|
| Use SSL/TLS | leave as you prefer for WebGUI |
| SSH | **Yes** (only if you need it) |
| Telnet | **No** |

3. From another computer:

```bash
ssh root@brian-server
# or
ssh root@192.168.1.10
```

Prefer SSH keys later; do not expose port 22 to the internet.

---

## Part B — Remote access (away from home)

**Recommended method:** Tailscale mesh VPN. Your laptop/phone joins the same private Tailscale network as the server. No router port forwarding.

Official docs:

- Install overview: https://tailscale.com/kb/1017/install  
- Unraid notes: https://tailscale.com/kb/1134/unraid  
- Downloads: https://tailscale.com/download  

### B1. Create a Tailscale account

1. Sign up at https://login.tailscale.com (use a password manager; enable MFA on the Tailscale account).
2. You will approve devices from the Tailscale admin console.

### B2. Install Tailscale on Unraid

1. Open **Apps**.
2. Search for **Tailscale** (Plugin) — prefer the official Unraid Tailscale plugin (EDACerton), not a random third-party container unless you know why.
3. Install, then open it from **Settings → Tailscale** (or the plugin’s menu entry).
4. Typical first-run fields:

| Field | Value |
|---|---|
| Enable Tailscale | **Yes** |
| Unraid WebGUI / serve options | follow plugin prompts; enable access to the WebGUI over Tailscale if offered |
| Exit node / subnet router | leave **off** for Phase 1 unless you know you need LAN subnet routing |
| Accept DNS / MagicDNS | **Yes** (recommended) |

5. Click the auth / login link the plugin shows, approve the device in the browser, and wait until the plugin shows **Connected**.
6. In the [Tailscale admin console](https://login.tailscale.com/admin/machines), confirm a machine named like `brian-server` with a **100.x.y.z** Tailscale IP.

Write down:

| Item | Example |
|---|---|
| Tailscale IP | `100.x.y.z` |
| MagicDNS name | `brian-server.tailXXXX.ts.net` (if MagicDNS is on) |

### B3. Install Tailscale on your other computer / phone

| Device | Action |
|---|---|
| macOS / Windows / Linux | Install from https://tailscale.com/download → log in with the **same** Tailscale account → approve if asked |
| iOS / Android | Install Tailscale app → log in → VPN permission **Allow** → Connected |

Both the server and the client must show as online in the Tailscale admin console.

### B4. Open services over Tailscale

On the remote computer (Tailscale connected), use the **Tailscale IP** or MagicDNS name — not your home public IP.

| Service | Remote URL |
|---|---|
| Unraid web UI | `http://100.x.y.z` or `http://brian-server.tailXXXX.ts.net` |
| Immich | `http://100.x.y.z:2283` |
| Home Assistant | `http://100.x.y.z:8123` |
| Jellyfin | `http://100.x.y.z:8096` |

SMB over Tailscale (optional):

| OS | Address |
|---|---|
| macOS | `smb://100.x.y.z` or `smb://brian-server.tailXXXX.ts.net` |
| Windows | `\\100.x.y.z` |

Log in with the same SMB user as on the LAN (`brian`, not root).

### B5. Immich / HA mobile apps remotely

In each app’s server URL setting, use the Tailscale address while away from home, for example:

| App | Server URL example |
|---|---|
| Immich | `http://100.x.y.z:2283` |
| Home Assistant | `http://100.x.y.z:8123` |

Some people keep two server entries (LAN IP at home, Tailscale IP away). Tailscale on the phone must be connected when using the Tailscale URL.

### B6. SSH over Tailscale (optional)

```bash
ssh root@100.x.y.z
```

Still do not forward port 22 on the router.

---

## Part C — What not to do (Phase 1)

| Avoid | Why |
|---|---|
| Router port forward of `80` / `443` / `8080` to Unraid | Exposes admin UI |
| Port forward `2283`, `8123`, `8096`, `22` | Apps/SSH on the public internet without full hardening |
| Using `root` for SMB | Wrong account type; insecure habit |
| Relying only on dynamic public IP bookmarks | Breaks when ISP IP changes; Tailscale avoids this |

Later (Phase 2+), if you want a public HTTPS URL, plan a reverse proxy, TLS certificates, auth, logging, and updates first — not during initial setup.

---

## Quick cheat sheet

**At home (LAN)**

```text
Unraid UI     http://brian-server
Immich        http://brian-server:2283
Home Assistant http://brian-server:8123
Jellyfin      http://brian-server:8096
Files (Mac)   smb://brian-server
Files (Win)   \\brian-server
```

**Away (Tailscale connected)**

```text
Unraid UI     http://100.x.y.z
Immich        http://100.x.y.z:2283
Home Assistant http://100.x.y.z:8123
Jellyfin      http://100.x.y.z:8096
Files         smb://100.x.y.z   or   \\100.x.y.z
```

---

## Accounts reminder

| Access type | Account |
|---|---|
| Unraid WebGUI / SSH | `root` |
| SMB file shares | named user (example `brian`) from chapter `15` |
| Immich / HA / Jellyfin | each app’s own user accounts |
| Tailscale | your Tailscale login (MFA on) |

## Secrets to keep out of Git

- Tailscale auth keys (if you create any)
- root and SMB passwords
- app admin passwords
- `.env` / API tokens

## Related chapters

- Hostname and IP reservation: `03`
- SMB users and share export: `15`
- Per-app notes: `06` Immich, `07` Home Assistant, `14` Jellyfin
