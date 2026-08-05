# 06 - Immich Installation and Setup

Do this **after** Storage (`04`) and Docker (`05`).

Immich changes quickly. Use the current official Docker Compose files from the latest Immich release.

Official guide: https://docs.immich.app/install/docker-compose

## Before you start (stay in this chapter once ready)

Confirm these already exist on the server:

- Array started; IronWolf is Disk 1; GM7000 pool online
- Shares `appdata` and `photos` exist
- Docker is enabled
- **Compose Manager Plus** is installed (not the deprecated Compose Manager)
- `/mnt/user/appdata/compose-projects` exists

If any item is missing, finish chapters `04` and `05` first, then return here and continue step by step below.

## Layout for this server

```text
Mobile apps / browser
        |
   Immich server (:2283)
    /         \
PostgreSQL   Machine learning
   |               |
GM7000 SSD      GM7000 cache

Original photo/video library -> IronWolf (/mnt/user/photos/immich-library)
```

## Step 1 — Create directories

On Unraid terminal:

```bash
mkdir -p /mnt/user/appdata/immich/postgres
mkdir -p /mnt/user/appdata/immich/model-cache
mkdir -p /mnt/user/photos/immich-library
mkdir -p /mnt/user/appdata/compose-projects/immich
mkdir -p /mnt/user/database-backups-staging
```

Keep PostgreSQL on the GM7000 (`appdata`). Do not put the database on the IronWolf or on SMB/NFS.

## Step 2 — Obtain current official files

From the compose project directory on the server, download the current **release** files (not files from the GitHub `main` branch):

```bash
cd /mnt/user/appdata/compose-projects/immich
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
```

Equivalent `curl` commands:

```bash
curl -L -o docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
curl -L -o .env https://github.com/immich-app/immich/releases/latest/download/example.env
curl -L -o hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
```

Release notes: https://github.com/immich-app/immich/releases

Do not blindly reuse older sample compose files after Immich changes its required services. Treat `docker/immich/` in this repository as a path/env guide and diff it against the latest official release.

## Step 3 — Configure `.env`

Edit `.env` on the server, not in Git.

Suggested values for this hardware layout:

```dotenv
UPLOAD_LOCATION=/mnt/user/photos/immich-library
DB_DATA_LOCATION=/mnt/user/appdata/immich/postgres
IMMICH_VERSION=release
DB_PASSWORD=REPLACE_WITH_A_LONG_RANDOM_PASSWORD
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
```

Notes:

- Use only `A-Za-z0-9` in `DB_PASSWORD` if Immich's current example warns about special characters.
- Set `TZ=` to your timezone if the example file provides that variable.
- Restrict permissions: `chmod 600 .env`

If the official compose maps a machine-learning model cache volume, point that host path at `/mnt/user/appdata/immich/model-cache` on the GM7000.

## Step 4 — Start the stack

From terminal:

```bash
cd /mnt/user/appdata/compose-projects/immich
docker compose pull
docker compose up -d
```

Or use **Docker → Compose Manager Plus**: add/select the `immich` stack and **Compose Up**.

Check:

```bash
docker compose ps
docker compose logs --tail=200
```

Open Immich at:

`http://SERVER-IP:2283`

Create the first administrator account immediately.

## Step 5 — Library placement

Use the IronWolf for original uploads. Keep PostgreSQL, thumbnails, application metadata, and model cache on the GM7000 when the official compose variables/volumes allow it.

Do not manually modify files inside the managed Immich upload library. Use Immich import/upload features or supported external-library functions.

## Step 6 — Intel hardware transcoding

1. Ensure `hwaccel.transcoding.yml` is in the same directory as `docker-compose.yml` when your Compose tool supports multiple files.
2. In `docker-compose.yml` under `immich-server`, uncomment the `extends` section and set the service to `quicksync`.
3. **Unraid note:** If Compose Manager Plus cannot use multiple Compose files the way you expect, skip `extends` and inline devices on `immich-server`:

```yaml
devices:
  - /dev/dri:/dev/dri
```

4. Redeploy `immich-server`.
5. In Immich Administration, select the Intel/Quick Sync acceleration option supported by the installed version.

Official detail: [Immich hardware-transcoding](https://docs.immich.app/features/hardware-transcoding) (includes Unraid inline instructions).

Verify host devices:

```bash
ls -l /dev/dri
```

Test with a video upload while watching container logs and Intel GPU activity. Do not assume hardware acceleration works merely because the container starts.

## Step 7 — Machine learning

Initially use CPU-based machine learning or Intel OpenVINO only if the current Immich release supports your desired configuration. The i5-14400 is capable of initial face recognition and search indexing, but the first large import can take time.

Schedule the initial import when the server can run uninterrupted. Monitor NVMe and CPU temperatures.

## Step 8 — Mobile apps

- Install the official Immich mobile app ([quick start / app links](https://docs.immich.app/overview/quick-start)).
- Connect while on the local network first using `http://SERVER-IP:2283`.
- Enable backup for selected camera folders.
- Keep the phone on power and Wi-Fi for the initial upload.
- Confirm server-side files and thumbnails before deleting anything from Google Photos or the phone.

## Step 9 — Remote access

Use Tailscale first. Do not expose port 2283 to the public internet yet.

## Step 10 — Immich backup notes

Back up both:

1. Original media library (`/mnt/user/photos/immich-library`).
2. PostgreSQL database dump.

A media-only copy is incomplete because albums, users, face data, and metadata live in the database.

Before major Immich upgrades:

```bash
cd /mnt/user/appdata/compose-projects/immich
docker compose exec -T database pg_dumpall --clean --if-exists --username=postgres | gzip > /mnt/user/database-backups-staging/immich-$(date +%F).sql.gz
```

Confirm the database service name in your active compose file if this command fails.

## Step 11 — Update procedure

1. Read Immich release notes: https://github.com/immich-app/immich/releases
2. Back up the database and appdata.
3. Re-download official compose, `.env` example, and hwaccel file.
4. Compare local changes.
5. Pull images and restart.
6. Test upload, search, playback, and mobile sync.

Never downgrade Immich casually after a database migration.

**Next:** chapter `07` Home Assistant.
