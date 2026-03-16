# homelab-iac

Infrastructure as Code for my personal homelab. Ansible automation, Docker Compose stacks, and Proxmox configuration — built with the same discipline I apply to production environments.

---

## 📁 Repository Structure

```
homelab-iac/
├── ansible/                  # Fleet automation and provisioning
│   ├── playbooks/            # Provisioning, day-2 ops, app maintenance
│   ├── inventory/            # Inventory sample and group structure
│   ├── scripts/              # Control node bootstrap
│   └── 00-Getting-Started-Ansible.md
│
├── docker/                   # Self-hosted service stacks
│   ├── traefik/              # Reverse proxy with Cloudflare DNS-01 TLS
│   ├── observability/        # Prometheus + Grafana + Loki + Promtail
│   ├── ghost/                # Ghost blog + MariaDB
│   ├── cloudflared/          # Cloudflare Tunnel (no open inbound ports)
│   ├── cloudflare-ddns/      # Dynamic DNS updater
│   ├── watchtower/           # Automated container image updates
│   ├── caddy/                # Caddy reverse proxy
│   ├── deunhealth/           # Restart containers that fail health checks
│   ├── dozzle/               # Real-time container log viewer
│   └── scripts/              # Docker host bootstrap
│
└── proxmox/                  # Coming soon
```

---

## ⚙️ Ansible

Idempotent playbooks for provisioning and maintaining Debian/Ubuntu and RHEL-family hosts. All modules use FQCN (`ansible.builtin.*`, `community.docker.*`) and handler patterns for safe restarts.

| Playbook | Purpose |
|---|---|
| `provision_base.yml` | Baseline packages + SSH hardening for Debian/Ubuntu |
| `provision_base_rhel.yml` | Same baseline for AlmaLinux / Rocky Linux / RHEL |
| `provision_docker_node.yml` | Docker CE + Compose plugin + Portainer Agent |
| `provision_podman_node.yml` | Podman + podman-compose for RHEL-family hosts |
| `maintenance.yml` | Fleet apt update/upgrade/cleanup with tag-based targeting |
| `manage_aliases.yml` | Deploy shell aliases to `~/.bash_aliases` across the fleet |
| `nextcloud_maintenance.yml` | Post-upgrade `occ` tasks and health check for Nextcloud |

→ See [`ansible/playbooks/README.md`](ansible/playbooks/README.md) for usage, variables, and tag reference.

→ See [`ansible/00-Getting-Started-Ansible.md`](ansible/00-Getting-Started-Ansible.md) for control node setup.

---

## 🐳 Docker

Each stack lives in its own folder with a minimal `docker-compose.yml` and a `README.md` covering variables, setup steps, and configuration examples. All sensitive values are in `.env` files (not committed).

| Stack | Description |
|---|---|
| [`traefik/`](docker/traefik/) | Reverse proxy — Cloudflare DNS-01 wildcard TLS, file provider (dyconfig), no container labels |
| [`observability/`](docker/observability/) | Prometheus + Node Exporter + Grafana + Loki + Promtail syslog receiver |
| [`ghost/`](docker/ghost/) | Ghost blog with MariaDB, health-check dependency ordering |
| [`cloudflared/`](docker/cloudflared/) | Cloudflare Tunnel — expose services without opening firewall ports |
| [`cloudflare-ddns/`](docker/cloudflare-ddns/) | Dynamic DNS — keep Cloudflare A records current with your WAN IP |
| [`watchtower/`](docker/watchtower/) | Auto-update container images with Slack notifications |
| [`caddy/`](docker/caddy/) | Caddy reverse proxy with automatic HTTPS |
| [`deunhealth/`](docker/deunhealth/) | Restart containers that are running but fail their health check |
| [`dozzle/`](docker/dozzle/) | Browser-based real-time Docker log viewer |

---

## 🖥️ Proxmox

Coming soon — VM templates, cloud-init configs, and post-install provisioning scripts.

---

## 🔒 Secrets and Sanitization

This repository contains no real credentials. All sensitive values use placeholder patterns:
- `.env` files → `${VAR_NAME}` placeholders (see `.env.example` in each stack)
- Ansible inventory → sample IPs in `10.0.0.X` range
- API tokens, passwords, and tunnel tokens → documented in `.env.example` with descriptions

Live `.env` files and `acme.json` are excluded via `.gitignore`.
