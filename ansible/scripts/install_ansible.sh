#!/bin/bash
# =============================================================================
# install_ansible.sh
# homelab-iac | ansible/scripts/install_ansible.sh
# =============================================================================
#
# WHAT IT DOES:
#   Bootstraps a fresh Debian or Ubuntu VM into a fully operational Ansible
#   control node. Run this once on your dedicated management VM before
#   using any playbooks in this repository.
#
#   Steps performed:
#     1. Detects OS (Debian / Ubuntu) — exits cleanly on unsupported systems
#     2. Updates the apt package cache
#     3. Installs Python 3, pip, git, and curl
#     4. Installs Ansible via pip (always gets the latest stable release)
#     5. Installs required Ansible Galaxy collections from requirements.yml
#     6. Generates a dedicated ed25519 SSH key for Ansible (if not present)
#     7. Verifies the installation and prints a summary
#
# HOW TO USE:
#   chmod +x install_ansible.sh
#   ./install_ansible.sh
#
#   After running, follow the printed instructions to:
#     - Copy ansible/inventory/inventory.sample.ini to ansible/inventory/hosts.ini
#     - Distribute your SSH public key to target hosts
#     - Run: ansible all -i ansible/inventory/hosts.ini -m ping
#
# REQUIREMENTS:
#   - Debian 11+ or Ubuntu 20.04+
#   - sudo privileges
#   - Internet access to reach PyPI and GitHub
#
# =============================================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${BLUE}──────────────────────────────────────────${NC}"; echo -e "${BLUE}$*${NC}"; echo -e "${BLUE}──────────────────────────────────────────${NC}"; }

# ── OS Detection ──────────────────────────────────────────────────────────────
section "Step 1 — Detecting OS"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID}"
    OS_NAME="${PRETTY_NAME}"
else
    error "Cannot detect OS. /etc/os-release not found."
fi

case "${OS_ID}" in
    ubuntu|debian)
        info "Supported OS detected: ${OS_NAME}"
        ;;
    *)
        error "Unsupported OS: ${OS_NAME}. This script supports Debian and Ubuntu only."
        ;;
esac

# ── Package Installation ──────────────────────────────────────────────────────
section "Step 2 — Installing system dependencies"

info "Updating apt package cache..."
sudo apt update -q

info "Installing Python 3, pip, git, curl..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    sshpass   # Required for ansible's initial password-based key distribution

# ── Ansible via pip ───────────────────────────────────────────────────────────
section "Step 3 — Installing Ansible"

info "Installing Ansible via pip (latest stable)..."
pip3 install --user ansible

# Ensure pip-installed binaries are in PATH for this session
export PATH="${HOME}/.local/bin:${PATH}"

# Persist PATH addition to shell profile if not already present
PROFILE_LINE='export PATH="${HOME}/.local/bin:${PATH}"'
if ! grep -qF '.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
    echo "${PROFILE_LINE}" >> "${HOME}/.bashrc"
    info "Added ~/.local/bin to PATH in ~/.bashrc"
fi

info "Verifying Ansible installation..."
if ansible --version > /dev/null 2>&1; then
    ANSIBLE_VER=$(ansible --version | head -1)
    info "Installed: ${ANSIBLE_VER}"
else
    error "Ansible installation failed. Check pip output above."
fi

# ── Ansible Galaxy Collections ────────────────────────────────────────────────
section "Step 4 — Installing Ansible Galaxy collections"

REQUIREMENTS_FILE="$(dirname "$0")/../requirements.yml"

if [ -f "${REQUIREMENTS_FILE}" ]; then
    info "Found requirements.yml — installing collections..."
    ansible-galaxy collection install -r "${REQUIREMENTS_FILE}"
    info "Collections installed successfully."
else
    warn "requirements.yml not found at ${REQUIREMENTS_FILE}"
    warn "Run manually after cloning: ansible-galaxy collection install -r ansible/requirements.yml"
fi

# ── SSH Key Generation ────────────────────────────────────────────────────────
section "Step 5 — Setting up Ansible SSH key"

SSH_KEY="${HOME}/.ssh/ansible_ed25519"

if [ -f "${SSH_KEY}" ]; then
    warn "SSH key already exists at ${SSH_KEY} — skipping generation."
else
    info "Generating ed25519 SSH key for Ansible..."
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    ssh-keygen -t ed25519 -C "ansible-homelab-$(hostname)" -f "${SSH_KEY}" -N ""
    info "Key pair created:"
    info "  Private: ${SSH_KEY}"
    info "  Public:  ${SSH_KEY}.pub"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
section "Installation Complete"

echo ""
echo -e "${GREEN}Ansible control node is ready.${NC}"
echo ""
echo "Next steps:"
echo "  1. Clone the repository (if not already done):"
echo "       git clone git@github.com:YOUR_USERNAME/homelab-iac.git ~/homelab-iac"
echo ""
echo "  2. Copy the inventory template:"
echo "       cp ansible/inventory/inventory.sample.ini ansible/inventory/hosts.ini"
echo "       nano ansible/inventory/hosts.ini   # Fill in your real IPs"
echo ""
echo "  3. Distribute your SSH public key to each target host:"
echo "       ssh-copy-id -i ${SSH_KEY}.pub YOUR_USER@TARGET_IP"
echo ""
echo "  4. Test connectivity:"
echo "       ansible all -i ansible/inventory/hosts.ini -m ping"
echo ""
echo "  5. Run the base provisioning playbook:"
echo "       ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/provision_base.yml"
echo ""
echo -e "Public key (add to target hosts' authorized_keys):"
echo -e "${YELLOW}$(cat "${SSH_KEY}.pub" 2>/dev/null || echo '(key not found)')${NC}"
echo ""
