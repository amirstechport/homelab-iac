# Watchtower

Automatically checks for updated Docker images and redeploys containers when a new version is found. Sends a single Slack summary report per check cycle.

This stack uses [nickfedor/watchtower](https://github.com/nicholas-fedor/watchtower) — the actively maintained fork of `containrrr/watchtower`.

---

## Quick Start

```bash
cp .env.example .env
nano .env  # Add your Slack webhook URL
docker compose up -d
docker logs watchtower --follow
```

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL` | — | **Required.** Slack Incoming Webhook URL |
| `WATCHTOWER_POLL_INTERVAL` | `86400` | Check interval in seconds (86400 = 24h) |
| `WATCHTOWER_CLEANUP` | `true` | Remove old images after update |
| `WATCHTOWER_NOTIFICATION_REPORT` | `true` | One summary message per cycle (less noisy) |
| `DOCKER_API_VERSION` | `1.47` | Pin to match your Docker version |

## Opting Containers Out

Add this label to any container Watchtower should ignore:
```yaml
labels:
  - "com.centurylinklabs.watchtower.disable=true"
```

Add this to monitor-only (notify but don't update):
```yaml
labels:
  - "com.centurylinklabs.watchtower.monitor-only=true"
```

## Create a Slack Webhook

Slack App Directory → Incoming Webhooks → Add to Slack → Choose a channel → Copy URL
