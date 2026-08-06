#!/usr/bin/env bash
# Shared share expectations for Brian Home Server (docs/04-Storage.md).
# Sourced by create-shares.sh and validate-shares.sh — do not run directly.
#
# Each share line: name|comment|floor|useCache|export|security
# useCache: only = cache/None | yes = cache→array | no = Array/None
# export: - = No | e = Yes
# security: private | secure | public

POOL="${POOL:-cache}"
ARRAY_DISK="${ARRAY_DISK:-disk1}"
CFG_DIR="${CFG_DIR:-/boot/config/shares}"

# shellcheck disable=SC2034
SHARE_EXPECTATIONS=(
  "appdata|Docker configs and databases|20G|only|-|private"
  "system|Docker system data|10G|only|-|private"
  "domains|Future VMs|50G|only|-|private"
  "database-backups-staging|Temporary DB dumps before weekly backup|10G|only|-|private"
  "photos|Immich photo library (cache → array)|50G|yes|e|private"
  "documents|Personal documents|20G|no|e|private"
  "media|Jellyfin media libraries|100G|no|e|private"
  "backups-incoming|Incoming backups from PCs|50G|no|e|private"
  "downloads|Browser / PC downloads and staging files|50G|no|e|private"
  "public|Temporary transfer folder|10G|no|e|secure"
)

# Required beside validate/create (this scripts dir, e.g. /boot/config/custom/shares)
# shellcheck disable=SC2034
REQUIRED_SHARE_SCRIPTS=(
  create-shares.sh
  validate-shares.sh
)

# Optional backup scripts (default Unraid User Scripts install path)
# shellcheck disable=SC2034
BACKUP_SCRIPT_DIR="${BACKUP_SCRIPT_DIR:-/boot/config/custom/backup}"
# shellcheck disable=SC2034
OPTIONAL_BACKUP_SCRIPTS=(
  weekly-backup.sh
  pre-backup-db-dumps.sh
  post-backup-check.sh
  backup.env.example
)

# shareFloor is stored in KB (SI). 20G => 20000000
floor_kb() {
  local human="$1" num unit
  num="${human%%[A-Za-z]*}"
  unit="${human##*[0-9.]}"
  case "${unit^^}" in
    G|GB) echo $(( ${num%.*} * 1000 * 1000 )) ;;
    M|MB) echo $(( ${num%.*} * 1000 )) ;;
    T|TB) echo $(( ${num%.*} * 1000 * 1000 * 1000 )) ;;
    *)
      echo "ERROR: bad floor '$human'" >&2
      return 1
      ;;
  esac
}

primary_dir_for() {
  local name="$1" use="$2"
  case "$use" in
    only|yes) echo "/mnt/${POOL}/${name}" ;;
    no) echo "/mnt/${ARRAY_DISK}/${name}" ;;
    *)
      echo "ERROR: bad useCache=$use" >&2
      return 1
      ;;
  esac
}

cfg_get() {
  # cfg_get <file> <key>  → value without quotes
  local file="$1" key="$2" line val
  [[ -f "$file" ]] || return 1
  line="$(grep -E "^${key}=" "$file" | tail -n1 || true)"
  [[ -n "$line" ]] || { echo ""; return 0; }
  val="${line#*=}"
  val="${val%\"}"
  val="${val#\"}"
  printf '%s' "$val"
}

use_cache_label() {
  case "$1" in
    only) echo "Primary=cache Secondary=None" ;;
    yes) echo "Primary=cache Secondary=Array Mover=cache→array" ;;
    prefer) echo "Primary=cache Secondary=Array Mover=array→cache" ;;
    no) echo "Primary=Array Secondary=None" ;;
    *) echo "unknown($1)" ;;
  esac
}
