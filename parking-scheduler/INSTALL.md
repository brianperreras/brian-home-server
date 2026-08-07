# Parking automation — install guide

Use `install.sh` to set up **SSO login**, **automated booking**, and optional **cron schedules** for Asurion Resource Scheduler.

```bash
cd parking
./install.sh --schedules
```

---

## Prerequisites

| Requirement | Used for |
|-------------|----------|
| **Node.js 18+** and **npm** | SSO login (Playwright) |
| **Java 11+** and **javac** | Booking (`submit.asp`) |
| **Python 3** | Shell helper scripts |
| **AWS CLI** + credentials | SSM credential storage (unless using local password only) |
| **Java JARs** in `resource-scheduler/lib/` | OkHttp + okio + kotlin-stdlib (included in zip) |

Linux cron: your user must be allowed to use crontab (listed in `/etc/cron.allow` on restricted servers).

**Unraid OS 7.3.2:** use [UNRAID.md](UNRAID.md) first (Compose Manager Plus Docker path). Do not install Playwright on the Unraid host via User Scripts. This file is for a normal Linux install or the optional Ubuntu VM appendix in UNRAID.md.

---

## Quick start (interactive)

```bash
cd parking
./install.sh --schedules
```

You will be prompted for (first time only):

1. **Parking slots** — comma-separated try order, e.g. `R400, R405, R406` (full car-slot map in `resources.txt.example`)
2. **Reservation time window** — e.g. `6 AM` to `3 PM` (the slot times on the booked day)
3. **Passphrase** — encrypts credentials locally (saved to `~/.config/resource-scheduler/sso-passphrase`)
4. **SSO username**
5. **SSO password** — encrypted and uploaded to AWS SSM at `/credentials/<username>`

After install, approve **PingID** on your phone when SSO runs (9 PM cron or manual test).

---

## Options

```bash
./install.sh [options]
```

| Option | Description |
|--------|-------------|
| *(none)* | Full setup: deps + config prompts + SSM credentials |
| `--schedules` | Also install cron: **evening SSO** + keep-alive + **scheduled booking** |
| `--skip-credentials` | Skip passphrase / username / SSM upload (deps + slots/times only) |
| `--test-login` | Run `./run-manual-login.sh` after setup |
| `-h`, `--help` | Show help |

### Common combinations

```bash
# Full automated pipeline (recommended)
./install.sh --schedules

# Deps + config only (credentials already set up)
./install.sh --skip-credentials --schedules

# Setup + verify SSO works
./install.sh --test-login

# Non-interactive (CI / scripted setup)
RS_SLOTS=R502,R503,R504 \
RS_START_TIME="6 AM" \
RS_END_TIME="3 PM" \
./install.sh --skip-credentials --schedules
```

Legacy env still works: `RS_PRIMARY_SLOT` + optional `RS_BACKUP_SLOT` (merged into the slot list).

---

## What install creates

### Config files (per user)

| File | Purpose |
|------|---------|
| `resource-scheduler/resources.txt` | Slot try order (one booking; retry until secured) |
| `resource-scheduler/reservation.env` | Start/end time on booked day (`6+AM`, `3+PM`) |
| `resource-scheduler/schedule.env` | Days, `hh:mm:ss`, days-ahead, retry settings |
| `resource-scheduler-sso-login/.env` | SSO username, schedule times, topic ID |
| `resource-scheduler-sso-login/output/session.json` | Live session: token, cookies, **displayName** (from SSO) |
| `~/.config/resource-scheduler/sso-passphrase` | Local encryption key (never uploaded) |

**Booking name:** not a config file. After SSO login, `session.json` includes `displayName` for the logged-in user; booking sends that as `txtDesc` (`Last, First` → `First Last`). Each person’s SSO account books under their own name.

### Marker files (skip re-prompting)

| File | Meaning |
|------|---------|
| `resource-scheduler/.booking-configured` | Slots already set |
| `resource-scheduler/.reservation-configured` | Start/end times already set |

### Dependencies

- `resource-scheduler-sso-login/node_modules/` + Playwright Chromium
- `resource-scheduler/target/classes/` (compiled booking Java)

---

## Customize before or after install

Edit config files, then reinstall cron:

```bash
# When SSO runs (default 9:00 PM; evening before booking)
nano resource-scheduler-sso-login/.env
# SSO_SCHEDULE_HOUR=21
# SSO_SCHEDULE_MINUTE=0
# SSO_SCHEDULE_DAYS=2-4   # optional override; else RS_SCHEDULE_DAYS − 1
# KEEPALIVE_UNTIL_HOUR=0
# KEEPALIVE_UNTIL_MINUTE=5

# When booking runs (days + exact time)
nano resource-scheduler/schedule.env
# RS_SCHEDULE_DAYS=1-5
# RS_SCHEDULE_TIME=00:00:05
# RS_RESERVATION_DAYS_AHEAD=7
# BOOK_RETRY_TIMEOUT_SEC=180
# BOOK_RETRY_SLEEP_SEC=2

# Parking slot times on the booked day
nano resource-scheduler/reservation.env
# RS_START_HR=6+AM
# RS_END_HR=3+PM

# Apply cron changes
cd resource-scheduler && ./install-schedule.sh
# (or: cd parking && ./install.sh --schedules)
```

Cron fires at `HH:MM`; `run-scheduled.sh` waits until `:SS` before booking.

