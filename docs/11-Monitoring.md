# 11 - Monitoring and Alerts

Start with Unraid's built-in dashboard and notifications (**Unraid 7.3.2**). Add a large monitoring stack only when it solves a real need.

## Minimum monitoring

Use **Dashboard** for live tiles, then wire alerts under **Settings → Notifications**.

- CPU temperature and load (**Dashboard**)
- RAM usage (**Dashboard**)
- GM7000 temperature and SMART/NVMe health (**Main** → click the pool disk)
- IronWolf SMART attributes and temperature (**Main** → **Disk 1**)
- Docker container health/restarts (**Docker** tab)
- Share free space (**Shares** / **Dashboard**)
- Backup success/failure (User Scripts log + notification agents)

## Configure alerts

1. Open **Settings → Notifications**.
2. Enable notification agents you use (browser, email, Discord, Telegram, etc.).
3. Send a test notification.
4. Tune thresholds under **Settings → Disk Settings** and per-disk SMART views on **Main**.

## Recommended alert policy

- HDD above 48 C warning; 52 C critical as an initial policy.
- NVMe sustained above 75 C warning.
- SMART pending/reallocated/uncorrectable sectors greater than zero.
- Filesystem read-only or I/O errors.
- Monitor Docker disk usage manually via **Settings → Docker** (check vDisk usage when Docker is stopped) or add a custom User Scripts alert. Unraid 7.3.2 has no native notification for Docker image disk utilization percentage.
- Primary data share above 80% capacity.
- Backup older than eight days.

## Uptime Kuma

Uptime Kuma is useful for checking web endpoints such as Immich (`:2283`), Home Assistant (`:8123`), and Jellyfin (`:8096`). Store its appdata on GM7000 and include it in weekly backups.

## Grafana/Prometheus

Optional for Phase 2. Do not add them before core services and backups are stable.

## Verify your setup

1. **Dashboard loads without errors** — open a browser on a LAN machine.
   Expected result: `http://192.168.0.10` → Dashboard tab shows CPU, RAM, and network tiles with live data; no red error banners.

2. **Disk temperatures visible** — Main tab → click each disk row.
   Expected result: IronWolf and GM7000 show a current temperature in °C; Exos shows a temperature when mounted.

3. **Docker container status visible** — Docker tab.
   Expected result: Immich (4 containers), Jellyfin, and Home Assistant all show green / running status.

4. **At least one User Script visible** — Settings → User Scripts.
   Expected result: the `weekly-backup` script (and any others added in chapter `15`) appears in the list with a schedule shown.
