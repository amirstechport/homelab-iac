# Deunhealth

Automatically restarts Docker containers that fail their health check. Docker's built-in restart policy only handles stopped containers — deunhealth fills the gap for containers that are running but in an unhealthy state.

---

## Quick Start

```bash
cp .env.example .env   # Optional — defaults work out of the box
docker compose up -d
```

---

## Opting Containers In

Add this label to any container you want deunhealth to manage. The container must also have a `healthcheck` defined.

```yaml
services:
  myapp:
    image: myapp:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "deunhealth.restart.on.unhealthy=true"
```

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `DEUNHEALTH_LOG_LEVEL` | `info` | Log verbosity: `debug`, `info`, `warning`, `error` |
| `TZ` | `UTC` | Timezone for log timestamps |

## Notes

- `network_mode: none` is intentional — deunhealth needs no network access whatsoever
- Uses read-only Docker socket access
