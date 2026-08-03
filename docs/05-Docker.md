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

## 2. Path-mapping rule

Every container path that writes significant data must map to a host path. Do not let large files accumulate inside the writable container layer.

Example:

| Container path | Host path |
|---|---|
| `/config` | `/mnt/user/appdata/application-name` |
| `/photos` | `/mnt/user/photos` |
| `/media` | `/mnt/user/media` |

## 3. Networking

Use the default bridge network for most apps. Create a custom bridge network for related stacks such as Immich, reverse proxy, and databases when needed.

Avoid assigning every container a unique LAN IP unless there is a clear reason. It increases complexity and can conflict with router settings.

## 4. Docker Compose

For services with an official Compose deployment, use the maintained Compose Manager plugin or another supported method. Keep compose files in this Git repository, but keep secrets only on the server.

Suggested server location:

`/mnt/user/appdata/compose-projects/<project>`

Repository templates are in `docker/`.

## 5. Updates

- Back up appdata before major updates.
- Read release notes for Immich and Home Assistant.
- Do not use floating `latest` tags for critical services unless the project explicitly expects it and you have backups.
- Update one stack at a time.
- Verify logs and functionality after every change.

## 6. Resource limits

Do not impose CPU/RAM limits initially unless a container misbehaves. Monitor normal usage first. For the i5-14400 and 32 GB RAM, Phase 1 workloads should have ample headroom.

## 7. Intel iGPU access

For containers using Quick Sync, pass:

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
