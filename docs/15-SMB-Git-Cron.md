# 15 - SMB, Git, and Cron on Unraid

Do this **after** Jellyfin (`14`). Shares already exist from Storage (`04`); this chapter adds users, SMB access, and schedules. Steps match **Unraid 7.3.2**.

## Step 1 — Enable SMB

1. Open **Settings → SMB**.
2. Fill:

| Field | Value |
|---|---|
| Enable SMB | **Yes** |
| Hide “dot” files | optional (**No** is fine) |
| Enhanced macOS interoperability | **Yes** (recommended for Mac clients) |
| Enable NetBIOS | optional; often **No** on modern LANs |
| Enable WSD | **Yes** (helps Windows discovery) if shown |
| Workgroup | `WORKGROUP` (or your home workgroup name) |

3. Click **Apply**.

4. Optional check — **Settings → Identification**:

| Field | Value |
|---|---|
| Server name | `brian-server` |

This is what macOS shows in Finder / `smb://brian-server`.

## Step 2 — Create SMB users

Do not use `root` for day-to-day SMB. Root is for the WebGUI / SSH only.

1. Open **Users**.
2. Under **Shares Access**, click **Add User**.
3. Fill:

| Field | Value (example) |
|---|---|
| User name | `brian` |
| Description | `Brian SMB` |
| Password | strong unique password (password manager) |
| Retype password | same |

4. Click **Add**.
5. Click the new user name to edit share access.
6. Set each share:

| Share | Access for `brian` |
|---|---|
| `photos` | **Read/Write** (or **None** if Immich-only; admin often keeps R/W) |
| `documents` | **Read/Write** |
| `media` | **Read/Write** |
| `backups-incoming` | **Read/Write** |
| `public` | **Read/Write** (if you created it) |
| `appdata` | **None** |
| `system` | **None** |
| `domains` | **None** |
| `database-backups-staging` | **None** |

7. Click **Apply**.
8. Repeat for household accounts with tighter access, for example:

| Share | Household user |
|---|---|
| `documents` | **Read/Write** or **Read-only** |
| `media` | **Read-only** |
| `photos` | **None** or **Read-only** |
| everything else | **None** unless needed |

## Step 3 — Per-share SMB export

For each share, open **Shares → [share name] → SMB Security Settings** and fill:

### Private data shares

| Share | Export | Security | Case-sensitive | Guest / anonymous |
|---|---|---|---|---|
| `photos` | **Yes** | **Private** | Auto / default | No guest |
| `documents` | **Yes** | **Private** | Auto / default | No guest |
| `media` | **Yes** | **Private** | Auto / default | No guest |
| `backups-incoming` | **Yes** | **Private** | Auto / default | No guest |

User read/write checkboxes on the share page should match Step 2. Click **Apply**.

### Optional public transfer share

| Field | Value |
|---|---|
| Share | `public` |
| Export | **Yes** |
| Security | **Secure** (guests read-only if offered) or **Private** |
| Guest write | **No** |

### Do not export over SMB

| Share | Export |
|---|---|
| `appdata` | **No** |
| `system` | **No** |
| `domains` | **No** |
| `database-backups-staging` | **No** |

## Step 4 — Connect from another computer (local)

### macOS

1. Finder → **Go → Connect to Server…** (⌘K).
2. Server address: `smb://brian-server` (or `smb://` + reserved IP).
3. Connect As: **Registered User**.
4. Name: `brian` (SMB user, not root).
5. Password: from your password manager.
6. Confirm only the intended shares mount and permissions match Step 2.

### Windows

1. File Explorer → address bar or **Map network drive**.
2. Path: `\\brian-server` or `\\YOUR-RESERVED-IP`.
3. Sign in as `brian` (not root).

Full local and remote (Tailscale) access for Unraid UI, SMB, and apps: chapter `09`.

## Step 5 — Git

Keep this handbook on your Mac and push to GitHub. The server does not need to host Git for Phase 1.

Optional later: Gitea container on the GM7000 if you want self-hosted repos.

## Step 6 — Cron via User Scripts

Use the **User Scripts** plugin (not a normal Linux user crontab).

### Install (if missing)

1. Open **Apps**.
2. Search for **User Scripts**.
3. Install, then confirm under **Plugins**.

### Add a job

1. Open **Settings → User Scripts**.
2. Click **Add New Script**.
3. Fill:

| Field | Value (example) |
|---|---|
| Script name | `weekly-backup` |
| Description / comment | Weekly Exos rsync snapshot |

4. Click the gear / edit control → **Edit Script**.
5. Paste a runner that calls your script with `bash` (required on Unraid 7.3.x because `/boot` files are not executable):

```bash
#!/bin/bash
bash /boot/config/custom/backup/weekly-backup.sh
```

6. Save the script.
7. Set schedule:

| Field | Value (example) |
|---|---|
| Schedule | **Custom** |
| Cron schedule | `0 3 * * 0` (Sunday 03:00 server time) |

Or use a built-in weekly preset if you prefer. Click **Apply**.

### Suggested jobs

| Script name | Schedule idea | Script body idea |
|---|---|---|
| `pre-backup-db-dumps` | Sunday 02:45 | dump Immich/HA DBs into `database-backups-staging` |
| `weekly-backup` | Sunday 03:00 | `bash /boot/config/custom/backup/weekly-backup.sh` |
| `post-backup-check` | Sunday 04:00 | verify exit log / send notification |

Avoid overlapping SMART extended tests, big Immich imports, and Jellyfin library scans.

### Install scripts on the server

From a terminal on Unraid (or after copying files from your Mac):

```bash
mkdir -p /boot/config/custom/backup
cp /path/to/Brian-HomeServer/scripts/*.sh /boot/config/custom/backup/
```

Do **not** rely on `chmod +x` on `/boot` under Unraid 7.3.x — always run with `bash /path/to/script.sh`.

Copy `scripts/backup.env.example` to `backup.env` beside the scripts and keep `backup.env` out of Git.

**Next:** chapter `10` Weekly backup.
