#!/bin/bash
# =============================================================================
# User Scripts → name: validate-shares  |  Schedule: Run manually
# Paste this ENTIRE file into Edit Script.
#
# For shares you created in the WebGUI (not create-shares.sh).
# Focuses on placement (Primary/Secondary/Mover). SMB export/floor/include
# mismatches are WARN by default — they are normal for GUI setup.
#
# MODE=strict  → old behavior (export/floor/include/security must match exactly)
# DUMP=1       → print each share .cfg
# CHECK_APPS=1 → Immich/compose paths
# =============================================================================
set -Eeuo pipefail

MODE="${MODE:-gui}" # gui | strict
DUMP="${DUMP:-0}"
CHECK_APPS="${CHECK_APPS:-0}"
CHECK_BACKUP_ENV="${CHECK_BACKUP_ENV:-0}"
POOL="${POOL:-cache}"
ARRAY_DISK="${ARRAY_DISK:-disk1}"
CFG_DIR="${CFG_DIR:-/boot/config/shares}"
BACKUP_SCRIPT_DIR="${BACKUP_SCRIPT_DIR:-/boot/config/custom/backup}"

# name|floor|useCache|export|security|optional(0|1)
# optional=1 → missing share is WARN, not FAIL (domains)
SHARES=(
  "appdata|20G|only|-|private|0"
  "system|10G|only|-|private|0"
  "domains|50G|only|-|private|1"
  "database-backups-staging|10G|only|-|private|0"
  "photos|50G|yes|e|private|0"
  "documents|20G|no|e|private|0"
  "media|100G|no|e|private|0"
  "backups-incoming|50G|no|e|private|0"
  "downloads|50G|no|e|private|0"
  "public|10G|no|e|secure|1"
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
    *) return 1 ;;
  esac
}

# GUI may store floor as SI-KB (20000000) or as bytes (20000000000) for 20G
floor_matches() {
  local expected_h="$1" actual="$2"
  local kb bytes
  kb="$(floor_kb "$expected_h")" || return 1
  bytes=$((kb * 1000))
  [[ -z "$actual" ]] && return 1
  [[ "$actual" == "$kb" || "$actual" == "$bytes" ]] && return 0
  # also accept binary GiB approximations (±5%)
  local gib=$(( ${expected_h%%[A-Za-z]*} * 1024 * 1024 ))
  local lo=$((gib * 95 / 100)) hi=$((gib * 105 / 100))
  [[ "$actual" -ge "$lo" && "$actual" -le "$hi" ]] 2>/dev/null && return 0
  local gib_b=$((gib * 1024))
  lo=$((gib_b * 95 / 100)); hi=$((gib_b * 105 / 100))
  [[ "$actual" -ge "$lo" && "$actual" -le "$hi" ]] 2>/dev/null && return 0
  return 1
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

use_label() {
  case "$1" in
    only) echo "Primary=cache Secondary=None" ;;
    yes) echo "Primary=cache Secondary=Array Mover=cache→array" ;;
    prefer) echo "Primary=cache Secondary=Array Mover=array→cache" ;;
    no) echo "Primary=Array Secondary=None" ;;
    *) echo "unknown($1)" ;;
  esac
}

soft_or_hard() {
  # soft_or_hard "message" expected actual
  local msg="$1" exp="$2" act="$3"
  if [[ "$act" == "$exp" ]]; then
    ok "$msg = ${act}"
  elif [[ "$MODE" == "strict" ]]; then
    bad "$msg expected='${exp}' actual='${act}'"
  else
    warn "$msg expected='${exp}' actual='${act}' (ok for GUI; MODE=strict to fail)"
  fi
}

dir_ok() {
  local p
  for p in "$@"; do
    [[ -d "$p" || -L "$p" ]] && return 0
  done
  return 1
}

need_array() {
  if [[ ! -d "/mnt/${POOL}" ]]; then
    bad "pool /mnt/${POOL} missing — is array started and pool named '${POOL}'?"
  else
    ok "pool /mnt/${POOL}"
  fi
  if [[ ! -d "/mnt/${ARRAY_DISK}" ]]; then
    bad "array /mnt/${ARRAY_DISK} missing — is Disk 1 assigned?"
  else
    ok "array /mnt/${ARRAY_DISK}"
  fi
}

