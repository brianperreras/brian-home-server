# 06 - Immich Installation and Setup

Immich changes quickly. Use the current official Docker Compose files from the latest Immich release rather than copying an old compose definition permanently.

## Architecture for this server

```text
Mobile apps / browser
        |
   Immich server
    /         \
PostgreSQL   Machine learning
   |               |
GM7000 SSD      GM7000 cache

Original photo/video library -> IronWolf 6 TB
```

## 1. Create directories

On Unraid terminal:

```bash
mkdir -p /mnt/user/appdata/immich/postgres
mkdir -p /mnt/user/appdata/immich/model-cache
mkdir -p /mnt/user/photos/immich-library
mkdir -p /mnt/user/appdata/compose-projects/immich
```

The PostgreSQL directory must be local storage, not SMB/NFS.

## 2. Obtain current official files

Follow the official guide: [Immich Docker Compose install](https://docs.immich.app/install/docker-compose)

From the compose project directory on the server, download the current release files (not files from the GitHub `main` branch):

```bash
cd /mnt/user/appdata/compose-projects/immich
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
```

Equivalent `curl` commands:

```bash
curl -L -o docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
curl -L -o .env https://github.com/immich-app/immich/releases/latest/download/example.env
```

Release notes: https://github.com/immich-app/immich/releases

Do not blindly reuse the repository's sample compose file after Immich changes its required services. Treat `docker/immich/` as a local configuration guide and diff it against the latest official release.

## 3. Configure `.env`

Create `.env` on the server, not in Git.

Suggested values:

```dotenv
UPLOAD_LOCATION=/mnt/user/photos/immich-library
DB_DATA_LOCATION=/mnt/user/appdata/immich/postgres
IMMICH_VERSION=release
DB_PASSWORD=REPLACE_WITH_A_LONG_RANDOM_PASSWORD
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
```

Use a password manager-generated database password. Restrict permissions:

```bash
chmod 600 .env
```

## 4. Start the stack

```bash
docker compose pull
docker compose up -d
```

Check:

```bash
docker compose ps
docker compose logs --tail=200
```

Open Immich using the server IP and configured port. Create the first administrator account immediately.

## 5. Library placement

Use the IronWolf for original uploads. Keep PostgreSQL, thumbnails, application metadata, and model cache on the GM7000 when the official compose variables allow it.

Do not manually modify files inside the managed Immich upload library. Use Immich import/upload features or supported external-library functions.

## 6. Intel hardware transcoding

Pass `/dev/dri` to the relevant Immich server container according to the current [Immich hardware-transcoding docs](https://docs.immich.app/features/hardware-transcoding). In Immich Administration, select the Intel/Quick Sync acceleration option supported by the installed version.

Test with a video upload while watching container logs and Intel GPU activity. Do not assume hardware acceleration works merely because the container starts.

## 7. Machine learning

Initially use CPU-based machine learning or Intel OpenVINO only if the current Immich release supports your desired configuration. The i5-14400 is capable of initial face recognition and search indexing, but the first large import can take time.

Schedule the initial import when the server can run uninterrupted. Monitor NVMe and CPU temperatures.

## 8. Mobile apps

- Install the official Immich mobile app ([quick start / app links](https://docs.immich.app/overview/quick-start)).
- Connect while on the local network first.
- Enable backup for selected camera folders.
- Keep the phone on power and Wi-Fi for the initial upload.
- Confirm server-side files and thumbnails before deleting anything from Google Photos or the phone.

## 9. Remote access

Use Tailscale first. Do not expose the Immich port directly to the public internet. A reverse proxy can be added later after backups, TLS, authentication, and update procedures are established.

## 10. Immich backup

Back up both:

1. Original media library.
2. PostgreSQL database dump.

A media-only copy is incomplete because albums, users, face data, and metadata are stored in the database.

Before major Immich upgrades:

```bash
docker compose exec -T database pg_dumpall --clean --if-exists --username=postgres | gzip > /mnt/user/database-backups-staging/immich-$(date +%F).sql.gz
```

The actual database service name and username may differ in current releases; confirm with the active compose file.

## 11. Update procedure

1. Read Immich [release notes](https://github.com/immich-app/immich/releases) and breaking changes.
2. Back up the database and appdata.
3. Re-download the current official compose and environment example from:
   - https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
   - https://github.com/immich-app/immich/releases/latest/download/example.env
4. Compare local changes.
5. Pull images and restart.
6. Review logs and test upload, search, playback, and mobile sync.

Never downgrade Immich casually after a database migration.
