#!/bin/bash
# Container entrypoint: link Unraid/appdata config, install crontab, run cron or a one-shot command.
set -euo pipefail

PARKING_ROOT="${PARKING_ROOT:-/app/parking}"
SSO_DIR="$PARKING_ROOT/resource-scheduler-sso-login"
SCHEDULER_DIR="$PARKING_ROOT/resource-scheduler"
CFG_DIR="${PARKING_CONFIG_DIR:-/data/config}"
export HOME="${HOME:-/data/home}"

# shellcheck source=/dev/null
source "$PARKING_ROOT/scripts/log.sh"

mkdir -p \
  "$HOME/.config/resource-scheduler" \
  "$SSO_DIR/output" \
  "$SSO_DIR/logs" \
  "$SCHEDULER_DIR/logs/responses" \
  "$CFG_DIR"

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
    log_warn "Seeded $dest from example — edit $CFG_DIR/$name (or this file) before relying on cron"
  fi
}

link_or_seed ".env" "$SSO_DIR/.env" "$SSO_DIR/.env.example"
link_or_seed "schedule.env" "$SCHEDULER_DIR/schedule.env" "$SCHEDULER_DIR/schedule.env.example"
link_or_seed "resources.txt" "$SCHEDULER_DIR/resources.txt" "$SCHEDULER_DIR/resources.txt.example"
link_or_seed "reservation.env" "$SCHEDULER_DIR/reservation.env" "$SCHEDULER_DIR/reservation.env.example"

# Optional markers so interactive install prompts are skipped when files exist
if [ -f "$SCHEDULER_DIR/resources.txt" ]; then
  touch "$SCHEDULER_DIR/.booking-configured"
fi
if [ -f "$SCHEDULER_DIR/reservation.env" ]; then
  touch "$SCHEDULER_DIR/.reservation-configured"
fi

# Prefer passphrase on the persistent home volume
if [ -f "$CFG_DIR/sso-passphrase" ] && [ ! -e "$HOME/.config/resource-scheduler/sso-passphrase" ]; then
  ln -sfn "$CFG_DIR/sso-passphrase" "$HOME/.config/resource-scheduler/sso-passphrase"
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
    # Ubuntu cron has no long-lived -f; start daemon and keep PID 1 alive.
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
