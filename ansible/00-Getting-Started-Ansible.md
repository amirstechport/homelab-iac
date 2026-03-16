# 00 — Getting Started with Ansible

**Repository:** `homelab-iac`
**Applies to:** All playbooks in `ansible/playbooks/`

---

## What This Guide Covers

This guide walks you through setting up an Ansible **control node** from scratch,
cloning this repository, configuring SSH key authentication, and running your
first connectivity test against your infrastructure inventory.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| A Linux control node | A dedicated VM or LXC container is recommended (Debian 12 / Ubuntu 22.04+) |
| SSH access to target hosts | Covered in Step 3 below |
| Python 3.8+ on all target hosts | Usually pre-installed on modern Debian/Ubuntu |
| `sudo` privileges on the control node | For package installation |

> **Recommended:** Run Ansible from a dedicated management VM — not your laptop.
> This repo is designed around an always-on control node (e.g., a Proxmox LXC).

---

## Step 1 — Install Ansible on the Control Node

SSH into your control node and run the following:

```bash
# Update package index
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip git curl

# Install Ansible via pip (always gets the latest stable release)
pip3 install --user ansible

# Verify installation
ansible --version
```

Expected output:
```
ansible [core 2.x.x]
  python version = 3.x.x
  ...
```

> **Alternative (distro package):** `sudo apt install ansible` works but may
> install an older version. The `pip` method is recommended for homelabs.

---

## Step 2 — Clone This Repository

```bash
# Clone via SSH (recommended — requires GitHub SSH key configured)
git clone git@github.com:YOUR_USERNAME/homelab-iac.git ~/homelab-iac

# Or clone via HTTPS
git clone https://github.com/YOUR_USERNAME/homelab-iac.git ~/homelab-iac

cd ~/homelab-iac
```

---

## Step 3 — Generate and Distribute SSH Keys

Ansible connects to target hosts via SSH. Each target host needs your control
node's **public key** in its `~/.ssh/authorized_keys` file.

### 3a. Generate a dedicated Ansible SSH key pair

```bash
# Run this on your CONTROL NODE
ssh-keygen -t ed25519 -C "ansible-homelab" -f ~/.ssh/ansible_ed25519
```

This creates:
- `~/.ssh/ansible_ed25519` — **private key** (never share this)
- `~/.ssh/ansible_ed25519.pub` — **public key** (copy this to target hosts)

### 3b. Copy the public key to each target host

```bash
# Replace YOUR_USER and TARGET_IP with your values
ssh-copy-id -i ~/.ssh/ansible_ed25519.pub YOUR_USER@TARGET_IP
```

Repeat for every host in your inventory.

### 3c. Verify SSH works without a password prompt

```bash
ssh -i ~/.ssh/ansible_ed25519 YOUR_USER@TARGET_IP
```

If you connect without being asked for a password, you are ready.

---

## Step 4 — Configure Your Inventory

```bash
# Copy the sample inventory to a working file
cp ansible/inventory/inventory.sample.ini ansible/inventory/hosts.ini
```

Open `ansible/inventory/hosts.ini` and replace the placeholder values:

| Placeholder | Replace With |
|---|---|
| `10.0.0.X` | Your actual host IPs |
| `your_user` | The SSH user on each target host |
| `~/.ssh/ansible_ed25519` | Path to your private key (if different) |

> **Important:** `hosts.ini` is listed in `.gitignore` — it will never be
> committed. The `inventory.sample.ini` is what lives in version control.

---

## Step 5 — Run a Connectivity Test

Before running any playbook, verify Ansible can reach all your hosts:

```bash
# Ping all hosts in the inventory
ansible all -i ansible/inventory/hosts.ini -m ping

# Ping a specific group only
ansible lan -i ansible/inventory/hosts.ini -m ping
```

A successful response looks like:
```
server_01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

If you see `UNREACHABLE` errors, check:
- The IP is correct in `hosts.ini`
- SSH key was copied to that host (Step 3b)
- No firewall is blocking port 22 between control node and target

---

## Step 6 — Run Your First Playbook

```bash
# Syntax check before running (always do this first)
ansible-playbook -i ansible/inventory/hosts.ini \
  ansible/playbooks/provision_base.yml --syntax-check

# Dry run — shows what WOULD change without making changes
ansible-playbook -i ansible/inventory/hosts.ini \
  ansible/playbooks/provision_base.yml --check

# Full run against all hosts
ansible-playbook -i ansible/inventory/hosts.ini \
  ansible/playbooks/provision_base.yml

# Target a single host only
ansible-playbook -i ansible/inventory/hosts.ini \
  ansible/playbooks/provision_base.yml --limit server_01

# Target a specific group
ansible-playbook -i ansible/inventory/hosts.ini \
  ansible/playbooks/provision_base.yml --limit lan
```

---

## Directory Structure Reference

```
ansible/
├── inventory/
│   ├── inventory.sample.ini   # Template — edit and copy to hosts.ini
│   └── hosts.ini              # Your real inventory (gitignored)
├── playbooks/
│   ├── provision_base.yml     # Step 1: Baseline harden any Debian/Ubuntu VM
│   ├── provision_ubuntu_docker.yml
│   ├── provision_debian_docker.yml
│   ├── portainer_update.yml
│   └── maintenance.yml
└── group_vars/
    └── all.yml                # Shared variables (non-secret)
```

---

## Security Notes

- Never commit `hosts.ini` — it contains your real IPs
- Never commit SSH private keys
- Use `ansible-vault` to encrypt any file containing secrets:
  ```bash
  ansible-vault encrypt ansible/group_vars/vault.yml
  ```
- The playbooks in this repo use `{{ variable }}` syntax throughout —
  no credentials are hardcoded

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `UNREACHABLE` on ping | Verify SSH key is on the target, IP is correct |
| `sudo: command not found` | Install sudo: `apt install sudo` on target |
| `Python not found` | Set `ansible_python_interpreter=/usr/bin/python3` in inventory |
| Permission denied (publickey) | Run `ssh-copy-id` again for that host |
| Playbook fails mid-run | Add `-v` flag for verbose output: `ansible-playbook ... -v` |
