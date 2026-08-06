#!/bin/bash
# =============================================================================
# User Scripts → Add New Script → name: create-shares
# Schedule: Run manually
# Paste this ENTIRE file into Edit Script. No repo / no extra files needed.
# Array must be STARTED. After Run: Main → Stop Array → Start Array → run validate-shares.
#
# Optional env overrides (edit lines below or prefix when testing from terminal):
#   FORCE=0   → skip existing .cfg (default is FORCE=1 overwrite with .bak)
#   DRY_RUN=1 → print only
# =============================================================================
set -Eeuo pipefail

FORCE="${FORCE:-1}"
DRY_RUN="${DRY_RUN:-0}"
POOL="${POOL:-cache}"
ARRAY_DISK="${ARRAY_DISK:-disk1}"
CFG_DIR="${CFG_DIR:-/boot/config/shares}"

# name|comment|floor|useCache|export|security
# useCache: only=cache/None | yes=cache→array | no=Array/None
# export: - = No | e = Yes
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

floor_kb() {
  local human="$1" num unit
  num="${human%%[A-Za-z]*}"
  unit="${human##*[0-9.]}"
  case "${unit^^}" in
    G|GB) echo $(( ${num%.*} * 1000 * 1000 )) ;;
    M|MB) echo $(( ${num%.*} * 1000 )) ;;
    T|TB) echo $(( ${num%.*} * 1000 * 1000 * 1000 )) ;;
    *) echo "ERROR: bad floor '$human'" >&2; exit 1 ;;
  esac
}

need_array() {
  [[ -d "/mnt/${POOL}" ]] || { echo "ERROR: /mnt/${POOL} missing — start the array / check pool name '${POOL}'" >&2; exit 1; }
  [[ -d "/mnt/${ARRAY_DISK}" ]] || { echo "ERROR: /mnt/${ARRAY_DISK} missing — assign Disk 1 and start the array" >&2; exit 1; }
}

write_one() {
  local name="$1" comment="$2" floor_h="$3" use="$4" export="$5" security="$6"
  local cfg="${CFG_DIR}/${name}.cfg"
  local floor include pool_line primary
  floor="$(floor_kb "$floor_h")"

  case "$use" in
    only)
      pool_line="shareCachePool=\"${POOL}\""
      include=""
      primary="/mnt/${POOL}/${name}"
      ;;
    yes)
      pool_line="shareCachePool=\"${POOL}\""
      include="${ARRAY_DISK}"
      primary="/mnt/${POOL}/${name}"
      ;;
    no)
      pool_line='shareCachePool=""'
      include="${ARRAY_DISK}"
      primary="/mnt/${ARRAY_DISK}/${name}"
      ;;
    *) echo "ERROR: bad useCache=$use" >&2; exit 1 ;;
  esac

  if [[ -f "$cfg" && "$FORCE" != "1" ]]; then
    echo "SKIP cfg (exists): $cfg"
  else
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
      echo "=== DRY_RUN $cfg ==="
      printf '%s\n' "$body"
    else
      mkdir -p "$CFG_DIR"
      printf '%s\n' "$body" >"$cfg"
      echo "WROTE $cfg (UseCache=${use}, Floor=${floor_h}, Export=${export})"
    fi
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "DRY_RUN mkdir -p $primary"
  else
    mkdir -p "$primary"
    echo "DIR  $primary"
  fi
}

need_array
echo "Creating handbook shares (FORCE=${FORCE}, DRY_RUN=${DRY_RUN}, POOL=${POOL})..."

for line in "${SHARES[@]}"; do
  IFS='|' read -r name comment floor_h use export security <<<"$line"
  write_one "$name" "$comment" "$floor_h" "$use" "$export" "$security"
done

cat <<'EOF'

DONE.

NEXT:
  1) Main → Stop Array → Start Array
  2) User Scripts → validate-shares → Run Script
  3) Shares tab: photos = Primary cache, Secondary Array, Mover cache→array
EOF
