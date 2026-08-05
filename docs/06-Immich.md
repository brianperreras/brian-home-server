# 06 - Immich Installation and Setup

Do this **after** Storage (`04`) and Docker (`05`). Steps are for **Unraid OS 7.3.2** with **Compose Manager Plus**.

Immich changes quickly. Use the current official Docker Compose files from the latest Immich release.

Official guide: https://docs.immich.app/install/docker-compose

## Before you start

Confirm:

| Check | Where |
|---|---|
| Array started | **Main** |
| Shares `appdata`, `photos`, `database-backups-staging` | **Shares** |
| Docker enabled | **Settings → Docker** |
| Compose Manager Plus installed | **Plugins** / **Docker** tab shows a Compose section |
| Project folder parent exists | Terminal: `ls /mnt/user/appdata/compose-projects` |

If anything is missing, finish chapters `04` and `05` first.

## Layout for this server

```text
Mobile apps / browser
        |
   Immich server (:2283)
    /         \
PostgreSQL   Machine learning
   |               |
GM7000 SSD      GM7000 (cache)

Original photo/video library -> IronWolf (/mnt/user/photos/immich-library)
```

Project files live here:

`/mnt/user/appdata/compose-projects/immich/`

| File | Purpose |
|---|---|
| `docker-compose.yml` | Official Immich stack definition |
| `.env` | Paths and DB password (edit this on the server) |
| `hwaccel.transcoding.yml` | Optional Intel Quick Sync snippet |

---

## Step 1 — Open a terminal on Unraid

1. In the Unraid WebGUI, click the **>_** (Terminal) icon in the top-right.
2. Or SSH: `ssh root@brian-server` (or your reserved IP).

All `mkdir` / `wget` / `nano` commands below run in that terminal as root.

---

## Step 2 — Create directories

Paste:

```bash
mkdir -p /mnt/user/appdata/immich/postgres
mkdir -p /mnt/user/appdata/immich/model-cache
mkdir -p /mnt/user/photos/immich-library
mkdir -p /mnt/user/appdata/compose-projects/immich
mkdir -p /mnt/user/database-backups-staging
```

Confirm:

```bash
ls -la /mnt/user/appdata/compose-projects/immich
ls -la /mnt/user/photos/immich-library
```

Keep PostgreSQL on GM7000 (`appdata`). Do not put the database on the IronWolf or on SMB.

---

## Step 3 — Download official Immich files

In the terminal:

```bash
cd /mnt/user/appdata/compose-projects/immich

wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
```

If `wget` is missing, use:

```bash
curl -L -o docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
curl -L -o .env https://github.com/immich-app/immich/releases/latest/download/example.env
curl -L -o hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
```

Confirm the three files exist:

```bash
ls -la /mnt/user/appdata/compose-projects/immich
```

You should see `docker-compose.yml`, `.env`, and `hwaccel.transcoding.yml`.

Do **not** commit the real `.env` to Git. Treat `docker/immich/` in this repo only as a path guide.

---

## Step 4 — Configure `.env` (where and how)

**Where the file is:**

`/mnt/user/appdata/compose-projects/immich/.env`

You can edit it two ways. Pick one.

### Option A — Terminal (`nano`) — recommended first time

1. Open Unraid Terminal (**>_**).
2. Run:

```bash
cd /mnt/user/appdata/compose-projects/immich
nano .env
```

3. Find each variable below and set the value (arrow keys to move; edit the text after `=`).
4. Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.
5. Lock permissions:

```bash
chmod 600 .env
```

### Option B — Compose Manager Plus UI

1. First register the stack (Step 5 below) if you have not yet.
2. Open **Docker** → in the **Compose** section, open the **immich** stack editor (pencil / edit).
3. Open the **.ENV** (or **ENV**) tab.
4. Paste or edit the same values as in the table.
5. Click **Save** / **Save All**.

### Values to set for this build

Open `.env` and make sure these lines exist and match (other lines in the official example can stay unless Immich docs say otherwise):

| Variable | Set to | Why |
|---|---|---|
| `UPLOAD_LOCATION` | `/mnt/user/photos/immich-library` | Photo library on IronWolf |
| `DB_DATA_LOCATION` | `/mnt/user/appdata/immich/postgres` | Postgres on GM7000 / `cache` |
| `IMMICH_VERSION` | `release` | Track Immich stable releases |
| `DB_PASSWORD` | a long random password you create | Database password — store in your password manager |
| `DB_USERNAME` | `postgres` | Default Immich example |
| `DB_DATABASE_NAME` | `immich` | Default Immich example |
| `TZ` | your timezone, e.g. `Asia/Manila` | Only if the example `.env` includes `TZ=` |

Example (replace the password):

```dotenv
UPLOAD_LOCATION=/mnt/user/photos/immich-library
DB_DATA_LOCATION=/mnt/user/appdata/immich/postgres
IMMICH_VERSION=release
DB_PASSWORD=ReplaceWithYourLongRandomPassword
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
TZ=Asia/Manila
```

Notes:

