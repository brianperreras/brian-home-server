# 08 - PostgreSQL and MariaDB

## General rule

Use a dedicated database container per application when the application's official deployment expects it. Sharing one database server can save memory but couples maintenance and failure domains.

| Application | Database | Notes |
|---|---|---|
| Immich | PostgreSQL (official Immich image/version) | Required; follow Immich compose |
| Home Assistant Container | SQLite by default | No separate DB needed initially |
| Jellyfin | SQLite by default | Prefer built-in DB unless you have a specific reason to externalize |
| Future apps | MariaDB/MySQL only if the app requires it | Deploy per-app on GM7000 |

Immich should use the PostgreSQL version and extensions specified by the current official Immich compose release. Do not substitute a generic Postgres image casually.

## Storage

Database files belong on the GM7000:

- `/mnt/user/appdata/<application>/postgres`
- `/mnt/user/appdata/<application>/mariadb`

Do not place live database files on the IronWolf or on a network share unless you knowingly accept the latency and consistency trade-offs.

## Backup strategy

Database files should not be copied live as the only backup. Produce logical dumps:

PostgreSQL example (Immich compose project directory):

```bash
docker compose exec -T database pg_dumpall --clean --if-exists --username=postgres \
  | gzip > /mnt/user/database-backups-staging/immich-$(date +%F).sql.gz
```

MariaDB example:

```bash
docker compose exec -T mariadb mariadb-dump --single-transaction --routines --events APPDB \
  | gzip > /mnt/user/database-backups-staging/appdb-$(date +%F).sql.gz
```

Store dumps in `/mnt/user/database-backups-staging`, then include that directory in the weekly Exos backup.

## Retention

A reasonable starting policy:

- 7 daily database dumps.
- 8 weekly dumps.
- 12 monthly dumps for irreplaceable services.

Adjust to available storage and recovery requirements.

## Restore testing

A backup is not proven until restored. Quarterly, restore a dump into a temporary container/database and verify application-level data.
