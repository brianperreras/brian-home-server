# 04 - Storage Layout

## Intended devices

| Device | Role | Availability |
|---|---|---|
| Acer Predator GM7000 | SSD pool for appdata, system, databases, metadata, cache | 24/7 |
| Seagate IronWolf 6 TB | Primary data disk | 24/7 |
| Future 6 TB backup HDD | Independent backup target | Once or twice weekly |

There is no parity disk by design. You accept up to approximately one week of new-data loss in exchange for an independent backup copy.

## Important Unraid behavior

A normal Unraid user share can span array disks and pools. For your design, keep application data explicitly on the SSD pool and bulk data on the IronWolf.

## 1. Create the SSD pool

Name the pool `fast` or `cache`.

Recommended filesystem:

- Single-drive pool: XFS is simple, or Btrfs/ZFS if you deliberately want their features.
- Do not choose a filesystem only because it is fashionable. A single drive is not redundant under any filesystem.

Suggested shares on SSD:

| Share | Primary storage | Secondary storage | Notes |
|---|---|---|---|
| appdata | fast | none | Docker persistent configuration |
| system | fast | none | Docker image and system data |
| domains | fast | none | Future VM disks |
| database-backups-staging | fast | IronWolf optional | Temporary DB dumps before weekly backup |

Set `appdata`, `system`, and `domains` to exclusive access when supported and when they reside only on the pool.

## 2. Configure the IronWolf array disk

Assign the IronWolf as data disk 1. Leave parity unassigned. Start the array and format the disk using XFS unless you have a specific reason to use another filesystem.

Suggested shares:

| Share | Purpose | Primary storage |
|---|---|---|
| photos | Immich originals/library | IronWolf |
| documents | Personal documents | IronWolf |
| media | Movies/music/video | IronWolf |
| backups-incoming | Backup files from computers | IronWolf |
| public | Optional shared transfer area | IronWolf |

## 3. Immich path split

Recommended:

- Originals/uploads: `/mnt/user/photos/immich-library` on IronWolf.
- PostgreSQL database: `/mnt/user/appdata/immich/postgres` on GM7000.
- Immich model cache and application data: `/mnt/user/appdata/immich/...` on GM7000.

Do not place PostgreSQL database files on an SMB/NFS share. The official Immich instructions explicitly state that network shares are unsupported for the database location.

## 4. Backup disk handling

Use the Unassigned Devices plugin so the backup drive is not part of the array and is not constantly mounted.

Suggested mount point:

`/mnt/disks/weekly_backup`

Workflow:

1. Mount the backup filesystem immediately before the job.
2. Run versioned/incremental backups.
3. Verify success and write logs.
4. Unmount cleanly.
5. Allow the drive to spin down.

Unmounting is stronger isolation than merely spinning down. It reduces accidental writes, though a physically connected disk is still not protection against every type of malware or electrical event.

## 5. Share security

- Set private shares to `Secure` or `Private`.
- Create named users; do not use root for SMB access.
- Give write access only where required.
- Disable guest write access.

## 6. SMART schedule

Primary IronWolf:

- Short test: weekly.
- Extended test: monthly.
- Temperature alerts: warning around 45-48 C, critical around 50-55 C according to your comfort and drive environment.

Backup drive:

- Short test before or after a weekly backup.
- Extended test monthly, during a planned window.

Track reallocated sectors, pending sectors, uncorrectable sectors, command timeouts, and UDMA CRC errors. CRC errors often indicate cabling rather than disk media.
