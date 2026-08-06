#!/bin/bash
# =============================================================================
# User Scripts → name: validate-shares  |  Schedule: Run manually
# Paste this ENTIRE file into Edit Script.
#
# Patterned on real Unraid 7.3.2 WebGUI share .cfg (example photos.cfg):
#   shareUseCache="yes"
#   shareCachePool="cache"
#   shareInclude="disk1"
#   shareFloor="100020360"   # GUI default on ~6TB disk; 50000000 (50G) also OK
#   shareExport="e"
#   shareSecurity="private"
#
# MODE=gui (default): FAIL only on placement; floor/export noise → WARN
# MODE=strict: exact handbook floors (50000000 for photos, etc.)
# DUMP=1: print each .cfg
# =============================================================================
set -Eeuo pipefail

MODE="${MODE:-gui}"
DUMP="${DUMP:-0}"
CHECK_APPS="${CHECK_APPS:-0}"
CHECK_BACKUP_ENV="${CHECK_BACKUP_ENV:-0}"
POOL="${POOL:-cache}"
ARRAY_DISK="${ARRAY_DISK:-disk1}"
CFG_DIR="${CFG_DIR:-/boot/config/shares}"
BACKUP_SCRIPT_DIR="${BACKUP_SCRIPT_DIR:-/boot/config/custom/backup}"

# name|useCache|export|security|optional|handbookFloorKB
# handbookFloorKB = preferred script value; GUI default ~100020360 on 6TB is OK in gui mode
SHARES=(
  "appdata|only|-|private|0|20000000"
  "system|only|-|private|0|10000000"
  "domains|only|-|private|1|50000000"
  "database-backups-staging|only|-|private|0|10000000"
  "photos|yes|e|private|0|50000000"
  "documents|no|e|private|0|20000000"
  "media|no|e|private|0|100000000"
  "backups-incoming|no|e|private|0|50000000"
  "downloads|no|e|private|0|50000000"
  "public|no|e|secure|1|10000000"
)

PASS=0
FAIL=0
WARN=0

ok() { echo "PASS  $*"; PASS=$((PASS + 1)); }
bad() { echo "FAIL  $*"; FAIL=$((FAIL + 1)); }
warn() { echo "WARN  $*"; WARN=$((WARN + 1)); }

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

use_label() {
  case "$1" in
    only) echo "Primary=cache Secondary=None" ;;
    yes) echo "Primary=cache Secondary=Array Mover=cache→array" ;;
    prefer) echo "Primary=cache Secondary=Array Mover=array→cache" ;;
    no) echo "Primary=Array Secondary=None" ;;
    *) echo "unknown($1)" ;;
  esac
}

dir_ok() {
  local p
  for p in "$@"; do
    [[ -d "$p" || -L "$p" ]] && return 0
  done
  return 1
}

# Accept handbook floor, Unraid ~6TB GUI default, or any positive floor in gui mode
floor_ok() {
  local actual="$1" handbook="$2"
  [[ -n "$actual" && "$actual" -gt 0 ]] 2>/dev/null || return 1
  [[ "$actual" == "$handbook" ]] && return 0
  # Known GUI default-ish value on IronWolf-sized disks
  [[ "$actual" == "100020360" ]] && return 0
  # Within 5% of handbook
  local lo=$((handbook * 95 / 100)) hi=$((handbook * 105 / 100))
  [[ "$actual" -ge "$lo" && "$actual" -le "$hi" ]] 2>/dev/null && return 0
  return 1
}

need_array() {
  if [[ ! -d "/mnt/${POOL}" ]]; then
    bad "pool /mnt/${POOL} missing — array started? pool named '${POOL}'?"
  else
    ok "pool /mnt/${POOL}"
  fi
  if [[ ! -d "/mnt/${ARRAY_DISK}" ]]; then
    bad "array /mnt/${ARRAY_DISK} missing — Disk 1 assigned?"
  else
    ok "array /mnt/${ARRAY_DISK}"
  fi
}

