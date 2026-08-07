#!/bin/bash
# Container entrypoint: materialize config from stack .env, install crontab, run cron.
set -euo pipefail

PARKING_ROOT="${PARKING_ROOT:-/app/parking}"
SSO_DIR="$PARKING_ROOT/resource-scheduler-sso-login"
SCHEDULER_DIR="$PARKING_ROOT/resource-scheduler"
CFG_DIR="${PARKING_CONFIG_DIR:-/data/config}"
export HOME="${HOME:-/data/home}"
export PARKING_LOCAL_CREDENTIALS_ONLY="${PARKING_LOCAL_CREDENTIALS_ONLY:-1}"

# shellcheck source=/dev/null
source "$PARKING_ROOT/scripts/log.sh"

mkdir -p \
  "$HOME" \
  "$SSO_DIR/output" \
  "$SSO_DIR/logs" \
  "$SCHEDULER_DIR/logs/responses" \
  "$CFG_DIR"

write_kv_file() {
  local dest="$1"
  shift
  local key value
  : >"$dest"
  for key in "$@"; do
    value="${!key-}"
    if [ -n "$value" ]; then
      # Quote so passwords with # / spaces survive `source`
      printf '%s=%q\n' "$key" "$value" >>"$dest"
    fi
  done
}

materialize_from_stack_env() {
  log_step "Materializing config from stack environment"

  if [ -z "${RS_USERNAME:-}" ] || [ -z "${RS_PASSWORD:-}" ]; then
    log_error "RS_USERNAME and RS_PASSWORD must be set in the stack .env"
    return 1
  fi

  write_kv_file "$CFG_DIR/.env" \
    RS_USERNAME RS_PASSWORD RS_ENTRY_URL RS_DOMAIN HEADED \
    SSO_MAX_ATTEMPTS SSO_RETRY_DELAY_MS SSO_POST_LOGIN_TIMEOUT_MS \
    SESSION_OUTPUT SSO_SCHEDULE_TZ SSO_SCHEDULE_HOUR SSO_SCHEDULE_MINUTE \
    SSO_SCHEDULE_DAYS RS_TOPIC_ID RS_SCHEDULE_URL

  write_kv_file "$CFG_DIR/schedule.env" \
    RS_SCHEDULE_TZ RS_SCHEDULE_DAYS RS_SCHEDULE_TIME BOOK_PREWARM_MINUTES \
    RS_RESERVATION_DAYS_AHEAD BOOK_RETRY_TIMEOUT_SEC BOOK_RETRY_SLEEP_SEC \
    MAX_SESSION_AGE_HOURS

  write_kv_file "$CFG_DIR/reservation.env" \
    RS_START_HR RS_END_HR RS_END_MIN

  local slots="${PARKING_SLOTS:-}"
  if [ -z "$slots" ]; then
    log_error "PARKING_SLOTS must be set in the stack .env (comma-separated, e.g. R405,R406)"
    return 1
  fi
  {
    echo "# Generated from PARKING_SLOTS in stack .env — edit the stack .env, not this file"
    echo "$slots" | tr ',;' '\n\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -E '^R[0-9]+' || true
  } >"$CFG_DIR/resources.txt"

  if ! grep -qE '^R[0-9]+' "$CFG_DIR/resources.txt"; then
    log_error "PARKING_SLOTS produced no valid slots (expected R405,R406,...)"
    return 1
  fi

  chmod 600 "$CFG_DIR/.env" 2>/dev/null || true
  log_ok "Wrote .env, schedule.env, reservation.env, resources.txt under $CFG_DIR"
}

link_or_seed() {
  local name="$1"
  local dest="$2"
  local example="${3:-}"
  local src="$CFG_DIR/$name"

  mkdir -p "$(dirname "$dest")"
  if [ -f "$src" ]; then
    ln -sfn "$src" "$dest"
    return 0
  fi
  if [ -n "$example" ] && [ -f "$example" ] && [ ! -e "$dest" ]; then
    cp "$example" "$dest"
    log_warn "Seeded $dest from example — prefer stack .env (PARKING_MANAGE_FROM_STACK_ENV=1)"
  fi
}

if [ "${PARKING_MANAGE_FROM_STACK_ENV:-1}" = "1" ]; then
  materialize_from_stack_env
fi

link_or_seed ".env" "$SSO_DIR/.env" "$SSO_DIR/.env.example"
link_or_seed "schedule.env" "$SCHEDULER_DIR/schedule.env" "$SCHEDULER_DIR/schedule.env.example"
link_or_seed "resources.txt" "$SCHEDULER_DIR/resources.txt" "$SCHEDULER_DIR/resources.txt.example"
link_or_seed "reservation.env" "$SCHEDULER_DIR/reservation.env" "$SCHEDULER_DIR/reservation.env.example"

if [ -f "$SCHEDULER_DIR/resources.txt" ]; then
  touch "$SCHEDULER_DIR/.booking-configured"
fi
if [ -f "$SCHEDULER_DIR/reservation.env" ]; then
  touch "$SCHEDULER_DIR/.reservation-configured"
fi

ensure_crontab() {
  if [ ! -f "$SSO_DIR/.env" ] || [ ! -f "$SCHEDULER_DIR/schedule.env" ]; then
    log_warn "Missing .env or schedule.env — skipping crontab install"
    return 0
  fi
  if [ "${PARKING_SKIP_CRONTAB:-0}" = "1" ]; then
    log_info "PARKING_SKIP_CRONTAB=1 — not installing crontab"
    return 0
  fi
  log_step "Installing parking crontab inside container"
  bash "$PARKING_ROOT/scripts/install-crontab.sh"
}

cmd="${1:-cron}"
shift || true

case "$cmd" in
  cron)
    ensure_crontab
    log_ok "Starting cron (TZ=${TZ:-Asia/Manila})"
    if command -v service >/dev/null 2>&1; then
      service cron start
    else
      cron
    fi
    log_info "Logs: $SSO_DIR/logs/ and $SCHEDULER_DIR/logs/ (bind-mounted)"
    exec sleep infinity
    ;;
  install-crontab|crontab-install)
    ensure_crontab
    ;;
  bash|sh)
    exec /bin/bash "$@"
    ;;
  parking)
    exec "$PARKING_ROOT/bin/parking" "$@"
    ;;
  *)
    exec "$cmd" "$@"
    ;;
esac
