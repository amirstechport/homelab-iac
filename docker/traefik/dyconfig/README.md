# Traefik dyconfig

This folder holds Traefik's dynamic configuration — one `.yml` file per service. Traefik watches this directory with `watch: true` and picks up changes instantly, no restart needed.

---

## Templates

| File | Use when… |
|---|---|
| [`_template-http.yml`](_template-http.yml) | Backend runs plain HTTP — most Docker containers |
| [`_template-https.yml`](_template-https.yml) | Backend runs HTTPS with a self-signed cert — Proxmox, Portainer, pfSense |

Both templates expose the service over HTTPS at the Traefik edge (TLS terminated by Cloudflare DNS-01). The difference is only what protocol Traefik uses to talk to your backend.

---

## How to add a new service

**1. Copy the right template:**
```bash
cp _template-http.yml myapp.yml
# or
cp _template-https.yml myapp.yml
```

**2. Find and replace every placeholder — don't skip the names:**

For the HTTP template (4 replacements):

| Placeholder | Replace with | Notes |
|---|---|---|
| `APPNAME-rtr` | `myapp-rtr` | Router name — must be unique across all files |
| `APPNAME-svc` | `myapp-svc` | Service name — must be unique across all files |
| `your.domain.com` | `myapp.yourdomain.com` | Public hostname |
| `192.168.X.X:PORT` | `192.168.1.50:8080` | Backend IP and port |

For the HTTPS template (5 replacements):

| Placeholder | Replace with | Notes |
|---|---|---|
| `APPNAME-rtr` | `myapp-rtr` | Router name — must be unique across all files |
| `APPNAME-svc` | `myapp-svc` | Service name — must be unique across all files |
| `APPNAME-transport` | `myapp-transport` | Transport name — must be unique across all files |
| `APPNAME-ws` | `myapp-ws` | Middleware name — must be unique across all files |
| `your.domain.com` | `myapp.yourdomain.com` | Public hostname |
| `192.168.X.X:PORT` | `192.168.1.50:9443` | Backend IP and port |

**3. Save and done.** Traefik reloads automatically.

---

## The most common mistake

Copying a file and only changing the domain and IP — forgetting to rename `APPNAME-rtr`, `APPNAME-svc`, etc.

**Duplicate names across files will silently break routing.** Traefik will load both configs but only one will win. Name every router, service, middleware, and transport after the app it belongs to.

---

## Naming convention

Use a consistent prefix per service so files stay readable:

```
myapp-rtr        # router
myapp-svc        # service
myapp-transport  # serversTransport (HTTPS template only)
myapp-ws         # middleware (HTTPS template only)
```

---

## Zero-downtime config check

Traefik exposes its current routing state at the dashboard. To verify a new file loaded correctly:

```
http://YOUR_HOST_IP:8080/dashboard/#/http/routers
```

If your router doesn't appear or shows an error, check:
- Duplicate router/service names with another file
- Indentation errors (YAML is whitespace-sensitive)
- `certResolver` name doesn't match what's in `traefik.yml`
