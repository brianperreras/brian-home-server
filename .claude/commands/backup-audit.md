# backup-audit

Audit the backup scripts for correctness and completeness.

Usage: `/backup-audit`

Steps:
1. Read `scripts/weekly-backup.sh`, `scripts/pre-backup-db-dumps.sh`, `scripts/post-backup-check.sh`, and `scripts/backup.env.example`.
2. Verify:
   - All required env variables in `backup.env.example` are actually checked in the main script
   - DB dump script covers all databases that the active stacks use (Immich Postgres, any others)
   - Post-check script verifies the snapshot actually contains expected top-level directories
   - Retention pruning logic is correct (sorts by date, keeps newest N)
   - Script uses `set -Eeuo pipefail` and mounts are verified before rsync runs
   - No hardcoded paths that differ from the storage layout (NVMe appdata, IronWolf data, Exos backup)
3. Report findings grouped as: Issues, Warnings, and OK.
4. If asked, apply fixes directly to the script files.
