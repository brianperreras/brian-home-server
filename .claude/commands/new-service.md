# new-service

Scaffold a new Docker Compose service for this Unraid server.

Usage: `/new-service <service-name>`

Steps:
1. Ask for: the service name, the port it exposes, whether it needs a database, and the data paths it needs.
2. Create `docker/<service-name>/compose.yaml` following the same pattern as the existing stacks:
   - `restart: unless-stopped` on all containers
   - Appdata volumes rooted at `/mnt/user/appdata/<service-name>/`
   - Data volumes rooted at `/mnt/user/<share>/` (on IronWolf)
   - Secrets via `.env` file references — never hardcoded
   - No exposed ports other than what's needed; prefer internal networks where possible
3. Create `docker/<service-name>/README.md` with: purpose, port, volume paths, and any first-run steps.
4. Create `docker/<service-name>/.env.example` listing every variable the compose file references.
5. Add the service to the table in `README.md`.
6. Remind the user to add backup paths for the new service's appdata and data to `scripts/backup.env`.
