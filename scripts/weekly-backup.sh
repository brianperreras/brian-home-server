#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/backup.env"
LOG_DIR="/boot/logs/home-server-backup"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-$(date +%F-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy backup.env.example and configure it." >&2
  exit 2
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

required=(BACKUP_MOUNT SNAPSHOT_ROOT SOURCE_PHOTOS SOURCE_DOCUMENTS SOURCE_APPDATA STAGING RETENTION_WEEKS)
for name in "${required[@]}"; do
  [[ -n "${!name:-}" ]] || { echo "Missing variable: $name" >&2; exit 2; }
done

# Optional media share for Jellyfin libraries
SOURCE_MEDIA="${SOURCE_MEDIA:-}"

if ! mountpoint -q "$BACKUP_MOUNT"; then
  echo "Backup disk is not mounted at $BACKUP_MOUNT" >&2
  echo "Mount it with Unassigned Devices or a pre-script, then retry." >&2
  exit 3
fi

DATE="$(date +%F)"
DEST="$SNAPSHOT_ROOT/$DATE"
LATEST_LINK="$SNAPSHOT_ROOT/latest"
mkdir -p "$DEST" "$STAGING"

echo "Backup started: $(date -Is)"
echo "Destination: $DEST"

# Database dumps should be created before this script or added here using the
# exact active container/service names. This script backs up the staging folder.

RSYNC_BASE=(rsync -aHAX --numeric-ids --delete-delay --info=stats2,progress2)
LINK_ARGS=()
if [[ -L "$LATEST_LINK" ]] && [[ -d "$(readlink -f "$LATEST_LINK")" ]]; then
  LINK_ARGS=(--link-dest="$(readlink -f "$LATEST_LINK")")
fi

backup_one() {
  local src="$1" name="$2"
  if [[ -d "$src" ]]; then
    mkdir -p "$DEST/$name"
    "${RSYNC_BASE[@]}" "${LINK_ARGS[@]}" "$src/" "$DEST/$name/"
  else
    echo "WARNING: source missing, skipped: $src"
  fi
}

backup_one "$SOURCE_PHOTOS" photos
backup_one "$SOURCE_DOCUMENTS" documents
if [[ -n "$SOURCE_MEDIA" ]]; then
  backup_one "$SOURCE_MEDIA" media
fi
backup_one "$SOURCE_APPDATA" appdata
backup_one "$STAGING" database-backups-staging

ln -sfn "$DEST" "$LATEST_LINK"

# Keep the newest N dated snapshots. This assumes YYYY-MM-DD directory names.
mapfile -t snapshots < <(find "$SNAPSHOT_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r)
if (( ${#snapshots[@]} > RETENTION_WEEKS )); then
  for old in "${snapshots[@]:RETENTION_WEEKS}"; do
    echo "Pruning old snapshot: $old"
    rm -rf --one-file-system "$SNAPSHOT_ROOT/$old"
  done
fi

sync
df -h "$BACKUP_MOUNT"
echo "Backup completed successfully: $(date -Is)"
echo "Unmount the disk through Unassigned Devices after this script returns."
