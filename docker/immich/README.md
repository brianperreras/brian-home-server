# Immich Compose Project

Do not treat a copied compose file as permanently current. Follow **`docs/06-Immich.md`** end-to-end on Unraid (terminal + Compose Manager Plus).

Quick reminder of where files live on the server:

| Path | What |
|---|---|
| `/mnt/user/appdata/compose-projects/immich/` | Project folder |
| `docker-compose.yml` | Official Immich compose |
| `.env` | Edit on the server only (`nano` or Compose Manager Plus **.ENV** tab) |
| `hwaccel.transcoding.yml` | Optional Quick Sync |

```bash
cd /mnt/user/appdata/compose-projects/immich
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
nano .env
```

Set at least:

```dotenv
UPLOAD_LOCATION=/mnt/user/photos/immich-library
DB_DATA_LOCATION=/mnt/user/appdata/immich/postgres
IMMICH_VERSION=release
DB_PASSWORD=CHANGE_ME
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
```

Official guide: https://docs.immich.app/install/docker-compose

Keep the real `.env` on the server and out of Git.
