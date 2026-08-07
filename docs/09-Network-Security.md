# 09 - Access the Server (Local and Remote)

**Unraid OS 7.3.2.** This build’s LAN IP is **`192.168.0.10`**.

- **While installing Immich / Home Assistant / Jellyfin:** use **Part A (LAN only)**.
- **Tailscale (Part B):** optional, after apps work on the LAN. Do not mix Tailscale into app install chapters.
- **Cloudflare Tunnel + Access (Part D):** browser WebGUI at `https://unraid.migulix.uk` without Tailscale — after LAN WebGUI works.

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
Do not put Cloudflare Tunnel in front of SSH (port 22).
Do not tunnel Unraid WebGUI without Cloudflare Access (login gate) in front.
```

---

# Part D — Browser remote WebGUI (Cloudflare Tunnel + Access)

Use this when you want Unraid WebGUI in **any browser** without Tailscale on the phone/laptop. No router port forwards.

**Domain for this build:** `migulix.uk`  
**Public WebGUI URL:** `https://unraid.migulix.uk`

Tunnel dials **out** from Unraid to Cloudflare. Cloudflare Access asks you to prove identity before Unraid’s root login appears.

Do this **after** the WebGUI works on LAN (Part A). Tailscale (Part B) remains optional for SSH / SMB / full LAN-like access.

Kit files in this repo: [`docker/cloudflared/`](../docker/cloudflared/).

## D0 — Before you start

| Check | Where |
|-------|--------|
| Domain `migulix.uk` registered and active | Cloudflare dashboard → **Domain registration** / **Websites** |
| DNS for `migulix.uk` on Cloudflare | **Websites → migulix.uk** (nameservers active) |
| Array Started; Docker on | **Main** / **Settings → Docker** |
| Compose Manager Plus; Projects Folder | `/mnt/user/appdata/compose-projects` (chapter `05`) |
| MFA on your Cloudflare account | Cloudflare account settings (recommended) |

## D1 — Add the site (if not already)

1. Open https://dash.cloudflare.com
2. **Add a site** / confirm **`migulix.uk`** is listed.
3. Plan: **Free** is enough.
4. Wait until Cloudflare shows the zone as **Active** (nameservers already set if you bought via Cloudflare Registrar).

## D2 — Create a Zero Trust tunnel

1. Open https://one.dash.cloudflare.com (Zero Trust).
2. If prompted, create a Zero Trust org (free team name is fine).
3. Go to **Networks → Tunnels → Create a tunnel**.
4. Connector: **Cloudflared**.
5. Tunnel name: `brian-server` (or `unraid`).
6. Save tunnel.
7. Environment: **Docker**.
8. Copy the long **token** after `--token` (or the `TUNNEL_TOKEN` value). Store it in your password manager — treat it like a root password.

Do **not** paste the token into Git or chat logs.

## D3 — Public hostname → Unraid WebGUI

Still in the tunnel config (**Public Hostname** tab):

| Field | Value |
|-------|--------|
| Subdomain | `unraid` |
| Domain | `migulix.uk` |
| Path | *(leave empty)* |
| Type | **HTTP** |
| URL | `192.168.0.10:80` |

Notes:

- Unraid WebGUI is usually on **port 80** (HTTP) on the LAN. If you forced HTTPS-only on the LAN GUI, use `https://192.168.0.10` and enable **No TLS Verify** / skip verify for the origin (self-signed), or keep LAN HTTP and terminate TLS at Cloudflare only.
- Save the public hostname. Cloudflare creates the DNS CNAME for `unraid.migulix.uk` automatically.

**Do not** add SSH, SMB, or random Docker ports here yet.

## D4 — Deploy cloudflared on Unraid

### Option A — Compose Manager Plus (preferred)

1. WebGUI → top-right **>_** (or `ssh root@192.168.0.10`).
2. Create the stack folder and files:

```bash
mkdir -p /mnt/user/appdata/compose-projects/cloudflared
cd /mnt/user/appdata/compose-projects/cloudflared
```

3. Create `docker-compose.yml`:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    environment:
      TUNNEL_TOKEN: ${TUNNEL_TOKEN}
