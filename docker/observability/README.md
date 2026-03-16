# Observability Stack

Full metrics and log aggregation for homelab monitoring. Five services in one stack:

| Service | Port | Role |
|---|---|---|
| Prometheus | 9090 | Metrics collection and storage |
| Node Exporter | 9100 | Host OS metrics (CPU, RAM, disk, network) |
| Grafana | 3000 | Dashboards and visualization |
| Loki | 3100 | Log aggregation backend |
| Promtail | 1514 / 9080 | Log shipper (syslog receiver + file tails) |

---

## Quick Start

```bash
cp .env.example .env
nano .env  # Set OBSERVABILITY_DATA_DIR and GRAFANA_ADMIN_PASSWORD

mkdir -p ${OBSERVABILITY_DATA_DIR}/{prometheus,promtail}
docker network create monitoring

# Add your prometheus.yml and promtail-config.yaml (see examples below)
docker compose up -d
# Open Grafana at http://YOUR_HOST_IP:3000
```

---

## Config Files Required on Host

### `prometheus.yml` — Scrape targets

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter_local'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'remote_host'
    static_configs:
      - targets: ['192.168.1.50:9100']
        labels:
          instance: 'myserver'
```

Zero-downtime reload after editing: `docker kill --signal=SIGHUP prometheus`

### `promtail-config.yaml` — Log pipeline

```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Receive syslog from OPNsense or other devices
  - job_name: syslog
    syslog:
      listen_address: 0.0.0.0:1514
      listen_protocol: tcp
      idle_timeout: 60s
      label_structured_data: yes
    relabel_configs:
      - source_labels: [__syslog_message_hostname]
        target_label: hostname
```

---

## Grafana Setup

1. Log in at `http://YOUR_HOST_IP:3000` with your admin credentials
2. Add datasources:
   - Prometheus: `http://prometheus:9090`
   - Loki: `http://loki:3100`
3. Import recommended dashboards:
   - **Node Exporter Full** — ID `1860`
   - **cAdvisor Exporter** — ID `14282`

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `OBSERVABILITY_DATA_DIR` | — | **Required.** Host path containing config files |
| `GRAFANA_ADMIN_PASSWORD` | `changeme` | Grafana admin password — change immediately |
| `GRAFANA_ADMIN_USER` | `admin` | Grafana admin username |
| `GRAFANA_PORT` | `3000` | Host port for Grafana |
| `PROMETHEUS_PORT` | `9090` | Host port for Prometheus |
| `NODE_EXPORTER_PORT` | `9100` | Host port for node exporter |
| `LOKI_PORT` | `3100` | Host port for Loki |
| `PROMTAIL_SYSLOG_PORT` | `1514` | Syslog receiver port |
