# 10 - Weekly Backup Plan

## Recovery objective

You accept the possible loss of up to approximately one week of new or changed data. The **Seagate Exos 6 TB** backup disk runs only once or twice per week and is otherwise unmounted/spun down via Unassigned Devices.

## What must be backed up

- IronWolf data shares: photos, documents, media as desired.
- Immich PostgreSQL dump.
- Home Assistant configuration/backup.
- Jellyfin appdata (and media if not duplicated elsewhere).
- Docker appdata for critical applications.
- Compose files and secret configuration through an encrypted/private backup.
- Unraid flash configuration backup.

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

## Unassigned Devices

Mount the Exos backup disk at:

`/mnt/disks/weekly_backup`

Do not configure automatic mount at boot unless you intentionally want the disk always mounted.

## Install scripts

Copy scripts from this repository to a persistent location, for example:

```bash
mkdir -p /boot/config/custom/backup
cp scripts/*.sh /boot/config/custom/backup/
chmod 700 /boot/config/custom/backup/*.sh
```

Edit variables in `backup.env.example`, save the real file as `backup.env`, and keep it out of Git.

## Schedule

Use the User Scripts plugin to run `weekly-backup.sh` every Sunday at a quiet time. Do not schedule it at exactly the same time as appdata backup, SMART extended tests, mover, or major media scans.

## Deletion protection

The snapshot script creates dated directories. It does not immediately delete older versions when a source file disappears. Retention pruning should preserve several weekly versions.

## Verification

Every run must produce:

- Exit status.
- Start/end timestamps.
- Amount transferred.
- Backup destination free space.
- Failure notification.

Monthly, restore several random files. Quarterly, restore an Immich database dump into a temporary environment.

## Additional off-site copy

Both internal disks remain in the same case. Fire, theft, surge, filesystem compromise, or operator error can affect both. For irreplaceable photos, keep at least one additional off-site copy: an external drive stored elsewhere or encrypted cloud/object storage.
