#!/usr/bin/env bash
# FreeLLMAPI updater
# Usage: bash /root/freellmapi-installer/update.sh

set -euo pipefail

INSTALL_DIR="/root/freellmapi"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}"; }
info() { echo -e "${CYAN}  ->${NC} $*"; }
ok()   { echo -e "${GREEN}  ok${NC} $*"; }
err()  { echo -e "${RED}  xx${NC} $*" >&2; }

if [[ ! -d "${INSTALL_DIR}" ]]; then
  err "FreeLLMAPI not found at ${INSTALL_DIR}. Run install.sh first."
  exit 1
fi

step "Pulling latest changes"
cd "${INSTALL_DIR}"
git pull
ok "Code updated"

step "Installing dependencies"
npm install --prefer-offline 2>&1 | tail -3
ok "Dependencies ready"

step "Building"
npm run build 2>&1 | tail -5
ok "Build complete"

step "Restarting service"
pm2 restart freellmapi
ok "FreeLLMAPI restarted"

echo
echo -e "${BOLD}${GREEN}Update complete!${NC}"
pm2 status freellmapi
