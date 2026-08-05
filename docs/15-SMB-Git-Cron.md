# 15 - SMB, Git, and Cron on Unraid

## SMB (file shares)

Unraid provides SMB through user shares. Create named users; do not use `root` for day-to-day file access.

### Users

1. `Users` → add a personal account (for example `brian`).
2. Set a strong password stored in your password manager.
3. Assign share access per share (`Read/Write`, `Read-only`, or `None`).

### Share recommendations for this build

| Share | Suggested export | Access |
|---|---|---|
| `photos` | Private/Secure | Read/write for admin only; Immich owns the library workflow |
| `documents` | Private | Household users as needed |
| `media` | Private/Secure | Read/write for admin; read-only for media clients if useful |
| `backups-incoming` | Private | Write from trusted PCs |
| `public` | Optional | Guest write disabled |
| `appdata` | Prefer not exported | Keep Docker config off SMB |

Connect from macOS Finder via `smb://brian-server` or the reserved IP.

More detail: [Unraid shares docs](https://docs.unraid.net/unraid-os/using-unraid-to/manage-storage/shares/)

## Git

### This documentation repository

Keep the Brian-HomeServer handbook on your Mac (or another workstation) and push to GitHub. The Unraid server does not need to host the handbook for day-to-day operations.

### Optional Git hosting later

If you want self-hosted Git (for example Gitea):

- Deploy as a separate Docker stack on the GM7000.
- Store repositories under `/mnt/user/appdata/gitea` or a dedicated IronWolf share if repos are large.
- Back up the Gitea data directory and database dumps with the weekly Exos job.
- Do not expose Git hosting publicly without authentication and TLS review.

Until then, GitHub + local clones are enough.

## Cron and scheduled jobs

Unraid does not use a traditional user crontab for most home-lab tasks. Prefer the **User Scripts** plugin.

### Schedules to create

| Job | Suggested timing | Script / action |
|---|---|---|
| Weekly backup | Sunday quiet hours | `scripts/weekly-backup.sh` after mounting Exos ([`10-Backup.md`](10-Backup.md)) |
| Pre-backup DB dumps | Immediately before weekly backup | `scripts/pre-backup-db-dumps.sh` |
| Post-backup check | Immediately after weekly backup | `scripts/post-backup-check.sh` |
| Appdata Backup plugin | Separate from weekly Exos job | Flash + appdata convenience backup |

Avoid overlapping:

- Extended SMART tests
- Mover (should rarely matter with exclusive SSD shares)
- Large Immich imports or Jellyfin library scans

### Installing backup scripts

```bash
mkdir -p /boot/config/custom/backup
cp /path/to/Brian-HomeServer/scripts/*.sh /boot/config/custom/backup/
chmod 700 /boot/config/custom/backup/*.sh
```

Copy `scripts/backup.env.example` to `backup.env` next to the scripts, edit paths, and keep `backup.env` out of Git.

## Related chapters

- Storage and share layout: [`04-Storage.md`](04-Storage.md)
- Network/security: [`09-Network-Security.md`](09-Network-Security.md)
- Weekly backup workflow: [`10-Backup.md`](10-Backup.md)
