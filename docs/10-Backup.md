# 10 - Weekly Backup Plan

Do this **after** apps and SMB/cron (`15`) are in place. Steps match **Unraid 7.3.2**.

## Recovery objective

You accept about one week of risk on new data. The **Seagate Exos 6 TB** mounts only for backup, then unmounts and spins down.

## What must be backed up

- IronWolf data shares: photos, documents, media as desired.
- Immich PostgreSQL dump.
- Home Assistant configuration/backup.
- Jellyfin appdata (and media if not duplicated elsewhere).
- Docker appdata for critical applications.
- Compose files and secret configuration through an encrypted/private backup.
- Unraid boot-device configuration backup (**Main → Boot Device → Boot Device Backup**).

## Recommended tool

Use **restic** for encrypted, versioned, deduplicated backups, or `rsync --link-dest` for snapshot-style hard-link copies. A plain mirror alone can propagate accidental deletion.

The repository includes an rsync snapshot script because it is easy to audit. For off-site storage, prefer restic with encryption.

## Weekly sequence

```text
Schedule starts
  -> mount backup disk
  -> create DB dumps
  -> snapshot data/appdata
  -> verify command exit codes
  -> write log and notification
  -> prune old snapshots
  -> unmount backup disk
  -> disk becomes idle and spins down
```

## Unassigned Devices (Exos)

1. Confirm **Unassigned Devices** is installed (**Apps** / **Plugins**).
2. Attach the Exos. Do **not** add it under **Main → Array Devices**.
3. On **Main → Unassigned Devices**, configure/mount with:

| Field | Value |
|---|---|
| Device | Seagate Exos 6 TB (match serial) |
| Mount point / Mount name | `weekly_backup` → `/mnt/disks/weekly_backup` |
| File system | **xfs** (if formatting new) |
| Auto mount | **No** |
| Share (SMB) | **No** |
| Destructive mode | leave off unless you intentionally need format/wipe |

4. Open **Settings → Unassigned Devices** and keep boot auto-mount **off**.
5. After the backup script finishes, unmount from **Main → Unassigned Devices**.

## Install scripts and `backup.env`

1. Open the Unraid terminal (**>_**).
2. Copy scripts from this repository:

```bash
mkdir -p /boot/config/custom/backup
cp /path/to/Brian-HomeServer/scripts/*.sh /boot/config/custom/backup/
cp /path/to/Brian-HomeServer/scripts/backup.env.example /boot/config/custom/backup/backup.env
```

3. Edit `/boot/config/custom/backup/backup.env` and fill:

| Variable | Example value |
|---|---|
| `BACKUP_MOUNT` | `/mnt/disks/weekly_backup` |
| `SNAPSHOT_ROOT` | `/mnt/disks/weekly_backup/snapshots` |
| `SOURCE_PHOTOS` | `/mnt/user/photos` |
| `SOURCE_DOCUMENTS` | `/mnt/user/documents` |
| `SOURCE_MEDIA` | `/mnt/user/media` (optional; leave empty to skip) |
| `SOURCE_APPDATA` | `/mnt/user/appdata` |
| `STAGING` | `/mnt/user/database-backups-staging` |
| `RETENTION_WEEKS` | `8` |

4. Keep `backup.env` out of Git.

On Unraid **7.3.x**, boot-device files are not executable. Always run with:

```bash
bash /boot/config/custom/backup/weekly-backup.sh
```

## Schedule with User Scripts

1. Open **Settings → User Scripts**.
2. **Add New Script** (or edit the one from chapter `15`) and fill:

| Field | Value |
|---|---|
| Script name | `weekly-backup` |
| Schedule | **Custom** |
| Cron | `0 3 * * 0` (Sunday 03:00) |

3. Script body:

```bash
#!/bin/bash
bash /boot/config/custom/backup/weekly-backup.sh
```

4. Click **Apply**.
5. Optionally add separate scripts for pre-backup DB dumps and post-backup checks.

Do not schedule at the same time as Appdata Backup, SMART extended tests, mover, or major media scans.

## Deletion protection

The snapshot script creates dated directories. It does not immediately delete older versions when a source file disappears. Retention pruning should preserve several weekly versions.

## Verification

Every run must produce:

- Exit status.
- Start/end timestamps.
- Amount transferred.
- Backup destination free space.
- Failure notification (**Settings → Notifications** should already be configured from chapter `03`).

Monthly, restore several random files. Quarterly, restore an Immich database dump into a temporary environment.

## Additional off-site copy

Both internal disks remain in the same case. For irreplaceable photos, keep at least one off-site copy as well.

**Done with Phase 1 setup.** Later reference chapters: `08` Databases, `09` Network, `11` Monitoring, `12` Maintenance, `13` Future GPU.
