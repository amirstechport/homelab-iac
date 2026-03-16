# Ansible Playbooks

All playbooks use FQCN module names (`ansible.builtin.*`, `community.docker.*`) and idempotent handler patterns.

**Common flags:**
```bash
--limit server_01        # Target a single host
-e "target_hosts=docker" # Override the target group at runtime
--check                  # Dry run — show changes without applying
--tags update            # Run only tagged tasks
```

---

## Provisioning

### `provision_base.yml` — Debian/Ubuntu baseline

Step 1 for every new Debian or Ubuntu VM or LXC container. Run before any service-specific playbook.

**What it does:** apt update → base packages → qemu-guest-agent → SSH hardening (key-only, no root) → reboot

**Requirements:** SSH key on target, passwordless sudo

```bash
ansible-playbook -i inventory/hosts.ini playbooks/provision_base.yml
ansible-playbook -i inventory/hosts.ini playbooks/provision_base.yml --limit server_01
```

**Key vars (override in `group_vars/` or `-e`):**

| Variable | Default | Description |
|---|---|---|
| `base_packages` | curl, net-tools, dnsutils… | apt packages installed on all hosts |
| `ssh_config_path` | `/etc/ssh/sshd_config` | SSH daemon config path |
| `reboot_timeout` | `300` | Seconds to wait after reboot |

---

### `provision_base_rhel.yml` — AlmaLinux/Rocky/RHEL baseline

RHEL-family equivalent of `provision_base.yml`. Uses `dnf` and `sshd` (not `ssh`) as the service name.

**Supports:** AlmaLinux 8/9, Rocky Linux 8/9, RHEL 8/9

```bash
ansible-playbook -i inventory/hosts.ini playbooks/provision_base_rhel.yml
ansible-playbook -i inventory/hosts.ini playbooks/provision_base_rhel.yml --limit rhel_servers
```

Includes an `ansible.builtin.assert` pre-flight that fails fast on Debian/Ubuntu hosts.

---

### `provision_docker_node.yml` — Docker CE + Portainer Agent (Debian/Ubuntu)

Step 2 for Docker hosts. Run `provision_base.yml` first.

**What it does:** Docker prerequisites → GPG keyring (modern `/etc/apt/keyrings/` method, no apt-key) → dynamic arch detection (`dpkg --print-architecture`) → Docker CE + Compose plugin → docker group → Portainer Agent container → SSH hardening → reboot

**Requirements:** `community.docker` collection installed on control node

```bash
ansible-galaxy collection install community.docker

ansible-playbook -i inventory/hosts.ini playbooks/provision_docker_node.yml
ansible-playbook -i inventory/hosts.ini playbooks/provision_docker_node.yml --limit docker_host_01
```

**Key vars:**

| Variable | Default | Description |
|---|---|---|
| `docker_users` | `["{{ ansible_user }}"]` | Users added to the docker group |
| `portainer_agent_port` | `9001` | Host port for the Portainer Agent |
| `portainer_agent_tag` | `latest` | Image tag — pin for production |

---

### `provision_podman_node.yml` — Podman + podman-compose (AlmaLinux/Rocky/RHEL)

Step 2 for RHEL-family container hosts. Run `provision_base_rhel.yml` first.

**What it does:** Podman via dnf → podman-compose via pip → bash completion → Podman system socket → `loginctl enable-linger` for rootless containers → SSH hardening → reboot

```bash
ansible-playbook -i inventory/hosts.ini playbooks/provision_podman_node.yml
ansible-playbook -i inventory/hosts.ini playbooks/provision_podman_node.yml -e "podman_user=myuser"
```

**Key vars:**

| Variable | Default | Description |
|---|---|---|
| `podman_user` | `"{{ ansible_user }}"` | User for rootless Podman socket |
| `enable_podman_socket` | `true` | Enable the Podman API socket |

---

## Day-2 Operations

### `maintenance.yml` — apt update/upgrade/cleanup

Routine package maintenance for the Debian/Ubuntu fleet. Supports selective execution via tags and batched host rolling via `serial`.

**Tags:**

| Tag | Tasks |
|---|---|
| `update` | Refresh apt cache + report pending upgrades (read-only) |
| `upgrade` | Apply full `dist-upgrade` |
| `cleanup` | `autoremove` + `autoclean` |
| `reboot_check` | Check `/var/run/reboot-required` and optionally reboot |

```bash
# Full run
ansible-playbook -i inventory/hosts.ini playbooks/maintenance.yml

# Cache refresh only
ansible-playbook -i inventory/hosts.ini playbooks/maintenance.yml --tags update

# Allow auto-reboot if kernel was updated
ansible-playbook -i inventory/hosts.ini playbooks/maintenance.yml -e "reboot_if_needed=true"

# Roll through hosts 3 at a time
ansible-playbook -i inventory/hosts.ini playbooks/maintenance.yml -e "batch_size=3"
```

**Key vars:**

| Variable | Default | Description |
|---|---|---|
| `reboot_if_needed` | `false` | Auto-reboot when `/var/run/reboot-required` exists |
| `apt_cache_max_age` | `3600` | Skip cache refresh if updated within N seconds |
| `batch_size` | `100%` | Hosts per batch (pass via `-e "batch_size=3"`) |

---

### `manage_aliases.yml` — Fleet shell alias deployment

Writes a configurable list of shell aliases to `~/.bash_aliases` on remote hosts. Idempotent — re-running will not duplicate entries.

**What it does:** Touch `~/.bash_aliases` → ensure `.bashrc` sources it → deploy each alias via `lineinfile`

```bash
ansible-playbook -i inventory/hosts.ini playbooks/manage_aliases.yml
ansible-playbook -i inventory/hosts.ini playbooks/manage_aliases.yml --limit docker

# Override the alias list at runtime
ansible-playbook -i inventory/hosts.ini playbooks/manage_aliases.yml \
  -e '{"shell_aliases": [{"name": "myalias", "command": "echo hello", "description": "test"}]}'
```

Default aliases included: `dod` (docker prune all), `dps` (formatted docker ps), `dlogs` (tail + follow container logs)

To customize fleet-wide, override `shell_aliases` in `group_vars/all.yml`.

---

### `nextcloud_maintenance.yml` — Nextcloud post-upgrade tasks

Runs `occ` maintenance commands inside the Nextcloud Docker container after an image update. No `community.docker` required — uses raw `docker exec`.

**Tags:**

| Tag | Tasks |
|---|---|
| `db_checks` | `occ upgrade` → missing indices → BigInt filecache migration |
| `maintenance` | `files:scan-app-data` → `maintenance:repair` → disable AppAPI |
| `health_check` | Curl `/status.php` with retries — fails playbook if unhealthy |

```bash
# Full post-upgrade run
ansible-playbook -i inventory/hosts.ini playbooks/nextcloud_maintenance.yml

# Health check only
ansible-playbook -i inventory/hosts.ini playbooks/nextcloud_maintenance.yml --tags health_check

# Override container name
ansible-playbook -i inventory/hosts.ini playbooks/nextcloud_maintenance.yml -e "nc_container=nextcloud"

# Keep AppAPI enabled
ansible-playbook -i inventory/hosts.ini playbooks/nextcloud_maintenance.yml -e "disable_appapi=false"
```

**Key vars:**

| Variable | Default | Description |
|---|---|---|
| `nc_container` | `nc` | Nextcloud Docker container name |
| `nc_web_user` | `www-data` | User for `occ` commands |
| `disable_appapi` | `true` | Disable AppAPI app after maintenance |
| `health_check_retries` | `3` | Retry count for `/status.php` check |
| `health_check_delay` | `10` | Seconds between retries |