validate_share() {
  local name="$1" floor_h="$2" use="$3" export="$4" security="$5" optional="$6"
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

  # --- critical: placement ---
  if [[ "$actual_use" == "$use" ]]; then
    ok "${name}.shareUseCache = ${actual_use} ($(use_label "$actual_use"))"
  else
    bad "${name}.shareUseCache expected='${use}' ($(use_label "$use")) actual='${actual_use}' ($(use_label "$actual_use")) — fix on Shares → ${name}"
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
      # pool value often ignored when UseCache=no
      ok "${name}.shareCachePool = '${actual_pool}' (ignored for Array-only)"
      ;;
  esac

  # include: GUI often leaves blank even for array shares — warn only in gui mode
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
        warn "${name}.shareInclude empty (GUI default = all array disks; fine with one disk)"
      else
        soft_or_hard "${name}.shareInclude" "$ARRAY_DISK" "$actual_include"
      fi
      ;;
  esac

  # floor: GUI units vary — never hard-fail in gui mode
  if floor_matches "$floor_h" "$actual_floor"; then
    ok "${name}.shareFloor ≈ ${floor_h} (raw=${actual_floor})"
  else
    warn "${name}.shareFloor handbook≈${floor_h} raw='${actual_floor}' (cosmetic; check Shares → Minimum free space)"
  fi

  # export / security: often still Export=No until chapter 15
  if [[ "$actual_export" == "$export" ]]; then
    ok "${name}.shareExport = ${actual_export}"
  else
    warn "${name}.shareExport expected='${export}' actual='${actual_export}' (Export No until SMB chapter is fine)"
  fi
  if [[ "$actual_sec" == "$security" ]]; then
    ok "${name}.shareSecurity = ${actual_sec}"
  else
    warn "${name}.shareSecurity expected='${security}' actual='${actual_sec}'"
  fi

  # dirs: accept user share + any real disk location (GUI may not mkdir on cache yet)
  local user_path="/mnt/user/${name}"
  local cache_path="/mnt/${POOL}/${name}"
  local disk_path="/mnt/${ARRAY_DISK}/${name}"

  if dir_ok "$user_path"; then
    ok "${name}: ${user_path}"
  else
    bad "${name}: missing ${user_path} (Stop/Start array?)"
  fi

  case "$use" in
    only)
      if dir_ok "$cache_path"; then
        ok "${name}: on pool ${cache_path}"
      else
        warn "${name}: ${cache_path} missing (share may still work via ${user_path})"
      fi
      ;;
    yes)
      if dir_ok "$cache_path" || dir_ok "$disk_path"; then
        ok "${name}: data on cache and/or ${ARRAY_DISK} (cache→array ok)"
      else
        warn "${name}: no dir yet on ${cache_path} or ${disk_path} (empty share is ok)"
      fi
      ;;
    no)
      if dir_ok "$disk_path"; then
        ok "${name}: on array ${disk_path}"
      else
        warn "${name}: ${disk_path} missing (empty share / only under ${user_path} is ok)"
      fi
      ;;
  esac
}

validate_backup_env() {
  echo ""
  echo "── backup.env (optional until chapter 10)"
  local env_file="${BACKUP_SCRIPT_DIR}/backup.env"
  if [[ ! -f "$env_file" ]]; then
    if [[ "$CHECK_BACKUP_ENV" == "1" ]]; then
      bad "backup.env missing at ${env_file}"
    else
      warn "backup.env not present yet (ok)"
    fi
    return
  fi
  ok "backup.env present"
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
    if [[ -e "$p" ]]; then
      ok "$p"
    else
      warn "missing $p"
    fi
  done
}

echo "Brian Home Server — validate shares (MODE=${MODE})"
echo "POOL=${POOL}  ARRAY_DISK=${ARRAY_DISK}"
echo "Critical checks: shareUseCache + pool + /mnt/user/<share>"
echo "GUI noise (export/floor/include): WARN only unless MODE=strict"
echo ""

need_array

for line in "${SHARES[@]}"; do
  IFS='|' read -r name floor_h use export security optional <<<"$line"
  validate_share "$name" "$floor_h" "$use" "$export" "$security" "$optional"
done

validate_backup_env
[[ "$CHECK_APPS" == "1" ]] && validate_apps

echo ""
echo "── summary"
echo "PASS=${PASS}  FAIL=${FAIL}  WARN=${WARN}"
echo ""
echo "What FAIL means: fix Primary/Secondary/Mover (or pool name) on Shares tab."
echo "What WARN means: usually fine for GUI (Export No, blank Include, different min-free)."
echo "Dump configs: add DUMP=1 at top, or run:  cat /boot/config/shares/photos.cfg"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "RESULT: FAILED — see FAIL lines above (placement)."
  exit 1
fi

echo "RESULT: OK — placement matches handbook (warnings are optional cleanup)."
exit 0