```

4. Create `.env` (paste your real token):

```bash
nano /mnt/user/appdata/compose-projects/cloudflared/.env
```

```bash
TUNNEL_TOKEN=paste-your-tunnel-token-here
```

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

```bash
chmod 600 /mnt/user/appdata/compose-projects/cloudflared/.env
```

5. Open **Docker** → Compose section. You should see stack **`cloudflared`**.  
   **Do not click Add Stack** if it already appears.
6. Turn **Autostart** **On**.
7. Stack menu → **Compose Up** (or Terminal):

```bash
cd /mnt/user/appdata/compose-projects/cloudflared
docker compose up -d
docker compose logs --tail=50
```

8. In Zero Trust → **Networks → Tunnels**, the tunnel should show **Healthy** / connector connected.

### Option B — Community Apps template

**Apps** → search `cloudflared` / `cloudflare-tunnel` → install a maintained template → paste **TUNNEL_TOKEN** → apply. Prefer Option A so the stack lives under `compose-projects` like Immich.

## D5 — Cloudflare Access (required gate)

Without Access, anyone who learns `unraid.migulix.uk` hits your root login page.

1. Zero Trust → **Access → Applications → Add an application**.
2. Type: **Self-hosted**.
3. Name: `Unraid WebGUI`.
4. Application domain: `unraid.migulix.uk` (HTTPS).
5. Create / next to **Policy**:
   - Policy name: `Brian only`
   - Action: **Allow**
   - Include: **Emails** → your personal email (the one you control)
6. Save.

Optional but better: Identity → add **One-time PIN** (email) or Google/GitHub login, and use that in the policy instead of a shared password.

Test from a phone **off** Wi‑Fi (cellular):

1. Open `https://unraid.migulix.uk`
2. Complete Cloudflare Access challenge
3. Then Unraid root login

At home you can keep using `http://192.168.0.10` (no Cloudflare required).

## D6 — Hardening checklist

| Rule | Why |
|------|-----|
| Access policy on `unraid.migulix.uk` | Blocks anonymous probes of the root UI |
| Strong Unraid root password | Second factor after Access |
| MFA on Cloudflare account | Protects DNS + tunnel + Access |
| No port forwards for 80/443/22 | Tunnel is outbound-only |
| Do not publish SSH via Tunnel | Use Tailscale/WireGuard later if you need remote SSH |
| Autostart `cloudflared` | Remote access survives reboot |

## D7 — Optional later (apps)

When ready, add more public hostnames on the **same** tunnel (each with its own Access policy):

| Hostname | Service URL (LAN) |
|----------|-------------------|
| `photos.migulix.uk` | `http://192.168.0.10:2283` |
| `home.migulix.uk` | `http://192.168.0.10:8123` |
| `media.migulix.uk` | `http://192.168.0.10:8096` |

One app at a time; Access on each hostname.

## D8 — Troubleshooting

| Problem | Fix |
|---------|-----|
| Tunnel **Inactive** | Check `docker compose logs`; confirm `.env` token; container running |
| DNS error / nowhere | Zone **Active**; public hostname saved; wait a few minutes for DNS |
| 502 / bad gateway | Confirm Unraid GUI is up on LAN `http://192.168.0.10`; origin URL/port correct |
| Infinite Access loop | Policy email matches the identity you use; try a private browser window |
| Works on LAN Cloudflare URL but slow | Normal; for local use prefer `http://192.168.0.10` |

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

**Away (browser, Cloudflare Tunnel + Access)**

```text
https://unraid.migulix.uk
```

**Away (Tailscale on)** — optional, Part B

```text
http://100.x.y.z
http://100.x.y.z:2283
http://100.x.y.z:8123
http://100.x.y.z:8096
```

## Verify your setup

1. **Immich reachable on LAN** — open a browser on a LAN machine.
   Expected result: `http://192.168.0.10:2283` loads the Immich login page.

2. **Home Assistant reachable on LAN** — open a browser on a LAN machine.
   Expected result: `http://192.168.0.10:8123` loads the HA login or onboarding page.

3. **Jellyfin reachable on LAN** — open a browser on a LAN machine.
   Expected result: `http://192.168.0.10:8096` loads the Jellyfin setup wizard or dashboard.

4. **Tailscale connected and server shows Tailscale IP** (only if you use Part B) — run in the Unraid terminal:

   ```bash
   tailscale status
   ```

   Expected result: `brian-server` appears as a connected node with a `100.x.x.x` address; status is `active`.

5. **No WAN port forwards to services** — check your router's port forwarding / NAT rules page (UI check).
   Expected result: no rules forward ports 2283, 8123, 8096, 80, 443, or 22 from the internet to `192.168.0.10`.

6. **Cloudflare Tunnel healthy** (Part D) — Zero Trust → **Networks → Tunnels**.
   Expected result: tunnel `brian-server` (or your name) shows connected/healthy; `cloudflared` container is running on Unraid.

7. **Access gate works** — on cellular data, open `https://unraid.migulix.uk`.
   Expected result: Cloudflare Access prompt first, then Unraid login; no Tailscale app required.

## Related

- Network IP: `03`
- Docker / Compose: `05`
- SMB users: `15`
- Apps (LAN install only): `06`, `07`, `14`
- cloudflared compose kit: [`docker/cloudflared/`](../docker/cloudflared/)
