# Cloudflare Tunnel (cloudflared) — Unraid 7.3.2

**Full guide:** [docs/09-Network-Security.md](../../docs/09-Network-Security.md) → **Part D → D4 Option A**.

Place on the server at:

`/mnt/user/appdata/compose-projects/cloudflared/`

## Files in this folder

| File | Purpose |
|---|---|
| `docker-compose.yml` | cloudflared service (copy as-is) |
| `.env.example` | template for `TUNNEL_TOKEN` |

Never commit a real `.env` with a live token.

## Quick deploy (Compose Manager Plus)

Prereq: Projects Folder = `/mnt/user/appdata/compose-projects` (chapter `05`). Tunnel token from Zero Trust → **Networks → Tunnels** (Docker install).

On Unraid Terminal (**>_** or `ssh root@192.168.0.10`):

```bash
mkdir -p /mnt/user/appdata/compose-projects/cloudflared
cd /mnt/user/appdata/compose-projects/cloudflared
nano docker-compose.yml
```

Paste:

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

```bash
nano .env
```

Paste (replace the placeholder with your real token):

```dotenv
TUNNEL_TOKEN=paste-your-tunnel-token-here
```

Save, then:

```bash
chmod 600 .env
ls -la
```

Open **Docker** → Compose → stack **`cloudflared`** appears (do **not** Add Stack). On the **`cloudflared` row**, turn **Autostart** **On**, then stack menu → **Compose Up**.

Or:

```bash
docker compose up -d
docker compose logs --tail=50
```

Zero Trust → **Networks → Tunnels** → connector **Healthy**. Finish **Cloudflare Access** (D5) before using `https://unraid.migulix.uk` away from home.