- Prefer only `A-Za-z0-9` in `DB_PASSWORD` if the Immich example warns about special characters.
- Do not put spaces around `=`.
- If the official compose uses a model-cache volume, map that host path to `/mnt/user/appdata/immich/model-cache` (edit `docker-compose.yml` volume line if needed — see Immich docs for the current volume name).

Verify after saving:

```bash
grep -E 'UPLOAD_LOCATION|DB_DATA_LOCATION|DB_PASSWORD|IMMICH_VERSION' /mnt/user/appdata/compose-projects/immich/.env
```

---

## Step 5 — Add the stack in Compose Manager Plus

So the WebGUI manages this folder:

1. Open the **Docker** tab.
2. Scroll to the **Compose** section (Compose Manager Plus).
3. Click **Add New Stack** / **Add Stack**.
4. Fill:

| Field | Value |
|---|---|
| Stack name | `immich` |
| Description | `Immich photo stack` (optional) |
| Advanced → Indirect Path (or External / Project path) | `/mnt/user/appdata/compose-projects/immich` |

5. Click **Create** / **OK**.
6. If the editor opens:
   - **Compose** tab should already show `docker-compose.yml` contents (from the folder).
   - **.ENV** tab should show your `.env` (confirm Step 4 values).
   - **Settings** tab (optional): WebUI URL = `http://[IP]:2283` or `http://brian-server:2283`
7. **Save All** if you changed anything.

Path must be the **folder**, not the `docker-compose.yml` file itself.

---

## Step 6 — Start Immich

### From Compose Manager Plus (preferred)

1. **Docker** → Compose section → **immich**.
2. Open the stack menu (icon / right-click / context menu).
3. Choose **Compose Up** (or **Update** then Up if offered).
4. Wait for pull + start to finish (can take several minutes the first time).

### From terminal (same result)

```bash
cd /mnt/user/appdata/compose-projects/immich
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=200
```

### Open Immich

In a browser on your LAN:

`http://brian-server:2283`

or `http://YOUR-RESERVED-IP:2283`

Create the **first administrator account** immediately.

---

## Step 7 — Library placement

- Uploads go to IronWolf: `/mnt/user/photos/immich-library`
- Postgres stays on GM7000: `/mnt/user/appdata/immich/postgres`

Do not manually edit files inside the managed Immich library. Use Immich upload/import or supported external-library features.

---

## Step 8 — Intel hardware transcoding (optional, after Immich works)

1. Confirm GPU device on the host:

```bash
ls -l /dev/dri
```

2. Edit compose so `immich-server` can use Quick Sync.

**Either** keep `hwaccel.transcoding.yml` next to `docker-compose.yml` and, in `docker-compose.yml` under `immich-server`, uncomment the `extends` block and set service to `quicksync` (official Immich method),

**Or** (simpler on Unraid if multi-file compose is awkward) edit `docker-compose.yml` under `immich-server` and add:

```yaml
devices:
  - /dev/dri:/dev/dri
```

How to edit YAML:

- Terminal: `nano /mnt/user/appdata/compose-projects/immich/docker-compose.yml`
- Or Compose Manager Plus → **immich** → **Compose** tab → edit → **Save All**

3. Redeploy: Compose Manager Plus → **Compose Down**, then **Compose Up** (or `docker compose up -d` in that folder).
4. In Immich Admin UI, enable the Intel / Quick Sync option your version offers.

Official detail: https://docs.immich.app/features/hardware-transcoding

---

## Step 9 — Machine learning

Use CPU (or OpenVINO if your Immich release supports it) for face/search. First large import can take a long time. Run it when the server can stay on; watch CPU/NVMe temps.

---

## Step 10 — Mobile apps

1. Install the official Immich app: https://docs.immich.app/overview/quick-start
2. Server URL on LAN: `http://YOUR-RESERVED-IP:2283` (or `http://brian-server:2283` if DNS works on the phone)
3. Log in with the admin (or a user) account.
4. Enable backup for camera folders; keep phone on Wi‑Fi + power for the first sync.
5. Confirm files appear in Immich before deleting phone / Google Photos copies.

Remote later: chapter `09` (Tailscale). Do not port-forward `2283`.

---

## Step 11 — Backup notes

Back up both:

1. Media: `/mnt/user/photos/immich-library`
2. Database dump (albums, faces, users live here)

Before upgrades, in Terminal:

```bash
cd /mnt/user/appdata/compose-projects/immich
docker compose exec -T database pg_dumpall --clean --if-exists --username=postgres | gzip > /mnt/user/database-backups-staging/immich-$(date +%F).sql.gz
```

If that fails, check the database **service name** in your `docker-compose.yml` (may not be `database`) and adjust the command.

---

## Step 12 — Update procedure

1. Read https://github.com/immich-app/immich/releases
2. Dump the DB (Step 11) and note appdata backup.
3. Re-download official files into the project folder (Step 3), then re-apply your `.env` path/password values (do not lose `DB_PASSWORD`).
4. Compose Manager Plus → **Compose Up** / Update, or `docker compose pull && docker compose up -d`
5. Test upload, search, playback, mobile sync.

Never downgrade Immich casually after a DB migration.

**Next:** chapter `07` Home Assistant.
