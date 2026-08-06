#!/bin/bash
# =============================================================================
# User Scripts → Add New Script → name: validate-shares
# Schedule: Run manually
# Paste this ENTIRE file into Edit Script. No repo / no extra files needed.
# Run AFTER create-shares + Stop/Start array.
#
# Optional (edit before paste, or leave as-is):
#   CHECK_APPS=1        → also check Immich/compose paths
#   CHECK_BACKUP_ENV=1  → require /boot/config/custom/backup/backup.env
#   STRICT_FLOOR=0      → warn instead of fail on min-free mismatch
# =============================================================================
set -Eeuo pipefail

CHECK_APPS="${CHECK_APPS:-0}"
CHECK_BACKUP_ENV="${CHECK_BACKUP_ENV:-0}"
STRICT_FLOOR="${STRICT_FLOOR:-1}"
POOL="${POOL:-cache}"
ARRAY_DISK="${ARRAY_DISK:-disk1}"
CFG_DIR="${CFG_DIR:-/boot/config/shares}"
BACKUP_SCRIPT_DIR="${BACKUP_SCRIPT_DIR:-/boot/config/custom/backup}"

# name|comment|floor|useCache|export|security
SHARES=(
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

PASS=0
FAIL=0
WARN=0

ok() { echo "PASS  $*"; PASS=$((PASS + 1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL + 1)); }
warn() { echo "WARN  $*"; WARN=$((WARN + 1)); }

floor_kb() {
  local human="$1" num unit
  num="${human%%[A-Za-z]*}"
  unit="${human##*[0-9.]}"
  case "${unit^^}" in
    G|GB) echo $(( ${num%.*} * 1000 * 1000 )) ;;
    M|MB) echo $(( ${num%.*} * 1000 )) ;;
    T|TB) echo $(( ${num%.*} * 1000 * 1000 * 1000 )) ;;
    *) echo "ERROR: bad floor '$human'" >&2; return 1 ;;
  esac
}

primary_dir_for() {
  case "$2" in
    only|yes) echo "/mnt/${POOL}/$1" ;;
    no) echo "/mnt/${ARRAY_DISK}/$1" ;;
    *) return 1 ;;
  esac
}

cfg_get() {
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
    no) echo "Primary=Array Secondary=None" ;;
    *) echo "unknown($1)" ;;
  esac
}

expect_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    ok "$label = ${actual}"
  else
    bad "$label expected='${expected}' actual='${actual}'"
  fi
}

need_array() {
  if [[ ! -d "/mnt/${POOL}" ]]; then
    bad "pool mount /mnt/${POOL} missing"
    return 1
  fi
  ok "pool mount /mnt/${POOL}"
  if [[ ! -d "/mnt/${ARRAY_DISK}" ]]; then
    bad "array disk /mnt/${ARRAY_DISK} missing"
    return 1
  fi
  ok "array disk /mnt/${ARRAY_DISK}"
}

