# 05 - Docker on Unraid

Docker is built into Unraid; you do not install Docker Engine separately.

## 1. Enable Docker

In Unraid:

`Settings -> Docker -> Enable Docker: Yes`

Store Docker data on the GM7000 pool.

Recommended approach:

- Docker data root: `directory` mode if supported and desired, or a Docker image file.
- If using an image file, start around 30-40 GB and monitor usage. A growing image usually indicates incorrect container path mappings, not a need for a huge image.
- Default appdata: `/mnt/user/appdata`.

Confirm the array/pool is started before enabling Docker so paths resolve onto the GM7000.

## 2. Preferred deployment method for this build

Use the **Compose Manager** plugin (or another currently maintained Compose method) for Immich, Home Assistant, and Jellyfin. Keep official upstream compose files where projects provide them.

Suggested server location:

`/mnt/user/appdata/compose-projects/<project>`

Repository templates/notes are in `docker/`.

Phase 1 bring-up order:

1. Storage shares and Docker enabled ([`04-Storage.md`](04-Storage.md)).
2. Immich ([`06-Immich.md`](06-Immich.md)).
3. Home Assistant ([`07-Home-Assistant.md`](07-Home-Assistant.md)).
4. Jellyfin ([`14-Jellyfin.md`](14-Jellyfin.md)).
5. SMB users and schedules ([`15-SMB-Git-Cron.md`](15-SMB-Git-Cron.md)).
6. Weekly backup ([`10-Backup.md`](10-Backup.md)).

## 3. Path-mapping rule

Every container path that writes significant data must map to a host path. Do not let large files accumulate inside the writable container layer.

Example:

| Container path | Host path |
|---|---|
| `/config` | `/mnt/user/appdata/application-name` |
| `/photos` | `/mnt/user/photos` |
| `/media` | `/mnt/user/media` |

## 4. Networking

Use the default bridge network for most apps. Create a custom bridge network for related stacks such as Immich when the official compose defines one.

Avoid assigning every container a unique LAN IP unless there is a clear reason. It increases complexity and can conflict with router settings.

Home Assistant uses host networking in the provided template for discovery. Jellyfin can use published ports or host networking; prefer published ports first unless LAN discovery requires host mode.

## 5. Updates

- Back up appdata before major updates.
- Read release notes for Immich, Home Assistant, and Jellyfin.
- Do not use floating `latest` tags for critical services unless the project explicitly expects it and you have backups.
- Update one stack at a time.
- Verify logs and functionality after every change.

## 6. Resource limits

Do not impose CPU/RAM limits initially unless a container misbehaves. Monitor normal usage first. For the i5-14400 and 32 GB RAM, Phase 1 workloads should have ample headroom.

## 7. Intel iGPU access

For containers using Quick Sync (Immich, Jellyfin), pass:

`/dev/dri`

Verify on Unraid:

```bash
ls -l /dev/dri
```

Expected devices commonly include `card0` and `renderD128`. Exact numbering can differ.

## 8. Back up Docker correctly

Back up:

- `/mnt/user/appdata`
- Compose files
- `.env` files through a secure non-public backup process
- Database dumps
- Unraid flash configuration

A copy of the Docker image is usually not important; containers can be recreated. Persistent appdata and databases are important.
