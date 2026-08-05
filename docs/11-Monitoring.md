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
- Docker image usage above 75% (**Settings → Docker** / notifications).
- Primary data share above 80% capacity.
- Backup older than eight days.

## Uptime Kuma

Uptime Kuma is useful for checking web endpoints such as Immich (`:2283`), Home Assistant (`:8123`), and Jellyfin (`:8096`). Store its appdata on GM7000 and include it in weekly backups.

## Grafana/Prometheus

Optional for Phase 2. Do not add them before core services and backups are stable.
