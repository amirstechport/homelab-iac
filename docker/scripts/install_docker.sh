#!/bin/bash
# =============================================================================
# install_docker.sh
# homelab-iac | docker/scripts/install_docker.sh
# =============================================================================
#
# WHAT IT DOES:
#   Installs Docker CE, the Compose plugin, and optionally Portainer Agent
#   on a fresh Debian or Ubuntu server. Use this script for quick manual
#   installs. For fleet deployments, use provision_docker_node.yml instead.
#
#   Steps performed:
#     1. Detects OS and CPU architecture dynamically (amd64 / arm64)
#     2. Installs Docker prerequisites
#     3. Adds the official Docker GPG key using the modern keyring method
#        (/etc/apt/keyrings/) — replaces the deprecated apt-key approach
#     4. Adds the Docker stable apt repository
#     5. Installs Docker CE, CLI, containerd, and the Compose plugin
#     6. Adds the current user to the docker group
#     7. Enables and starts the Docker service
#     8. Verifies the installation
#
# HOW TO USE:
#   chmod +x install_docker.sh
#   ./install_docker.sh
#
#   Install with Portainer Agent (registers node with your Portainer instance):
#   INSTALL_PORTAINER_AGENT=true ./install_docker.sh
#
#   Skip adding user to docker group:
#   SKIP_DOCKER_GROUP=true ./install_docker.sh
#
# REQUIREMENTS:
#   - Debian 11+ or Ubuntu 20.04+
#   - sudo privileges
#   - Internet access to reach download.docker.com
#
# =============================================================================

set -euo pipefail

# ── Configuration (override via environment variables) ────────────────────────
INSTALL_PORTAINER_AGENT="${INSTALL_PORTAINER_AGENT:-false}"
SKIP_DOCKER_GROUP="${SKIP_DOCKER_GROUP:-false}"
PORTAINER_AGENT_PORT="${PORTAINER_AGENT_PORT:-9001}"

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

# ── OS & Architecture Detection ───────────────────────────────────────────────
section "Step 1 — Detecting OS and architecture"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID}"
    OS_NAME="${PRETTY_NAME}"
    OS_CODENAME="${VERSION_CODENAME:-}"
else
    error "Cannot detect OS. /etc/os-release not found."
fi

case "${OS_ID}" in
    ubuntu|debian)
        info "Supported OS: ${OS_NAME}"
        ;;
    *)
        error "Unsupported OS: ${OS_NAME}. This script supports Debian and Ubuntu only."
        ;;
esac

# Use dpkg for reliable arch detection (handles amd64, arm64, armhf correctly)
ARCH=$(dpkg --print-architecture)
info "Architecture: ${ARCH}"

if [ -z "${OS_CODENAME}" ]; then
    OS_CODENAME=$(lsb_release -cs 2>/dev/null || error "Cannot determine OS codename. Install lsb-release.")
fi
info "Codename: ${OS_CODENAME}"

# ── Prerequisites ─────────────────────────────────────────────────────────────
section "Step 2 — Installing prerequisites"

info "Updating apt cache..."
sudo apt update -q

info "Installing prerequisite packages..."
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# ── Docker GPG Key (modern keyring method) ────────────────────────────────────
section "Step 3 — Adding Docker GPG key"

KEYRING_DIR="/etc/apt/keyrings"
KEYRING_PATH="${KEYRING_DIR}/docker.asc"

sudo install -m 0755 -d "${KEYRING_DIR}"

if [ -f "${KEYRING_PATH}" ]; then
    warn "Docker GPG key already exists at ${KEYRING_PATH} — skipping download."
else
    info "Downloading Docker GPG key for ${OS_ID}..."
    sudo curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" \
        -o "${KEYRING_PATH}"
    sudo chmod a+r "${KEYRING_PATH}"
    info "Key saved to ${KEYRING_PATH}"
fi

# ── Docker apt Repository ─────────────────────────────────────────────────────
section "Step 4 — Adding Docker apt repository"

SOURCES_FILE="/etc/apt/sources.list.d/docker.list"

if [ -f "${SOURCES_FILE}" ]; then
    warn "Docker repository already configured at ${SOURCES_FILE} — skipping."
else
    echo \
        "deb [arch=${ARCH} signed-by=${KEYRING_PATH}] \
https://download.docker.com/linux/${OS_ID} ${OS_CODENAME} stable" | \
        sudo tee "${SOURCES_FILE}" > /dev/null
    info "Repository added: ${SOURCES_FILE}"
fi

info "Refreshing apt cache to include Docker repository..."
sudo apt update -q

# ── Install Docker ────────────────────────────────────────────────────────────
section "Step 5 — Installing Docker CE"

info "Installing Docker CE and Compose plugin..."
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose-plugin

info "Enabling and starting Docker service..."
sudo systemctl enable --now docker

# ── Docker Group ──────────────────────────────────────────────────────────────
section "Step 6 — Configuring docker group"

if [ "${SKIP_DOCKER_GROUP}" = "true" ]; then
    warn "Skipping docker group addition (SKIP_DOCKER_GROUP=true)."
else
    info "Adding ${USER} to the docker group..."
    sudo usermod -aG docker "${USER}"
    warn "Group change requires a new login session to take effect."
    warn "Log out and back in, then run: docker ps"
fi

# ── Verify Installation ───────────────────────────────────────────────────────
section "Step 7 — Verifying installation"

DOCKER_VER=$(sudo docker --version)
COMPOSE_VER=$(docker compose version)
info "Installed: ${DOCKER_VER}"
info "Installed: ${COMPOSE_VER}"

# ── Portainer Agent (optional) ────────────────────────────────────────────────
if [ "${INSTALL_PORTAINER_AGENT}" = "true" ]; then
    section "Step 8 — Deploying Portainer Agent (optional)"

    if sudo docker ps -a --format '{{.Names}}' | grep -q "^portainer_agent$"; then
        warn "Portainer Agent container already exists — skipping."
    else
        info "Deploying Portainer Agent on port ${PORTAINER_AGENT_PORT}..."
        sudo docker run -d \
            --name portainer_agent \
            --restart=always \
            -p "${PORTAINER_AGENT_PORT}:9001" \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /var/lib/docker/volumes:/var/lib/docker/volumes \
            portainer/agent:latest
        info "Portainer Agent running on port ${PORTAINER_AGENT_PORT}."
        info "Add this node in Portainer UI → Environments → Add Environment → Agent."
    fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
section "Installation Complete"

echo ""
echo -e "${GREEN}Docker is installed and running.${NC}"
echo ""
echo "Quick commands:"
echo "  docker ps                    # List running containers"
echo "  docker compose up -d         # Start a compose stack"
echo "  docker system df             # Show disk usage"
echo "  docker system prune -af      # Remove all unused resources"
echo ""
if [ "${SKIP_DOCKER_GROUP}" != "true" ]; then
    echo -e "${YELLOW}Remember: log out and back in to run docker without sudo.${NC}"
    echo ""
fi
