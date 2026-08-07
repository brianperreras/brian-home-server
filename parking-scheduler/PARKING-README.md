# Parking automation

Books one Asurion Resource Scheduler parking slot for you: SSO login at night, keep the session alive, then book at the configured time (default midnight).

```
parking/
├── install.sh                      # first-time setup
├── uninstall-schedules.sh          # remove cron / LaunchAgents
├── AGENTS.md                       # guidance for Cursor agents
├── INSTALL.md                      # detailed install guide
├── UNRAID.md                       # Unraid VM + Docker deploy
├── Dockerfile / docker-compose.yml # Unraid-native container (see UNRAID.md)
├── scripts/pack-zip.sh             # rebuild ~/resource-scheduler-automation.zip
├── resource-scheduler/             # booking (Java)
└── resource-scheduler-sso-login/   # SSO + session keep-alive (Node/Playwright)
```

---

## First-time setup

```bash
cd parking
./install.sh --schedules
```

You will be asked for parking slots, reservation hours, and SSO credentials. Approve **PingID** on your phone when login runs.

Full install details: [INSTALL.md](INSTALL.md)

---

## Run from any directory

After `./install.sh` (or `./scripts/install-cli.sh`), use the `parking` command from anywhere:

```bash
parking help
parking book                      # try all slots until one books
parking book R405 R406            # override slot list
parking book-first                # first slot only
parking login                     # full SSO + keep-alive
parking refresh                   # keep-alive once
parking keepalive status          # overnight loop start|stop|status
parking scheduled-login           # evening SSO cron entrypoint
parking status                    # schedule, slots, session, cron
parking crontab                   # schedule in plain English (Tue–Fri at 9:00 PM)
parking install --schedules       # setup / reinstall cron
parking uninstall                 # remove cron
parking pack-zip                  # rebuild distributable zip
```

If `parking` is not found, open a new terminal or:

```bash
export PATH="$HOME/.local/bin:$PATH"
# or: ~/parking/scripts/install-cli.sh
```

### Book now (manual)

```bash
parking book
parking book --dry-run            # simulate fail → next slot → success (no submit)
parking dry-run                   # same as book --dry-run
parking book-first
RESERVATION_DATE=2026-7-11 parking book
```

**Dry-run** walks the same retry loop as cron/manual booking (try order, fail, next slot, round retry) but never calls SSO or `submit.asp`. Tune with:

```bash
BOOK_DRY_FAIL_COUNT=2 BOOK_DRY_SLEEP_SEC=0.3 parking dry-run
BOOK_DRY_SUCCESS_SLOT=R406 parking book --dry-run
```

Or from the project folder:

```bash
cd resource-scheduler
./run-multiple.sh
./run-manual.sh
```

These **refresh the SSO session** automatically before booking (no PingID if the session is still valid). Full SSO login runs only if refresh fails. Skip both with:

```bash
SKIP_SSO_LOGIN=1 parking book
```

### Refresh SSO only

```bash
parking login                     # approve PingID when prompted
parking refresh                   # token refresh only
```

### Hands-off (cron)

After `./install.sh --schedules`:

| Time (Manila) | What |
|---------------|------|
| **9:00 PM** | Full SSO login → keep-alive every 5 min (**evening before** booking days) |
| **23:59** | Prewarm: refresh session + compile Java (cron starts 1 minute early) |
| **00:00:00** | Submit booking from `resources.txt` (no second refresh/compile) |

SSO runs on `RS_SCHEDULE_DAYS − 1` (e.g. book Tue–Fri → SSO Mon–Thu at 9 PM). `RS_SCHEDULE_TIME` is when the booking is **submitted**. The book cron fires one minute earlier so refresh + `javac` finish before that second (midnight book Tue–Fri → cron Mon–Thu at 23:59).

Check:

```bash
parking crontab          # human: Book Tue–Fri · midnight (+ prewarm note)
PARKING_CRON_RAW=1 parking crontab   # raw early cron line
crontab -l
```

### Remove cron

```bash
cd parking
./uninstall-schedules.sh
```

Removes the parking cron block (SSO + booking) and stops a running keep-alive loop. Manual booking scripts still work afterward.

Same effect via either project:

```bash
./resource-scheduler-sso-login/uninstall-schedule.sh
# or
./scripts/uninstall-crontab.sh
```

---

## What to configure

| File | Purpose |
|------|---------|
| `resource-scheduler/resources.txt` | Slot try order (`R405  # P2-C18`; see `resources.txt.example`) |
| `resource-scheduler/reservation.env` | Start/end time on the booked day |
| `resource-scheduler/schedule.env` | Booking days + **submit** time (`RS_SCHEDULE_DAYS`, `RS_SCHEDULE_TIME`); cron prewarms 1m early |
| `resource-scheduler-sso-login/.env` | SSO user, 9 PM hour/minute |

SSO cron days are `RS_SCHEDULE_DAYS − 1` (e.g. book `3-5` → SSO `2-4` at 9 PM). After editing schedule files:

```bash
./install.sh --schedules
# or: cd resource-scheduler && ./install-schedule.sh
```

Reconfigure slots/times:

```bash
rm resource-scheduler/.booking-configured
rm resource-scheduler/.reservation-configured
./install.sh --skip-credentials
```

---

## How booking works

1. Tries each slot in `resources.txt` in order  
2. Sleeps between failures, then retries the list  
3. Stops on first success, or when the retry timeout is hit  

Reservation date defaults to **today + 7 days** (`RS_RESERVATION_DAYS_AHEAD`). The name on the reservation comes from your SSO `displayName` in `session.json`.

---

## Logs

Terminal output is classified with icons and color:

| Tag | Meaning |
|-----|---------|
| `ℹ INFO` | Progress / details |
| `▸ STEP` | Action starting |
| `✔ OK` / `SUCCESS` | Completed successfully |
| `⚠ WARN` | Non-fatal problem (e.g. slot failed, retrying) |
| `✖ ERROR` | Failure |

Disable color with `NO_COLOR=1` or `PARKING_LOG_COLOR=0`. Log files strip ANSI codes automatically.

| Where | What |
|-------|------|
| `resource-scheduler/logs/run-*.log` | Manual booking runs |
| `resource-scheduler/logs/scheduled*.log` | Cron booking |
| `resource-scheduler/logs/responses/*-last.html` | Last booking HTML response |
| `resource-scheduler-sso-login/logs/` | SSO + keep-alive |

---

## More detail

- [AGENTS.md](AGENTS.md) — conventions for Cursor agents  
- [INSTALL.md](INSTALL.md) — install, cron, troubleshooting  
- [UNRAID.md](UNRAID.md) — Unraid Ubuntu VM **or** Docker (appdata + cron in container)  
- [resource-scheduler/README.md](resource-scheduler/README.md) — booking scripts  
- [resource-scheduler-sso-login/README.md](resource-scheduler-sso-login/README.md) — SSO login  

### Rebuild distributable zip

```bash
./scripts/pack-zip.sh
```

Writes `~/resource-scheduler-automation.zip` (secrets and runtime dirs excluded).
