# 15 - SMB, Git, and Cron on Unraid

Do this **after** Jellyfin (`14`). Shares already exist from Storage (`04`); this chapter only adds users and schedules.

## Step 1 — SMB users

1. Unraid → Users → add a personal account (for example `brian`).
2. Store the password in your password manager.
3. Set share access per share (`Read/Write`, `Read-only`, or `None`).
4. Do not use `root` for day-to-day SMB.

Suggested access:

| Share | Access idea |
|---|---|
| `photos` | Admin only; Immich manages the library |
| `documents` | Household as needed |
| `media` | Admin write; optional read-only for others |
| `backups-incoming` | Trusted PCs can write |
| `public` | Optional; guest write off |
| `appdata` | Prefer not exported over SMB |

Connect from macOS: `smb://brian-server` or the reserved IP.

## Step 2 — Git

Keep this handbook on your Mac and push to GitHub. The server does not need to host Git for Phase 1.

Optional later: Gitea container on the GM7000 if you want self-hosted repos.

## Step 3 — Cron via User Scripts

Use the User Scripts plugin (not a normal Linux user crontab).

Suggested jobs (create after backup scripts exist):

| Job | When |
|---|---|
| Pre-backup DB dumps | Just before weekly backup |
| Weekly backup script | Sunday quiet hours |
| Post-backup check | Right after weekly backup |

Avoid overlapping SMART extended tests, big Immich imports, and Jellyfin library scans.

Install scripts when ready for chapter `10`:

```bash
mkdir -p /boot/config/custom/backup
cp /path/to/Brian-HomeServer/scripts/*.sh /boot/config/custom/backup/
chmod 700 /boot/config/custom/backup/*.sh
```

Copy `scripts/backup.env.example` to `backup.env` beside the scripts and keep `backup.env` out of Git.

**Next:** chapter `10` Weekly backup.
