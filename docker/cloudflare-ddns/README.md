# Cloudflare DDNS

Automatically updates Cloudflare DNS A (and optionally AAAA) records when your public IP changes. Essential for homelabs with a dynamic ISP-assigned IP.

Uses [favonia/cloudflare-ddns](https://github.com/favonia/cloudflare-ddns) — lightweight, rootless, actively maintained.

---

## Quick Start

```bash
cp .env.example .env
nano .env  # Add your API token and domains
docker compose up -d
docker logs cloudflare-ddns
```

---

## Create a Cloudflare API Token

1. [Cloudflare Dashboard](https://dash.cloudflare.com) → My Profile → API Tokens → Create Token
2. Use the **"Edit zone DNS"** template
3. Scope it to your specific zone only
4. Copy the token into `.env`

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | — | **Required.** Cloudflare API token |
| `CF_DOMAINS` | — | **Required.** Comma-separated domains to update |
| `CF_PROXIED` | `false` | Route through Cloudflare CDN (hides your IP) |
| `CF_IP6_PROVIDER` | `none` | IPv6: `none`, `local`, or `cloudflare` |
| `CF_DDNS_USER` | `1000:1000` | UID:GID the container runs as |

## Security

The container runs fully hardened by default: read-only filesystem, all capabilities dropped, no new privileges, non-root user.
