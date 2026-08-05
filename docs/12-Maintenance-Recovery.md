# 12 - Maintenance and Recovery

## Weekly

- Confirm backup job succeeded (**Settings → User Scripts** history / logs).
- Review Unraid notifications (**Settings → Notifications** / bell icon).
- Check free space (**Dashboard** / **Shares**).
- Verify Immich mobile uploads are current.
- Spot-check Jellyfin playback if media was added.

## Monthly

- Run IronWolf extended SMART test (**Main → Disk 1**).
- Run backup-disk SMART test during its active window (**Main → Unassigned Devices**).
- Install selected application updates after reading release notes.
- Export/verify Unraid boot-device backup (**Main → Boot Device → Boot Device Backup**).
- Review Docker container logs for repeated errors (**Docker** tab).

## Quarterly

- Clean filters and fans.
- Inspect SATA and power cables.
- Restore random files from backup.
- Test a database restore.
- Review user accounts and remote access.

## Annual

- Inspect thermal paste/cooler mounting only if temperatures changed materially.
- Review storage growth and replacement plan.
- Review whether the backup disk is large enough.
- Run a planned shutdown/restart test.

## Primary HDD failure

1. Stop writes and shut down cleanly if the drive is failing.
2. Replace it with an equal or larger healthy disk.
3. Create a new filesystem/share layout.
4. Restore from the weekly backup.
5. Restore database dumps and appdata.
6. Verify applications before resuming mobile uploads.

There is no parity rebuild in this design.

## Unraid USB / boot-device failure

1. Prepare a replacement USB with current Unraid (7.3.2 or current stable).
2. Restore the boot-device configuration backup ZIP via the USB Creator **Use custom** option (or copy the backed-up `config` folder for a manual restore).
3. Transfer/replace the license using the official process when prompted about an invalid/missing registration key.
4. On **Main**, confirm disk assignments by serial number before starting the array.

## GM7000 failure

1. Replace or reformat the SSD pool device.
2. Recreate appdata/system shares.
3. Restore appdata and database dumps.
4. Recreate containers from templates/compose files.
5. Verify Immich database and library connection.

## Configuration documentation

After every major change, update this repository and `CHANGELOG.md`. Record:

- Hardware serial/model changes.
- Disk assignment and mount point.
- Container versions.
- Network address changes.
- Backup retention policy.
