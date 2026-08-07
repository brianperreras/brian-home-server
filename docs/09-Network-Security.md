# 09 - Access the Server (Local and Remote)

**Unraid OS 7.3.2.** This build’s LAN IP is **`192.168.0.10`**.

- **While installing Immich / Home Assistant / Jellyfin:** use [**Part A (LAN only)**](#part-a-lan).
- **Tailscale ([Part B](#part-b-tailscale)):** optional, after apps work on the LAN. Do not mix Tailscale into app install chapters.
- **Cloudflare Tunnel + Access ([Part D](#part-d-cloudflare)):** browser URLs at `*.migulix.uk` without Tailscale — after LAN works. Immich: [D7a](#d7a-immich).

Do not open router port forwards to Unraid or apps.

## Before you start

| Check | Where | Value |
|---|---|---|
| Server name | **Settings → Identification** | `brian-server` |
| LAN IP | **Dashboard** or **Settings → Network Settings** | `192.168.0.10` |
| Client network | Phone / PC Wi‑Fi | Main LAN (not isolated guest Wi‑Fi) |
| Array | **Main** | Started |

---

<a id="part-a-lan"></a>

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

<a id="part-b-tailscale"></a>

# Part B — Remote access with Tailscale (do later)

Tailscale connects your phone/laptop to Unraid over a private mesh VPN. No port forwarding.

Official references (if UI labels differ slightly by plugin version, use **Help** on the Tailscale settings page):

- Unraid manual: https://docs.unraid.net/unraid-os/manual/security/tailscale/
- Plugin setup: https://edac.dev/unraid/tailscale/plugin/
- Forum: https://forums.unraid.net/topic/136889-plugin-tailscale/

## B1. Create a Tailscale account (on your Mac/phone browser)

1. Open https://login.tailscale.com and sign up / sign in.
2. Enable MFA on that account.

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

<a id="part-d-cloudflare"></a>

# Part D — Browser remote WebGUI (Cloudflare Tunnel + Access)

Use this when you want Unraid WebGUI in **any browser** without Tailscale on the phone/laptop. No router port forwards.

**Domain for this build:** `migulix.uk`

| Public URL | Service | Guide |
|---|---|---|
| [`https://unraid.migulix.uk`](https://unraid.migulix.uk) | Unraid WebGUI | Part D first ([D3](#d3-public-hostname) + [D5](#d5-cloudflare-access)) |
| [`https://photos.migulix.uk`](https://photos.migulix.uk) | Immich | [D7a](#d7a-immich) (after [06](06-Immich.md)) |
| [`https://home.migulix.uk`](https://home.migulix.uk) | Home Assistant | [D7b](#d7b-home-assistant) (after [07](07-Home-Assistant.md)) |
| [`https://media.migulix.uk`](https://media.migulix.uk) | Jellyfin | [D7c](#d7c-jellyfin) (after [14](14-Jellyfin.md)) |

Tunnel dials **out** from Unraid to Cloudflare. Cloudflare Access asks you to prove identity before Unraid’s root login appears.

Do this **after** the WebGUI works on LAN (Part A). Tailscale (Part B) remains optional for SSH / SMB / full LAN-like access.

Kit files in this repo: [`docker/cloudflared/`](../docker/cloudflared/).

## D0 — Before you start

| Check | Where |
|-------|--------|
| Domain `migulix.uk` registered and active | Cloudflare dashboard → **Domain registration** / **Websites** |
| DNS for `migulix.uk` on Cloudflare | **Websites → migulix.uk** (nameservers active) |
| Array Started; Docker on | **Main** / **Settings → Docker** |
| Compose Manager Plus; Projects Folder | `/mnt/user/appdata/compose-projects` ([05 Docker](05-Docker.md)) |
| MFA on your Cloudflare account | Cloudflare account settings (recommended) |

## D1 — Add the site (if not already)

1. Open https://dash.cloudflare.com
2. **Add a site** / confirm **`migulix.uk`** is listed.
3. Plan: **Free** is enough.
4. Wait until Cloudflare shows the zone as **Active** (nameservers already set if you bought via Cloudflare Registrar).

## D2 — Create a Zero Trust tunnel

1. Open https://one.dash.cloudflare.com (Zero Trust).
2. If prompted, create a Zero Trust org (free team name is fine).
3. Left sidebar → **Networks** → **Tunnels & Mesh** (older UI may say **Tunnels** only).
4. Click **Create a tunnel**.
5. Connector: **Cloudflared**.
6. Tunnel name: `brian-server` (or `unraid`).
7. Save tunnel.
8. Environment: **Docker**.
9. Copy the long **token** after `--token` (or the `TUNNEL_TOKEN` value). Store it in your password manager — treat it like a root password.

Do **not** paste the token into Git or chat logs.

<a id="d3-public-hostname"></a>

## D3 — Public hostname → Unraid WebGUI

Hostnames live on the **tunnel**, not under **Access settings**.

### Where to click (current Zero Trust UI)

1. Open https://one.dash.cloudflare.com
2. Left sidebar → **Networks** (expand if needed)
3. Click **Tunnels & Mesh** (you should see your tunnel list; older label: **Tunnels**)
4. In the table, click the blue tunnel name **`brian-server`**
5. Open the **Published application routes** (or **Public Hostname**) tab
6. Click **Add a public hostname** (or **Add**)

### Hostname fields (Unraid)

| Field | Value |
|-------|--------|
| Subdomain | `unraid` |
| Domain | `migulix.uk` |
| Path | *(leave empty)* |
| Type / Service | **HTTP** |
| URL | `192.168.0.10:80` |

Notes:

- Save the public hostname. Cloudflare creates the DNS CNAME for `unraid.migulix.uk` automatically.
- Origin is LAN HTTP on port **80**.

**Do not** add SSH, SMB, or other Docker ports here yet.

## D4 — Deploy cloudflared on Unraid

Same pattern as Immich (`06`): one folder under Projects Folder → Compose Manager Plus shows the stack automatically. Kit: [`docker/cloudflared/`](../docker/cloudflared/).

#### A1. Confirm Compose Manager Plus

| Check | Where | Expected |
|---|---|---|
| Plugin installed | **Plugins** | **Compose Manager Plus** (mstrhakr) |
| Projects Folder | **Settings → Compose Manager Plus** (or **Settings → Compose**) | `/mnt/user/appdata/compose-projects` |
| Docker running | **Settings → Docker** | Enable Docker = **Yes** |

If Projects Folder is wrong, fix it and **Apply** before continuing (chapter `05`).

#### A2. Create the stack folder

WebGUI → top-right **>_** (or `ssh root@192.168.0.10`):

```bash
mkdir -p /mnt/user/appdata/compose-projects/cloudflared
cd /mnt/user/appdata/compose-projects/cloudflared
pwd
```

Expected: `/mnt/user/appdata/compose-projects/cloudflared`

#### A3. Create `docker-compose.yml`

```bash
cd /mnt/user/appdata/compose-projects/cloudflared
nano docker-compose.yml
```

Copy the YAML below into `nano` (no ports, no volumes — outbound tunnel only):

```yaml
# Unraid 7.3.2 + Compose Manager Plus
# Path: /mnt/user/appdata/compose-projects/cloudflared/

services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    environment:
      TUNNEL_TOKEN: ${TUNNEL_TOKEN}
```

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

#### A4. Create `.env` with the tunnel token

Token from **D2** (Zero Trust → Tunnels → Docker install → value after `--token`). Do **not** commit this file or paste the real token into Git/chat.

```bash
cd /mnt/user/appdata/compose-projects/cloudflared
nano .env
```

Copy this line into `nano`, then replace the placeholder with your real token (no quotes, no spaces around `=`):

```dotenv
TUNNEL_TOKEN=paste-your-tunnel-token-here
```

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

```bash
chmod 600 .env
ls -la
```

You should see `docker-compose.yml` and `.env`. Permissions on `.env` should be `-rw-------`.

Confirm the key exists without printing the secret:

```bash
grep -E '^TUNNEL_TOKEN=' .env | sed 's/=.*/=***redacted***/'
```

#### A5. Confirm the Compose Manager Plus stack

1. Open **Docker** → Compose section.
2. You should see a stack named **`cloudflared`**.
3. **Do not click Add Stack** — that creates a duplicate like `cloudflared-001`.

If no stack appears: refresh the Docker page. Still missing → confirm Projects Folder is `/mnt/user/appdata/compose-projects`, confirm `docker-compose.yml` exists under `cloudflared/`, then refresh again.

If you already have **`cloudflared` and `cloudflared-001`**: delete the extra (stack menu → Delete). Keep the one on `/mnt/user/appdata/compose-projects/cloudflared`.

#### A6. Autostart

On **Docker** → Compose → **`cloudflared` row**, turn **Autostart** **On** (not on the Settings tab).

#### A7. Start the stack

**Preferred:** **Docker** → Compose → **`cloudflared`** → stack menu → **Compose Up**.

**Or** Terminal:

```bash
cd /mnt/user/appdata/compose-projects/cloudflared
docker compose up -d
docker compose ps
docker compose logs --tail=50
```

Expected: container `cloudflared` is **Up**; logs mention the tunnel / connector without repeated auth errors.

#### A8. Confirm the tunnel is healthy

1. Open https://one.dash.cloudflare.com → **Networks → Tunnels**.
2. Tunnel `brian-server` (or the name from D2) should show **Healthy** / connector connected.
3. From a LAN browser, `http://192.168.0.10` should still work (tunnel does not replace LAN access).

Do **not** open `https://unraid.migulix.uk` from the public internet yet — finish **D5** (Access) first.

<a id="d5-cloudflare-access"></a>

## D5 — Cloudflare Access (required gate)

Without Access, anyone who learns `unraid.migulix.uk` hits your root login page. The tunnel hostname from [D3](#d3-public-hostname) already exists — Access only adds the login gate.

1. https://one.dash.cloudflare.com → left sidebar **Access controls** → **Applications** → **Add an application**
2. Top tab: **Self-hosted and private**
3. Chip: **Public DNS**
4. **Continue with Self-hosted and private**
5. Fill:

| Field | Value |
|---|---|
| Application name | `Unraid WebGUI` |
| Subdomain | `unraid` |
| Domain | `migulix.uk` |
| Path | leave empty |

6. Policy:

| Field | Value |
|---|---|
| Policy name | `Brian only` |
| Action | **Allow** |
| Include | **Emails** → your personal email |

7. If the wizard asks for a login method, enable **One-time PIN** (email). Leave other options at defaults.
8. **Create** / **Save**.
9. On cellular (off home Wi‑Fi), open `https://unraid.migulix.uk` → Access challenge → Unraid root login.

At home keep using `http://192.168.0.10`.

## D6 — Hardening checklist

| Rule | Why |
|------|-----|
| Access on every public hostname (`unraid` / `photos` / `home` / `media`) | Blocks anonymous access |
| Strong Unraid root password | Second factor after Access |
| MFA on Cloudflare account | Protects DNS + tunnel + Access |
| No port forwards for 80/443/22 | Tunnel is outbound-only |
| Autostart `cloudflared` | Survives reboot |

<a id="d7-app-hostnames"></a>

## D7 — App hostnames on the same tunnel (Immich, HA, Jellyfin)

After `unraid.migulix.uk` works with Access, you can publish apps on the **same** `cloudflared` tunnel. Do **one hostname at a time**. Each needs its own Access application.

**Domain:** `migulix.uk`

| Public URL | Service | LAN origin (tunnel Type = HTTP) | App chapter |
|---|---|---|---|
| `https://unraid.migulix.uk` | Unraid WebGUI | `192.168.0.10:80` (already [D3](#d3-public-hostname)) | — |
| `https://photos.migulix.uk` | Immich | `192.168.0.10:2283` | [06 Immich](06-Immich.md) → [D7a](#d7a-immich) |
| `https://home.migulix.uk` | Home Assistant | `192.168.0.10:8123` | [07 Home Assistant](07-Home-Assistant.md) → [D7b](#d7b-home-assistant) |
| `https://media.migulix.uk` | Jellyfin | `192.168.0.10:8096` | [14 Jellyfin](14-Jellyfin.md) → [D7c](#d7c-jellyfin) |

Do not port-forward `2283`, `8123`, or `8096`.

<a id="d7a-immich"></a>

### D7a — Immich: `photos.migulix.uk`

Prerequisite: Immich running on LAN — [06 Immich](06-Immich.md).  
Reuse tunnel **`brian-server`** (do **not** create a second tunnel).

**1. Add Immich hostname on the tunnel**

Exact clicks:

1. https://one.dash.cloudflare.com  
2. Left sidebar → **Networks** → **Tunnels & Mesh**  
3. Click **`brian-server`** (blue name in the table)  
4. Tab: **Published application routes** / **Public Hostname**  
5. Button: **Add a public hostname** (or **Add**)  

| Field | Value |
|---|---|
| Subdomain | `photos` |
| Domain | `migulix.uk` |
| Path | *(leave empty)* |
| Type / Service | **HTTP** |
| URL | `192.168.0.10:2283` |

Save. Cloudflare creates DNS for `photos.migulix.uk`.

You should now see both `unraid.migulix.uk` and `photos.migulix.uk` listed on **this same** tunnel.

**2. Access application (login gate — separate from hostname)**

Hostname is already done in step 1. Now protect it:

1. Left sidebar → **Access controls** → **Applications**
2. **Add an application**
3. **Self-hosted and private** → **Public DNS** → **Continue**
4. Name: `Immich`
5. Subdomain `photos`, domain `migulix.uk`
6. Policy: **Allow** → Include **Emails** → your email
7. If asked for a login method, enable **One-time PIN** → **Create** / Save

(Same path as [D5](#d5-cloudflare-access).)

**3. Test**

On cellular (or off home Wi‑Fi):

```text
https://photos.migulix.uk
```

Expected: Cloudflare Access → then Immich login.

At home you can keep using `http://192.168.0.10:2283`.

For the Immich **phone app** while away, use [Tailscale](#part-b-tailscale) (`http://100.x.y.z:2283`). Use `https://photos.migulix.uk` in a browser.

<a id="d7b-home-assistant"></a>

### D7b — Home Assistant: `home.migulix.uk`

Prerequisite: HA running on LAN — [07 Home Assistant](07-Home-Assistant.md).

**1. Trust the tunnel in HA (required first)**  
Follow [07 — trust Cloudflare Tunnel (UI)](07-Home-Assistant.md#ha-trusted-proxies).  
**Settings → System → Network** → Trust X-Forwarded-For **On** → trusted proxies include your `cloudflared` IP (e.g. `172.19.0.2`) + `172.16.0.0/12` + `127.0.0.1`.  
Do **not** put this in `configuration.yaml`.

**2. Tunnel + Access** (same clicks as [D7a](#d7a-immich)):

**Networks → Tunnels & Mesh** → **`brian-server`** → add public hostname, then **Access controls → Applications**.

| Field | Value |
|---|---|
| Subdomain | `home` |
| Domain | `migulix.uk` |
| Type / Service | **HTTP** |
| URL | `192.168.0.10:8123` |
| Access app name | `Home Assistant` |
| Public URL | `https://home.migulix.uk` |

**3. Test** `https://home.migulix.uk` → Access → HA login (not `400 Bad Request`).

Companion app while away: use [Tailscale](#part-b-tailscale) (`http://100.x.y.z:8123`), same idea as Immich.

<a id="d7c-jellyfin"></a>

### D7c — Jellyfin: `media.migulix.uk`

Prerequisite: Jellyfin running on LAN — [14 Jellyfin](14-Jellyfin.md).

Same clicks as [D7a](#d7a-immich): **Networks → Tunnels & Mesh** → **`brian-server`** → add public hostname, then **Access controls → Applications**.

| Field | Value |
|---|---|
| Subdomain | `media` |
| Domain | `migulix.uk` |
| Type / Service | **HTTP** |
| URL | `192.168.0.10:8096` |
| Access app name | `Jellyfin` |
| Public URL | `https://media.migulix.uk` |

## D8 — Troubleshooting

| Problem | Fix |
|---------|-----|
| Tunnel **Inactive** | `cd /mnt/user/appdata/compose-projects/cloudflared && docker compose logs --tail=50`; confirm `.env` has `TUNNEL_TOKEN`; container Up |
| Stack missing on Docker tab | Refresh; Projects Folder = `/mnt/user/appdata/compose-projects`; `docker-compose.yml` under `cloudflared/` |
| Duplicate `cloudflared-001` | Delete the extra stack; keep `compose-projects/cloudflared` |
| DNS error | Zone **Active**; public hostname saved on tunnel |
| 502 / bad gateway | LAN origin up (`http://192.168.0.10` or `:2283` etc.); tunnel URL/port correct |
| HA `400 Bad Request` on `home.migulix.uk` | Set Trust X-Forwarded-For + trusted proxies in HA **UI** ([07](07-Home-Assistant.md#ha-trusted-proxies)); remove any `http:` block from `configuration.yaml` |
| No Access login page | Access app hostname must match (e.g. `photos.migulix.uk`); type **Public DNS** |

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
https://photos.migulix.uk
https://home.migulix.uk
https://media.migulix.uk
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

8. **Immich via DNS (after [D7a](#d7a-immich))** — on cellular, open [`https://photos.migulix.uk`](https://photos.migulix.uk).
   Expected result: Access prompt first, then Immich login. At home, `http://192.168.0.10:2283` still works.

## Related

- Network IP: [03 Unraid](03-Unraid.md)
- Docker / Compose: [05 Docker](05-Docker.md)
- SMB users: [15 SMB / Git / cron](15-SMB-Git-Cron.md)
- Apps (LAN install first): [06 Immich](06-Immich.md) · [07 Home Assistant](07-Home-Assistant.md) · [14 Jellyfin](14-Jellyfin.md)
- Immich public URL steps: [D7a](#d7a-immich)
- HA public URL steps: [D7b](#d7b-home-assistant)
- Jellyfin public URL steps: [D7c](#d7c-jellyfin)
- cloudflared compose kit: [`docker/cloudflared/`](../docker/cloudflared/)
