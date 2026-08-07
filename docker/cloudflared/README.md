# Cloudflare Tunnel (cloudflared) — Unraid 7.3.2

Place on the server at:

`/mnt/user/appdata/compose-projects/cloudflared/`

Create `.env` from `.env.example` and paste the tunnel token from Cloudflare Zero Trust (never commit the real token).

```bash
# On Unraid Terminal
mkdir -p /mnt/user/appdata/compose-projects/cloudflared
# copy docker-compose.yml + .env here, then:
cd /mnt/user/appdata/compose-projects/cloudflared
docker compose up -d
```

Or use Compose Manager Plus: stack name **`cloudflared`** appears when the folder exists under Projects Folder.
