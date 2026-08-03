# Immich Compose Project

Do not treat a copied compose file as permanently current. Download the latest official files from the Immich release, then apply the paths documented in `docs/06-Immich.md`.

```bash
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
```

Official guide: https://docs.immich.app/install/docker-compose

Keep the real `.env` on the server and out of Git.
