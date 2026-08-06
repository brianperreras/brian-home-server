#!/usr/bin/env bash
# Validate handbook shares + scripts/configs on Unraid 7.3.2 (docs/04-Storage.md).
# Intended path on server: /boot/config/custom/shares/validate-shares.sh
# Call from User Scripts with: bash /boot/config/custom/shares/validate-shares.sh
# (Always use bash — /boot is not executable on Unraid 7.3.x.)
#
# Usage:
#   bash validate-shares.sh
#   CHECK_APPS=1 bash validate-shares.sh     # also check Immich/compose paths if present
#   CHECK_BACKUP_ENV=1 bash validate-shares.sh  # require backup.env under custom/backup
#
# Exit 0 = all required checks passed; non-zero = failures.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/share-defs.sh"

CHECK_APPS="${CHECK_APPS:-0}"
CHECK_BACKUP_ENV="${CHECK_BACKUP_ENV:-0}"
STRICT_FLOOR="${STRICT_FLOOR:-1}" # 1 = floor must match exactly; 0 = only warn

PASS=0
FAIL=0
WARN=0

ok() { echo "PASS  $*"; PASS=$((PASS + 1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL + 1)); }
warn() { echo "WARN  $*"; WARN=$((WARN + 1)); }

need_array() {
  if [[ ! -d "/mnt/${POOL}" ]]; then
    bad "pool mount /mnt/${POOL} missing (array started? pool named '${POOL}'?)"
    return 1
  fi
  ok "pool mount /mnt/${POOL}"
  if [[ ! -d "/mnt/${ARRAY_DISK}" ]]; then
    bad "array disk /mnt/${ARRAY_DISK} missing (Disk 1 assigned? array started?)"
    return 1
  fi
  ok "array disk /mnt/${ARRAY_DISK}"
  return 0
}

expect_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    ok "$label = ${actual}"
  else
    bad "$label expected='${expected}' actual='${actual}'"
  fi
}

validate_share() {
  local name="$1" comment="$2" floor_h="$3" use="$4" export="$5" security="$6"
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
      if [[ -z "$pool_val" || "$pool_val" == "cache" ]]; then
        # empty is correct for array-only; some GUI saves leave pool name unused
        if [[ -z "$pool_val" ]]; then
          ok "${name}.shareCachePool = (empty)"
        else
          warn "${name}.shareCachePool='${pool_val}' with UseCache=no (ignored if Primary=Array in GUI — confirm Shares tab)"
        fi
      else
        warn "${name}.shareCachePool='${pool_val}' with UseCache=no"
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
    bad "${name}: missing ${user_path} (Stop/Start array after creating shares?)"
  fi
}

validate_handbook_scripts() {
  echo ""
  echo "── share scripts (User Scripts install: /boot/config/custom/shares)"
  local f
  for f in "${REQUIRED_SHARE_SCRIPTS[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${f}" ]]; then
      ok "script ${SCRIPT_DIR}/${f}"
    else
      bad "missing required script ${SCRIPT_DIR}/${f}"
    fi
  done

  if [[ -f "${SCRIPT_DIR}/lib/share-defs.sh" ]]; then
    ok "lib/share-defs.sh"
  else
    bad "missing ${SCRIPT_DIR}/lib/share-defs.sh"
  fi

  echo ""
  echo "── backup scripts (optional; ${BACKUP_SCRIPT_DIR})"
  if [[ ! -d "$BACKUP_SCRIPT_DIR" ]]; then
    warn "backup script dir missing ${BACKUP_SCRIPT_DIR} (ok until chapter 10 / User Scripts backup setup)"
    return
  fi
  ok "backup script dir ${BACKUP_SCRIPT_DIR}"
  for f in "${OPTIONAL_BACKUP_SCRIPTS[@]}"; do
    if [[ -f "${BACKUP_SCRIPT_DIR}/${f}" ]]; then
      ok "backup script ${f}"
    else
      warn "missing ${BACKUP_SCRIPT_DIR}/${f}"
    fi
  done
}

validate_backup_env() {
  echo ""
  echo "── backup.env"
  local env_file="${BACKUP_SCRIPT_DIR}/backup.env"
  local example="${BACKUP_SCRIPT_DIR}/backup.env.example"
  if [[ ! -f "$example" ]]; then
    # fall back to repo layout when running from a full scripts/ checkout
    if [[ -f "${SCRIPT_DIR}/backup.env.example" ]]; then
      example="${SCRIPT_DIR}/backup.env.example"
      env_file="${SCRIPT_DIR}/backup.env"
    fi
  fi
  if [[ ! -f "$example" ]]; then
    warn "backup.env.example not found (ok until chapter 10)"
  else
    ok "backup.env.example present (${example})"
  fi
  if [[ ! -f "$env_file" ]]; then
    if [[ "$CHECK_BACKUP_ENV" == "1" ]]; then
      bad "backup.env missing (copy from backup.env.example into ${BACKUP_SCRIPT_DIR})"
    else
      warn "backup.env not present yet (ok until chapter 10)"
    fi
    return
  fi
  ok "backup.env present (${env_file})"
  # shellcheck disable=SC1090
  set +u
  # shellcheck disable=SC1091
  source "$env_file"
  set -u
  local req name
  req=(BACKUP_MOUNT SNAPSHOT_ROOT SOURCE_PHOTOS SOURCE_DOCUMENTS SOURCE_APPDATA STAGING RETENTION_WEEKS)
  for name in "${req[@]}"; do
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
  local paths=(
    /mnt/user/appdata/compose-projects
    /mnt/user/appdata/immich/postgres
    /mnt/user/photos/immich-library
    /mnt/user/appdata/compose-projects/immich/docker-compose.yml
    /mnt/user/appdata/compose-projects/immich/.env
  )
  local p
  for p in "${paths[@]}"; do
    if [[ -e "$p" ]]; then
      ok "app path ${p}"
    else
      warn "app path missing ${p} (ok if Immich not installed yet)"
    fi
  done
}

echo "Brian Home Server — validate shares / scripts / configs"
echo "POOL=${POOL}  ARRAY_DISK=${ARRAY_DISK}  CFG_DIR=${CFG_DIR}"
echo ""

need_array || true

validate_handbook_scripts

local_line=""
for local_line in "${SHARE_EXPECTATIONS[@]}"; do
  IFS='|' read -r name comment floor_h use export security <<<"$local_line"
  validate_share "$name" "$comment" "$floor_h" "$use" "$export" "$security"
done

validate_backup_env

if [[ "$CHECK_APPS" == "1" ]]; then
  validate_apps
fi

echo ""
echo "── summary"
echo "PASS=${PASS}  FAIL=${FAIL}  WARN=${WARN}"

if [[ "$FAIL" -gt 0 ]]; then
  echo "RESULT: FAILED — fix shares with FORCE=1 bash create-shares.sh then Stop/Start array"
  exit 1
fi

echo "RESULT: OK"
exit 0
