#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_MOUNT="${1:-/mnt/disks/weekly_backup}"
if ! mountpoint -q "$BACKUP_MOUNT"; then
  echo "Backup disk not mounted: $BACKUP_MOUNT" >&2
  exit 1
fi

echo "Filesystem usage:"
df -h "$BACKUP_MOUNT"

echo "Latest snapshot:"
readlink -f "$BACKUP_MOUNT/snapshots/latest" || true

echo "Recent backup logs:"
ls -lt /boot/logs/home-server-backup 2>/dev/null | head -n 10 || true
