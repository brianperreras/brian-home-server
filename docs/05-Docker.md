# 05 - Docker on Unraid

Do this chapter **after** storage (`04`) and **before** Immich / Home Assistant / Jellyfin. Steps match **Unraid OS 7.3.2**.

Goal: turn Docker on and install Compose support. Do **not** deploy apps in this chapter.

## Unraid 7.3.2 — why Docker settings look “missing”

On **Settings → Docker**:

1. Switch the page to **Advanced View** (top-right).
2. Set **Enable Docker** = **No** → click **Apply** and wait until Docker stops.
3. Path / size / data-root fields become editable only while Docker is **stopped**.
4. After you set values, set **Enable Docker** = **Yes** → **Apply**.

If Docker is already **Yes** and running, you will only see a short status page — that is normal in 7.3.2.

## Step 1 — Confirm storage is ready

Before enabling Docker, verify on the WebGUI:

1. **Main** → array is **Started**.
2. **Main** → SSD pool `cache` is online.
3. **Shares** → `appdata` exists with **Primary storage** = `cache`, **Secondary storage** = **None**.
4. **Shares** → `system` exists (same Primary = `cache`) — Docker image usually lives under this share.

If those are missing, finish chapter `04` first.

## Step 2 — Configure Docker (7.3.2 field names)

1. Open **Settings → Docker**.
2. Switch to **Advanced View**.
3. Set **Enable Docker** = **No** → **Apply**.
4. Fill the fields below (names as shown in 7.3.x). Leave any field not listed at Unraid default unless you know you need it.
5. Set **Enable Docker** = **Yes** → **Apply**.
6. Wait until Docker is running and the **Docker** tab appears in the top menu.

### Settings → Docker (recommended for this build)

| Field (7.3.2 label) | Value | Notes |
|---|---|---|
| Enable Docker | **Yes** (after paths are set) | Must be **No** first to edit paths |
| Docker vDisk location | `/mnt/user/system/docker/docker.img` | Path to the `.img` file. Default is fine if `system` is on `cache`. Avoid putting this on the IronWolf array |
| Docker vDisk size | `40G` | 30–40 GB is enough to start; increase later if the Docker image fills |
| Docker directory | *(hidden unless data-root = directory)* | Skip if using vDisk |
| Docker storage driver | leave default | Only matters for some directory/ZFS setups |
| Default appdata storage location | `/mnt/user/appdata/` | Trailing slash is fine |
| Docker LOG rotation | **Yes** | Advanced View |
| max file size | `50m` (or default) | Advanced View |
| max files | `1` (or default) | Advanced View |
| Docker PID Limit | leave default (`2048`) | Advanced View; Unraid 7+ |
| Host access to custom networks | leave default (**disabled** is fine for Phase 1) | Advanced View |
| Preserve user defined networks | **Yes** | Advanced View |

Click **Apply** after setting Enable Docker to **Yes**.

### What you should see afterward

| Check | Where |
|---|---|
| Docker tab in top nav | Top menu |
| No containers yet | **Docker** tab is empty / no stacks |
| Image on cache | `system` share Primary = `cache` so `/mnt/user/system/docker/docker.img` lands on the SSD |

## Step 3 — Install Compose Manager Plus

The original **Compose Manager** / **Docker Compose Manager** (dcflachs) is **deprecated**. Install **Compose Manager Plus** (mstrhakr) instead.

1. Open **Apps**.
2. Search for **Compose Manager Plus**.
3. Install the **stable** listing (not BETA), author **mstrhakr**.
4. Skip the old **Compose Manager** if it still appears in CA.
5. Confirm under **Plugins** that Compose Manager Plus is installed.
6. Open **Settings → Compose Manager Plus** (may appear as **Settings → Compose Manager** depending on plugin version) and set:

| Field | Value |
|---|---|
| Projects Folder | `/mnt/user/appdata/compose-projects` |

7. Click **Apply**.
8. In Terminal (**>_**):

```bash
mkdir -p /mnt/user/appdata/compose-projects
```

With Projects Folder set this way, each app is a **subfolder** under that path. When you later create `immich/` with a `docker-compose.yml` inside it, Compose Manager Plus shows an **`immich` stack on the Docker tab automatically**. Do **not** click **Add Stack** for Immich unless no stack appears after a page refresh.

| Path | App |
|---|---|
| `/mnt/user/appdata/compose-projects/immich` | Immich |
| `/mnt/user/appdata/compose-projects/homeassistant` | Home Assistant |
| `/mnt/user/appdata/compose-projects/jellyfin` | Jellyfin |
| `/mnt/user/appdata/compose-projects/cloudflared` | Cloudflare Tunnel ([09 Part D](09-Network-Security.md#part-d-cloudflare)) |

Manage stacks from **Docker** → Compose section. Support: https://forums.unraid.net/topic/197334-plugin-compose-manager-plus/

### How to edit compose / `.env` files

| Method | How |
|---|---|
| Unraid Terminal | **>_** → `nano /path/to/file` → **Ctrl+O** save, **Ctrl+X** exit |
| Compose Manager Plus | **Docker** → open the stack → **Compose** / **.ENV** tabs → **Save All** |

### Already had old Compose Manager?

1. **Apps** → **Compose Manager Plus** → **(Re)Install**.
2. Then set **Settings → Compose → Projects Folder** as above.

## Step 4 — Verify Intel iGPU device (for later apps)

```bash
ls -l /dev/dri
```

You should usually see `card0` and `renderD128` (names can vary). Immich and Jellyfin use this later for Quick Sync.

## Rules (remember for later chapters)

1. Map large data to host shares. Do not fill the container filesystem.
2. Prefer bridge networking and published ports unless an app needs host mode.
3. Update one app stack at a time after you have backups.
4. Back up `/mnt/user/appdata`, compose files, `.env` files, and DB dumps — not the Docker image itself.
5. Prefer official Compose for Immich over unofficial CA Immich templates.

## Done checklist

- [ ] **Settings → Docker** configured in Advanced View with Docker stopped, then re-enabled
- [ ] Docker vDisk under `/mnt/user/system/docker/docker.img` (on `cache`)
- [ ] Default appdata path `/mnt/user/appdata/`
- [ ] **Compose Manager Plus** installed via **Apps**
- [ ] `/mnt/user/appdata/compose-projects` exists
- [ ] `/dev/dri` visible
- [ ] No Immich / HA / Jellyfin containers yet

## Verify your setup

1. **Docker enabled and daemon responding** — open the Unraid terminal (>_) and run:

   ```bash
   docker info
   ```

   Expected result: output includes `Server Version:` and `Storage Driver:` with no connection error.

2. **Docker vDisk mounted on NVMe** — run:

   ```bash
   df -h | grep docker
   ```

   Expected result: a line referencing `/var/lib/docker` or `/mnt/user/system/docker/docker.img` shows space from the cache (NVMe) device.

3. **Compose Manager Plus active** — run:

   ```bash
   docker compose version
   ```

   Expected result: `Docker Compose version v2.x.x` (no error).

4. **Projects folder exists** — run:

   ```bash
   ls /mnt/user/appdata/compose-projects
   ```

   Expected result: directory is accessible (empty output is fine at this stage; subdirectories are added per app).

5. **iGPU devices present for Quick Sync** — run:

   ```bash
   ls -l /dev/dri
   ```

   Expected result: at least `card0` and `renderD128` listed.

**Next:** chapter `06` Immich.
