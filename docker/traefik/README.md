# Traefik — Reverse Proxy & Automatic TLS

Traefik acts as the single entry point for all self-hosted services. It handles TLS certificate provisioning automatically via the Cloudflare DNS-01 challenge and routes all traffic through **file-based dynamic configuration** in the `dyconfig/` folder.

> **This setup does not use Docker labels.** Every route is defined as a `.yml` file in `dyconfig/`. Traefik watches that folder and hot-reloads on any change — no restart needed, no container labels required.

→ **To add or configure a service, see [`dyconfig/README.md`](dyconfig/README.md)**. It has copy-paste templates for both HTTP-backend and HTTPS-backend services with all fields annotated.

---

## Architecture

```
Internet → Port 80/443 → Traefik → dyconfig/*.yml → Internal services
                              ↑
                    Cloudflare DNS-01
                    (wildcard cert for *.yourdomain.com)
```

Routing is decoupled from container lifecycle. A service doesn't need to be running for its route to be defined, and adding a route never touches `docker-compose.yml`.

---

## Directory Structure

```
traefik/
├── docker-compose.yml        # Container definition (this repo)
├── .env.example              # Variable template
├── traefik.yml.example       # Static config template
├── README.md                 # This guide
│
└── On your host (not in repo):
    ├── traefik.yml           # Your static config (from traefik.yml.example)
    ├── acme.json             # TLS cert store — auto-managed, chmod 600
    ├── cf_api_token.txt      # Cloudflare API token — gitignored
    ├── dyconfig/             # Dynamic route definitions (see below)
    │   ├── service_a.yml
    │   └── service_b.yml
    └── logs/                 # Access and error logs
```

---

## Setup Guide

### 1. Prerequisites

- A domain with DNS managed by Cloudflare
- Docker and the Compose plugin installed
- The shared `proxy` network created:

```bash
docker network create proxy
```

---

### 2. Create the data directory

```bash
export TRAEFIK_DATA_DIR=/home/youruser/traefik

mkdir -p ${TRAEFIK_DATA_DIR}/{dyconfig,logs}
touch ${TRAEFIK_DATA_DIR}/acme.json
chmod 600 ${TRAEFIK_DATA_DIR}/acme.json
```

---

### 3. Create your Cloudflare API token

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com) → My Profile → API Tokens
2. Create Token → Use the **"Edit zone DNS"** template
3. Scope it to your specific zone only
4. Copy the token and write it to the secrets file:

```bash
echo "your_token_here" > ${TRAEFIK_DATA_DIR}/cf_api_token.txt
chmod 600 ${TRAEFIK_DATA_DIR}/cf_api_token.txt
```

---

### 4. Configure the environment

```bash
cp .env.example .env
nano .env
```

Generate dashboard basic auth credentials:

```bash
# Install apache2-utils if needed: sudo apt install apache2-utils
htpasswd -nb yourusername yourpassword
# Copy the output into TRAEFIK_DASHBOARD_CREDENTIALS in .env
# Escape any $ in the hash as $$ when writing to .env
```

---

### 5. Create the static config

```bash
cp traefik.yml.example ${TRAEFIK_DATA_DIR}/traefik.yml
nano ${TRAEFIK_DATA_DIR}/traefik.yml
```

Update the `email` field under `certificatesResolvers` with your real email address.

---

### 6. Start Traefik

```bash
docker compose up -d
docker logs traefik --follow
```

On first start, Traefik requests your wildcard certificate from Let's Encrypt. This takes 30–60 seconds. You'll see `"certificate obtained successfully"` in the logs when it's done.

---

## Adding a Service

All routing is managed through the `dyconfig/` folder. See **[`dyconfig/README.md`](dyconfig/README.md)** for:

- Copy-paste templates for HTTP-backend and HTTPS-backend services
- A full table of every field that needs to change (not just domain/IP — router names, service names, transport names)
- The most common mistake (duplicate names across files) and how to avoid it
- How to verify a new route loaded in the dashboard

---

## Useful Commands

```bash
# Follow live logs
docker logs traefik --follow

# Check Traefik dashboard (once DNS resolves)
# https://traefik.yourdomain.com

# Reload static config (requires restart — only needed for traefik.yml changes)
docker compose restart traefik

# Dynamic config (dyconfig/) reloads automatically — no restart needed

# View current TLS cert status
cat ${TRAEFIK_DATA_DIR}/acme.json | python3 -m json.tool | grep -A2 "main"
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Certificate not issued | Check `docker logs traefik` for ACME errors. Verify CF token has DNS Edit permission |
| `acme.json` permission error | `chmod 600 ${TRAEFIK_DATA_DIR}/acme.json` |
| Route not working | Check `dyconfig/` file for YAML syntax errors. Traefik logs will show parse errors |
| 404 on all routes | Verify the `proxy` network exists and the target container is on it |
| Dashboard not loading | Check `TRAEFIK_DASHBOARD_CREDENTIALS` format — `$` must be escaped as `$$` in `.env` |
