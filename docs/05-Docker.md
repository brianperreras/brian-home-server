# 05 - Docker on Unraid

Do this chapter **after** storage (`04`) and **before** Immich / Home Assistant / Jellyfin. Steps match **Unraid 7.3.2**.

Goal: turn Docker on and install Compose support. Do **not** deploy apps in this chapter.

## Step 1 — Confirm storage is ready

Before enabling Docker, verify on the WebGUI:

1. **Main** → array is **Started**.
2. **Main** → SSD pool `fast` is online.
3. **Shares** → `appdata` exists with **Primary storage** = `fast`, **Secondary storage** = **None**.

If those are missing, finish chapter `04` first.

## Step 2 — Enable Docker

1. Open **Settings → Docker**.
2. Stop Docker first if the page requires it before editing paths (**Enable Docker** → **No** → **Apply**), then fill and re-enable.
3. Fill:

| Field | Value |
|---|---|
| Enable Docker | **Yes** |
| Docker data-root / Docker vDisk location | On pool `fast` (path Unraid shows under the pool, often something like `/mnt/fast/system/docker/docker.img` or directory mode under the pool) |
| Docker vDisk size | `40G` (30–40 GB is fine to start) |
| Docker directory (if using directory mode instead of image) | On `fast` / under `system` — optional alternative to the vDisk file |
| Default appdata storage location | `/mnt/user/appdata` |
| Docker LOG rotation | **Yes** (recommended) |
| max file size / max files (if shown) | e.g. `50m` and `1` (or Unraid defaults) |
| Host access to custom networks | leave default unless you know you need it |
| Preserve user defined networks | **Yes** (useful later) |

Exact field labels vary slightly by Unraid build. The important values: Docker **on**, image/data on **`fast`**, appdata default **`/mnt/user/appdata`**.

4. Click **Apply**.
5. Wait until Docker status shows as running.
6. Confirm the top navigation shows a **Docker** tab.

## Step 3 — Install Compose Manager

1. Open **Apps**.
2. Search for **Compose Manager**.
3. Install it.
4. Confirm under **Plugins** that it is installed.
5. Open a terminal (**>_** in the top-right, or SSH as root) and create the projects folder:

```bash
mkdir -p /mnt/user/appdata/compose-projects
```

You will put each app under:

| Path | App |
|---|---|
| `/mnt/user/appdata/compose-projects/immich` | Immich |
| `/mnt/user/appdata/compose-projects/homeassistant` | Home Assistant |
| `/mnt/user/appdata/compose-projects/jellyfin` | Jellyfin |

Compose stacks are managed later from the Compose Manager UI (usually under **Docker** or via the plugin’s menu entry after install).

## Step 4 — Verify Intel iGPU device (for later apps)

In the Unraid terminal:

```bash
ls -l /dev/dri
```

You should usually see `card0` and `renderD128` (names can vary). Immich and Jellyfin will use this later for Quick Sync.

## Rules (remember for later chapters)

1. Map large data to host shares. Do not fill the container filesystem.
2. Prefer bridge networking and published ports unless an app needs host mode.
3. Update one app stack at a time after you have backups.
4. Back up `/mnt/user/appdata`, compose files, `.env` files, and DB dumps — not the Docker image itself.

## Done checklist

- [ ] **Settings → Docker** filled as above and enabled
- [ ] Docker data on GM7000 / `fast`
- [ ] Default appdata path `/mnt/user/appdata`
- [ ] Compose Manager installed via **Apps**
- [ ] `/mnt/user/appdata/compose-projects` exists
- [ ] `/dev/dri` visible
- [ ] No Immich / HA / Jellyfin containers yet

**Next:** chapter `06` Immich.
