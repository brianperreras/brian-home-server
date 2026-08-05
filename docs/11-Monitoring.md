# 11 - Monitoring and Alerts

Start with Unraid's built-in dashboard and notifications. Add a large monitoring stack only when it solves a real need.

## Minimum monitoring

- CPU temperature and load.
- RAM usage.
- GM7000 temperature and SMART/NVMe health.
- IronWolf SMART attributes and temperature.
- Docker container health/restarts.
- Share free space.
- Backup success/failure.

## Recommended alerts

- HDD above 48 C warning; 52 C critical as an initial policy.
- NVMe sustained above 75 C warning.
- SMART pending/reallocated/uncorrectable sectors greater than zero.
- Filesystem read-only or I/O errors.
- Docker image usage above 75%.
- Primary data share above 80% capacity.
- Backup older than eight days.

## Uptime Kuma

Uptime Kuma is useful for checking web endpoints such as Immich (`:2283`), Home Assistant (`:8123`), and Jellyfin (`:8096`). Store its appdata on GM7000 and include it in weekly backups.

## Grafana/Prometheus

Optional for Phase 2. Do not add them before core services and backups are stable.
