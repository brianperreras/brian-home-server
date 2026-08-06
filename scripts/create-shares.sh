#!/usr/bin/env bash
# Create / update handbook user shares on Unraid 7.3.2 (docs/04-Storage.md).
# Intended path on server: /boot/config/custom/shares/create-shares.sh
# Call from User Scripts with: FORCE=1 bash /boot/config/custom/shares/create-shares.sh
# (Always use bash — /boot is not executable on Unraid 7.3.x.)
#
# Usage:
#   DRY_RUN=1 bash create-shares.sh          # print what would happen
#   bash create-shares.sh                    # write missing .cfg + mkdir (skip existing .cfg)
#   FORCE=1 bash create-shares.sh            # overwrite existing .cfg (backs up first)
#   bash validate-shares.sh                  # check configs/dirs after Stop/Start array
#
# After running: Main → Stop Array → Start Array, then run validate-shares User Script.
# Does not delete share data. SMB user ACLs still come from chapter 15.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/share-defs.sh"

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

write_cfg() {
  local name="$1" comment="$2" floor_h="$3" use="$4" export="$5" security="$6"
  local cfg="${CFG_DIR}/${name}.cfg"
  local floor include pool_line
  floor="$(floor_kb "$floor_h")"

  case "$use" in
    only)
      pool_line="shareCachePool=\"${POOL}\""
      include=""
      ;;
    yes)
      pool_line="shareCachePool=\"${POOL}\""
      include="${ARRAY_DISK}"
      ;;
    no)
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
  path="$(primary_dir_for "$name" "$use")"
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

for line in "${SHARE_EXPECTATIONS[@]}"; do
  IFS='|' read -r name comment floor_h use export security <<<"$line"
  create_share "$name" "$comment" "$floor_h" "$use" "$export" "$security"
done

cat <<'EOF'

DONE writing cfgs + dirs.

NEXT (required):
  1) Main → Stop Array → Start Array
  2) User Scripts → validate-shares → Run Script
     (or: bash /boot/config/custom/shares/validate-shares.sh)
  3) Shares tab: confirm photos = Primary=cache, Secondary=Array, Mover=cache→array
  4) Named SMB users still come from chapter 15
EOF
