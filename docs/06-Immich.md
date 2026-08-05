# 06 - Immich Installation and Setup

Do this **after** Storage (`04`) and Docker (`05`). **Unraid OS 7.3.2** + **Compose Manager Plus**.

Official Immich guide: https://docs.immich.app/install/docker-compose

## Before you start

| Check | Where |
|---|---|
| Array started | **Main** |
| Shares `appdata`, `photos`, `database-backups-staging` | **Shares** |
| Docker enabled | **Settings → Docker** |
| Compose Manager Plus installed | **Plugins** |
| Projects Folder | **Settings → Compose** = `/mnt/user/appdata/compose-projects` (set in chapter `05`) |

If Projects Folder is still the USB default, fix it in chapter `05` first so the `immich` stack appears automatically after you download files.

## Layout

```text
Browser / phone → Immich (:2283)
                    ├── PostgreSQL → GM7000 (/mnt/user/appdata/immich/postgres)
                    └── Uploads    → IronWolf (/mnt/user/photos/immich-library)
```

Compose project folder (also the Compose Manager Plus stack):

`/mnt/user/appdata/compose-projects/immich/`

---

## Step 1 — Terminal

WebGUI → top-right **>_** (or SSH as `root`).

---

## Step 2 — Create directories

```bash
mkdir -p /mnt/user/appdata/immich/postgres
mkdir -p /mnt/user/appdata/immich/model-cache
mkdir -p /mnt/user/photos/immich-library
mkdir -p /mnt/user/appdata/compose-projects/immich
mkdir -p /mnt/user/database-backups-staging
```

---

## Step 3 — Download official files

```bash
cd /mnt/user/appdata/compose-projects/immich

wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml

ls -la
```

(Use `curl -L -o …` instead of `wget -O …` if needed.)

You need these three files in that folder. Do not commit the real `.env` to Git.

**After this step:** open **Docker** → Compose section. You should see a stack named **`immich`** (Compose Manager Plus picks up the folder).  
**Do not click Add Stack** — that creates a duplicate like `immich-001`.

If no stack appears: refresh the Docker page. Still missing → confirm **Settings → Compose → Projects Folder** is `/mnt/user/appdata/compose-projects`, then refresh again.

If you already have **`immich` and `immich-001`**: keep one, delete the other (stack menu → Delete). Prefer the one tied to `/mnt/user/appdata/compose-projects/immich`.

---

## Step 4 — Edit `.env`

**File:** `/mnt/user/appdata/compose-projects/immich/.env`

```bash
cd /mnt/user/appdata/compose-projects/immich
nano .env
```

Replace the relevant lines so your `.env` includes at least this block (copy/paste, then change the password). Leave any other official Immich example lines that are not listed here unless Immich docs say to change them.

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

- Change `DB_PASSWORD` to your own password (prefer `A-Za-z0-9` only; save it in your password manager).
- Change `TZ` to your timezone if different.
- No spaces around `=`.

Save: **Ctrl+O**, Enter. Exit: **Ctrl+X**.

```bash
chmod 600 .env
grep -E 'UPLOAD_LOCATION|DB_DATA_LOCATION|DB_PASSWORD|IMMICH_VERSION|TZ' .env
```

Optional: **Docker** → open the **`immich`** stack → **.ENV** tab → paste the same block → **Save All**.

---

## Step 5 — Start Immich

1. **Docker** → Compose → **`immich`** (only one).
2. Stack menu → **Compose Up**.
3. Wait for the first image pull (several minutes).

Or:

```bash
cd /mnt/user/appdata/compose-projects/immich
docker compose pull
docker compose up -d
docker compose ps
docker compose logs --tail=200
```

Open `http://brian-server:2283` (or `http://YOUR-IP:2283`) and create the admin account.

---

## Step 6 — After it works

**Library:** uploads on IronWolf (`/mnt/user/photos/immich-library`); Postgres on GM7000. Do not hand-edit files inside the Immich library.

**Quick Sync (optional):**

```bash
ls -l /dev/dri
nano /mnt/user/appdata/compose-projects/immich/docker-compose.yml
```

Under `immich-server`, either enable official `extends` → `quicksync` with `hwaccel.transcoding.yml`, or add:

```yaml
devices:
  - /dev/dri:/dev/dri
```

Then Compose Down → Compose Up. Enable Intel/QSV in Immich Admin.  
Docs: https://docs.immich.app/features/hardware-transcoding

**Mobile:** install Immich app → server `http://YOUR-IP:2283` → enable backup on Wi‑Fi. Remote access: chapter `09` (Tailscale). Do not port-forward `2283`.

**Backup before upgrades** (both media + DB):

```bash
cd /mnt/user/appdata/compose-projects/immich
docker compose exec -T database pg_dumpall --clean --if-exists --username=postgres | gzip > /mnt/user/database-backups-staging/immich-$(date +%F).sql.gz
```

(Adjust service name if your compose file does not call it `database`.)

**Update:** read Immich release notes → dump DB → re-download official files into the same folder → re-apply `.env` paths/password → Compose Up. Never downgrade casually after a DB migration.

**Next:** chapter `07` Home Assistant.
