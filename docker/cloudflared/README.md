# Cloudflare Tunnel

Exposes internal homelab services to the internet without opening any inbound firewall ports or requiring a static IP. Traffic flows outbound through an encrypted tunnel to Cloudflare's edge.

Works behind CGNAT, dynamic IPs, and double-NAT.

---

## Quick Start

```bash
cp .env.example .env
nano .env  # Paste your tunnel token
docker compose up -d
docker logs cloudtunnel --follow
```

---

## Getting Your Tunnel Token

1. [Cloudflare Zero Trust](https://one.dash.cloudflare.com) → Networks → Tunnels → Create a Tunnel
2. Select **Cloudflared** → Name your tunnel
3. Copy the token from the Docker install command shown on screen
4. Paste it as `CLOUDFLARE_TUNNEL_TOKEN` in `.env`

---

## Routing Services Through the Tunnel

After the tunnel is connected, configure **Public Hostnames** in the Cloudflare dashboard:

| Public Hostname | Service |
|---|---|
| `blog.yourdomain.com` | `http://ghost_app:2368` |
| `app.yourdomain.com` | `http://192.168.1.100:8080` |

The tunnel container must be on the same Docker network as the services you want to expose, or you reference them by host IP.

---

## Variables

| Variable | Description |
|---|---|
| `CLOUDFLARE_TUNNEL_TOKEN` | **Required.** Token from the Cloudflare Zero Trust dashboard |

## Security

The tunnel token grants Cloudflare the ability to authenticate your connector. Treat it like a private key — store only in `.env`, never commit.
