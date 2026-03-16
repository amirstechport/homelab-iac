# Dozzle

Lightweight real-time log viewer for Docker containers. No database, no agents — reads directly from the Docker socket and streams logs to your browser.

---

## Quick Start

```bash
docker compose up -d
# Open http://YOUR_HOST_IP:9999
```

No `.env` required — defaults work immediately.

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `DOZZLE_PORT` | `9999` | Host port for the Dozzle UI |
| `DOZZLE_LEVEL` | `info` | Dozzle process log level |

## Security

Dozzle exposes all container logs, which may contain tokens or sensitive output. Keep it on your LAN or put it behind a reverse proxy with authentication. Do not expose directly to the internet.

Enable built-in auth by adding to the environment:
```yaml
DOZZLE_AUTH_PROVIDER: simple
DOZZLE_USERNAME: yourusername
DOZZLE_PASSWORD: yourpassword
```
