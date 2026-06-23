#!/usr/bin/env bash
# FreeLLMAPI installer for Ubuntu
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/ali934h/freellmapi-installer/main/install.sh)

set -euo pipefail

FREELLMAPI_REPO="https://github.com/tashfeenahmed/freellmapi.git"
INSTALL_DIR="/root/freellmapi"
NODE_VERSION="20"
DEFAULT_PORT="3001"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}"; }
info() { echo -e "${CYAN}  ->${NC} $*"; }
warn() { echo -e "${YELLOW}  !!${NC} $*"; }
ok()   { echo -e "${GREEN}  ok${NC} $*"; }
err()  { echo -e "${RED}  xx${NC} $*" >&2; }

# -- guards ------------------------------------------------------------------

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "This installer must be run as root."
    exit 1
  fi
}

require_ubuntu() {
  if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
    err "This installer supports Ubuntu only."
    exit 1
  fi
}

# -- banner ------------------------------------------------------------------

banner() {
  echo
  echo -e "${BOLD}${CYAN}========================================${NC}"
  echo -e "${BOLD}${CYAN}       FreeLLMAPI Installer             ${NC}"
  echo -e "${BOLD}${CYAN}========================================${NC}"
  echo -e "${BOLD} Stacks 16 free LLM providers behind one endpoint${NC}"
  echo -e "${BOLD} Source:${NC}      ${FREELLMAPI_REPO}"
  echo -e "${BOLD} Install dir:${NC} ${INSTALL_DIR}"
  echo
}

# -- port detection ----------------------------------------------------------

BLOCKED_PORTS=(80 443 22 1080 2053 2083 2087 2096 8443)

is_blocked_port() {
  local p="$1"
  for bp in "${BLOCKED_PORTS[@]}"; do
    [[ "$p" == "$bp" ]] && return 0
  done
  return 1
}

is_port_in_use() {
  ss -tlnp 2>/dev/null | grep -q ":$1 " && return 0
  return 1
}

find_free_port() {
  local port="${DEFAULT_PORT}"
  while is_port_in_use "${port}" || is_blocked_port "${port}"; do
    port=$((port + 1))
  done
  echo "${port}"
}

prompt_port() {
  local suggested
  suggested=$(find_free_port)

  if [[ "${suggested}" != "${DEFAULT_PORT}" ]]; then
    warn "Port ${DEFAULT_PORT} is already in use. Suggested next free port: ${suggested}"
  else
    info "Suggested port: ${suggested} (free)"
  fi

  local value=""
  while true; do
    read -r -p "$(echo -e "Port to listen on [${suggested}]: ")" value
    value="${value:-${suggested}}"

    if [[ ! "${value}" =~ ^[0-9]+$ ]] || (( value < 1024 || value > 65535 )); then
      err "Port must be a number between 1024 and 65535."
      continue
    fi
    if is_blocked_port "${value}"; then
      err "Port ${value} is reserved. Choose another."
      continue
    fi
    if is_port_in_use "${value}"; then
      err "Port ${value} is already in use. Choose another."
      continue
    fi
    echo "${value}"
    return
  done
}

# -- system deps -------------------------------------------------------------

install_system_deps() {
  step "Installing system dependencies"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y

  if ! command -v git >/dev/null 2>&1; then
    apt-get install -y git
  fi
  ok "git ready"

  if ! command -v curl >/dev/null 2>&1; then
    apt-get install -y curl
  fi
  ok "curl ready"
}

# -- Node.js -----------------------------------------------------------------

install_node() {
  step "Checking Node.js"

  if command -v node >/dev/null 2>&1; then
    local current_major
    current_major=$(node -e 'process.stdout.write(process.versions.node.split(".")[0])')
    if (( current_major >= NODE_VERSION )); then
      ok "Node.js ${current_major} already installed — skipping"
      return
    fi
    warn "Node.js ${current_major} found but need >= ${NODE_VERSION}. Upgrading..."
  fi

  info "Installing Node.js ${NODE_VERSION}.x via NodeSource"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
  apt-get install -y nodejs
  ok "Node.js $(node --version)"
}

# -- pm2 ---------------------------------------------------------------------

install_pm2() {
  step "Checking pm2"
  if command -v pm2 >/dev/null 2>&1; then
    ok "pm2 already installed — skipping"
    return
  fi
  info "Installing pm2 globally"
  npm install -g pm2
  ok "pm2 $(pm2 --version)"
}

# -- cleanup -----------------------------------------------------------------

cleanup_existing() {
  step "Cleaning up any previous installation"

  if pm2 list 2>/dev/null | grep -q freellmapi; then
    pm2 delete freellmapi 2>/dev/null || true
    ok "Stopped existing pm2 process"
  fi

  if [[ -d "${INSTALL_DIR}" ]]; then
    rm -rf "${INSTALL_DIR}"
    ok "Removed ${INSTALL_DIR}"
  fi
}

# -- clone -------------------------------------------------------------------

clone_repo() {
  step "Cloning FreeLLMAPI repository"
  git clone --depth 1 "${FREELLMAPI_REPO}" "${INSTALL_DIR}"
  ok "Cloned to ${INSTALL_DIR}"
}

# -- configure ---------------------------------------------------------------

configure() {
  step "Configuring"

  PORT=$(prompt_port)

  local enc_key
  enc_key=$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')

  printf "ENCRYPTION_KEY=%s\nPORT=%s\n" "${enc_key}" "${PORT}" > "${INSTALL_DIR}/.env"
  chmod 600 "${INSTALL_DIR}/.env"
  ok ".env written (chmod 600) — port: ${PORT}"
}

# -- build -------------------------------------------------------------------

build() {
  step "Installing npm dependencies and building"
  cd "${INSTALL_DIR}"
  npm install --prefer-offline 2>&1 | tail -3
  npm run build 2>&1 | tail -5
  ok "Build complete"
}

# -- start -------------------------------------------------------------------

start_service() {
  step "Starting FreeLLMAPI with pm2"
  cd "${INSTALL_DIR}"
  pm2 start server/dist/index.js --name freellmapi
  pm2 save
  pm2 startup systemd -u root --hp /root 2>/dev/null | tail -1 | bash || true
  ok "FreeLLMAPI running under pm2"
}

# -- success -----------------------------------------------------------------

success_message() {
  local ip
  ip=$(curl -fsSL https://ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

  echo
  echo -e "${BOLD}${GREEN}========================================${NC}"
  echo -e "${BOLD}${GREEN}     FreeLLMAPI is ready!               ${NC}"
  echo -e "${BOLD}${GREEN}========================================${NC}"
  echo -e "  Dashboard   : http://${ip}:${PORT}"
  echo -e "  API endpoint: http://${ip}:${PORT}/v1"
  echo
  echo -e "${BOLD}Next steps:${NC}"
  echo -e "  1. Open the dashboard and create your admin account"
  echo -e "  2. Go to Keys page and add your free provider API keys"
  echo -e "  3. Reorder the Fallback Chain to your preference"
  echo -e "  4. Copy your unified API key from the Keys page"
  echo
  echo -e "${BOLD}Useful commands:${NC}"
  echo -e "  pm2 status                 # check service status"
  echo -e "  pm2 logs freellmapi        # view logs"
  echo -e "  pm2 restart freellmapi     # restart service"
  echo
}

# -- main --------------------------------------------------------------------

main() {
  require_root
  require_ubuntu
  banner
  install_system_deps
  install_node
  install_pm2
  cleanup_existing
  clone_repo
  configure
  build
  start_service
  success_message
}

main "$@"