validate_share() {
  local name="$1" floor_h="$3" use="$4" export="$5" security="$6"
  local cfg="${CFG_DIR}/${name}.cfg"
  local floor primary user_path
  floor="$(floor_kb "$floor_h")"
  primary="$(primary_dir_for "$name" "$use")"
  user_path="/mnt/user/${name}"

  echo ""
  echo "── share: ${name}  ($(use_cache_label "$use"))"

  if [[ ! -f "$cfg" ]]; then
    bad "${name}: missing ${cfg}"
    return
  fi
  ok "${name}: cfg exists"
  expect_eq "${name}.shareUseCache" "$use" "$(cfg_get "$cfg" shareUseCache)"

  case "$use" in
    only|yes)
      expect_eq "${name}.shareCachePool" "$POOL" "$(cfg_get "$cfg" shareCachePool)"
      ;;
    no)
      local pool_val
      pool_val="$(cfg_get "$cfg" shareCachePool)"
      if [[ -z "$pool_val" ]]; then
        ok "${name}.shareCachePool = (empty)"
      else
        warn "${name}.shareCachePool='${pool_val}' with UseCache=no (confirm Shares tab shows Primary=Array)"
      fi
      ;;
  esac

  local include_val
  include_val="$(cfg_get "$cfg" shareInclude)"
  case "$use" in
    only)
      if [[ -z "$include_val" ]]; then
        ok "${name}.shareInclude = (empty)"
      else
        warn "${name}.shareInclude='${include_val}' (pool-only usually blank)"
      fi
      ;;
    yes|no)
      expect_eq "${name}.shareInclude" "$ARRAY_DISK" "$include_val"
      ;;
  esac

  local floor_val
  floor_val="$(cfg_get "$cfg" shareFloor)"
  if [[ "$floor_val" == "$floor" ]]; then
    ok "${name}.shareFloor = ${floor_h} (${floor})"
  elif [[ "$STRICT_FLOOR" == "1" ]]; then
    bad "${name}.shareFloor expected=${floor} (${floor_h}) actual=${floor_val}"
  else
    warn "${name}.shareFloor expected=${floor} (${floor_h}) actual=${floor_val}"
  fi

  expect_eq "${name}.shareExport" "$export" "$(cfg_get "$cfg" shareExport)"
  expect_eq "${name}.shareSecurity" "$security" "$(cfg_get "$cfg" shareSecurity)"

  if [[ -d "$primary" ]]; then
    ok "${name}: primary dir ${primary}"
  else
    bad "${name}: missing primary dir ${primary}"
  fi

  if [[ -d "$user_path" || -L "$user_path" ]]; then
    ok "${name}: user share ${user_path}"
  else
    bad "${name}: missing ${user_path} (Stop/Start array after create-shares?)"
  fi
}

validate_backup_env() {
  echo ""
  echo "── backup.env (optional until chapter 10)"
  local env_file="${BACKUP_SCRIPT_DIR}/backup.env"
  if [[ ! -f "$env_file" ]]; then
    if [[ "$CHECK_BACKUP_ENV" == "1" ]]; then
      bad "backup.env missing at ${env_file}"
    else
      warn "backup.env not present yet (ok until chapter 10)"
    fi
    return
  fi
  ok "backup.env present"
  # shellcheck disable=SC1090
  set +u
  # shellcheck disable=SC1091
  source "$env_file"
  set -u
  local name
  for name in BACKUP_MOUNT SNAPSHOT_ROOT SOURCE_PHOTOS SOURCE_DOCUMENTS SOURCE_APPDATA STAGING RETENTION_WEEKS; do
    if [[ -n "${!name:-}" ]]; then
      ok "backup.env ${name} set"
    else
      bad "backup.env missing/empty: ${name}"
    fi
  done
}

validate_apps() {
  echo ""
  echo "── optional app paths (CHECK_APPS=1)"
  local p
  for p in \
    /mnt/user/appdata/compose-projects \
    /mnt/user/appdata/immich/postgres \
    /mnt/user/photos/immich-library \
    /mnt/user/appdata/compose-projects/immich/docker-compose.yml \
    /mnt/user/appdata/compose-projects/immich/.env
  do
    if [[ -e "$p" ]]; then
      ok "app path ${p}"
    else
      warn "app path missing ${p} (ok if Immich not installed yet)"
    fi
  done
}

echo "Brian Home Server — validate shares"
echo "POOL=${POOL}  ARRAY_DISK=${ARRAY_DISK}"
echo ""

need_array || true

for line in "${SHARES[@]}"; do
  IFS='|' read -r name comment floor_h use export security <<<"$line"
  validate_share "$name" "$comment" "$floor_h" "$use" "$export" "$security"
done

validate_backup_env
[[ "$CHECK_APPS" == "1" ]] && validate_apps

echo ""
echo "── summary"
echo "PASS=${PASS}  FAIL=${FAIL}  WARN=${WARN}"

if [[ "$FAIL" -gt 0 ]]; then
  echo "RESULT: FAILED — re-run create-shares User Script, then Stop/Start array, then validate again"
  exit 1
fi

echo "RESULT: OK"
exit 0
