# Deploy and Host Omeka Classic on Railway

## About Hosting Omeka Classic

Omeka Classic is an open-source platform for digital collections, archives, exhibits, and cultural heritage publishing. This template deploys stable 3.2.2 with generated credentials and private MariaDB.

Sign in at `/admin` as `admin` with `OMEKA_ADMIN_PASSWORD`.

## Common Use Cases

- Digital archives and museum collections
- Scholarly exhibits and teaching collections
- Community history and metadata publishing

## Dependencies for Omeka Hosting

### Deployment Dependencies

Omeka and private MariaDB services each use a daily-backed-up volume. Railway provides HTTPS.

### Implementation Details

The adapter writes the private database configuration, runs the supported web installer before exposing Caddy, and persists original files plus uploads. Use one application replica.

## Why Deploy Omeka on Railway?

Railway provides generated credentials, private networking, HTTPS, persistent storage, backups, health checks, and Git-driven updates.
