#!/bin/bash
# =============================================================================
# User Scripts → name: validate-shares  |  Schedule: Run manually
# Paste ENTIRE file into Edit Script.
#
# GUI-friendly: one result line per share. FAIL only when placement is wrong.
# VERBOSE=1 → full field dump   DUMP=1 → print .cfg files
#
# Real Unraid 7.3.2 photos.cfg pattern (valid):
#   shareUseCache="yes"  shareCachePool="cache"  shareInclude="disk1"
# =============================================================================
set -Eeuo pipefail

VERBOSE="${VERBOSE:-0}"
DUMP="${DUMP:-0}"
CHECK_APPS="${CHECK_APPS:-0}"
POOL="${POOL:-cache}"
ARRAY_DISK="${ARRAY_DISK:-disk1}"
CFG_DIR="${CFG_DIR:-/boot/config/shares}"

# name|wantUseCache|optional
# want: only = stay on cache | yes = cache→array | no = array only
SHARES=(
  "appdata|only|0"
  "system|only|0"
  "domains|only|1"
  "database-backups-staging|only|0"
  "photos|yes|0"
  "documents|no|0"
  "media|no|0"
  "backups-incoming|no|0"
  "downloads|no|0"
  "public|no|1"
)

PASS=0
FAIL=0
WARN=0

ok() { [[ "$VERBOSE" == "1" ]] && echo "  PASS  $*"; }
bad() { echo "  FAIL  $*"; FAIL=$((FAIL + 1)); }
warn() { [[ "$VERBOSE" == "1" ]] && echo "  WARN  $*"; }

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

label() {
  case "$1" in
    only) echo "cache only (no mover)" ;;
    prefer) echo "prefer cache (mover array→cache)" ;;
    yes) echo "cache→array" ;;
    no) echo "array only" ;;
    *) echo "$1" ;;
  esac
}

# Return 0 if actual placement is acceptable for wanted mode
placement_ok() {
  local want="$1" actual="$2"
  case "$want" in
    only)
      # Handbook wants only. GUI often creates Prefer — still cache-primary, warn later.
      [[ "$actual" == "only" || "$actual" == "prefer" ]] && return 0
      return 1
      ;;
    yes)
      [[ "$actual" == "yes" ]] && return 0
      return 1
      ;;
    no)
      [[ "$actual" == "no" ]] && return 0
      return 1
      ;;
    *) return 1 ;;
  esac
}

echo "Brian Home Server — validate shares"
echo "Pool=${POOL}  Disk=${ARRAY_DISK}  (VERBOSE=1 for details)"
echo ""

# Mounts
if [[ ! -d "/mnt/${POOL}" ]]; then
  echo "FAIL  /mnt/${POOL} missing — start array / check pool name"
  FAIL=$((FAIL + 1))
else
  echo "OK    pool /mnt/${POOL}"
  PASS=$((PASS + 1))
fi
if [[ ! -d "/mnt/${ARRAY_DISK}" ]]; then
  echo "FAIL  /mnt/${ARRAY_DISK} missing — assign Disk 1"
  FAIL=$((FAIL + 1))
else
  echo "OK    disk /mnt/${ARRAY_DISK}"
  PASS=$((PASS + 1))
fi
echo ""

for line in "${SHARES[@]}"; do
  IFS='|' read -r name want optional <<<"$line"
  cfg="${CFG_DIR}/${name}.cfg"
  user_path="/mnt/user/${name}"

  if [[ ! -f "$cfg" ]]; then
    if [[ "$optional" == "1" ]]; then
      echo "SKIP  ${name} (optional, not created)"
      WARN=$((WARN + 1))
    else
      echo "FAIL  ${name} — missing ${cfg}"
      FAIL=$((FAIL + 1))
    fi
    continue
  fi

  if [[ "$DUMP" == "1" ]]; then
    echo "----- ${cfg} -----"
    cat "$cfg"
    echo "------------------"
  fi

  actual="$(cfg_get "$cfg" shareUseCache)"
  pool="$(cfg_get "$cfg" shareCachePool)"
  include="$(cfg_get "$cfg" shareInclude)"
  floor="$(cfg_get "$cfg" shareFloor)"
  export="$(cfg_get "$cfg" shareExport)"
  security="$(cfg_get "$cfg" shareSecurity)"

  issues=()
  notes=()

  if placement_ok "$want" "$actual"; then
    if [[ "$want" == "only" && "$actual" == "prefer" ]]; then
      notes+=("UseCache=prefer (OK-ish; change to Only so Docker never moves to HDD)")
      WARN=$((WARN + 1))
    fi
  else
    issues+=("UseCache='${actual}' ($(label "$actual")) want '$(label "$want")' — Shares → ${name} → Primary/Secondary/Mover")
  fi

  if [[ "$want" == "only" || "$want" == "yes" ]]; then
    if [[ "$pool" != "$POOL" ]]; then
      issues+=("shareCachePool='${pool}' want '${POOL}'")
    fi
  fi

  if [[ "$want" == "yes" && "$include" != "$ARRAY_DISK" && -n "$include" ]]; then
    notes+=("Include='${include}' (want disk1)")
    WARN=$((WARN + 1))
  fi

  if [[ ! -d "$user_path" && ! -L "$user_path" ]]; then
    issues+=("missing ${user_path}")
  fi

  if [[ "$VERBOSE" == "1" ]]; then
    echo "── ${name}"
    echo "  UseCache=${actual} Pool=${pool} Include=${include} Floor=${floor} Export=${export} Security=${security}"
    for n in "${notes[@]}"; do warn "$n"; done
    for i in "${issues[@]}"; do bad "$i"; done
  fi

  if [[ ${#issues[@]} -eq 0 ]]; then
    extra=""
    [[ ${#notes[@]} -gt 0 ]] && extra="  note: ${notes[*]}"
    echo "OK    ${name}  $(label "$actual")${extra}"
    PASS=$((PASS + 1))
  else
    echo "FAIL  ${name}  have=$(label "$actual") want=$(label "$want")"
    for i in "${issues[@]}"; do
      echo "        → $i"
    done
    FAIL=$((FAIL + 1))
  fi
done

if [[ "$CHECK_APPS" == "1" ]]; then
  echo ""
  for p in \
    /mnt/user/appdata/compose-projects \
    /mnt/user/photos/immich-library \
    /mnt/user/appdata/compose-projects/immich/docker-compose.yml
  do
    [[ -e "$p" ]] && echo "OK    $p" || echo "SKIP  $p (not installed yet)"
  done
fi

echo ""
echo "── summary: OK/PASS shares above | FAIL=${FAIL} | soft-notes=${WARN}"
echo ""
echo "Fix FAIL shares on the Shares tab:"
echo "  appdata/system/database-backups-staging → Primary=cache, Secondary=None (Use cache: Only)"
echo "  photos → Primary=cache, Secondary=Array, Mover=cache→array (Use cache: Yes)"
echo "  documents/media/downloads/... → Primary=Array, Secondary=None (Use cache: No)"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "RESULT: FAILED"
  exit 1
fi
echo "RESULT: OK"
exit 0
