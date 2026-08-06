#!/usr/bin/env bash
# Create / update handbook user shares on Unraid 7.3.2 (docs/04-Storage.md).
# Run as root on the Unraid host with the array started.
#
# Usage:
#   DRY_RUN=1 bash create-shares.sh          # print what would happen
#   bash create-shares.sh                    # write missing .cfg + mkdir (skip existing .cfg)
#   FORCE=1 bash create-shares.sh            # overwrite existing .cfg (backs up first)
#
# After running: Main → Stop Array → Start Array, then verify on Shares tab.
# Does not delete share data. SMB user ACLs still come from chapter 15.
set -Eeuo pipefail

CFG_DIR="/boot/config/shares"
POOL="cache"
ARRAY_DISK="disk1"
FORCE="${FORCE:-0}"
DRY_RUN="${DRY_RUN:-0}"

need_array() {
  [[ -d "/mnt/${POOL}" ]] || {
    echo "ERROR: /mnt/${POOL} missing — is pool '${POOL}' online and array started?" >&2
    exit 1
  }
  [[ -d "/mnt/${ARRAY_DISK}" ]] || {
    echo "ERROR: /mnt/${ARRAY_DISK} missing — is Disk 1 assigned and array started?" >&2
    exit 1
  }
}

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
      exit 1
      ;;
  esac
}

write_cfg() {
  local name="$1" comment="$2" floor_h="$3" use="$4" export="$5" security="$6"
  local cfg="${CFG_DIR}/${name}.cfg"
  local floor include pool_line
  floor="$(floor_kb "$floor_h")"

  case "$use" in
    only)
      # Primary=cache, Secondary=None
      pool_line="shareCachePool=\"${POOL}\""
      include=""
      ;;
    yes)
      # Primary=cache, Secondary=Array, Mover=cache→array
      pool_line="shareCachePool=\"${POOL}\""
      include="${ARRAY_DISK}"
      ;;
    no)
      # Primary=Array, Secondary=None
      pool_line='shareCachePool=""'
      include="${ARRAY_DISK}"
      ;;
    *)
      echo "ERROR: bad useCache=$use" >&2
      exit 1
      ;;
  esac

  if [[ -f "$cfg" && "$FORCE" != "1" ]]; then
    echo "SKIP cfg (exists): $cfg  (FORCE=1 to overwrite)"
    return 0
  fi
  if [[ -f "$cfg" && "$FORCE" == "1" ]]; then
    cp -a "$cfg" "${cfg}.bak.$(date +%Y%m%d%H%M%S)"
    echo "BACKED UP $cfg"
  fi

  local body
  body=$(cat <<EOF
# Generated settings:
shareComment="${comment}"
shareInclude="${include}"
shareExclude=""
shareUseCache="${use}"
${pool_line}
shareCachePool2=""
shareCOW="auto"
shareAllocator="highwater"
shareSplitLevel=""
shareFloor="${floor}"
shareExport="${export}"
shareCaseSensitive="auto"
shareSecurity="${security}"
shareReadList=""
shareWriteList=""
shareVolsizelimit=""
shareExportNFS="-"
shareExportNFSFsid="0"
shareSecurityNFS="public"
shareHostListNFS=""
EOF
)

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "=== DRY_RUN would write $cfg ==="
    printf '%s\n' "$body"
    return 0
  fi
  mkdir -p "$CFG_DIR"
  printf '%s\n' "$body" >"$cfg"
  echo "WROTE $cfg  (UseCache=${use}, Floor=${floor_h}, Export=${export}, Security=${security})"
}

mkdir_primary() {
  local name="$1" use="$2" path
  case "$use" in
    only|yes) path="/mnt/${POOL}/${name}" ;;
    no) path="/mnt/${ARRAY_DISK}/${name}" ;;
  esac
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY_RUN mkdir -p $path"
    return 0
  fi
  mkdir -p "$path"
  echo "DIR  $path"
}

create_share() {
  local name="$1" comment="$2" floor_h="$3" use="$4" export="$5" security="$6"
  write_cfg "$name" "$comment" "$floor_h" "$use" "$export" "$security"
  mkdir_primary "$name" "$use"
}

need_array

echo "Creating handbook shares (FORCE=${FORCE}, DRY_RUN=${DRY_RUN})..."

# POOL-ONLY: Primary=cache, Secondary=None → shareUseCache=only
create_share "appdata" "Docker configs and databases" "20G" only "-" "private"
create_share "system" "Docker system data" "10G" only "-" "private"
create_share "domains" "Future VMs" "50G" only "-" "private"
create_share "database-backups-staging" "Temporary DB dumps before weekly backup" "10G" only "-" "private"

# CACHE→ARRAY: Primary=cache, Secondary=Array, Mover cache→array → yes
create_share "photos" "Immich photo library (cache → array)" "50G" yes "e" "private"

# ARRAY-ONLY: Primary=Array, Secondary=None → no
create_share "documents" "Personal documents" "20G" no "e" "private"
create_share "media" "Jellyfin media libraries" "100G" no "e" "private"
create_share "backups-incoming" "Incoming backups from PCs" "50G" no "e" "private"
create_share "downloads" "Browser / PC downloads and staging files" "50G" no "e" "private"
create_share "public" "Temporary transfer folder" "10G" no "e" "secure"

cat <<'EOF'

DONE writing cfgs + dirs.

NEXT (required):
  1) Main → Stop Array → Start Array
  2) Shares tab → confirm Primary / Secondary / Mover match docs/04-Storage.md
  3) photos must show Primary=cache, Secondary=Array, Mover=cache→array
  4) Named SMB users still come from chapter 15

Checks:
  ls -la /boot/config/shares/
  ls -la /mnt/user/
  cat /boot/config/shares/photos.cfg
EOF
