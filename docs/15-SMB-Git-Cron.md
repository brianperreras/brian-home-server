# 15 - SMB, Git, and Cron on Unraid

Do this **after** Jellyfin (`14`). Shares already exist from Storage (`04`); this chapter adds users, SMB access, and schedules. Steps match **Unraid 7.3.2**.

## Step 1 — Enable SMB

1. Open **Settings → SMB**.
2. Switch to **Advanced View** if available.
3. Enable **SMB** and click **Apply**. Array stop is not required in Unraid 7.3.2.
4. Fill:

| Field | Value |
|---|---|
| Enable SMB | **Yes** (Workgroup) |
| Hide “dot” files | optional (**No** is fine) |
| Enhanced macOS interoperability | **Yes** (recommended for Mac clients) |
| Enable NetBIOS | optional; often **No** on modern LANs |
| Enable WSD | **Yes** (helps Windows discovery) if shown |
| Workgroup | `WORKGROUP` (or your home workgroup name) |

5. Click **Apply**.

6. Optional check — **Settings → Identification**:

| Field | Value |
|---|---|
| Server name | `brian-server` |

This is what macOS shows in Finder / `smb://brian-server`.

## Step 2 — Create SMB users

Do not use `root` for day-to-day SMB. Root is for the WebGUI / SSH only.

1. Open **Users**.
2. On the **Users** page, click **Add User**.
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
| `downloads` | **Read/Write** |
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

## Step 3 — Per-share SMB Security Settings

For each share, open **Shares → [share name]** and set **SMB Security Settings**. On this xfs build, **Enable Copy-on-write** is hidden — skip it (see chapter `04`). Also confirm Primary / Secondary / Mover for `photos` still match chapter `04` (`cache` → **Array**, mover **`cache→array`**).

### Field meanings (7.3.2)

| Field | Options / recommended | If missing |
|---|---|---|
| Export | **No** / **Yes** / **Yes (Time Machine)** | Confirm **Settings → SMB → Enable SMB** is Yes |
| Time Machine volume size limit | blank for normal shares | Only relevant when Export is **Yes (Time Machine)** |
| Case-sensitive names | **Auto** | Switch share page to **Advanced View** |
| Security | **Private** (best), **Secure**, avoid **Public** | Always on the share SMB section |
| Enable Copy-on-write (Share Settings) | Skip on this xfs build | Hidden unless Btrfs |

### Private data shares

| Share | Export | Time Machine volume size limit | Case-sensitive names | Security |
|---|---|---|---|---|
| `photos` | **Yes** | blank | **Auto** | **Private** |
| `documents` | **Yes** | blank | **Auto** | **Private** |
| `media` | **Yes** | blank | **Auto** | **Private** |
| `backups-incoming` | **Yes** | blank | **Auto** | **Private** |
| `downloads` | **Yes** | blank | **Auto** | **Private** |

User read/write checkboxes on the share page should match Step 2. Click **Apply**.

### Optional public transfer share

| Field | Value |
|---|---|
| Share | `public` |
| Export | **Yes** |
| Time Machine volume size limit | blank |
| Case-sensitive names | **Auto** |
| Security | **Secure** (preferred) or **Private** — not **Public** |
| Guest write | **No** |

### Do not export over SMB

| Share | Export | Time Machine volume size limit | Case-sensitive names | Security |
|---|---|---|---|---|
| `appdata` | **No** | blank | **Auto** | leave default |
| `system` | **No** | blank | **Auto** | leave default |
| `domains` | **No** | blank | **Auto** | leave default |
| `database-backups-staging` | **No** | blank | **Auto** | leave default |

### Optional later: Time Machine share

Only if you want Mac Time Machine on Unraid (separate from Phase 1 shares):

| Field | Value |
|---|---|
| Share name | e.g. `timemachine` |
| Enable Copy-on-write | **Auto** |
| Export | **Yes (Time Machine)** |
| Time Machine volume size limit | e.g. `1048576` (1 TB in MB) — pick a cap that fits the IronWolf |
| Case-sensitive names | **Auto** |
| Security | **Private** |
| User access | only the Mac owner’s SMB user = **Read/Write** |

