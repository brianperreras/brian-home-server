#!/usr/bin/env bash
set -Eeuo pipefail

STAGING="/mnt/user/database-backups-staging"
mkdir -p "$STAGING"
STAMP="$(date +%F-%H%M%S)"

# Immich example only. Confirm the actual service/container name and DB user
# from the current official Immich compose file before enabling.
# docker exec immich_postgres pg_dumpall --clean --if-exists --username=postgres \
#   | gzip > "$STAGING/immich-$STAMP.sql.gz"

echo "No database dump command is enabled yet. Edit this script after Immich is deployed."
