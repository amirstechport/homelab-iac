# Ghost Blog + MariaDB

Self-hosted blogging and publishing platform backed by MariaDB. Ghost provides a clean writing UI, membership/subscription support, and a built-in newsletter system.

---

## Quick Start

```bash
cp .env.example .env
nano .env  # Set passwords, GHOST_URL, and GHOST_DATA_DIR

mkdir -p ${GHOST_DATA_DIR}/{db,data}
docker compose up -d
# Open http://YOUR_HOST_IP:2368/ghost to complete setup
```

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `GHOST_URL` | — | **Required.** Public URL of your site (`https://blog.yourdomain.com`) |
| `GHOST_DB_ROOT_PASSWORD` | — | **Required.** MariaDB root password |
| `GHOST_DB_PASSWORD` | — | **Required.** Ghost app DB password |
| `GHOST_DATA_DIR` | — | **Required.** Host path for data (`/db` and `/data` subdirs) |
| `GHOST_DB_NAME` | `ghost` | Database name |
| `GHOST_DB_USER` | `ghost_u` | Database user |
| `GHOST_PORT` | `2368` | Host port for Ghost |

## Behind a Reverse Proxy

Ghost must know its public URL to generate correct links. Set `GHOST_URL` to your full HTTPS domain before first launch — changing it later requires a database update.

**Traefik dyconfig example (`ghost.yml`):**
```yaml
http:
  routers:
    ghost:
      rule: "Host(`blog.yourdomain.com`)"
      entryPoints: [https]
      tls:
        certResolver: cloudflare
      service: ghost
  services:
    ghost:
      loadBalancer:
        servers:
          - url: "http://YOUR_HOST_IP:2368"
```

## Backups

Back up both:
- `${GHOST_DATA_DIR}/db` — MariaDB data files (all posts and settings)
- `${GHOST_DATA_DIR}/data` — Ghost content (themes, images, uploaded files)
