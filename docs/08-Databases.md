# 08 - PostgreSQL and MariaDB

## General rule

Use a dedicated database container per application when the application's official deployment expects it. Sharing one database server can save memory but couples maintenance and failure domains.

Immich should use the PostgreSQL version and extensions specified by the current official Immich compose release.

## Storage

Database files belong on the GM7000:

- `/mnt/user/appdata/<application>/postgres`
- `/mnt/user/appdata/<application>/mariadb`

Do not place live database files on the IronWolf or on a network share unless you knowingly accept the latency and consistency trade-offs.

## Backup strategy

Database files should not be copied live as the only backup. Produce logical dumps:

PostgreSQL example:

```bash
pg_dump -Fc -U APPUSER APPDB > appdb-$(date +%F).dump
```

MariaDB example:

```bash
mariadb-dump --single-transaction --routines --events APPDB | gzip > appdb-$(date +%F).sql.gz
```

Store dumps in `/mnt/user/database-backups-staging`, then include that directory in the weekly backup.

## Retention

A reasonable starting policy:

- 7 daily database dumps.
- 8 weekly dumps.
- 12 monthly dumps for irreplaceable services.

Adjust to available storage and recovery requirements.

## Restore testing

A backup is not proven until restored. Quarterly, restore a dump into a temporary container/database and verify application-level data.