SSO DOW defaults to `RS_SCHEDULE_DAYS − 1` (e.g. booking `3-5` → SSO `2-4` at 9 PM). Set `SSO_SCHEDULE_DAYS` only to override.

Booking display name updates automatically on the next SSO login / keep-alive (no separate name config).

---

## After install

### Manual test (SSO + book)

```bash
cd resource-scheduler
./run-multiple.sh
```

### SSO only

```bash
cd resource-scheduler-sso-login
./run-manual-login.sh
```

Confirm the log shows `display name: ...` and that `output/session.json` has a `displayName` field.

### Scheduled booking only (uses evening session)

```bash
cd resource-scheduler
SKIP_SSO_LOGIN=1 ./run-scheduled.sh
```

### Check cron

```bash
crontab -l
```

Expected block (defaults: book Mon–Fri; SSO evening-before; book cron **1 minute early**):

```text
# >>> parking resource-scheduler (Asia/Manila)
CRON_TZ=Asia/Manila
0 21 * * 0-4  .../run-scheduled-login.sh    # SSO Sun–Thu (book Mon–Fri − 1)
59 23 * * 0-4 .../run-scheduled.sh          # prewarm then book at 00:00:00
# <<< parking resource-scheduler
```

Example for booking days `2-5` (Tue–Fri midnight):

```text
0 21 * * 1-4  .../run-scheduled-login.sh    # Mon–Thu 9 PM SSO
59 23 * * 1-4 .../run-scheduled.sh          # Mon–Thu 23:59 → submit Tue–Fri 00:00:00
```

`parking crontab` shows SSO as evening-before and Book as the **target** time (e.g. `Tue–Fri · midnight`) plus notes; use `PARKING_CRON_RAW=1 parking crontab` for raw lines.
---

## Reconfigure

### Change slots or reservation times

```bash
rm resource-scheduler/.booking-configured
rm resource-scheduler/.reservation-configured   # if changing times
cd parking
./install.sh --skip-credentials
```

Or edit `resources.txt` / `reservation.env` directly.

### Change SSO credentials

```bash
cd resource-scheduler-sso-login
./scripts/put-sso-credentials-to-ssm.sh
```

### Remove cron

```bash
cd parking
./uninstall-schedules.sh
```

Or from either project (same Linux crontab cleanup):

```bash
./resource-scheduler-sso-login/uninstall-schedule.sh
# or: ./scripts/uninstall-crontab.sh
```

---

## Per-user setup (shared server)

Each person should have:

- Their own **home directory** and copy of `parking/`
- Their own **`.env`**, `resources.txt`, `reservation.env`, `schedule.env`, cron
- Their own **SSM credentials** at `/credentials/<username>`
- Their own **`session.json`** (includes their `displayName` for booking)
- Their user listed in **`/etc/cron.allow`** (if the server restricts crontab)

Do **not** share `output/session.json` or passphrase files between users — that would book under the wrong name and reuse someone else’s session.

---

## Default nightly pipeline

| Time (Manila) | What |
|---------------|------|
| **9:00 PM** (booking − 1) | Full SSO login → `session.json` → keep-alive every 5 min until ~12:05 AM |
| **23:59** (1m early) | `run-scheduled.sh` starts: refresh session + compile Java, then wait |
| **00:00:00** | Submit booking immediately (`SKIP_SSO_LOGIN=1`, `SKIP_COMPILE=1`); retry slots until one books |

SSO DOW defaults to `RS_SCHEDULE_DAYS − 1` (evening before). `RS_SCHEDULE_TIME` is the **submit** target; `install-crontab.sh` also shifts the book cron 1 minute earlier (`BOOK_PREWARM_MINUTES`, default `1`) and adjusts DOW when that crosses midnight (e.g. book `2-5` @ `00:00` → SSO `1-4` @ `21:00`, book cron `1-4` @ `23:59`).

Override SSO days with `SSO_SCHEDULE_DAYS` if needed. Reservation date = run date + `RS_RESERVATION_DAYS_AHEAD` (default 7).
---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `You are not allowed to use crontab` | Ask admin to add your user to `/etc/cron.allow` |
| SSO cron fails, PingID timeout | Approve push on phone within ~2 min of 9 PM |
| Empty / buffered manual login logs | Scripts use `exec` + `tee` for live logs; re-run `parking login` and check `logs/manual-*.log` |
| `node not found` in cron | Ensure NVM/node is on PATH; scripts source `scripts/cron-env.sh` |
| Session expired at midnight | Keep-alive must run between 9 PM and booking; check `logs/keepalive-loop.log`. Prewarm also refreshes at 23:59 — if that fails, fix session before midnight. |
| Book cron shows 23:59 / wrong DOW | Expected: cron starts 1m early. `parking crontab` shows target days/time; raw line is the prewarm fire time. |
| All slots fail then timeout | Add more slots to `resources.txt` or raise `BOOK_RETRY_TIMEOUT_SEC` |
| Missing booking display name | Re-run `./run-manual-login.sh`; confirm `displayName` in `session.json` |
| Wrong name on reservation | Session is from another user — do not share `session.json`; re-login with your SSO |

---

## Help

```bash
./install.sh --help
```

More detail:

- `resource-scheduler/README.md` — booking scripts
- `resource-scheduler-sso-login/README.md` — SSO login