## Step 4 — Connect from another computer (local)

### macOS

1. Finder → **Go → Connect to Server…** (⌘K).
2. Server address: `smb://brian-server` or `smb://192.168.0.10`.
3. Connect As: **Registered User**.
4. Name: `brian` (SMB user, not root).
5. Password: from your password manager.
6. Confirm only the intended shares mount and permissions match Step 2.

### Windows

1. File Explorer → address bar or **Map network drive**.
2. Path: `\\brian-server` or `\\192.168.0.10`.
3. Sign in as `brian` (not root).

Full LAN access for Unraid UI / SMB / apps: chapter `09` Part A. Remote (Tailscale): chapter `09` Part B after apps work.

## Step 5 — Git

Keep this handbook on your Mac and push to GitHub. The server does not need to host Git for Phase 1.

Optional later: a self-hosted Git container on the GM7000 if you want self-hosted repos. **Forgejo** (https://forgejo.org) is the actively maintained community fork and is preferred over Gitea for new deployments; Gitea remains functional but has diverged in governance since 2022.

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
| `create-shares` | **Run manually** | `FORCE=1 bash /boot/config/custom/shares/create-shares.sh` (chapter `04`) |
| `validate-shares` | **Run manually** | `bash /boot/config/custom/shares/validate-shares.sh` (chapter `04`) |
| `pre-backup-db-dumps` | Sunday 02:45 | dump Immich/HA DBs into `database-backups-staging` |
| `weekly-backup` | Sunday 03:00 | `bash /boot/config/custom/backup/weekly-backup.sh` |
| `post-backup-check` | Sunday 04:00 | verify exit log / send notification |

Avoid overlapping SMART extended tests, big Immich imports, and Jellyfin library scans.

### Install scripts on the server

From a terminal on Unraid (or after copying files from your Mac):

```bash
# Share create/validate (chapter 04) — used by User Scripts wrappers
mkdir -p /boot/config/custom/shares/lib
cp /path/to/Brian-HomeServer/scripts/create-shares.sh /boot/config/custom/shares/
cp /path/to/Brian-HomeServer/scripts/validate-shares.sh /boot/config/custom/shares/
cp /path/to/Brian-HomeServer/scripts/lib/share-defs.sh /boot/config/custom/shares/lib/

# Weekly backup (chapter 10)
mkdir -p /boot/config/custom/backup
cp /path/to/Brian-HomeServer/scripts/weekly-backup.sh /boot/config/custom/backup/
cp /path/to/Brian-HomeServer/scripts/pre-backup-db-dumps.sh /boot/config/custom/backup/
cp /path/to/Brian-HomeServer/scripts/post-backup-check.sh /boot/config/custom/backup/
cp /path/to/Brian-HomeServer/scripts/backup.env.example /boot/config/custom/backup/
```

Do **not** rely on `chmod +x` on `/boot` under Unraid 7.3.x — always run with `bash /path/to/script.sh` from a User Scripts entry.

Copy `backup.env.example` to `backup.env` beside the backup scripts and keep `backup.env` out of Git.

## Verify your setup

1. **SMB share accessible from Mac** — open Finder → Go → Connect to Server (Cmd+K), enter `smb://192.168.0.10`, log in as `brian`.
   Expected result: a share picker appears listing `photos`, `documents`, `media`, and other exported shares; mounting one opens in Finder without an auth error.

2. **Mounted share shows correct contents** — browse the mounted share in Finder.
   Expected result: share contents match what is on the server; write test (create and delete a test file) succeeds for shares granted Read/Write.

3. **User Scripts plugin shows at least one script** — Settings → User Scripts.
   Expected result: `weekly-backup` (and any other scripts added) appears in the list with a cron schedule visible.

4. **Cron schedule saved and next run time shown** — Settings → User Scripts → click the script name.
   Expected result: schedule field shows `0 3 * * 0` (or your chosen schedule) and Unraid displays the next scheduled run time.

**Next:** chapter `10` Weekly backup.
