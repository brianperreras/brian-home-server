# 05 - Docker on Unraid

Do this chapter **after** storage (`04`) and **before** Immich / Home Assistant / Jellyfin.

Goal: turn Docker on and install Compose support. Do **not** deploy apps in this chapter.

## Step 1 — Confirm storage is ready

Before enabling Docker:

- Array is started.
- SSD pool (`fast` / `cache`) is online.
- Share `appdata` exists on the SSD.

If those are missing, finish chapter `04` first.

## Step 2 — Enable Docker

In Unraid:

`Settings -> Docker -> Enable Docker: Yes`

Settings to use:

- Default appdata path: `/mnt/user/appdata`
- Store Docker data on the GM7000 pool
- Image file size about 30-40 GB if Unraid uses an image file (or directory mode if you prefer and it is available)

Apply and wait until Docker shows as running.

## Step 3 — Install Compose Manager

From Community Applications, install **Compose Manager** (or another maintained Compose plugin).

Create this folder for later projects:

```bash
mkdir -p /mnt/user/appdata/compose-projects
```

You will put each app under:

- `/mnt/user/appdata/compose-projects/immich`
- `/mnt/user/appdata/compose-projects/homeassistant`
- `/mnt/user/appdata/compose-projects/jellyfin`

## Step 4 — Verify Intel iGPU device (for later apps)

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

- [ ] Docker enabled
- [ ] Appdata on GM7000
- [ ] Compose Manager installed
- [ ] `/mnt/user/appdata/compose-projects` exists
- [ ] `/dev/dri` visible
- [ ] No Immich / HA / Jellyfin containers yet

**Next:** chapter `06` Immich.