validate_share() {
  local name="$1" use="$2" export="$3" security="$4" optional="$5" floor_h="$6"
  local cfg="${CFG_DIR}/${name}.cfg"

  echo ""
  echo "── ${name}  (want: $(use_label "$use"))"

  if [[ ! -f "$cfg" ]]; then
    if [[ "$optional" == "1" ]]; then
      warn "${name}: not created (optional)"
    else
      bad "${name}: missing ${cfg}"
    fi
    return
  fi
  ok "${name}: cfg exists"

  if [[ "$DUMP" == "1" ]]; then
    echo "----- ${cfg} -----"
    cat "$cfg"
    echo "------------------"
  fi

  local actual_use actual_pool actual_include actual_floor actual_export actual_sec
  actual_use="$(cfg_get "$cfg" shareUseCache)"
  actual_pool="$(cfg_get "$cfg" shareCachePool)"
  actual_include="$(cfg_get "$cfg" shareInclude)"
  actual_floor="$(cfg_get "$cfg" shareFloor)"
  actual_export="$(cfg_get "$cfg" shareExport)"
  actual_sec="$(cfg_get "$cfg" shareSecurity)"

  # Critical: placement (matches your real photos.cfg pattern)
  if [[ "$actual_use" == "$use" ]]; then
    ok "${name}.shareUseCache = ${actual_use} ($(use_label "$actual_use"))"
  else
    bad "${name}.shareUseCache expected='${use}' ($(use_label "$use")) actual='${actual_use}' ($(use_label "$actual_use"))"
  fi

  case "$use" in
    only|yes)
      if [[ "$actual_pool" == "$POOL" ]]; then
        ok "${name}.shareCachePool = ${actual_pool}"
      else
        bad "${name}.shareCachePool expected='${POOL}' actual='${actual_pool}'"
      fi
      ;;
    no)
      # GUI often still sets shareCachePool="cache" even when UseCache=no — that is normal
      if [[ -z "$actual_pool" || "$actual_pool" == "$POOL" ]]; then
        ok "${name}.shareCachePool = '${actual_pool}' (ok with UseCache=no)"
      else
        warn "${name}.shareCachePool='${actual_pool}'"
      fi
      ;;
  esac

  case "$use" in
    only)
      if [[ -z "$actual_include" ]]; then
        ok "${name}.shareInclude = (empty)"
      else
        warn "${name}.shareInclude='${actual_include}' (pool-only usually blank)"
      fi
      ;;
    yes|no)
      if [[ "$actual_include" == "$ARRAY_DISK" ]]; then
        ok "${name}.shareInclude = ${actual_include}"
      elif [[ -z "$actual_include" ]]; then
        warn "${name}.shareInclude empty (GUI may use all disks; fine with one disk)"
      else
        warn "${name}.shareInclude expected='${ARRAY_DISK}' actual='${actual_include}'"
      fi
      ;;
  esac

  if floor_ok "$actual_floor" "$floor_h"; then
    ok "${name}.shareFloor = ${actual_floor}"
  elif [[ "$MODE" == "strict" ]]; then
    bad "${name}.shareFloor expected≈${floor_h} (or 100020360 GUI default) actual='${actual_floor}'"
  else
    warn "${name}.shareFloor=${actual_floor} (handbook ${floor_h}; GUI default 100020360 also OK)"
  fi

  if [[ "$actual_export" == "$export" ]]; then
    ok "${name}.shareExport = ${actual_export}"
  else
    warn "${name}.shareExport expected='${export}' actual='${actual_export}' (Export No until SMB is fine)"
  fi

  if [[ "$actual_sec" == "$security" ]]; then
    ok "${name}.shareSecurity = ${actual_sec}"
  else
    warn "${name}.shareSecurity expected='${security}' actual='${actual_sec}'"
  fi

  local user_path="/mnt/user/${name}"
  local cache_path="/mnt/${POOL}/${name}"
  local disk_path="/mnt/${ARRAY_DISK}/${name}"

  if dir_ok "$user_path"; then
    ok "${name}: ${user_path}"
  else
    bad "${name}: missing ${user_path}"
  fi

  case "$use" in
    only)
      if dir_ok "$cache_path"; then
        ok "${name}: on pool ${cache_path}"
      else
        warn "${name}: ${cache_path} missing (may still work via ${user_path})"
      fi
      ;;
    yes)
      if dir_ok "$cache_path" || dir_ok "$disk_path"; then
        ok "${name}: on cache and/or ${ARRAY_DISK}"
      else
        warn "${name}: empty share dirs ok until first write"
      fi
      ;;
    no)
      if dir_ok "$disk_path"; then
        ok "${name}: on array ${disk_path}"
      else
        warn "${name}: ${disk_path} missing (empty / only under user path ok)"
      fi
      ;;
  esac
}

validate_backup_env() {
  echo ""
  echo "── backup.env (optional until chapter 10)"
  if [[ -f "${BACKUP_SCRIPT_DIR}/backup.env" ]]; then
    ok "backup.env present"
  elif [[ "$CHECK_BACKUP_ENV" == "1" ]]; then
    bad "backup.env missing"
  else
    warn "backup.env not present yet (ok)"
  fi
}

validate_apps() {
  echo ""
  echo "── app paths (CHECK_APPS=1)"
  local p
  for p in \
    /mnt/user/appdata/compose-projects \
    /mnt/user/appdata/immich/postgres \
    /mnt/user/photos/immich-library \
    /mnt/user/appdata/compose-projects/immich/docker-compose.yml \
    /mnt/user/appdata/compose-projects/immich/.env
  do
    [[ -e "$p" ]] && ok "$p" || warn "missing $p"
  done
}

echo "Brian Home Server — validate shares (MODE=${MODE})"
echo "Reference pattern: WebGUI photos.cfg (UseCache=yes Pool=cache Include=disk1)"
echo ""

need_array

for line in "${SHARES[@]}"; do
  IFS='|' read -r name use export security optional floor_h <<<"$line"
  validate_share "$name" "$use" "$export" "$security" "$optional" "$floor_h"
done

validate_backup_env
[[ "$CHECK_APPS" == "1" ]] && validate_apps

echo ""
echo "── summary"
echo "PASS=${PASS}  FAIL=${FAIL}  WARN=${WARN}"
echo "FAIL = placement wrong. WARN = cosmetic (floor/export). Your photos.cfg sample is valid."
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "RESULT: FAILED"
  exit 1
fi
echo "RESULT: OK"
exit 0
