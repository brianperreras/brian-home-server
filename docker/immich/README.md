# Immich Compose Project

Follow **`docs/06-Immich.md`** on Unraid.

Server folder:

```text
/mnt/user/appdata/compose-projects/immich/
```

Download official files, then set `.env` to:

```dotenv
UPLOAD_LOCATION=/mnt/user/photos/immich-library
DB_DATA_LOCATION=/mnt/user/appdata/immich/postgres
IMMICH_VERSION=release
DB_PASSWORD=ReplaceWithYourLongRandomPassword
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
TZ=Asia/Manila
```

```bash
cd /mnt/user/appdata/compose-projects/immich
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
nano .env
chmod 600 .env
```

Official guide: https://docs.immich.app/install/docker-compose

Keep the real `.env` on the server and out of Git.
