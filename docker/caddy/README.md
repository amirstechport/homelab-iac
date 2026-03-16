# Caddy

Automatic HTTPS reverse proxy. Obtains and renews TLS certificates from Let's Encrypt automatically via the HTTP-01 ACME challenge. No manual cert management required.

Runs with `network_mode: host` so it can bind ports 80 and 443 directly and receive the ACME challenge.

---

## Quick Start

```bash
cp .env.example .env
nano .env  # Set CADDY_DATA_DIR

mkdir -p ${CADDY_DATA_DIR}/{site,data,config}
# Create your Caddyfile at ${CADDY_DATA_DIR}/Caddyfile

docker compose up -d
docker logs caddy --follow
```

---

## Caddyfile Examples

**Reverse proxy a service:**
```
app.yourdomain.com {
    reverse_proxy localhost:8080
}
```

**Multiple services:**
```
grafana.yourdomain.com {
    reverse_proxy localhost:3000
}

blog.yourdomain.com {
    reverse_proxy localhost:2368
}
```

**Static site:**
```
yourdomain.com {
    root * /srv
    file_server
}
```

---

## Variables

| Variable | Description |
|---|---|
| `CADDY_DATA_DIR` | Absolute path to Caddy data directory on the host |

## Notes

- The `data/` volume holds your TLS certificates — always include it in backups
- Watchtower is set to `monitor-only` for Caddy — you'll be notified of updates but it won't auto-update, since Caddyfile syntax can change between versions
