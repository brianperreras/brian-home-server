# Immich Compose Project

Do not treat a copied compose file as permanently current. Download the latest official files from the Immich release, then apply the paths documented in `docs/06-Immich.md`.

```bash
cd /mnt/user/appdata/compose-projects/immich
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
```

Official guide: https://docs.immich.app/install/docker-compose

This Unraid layout:

- `UPLOAD_LOCATION=/mnt/user/photos/immich-library` (IronWolf)
- `DB_DATA_LOCATION=/mnt/user/appdata/immich/postgres` (GM7000)

Keep the real `.env` on the server and out of Git.
