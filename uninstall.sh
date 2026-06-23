#!/usr/bin/env bash
# FreeLLMAPI uninstaller
# Usage: bash /root/freellmapi-installer/uninstall.sh

set -euo pipefail

INSTALL_DIR="/root/freellmapi"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}"; }
ok()   { echo -e "${GREEN}  ok${NC} $*"; }
warn() { echo -e "${YELLOW}  !!${NC} $*"; }

echo -e "${BOLD}${RED}This will remove FreeLLMAPI completely.${NC}"
read -r -p "Are you sure? [y/N]: " confirm
case "${confirm,,}" in
  y|yes) ;;
  *) echo "Aborted."; exit 0 ;;
esac

step "Stopping pm2 process"
if pm2 list 2>/dev/null | grep -q freellmapi; then
  pm2 delete freellmapi
  pm2 save
  ok "pm2 process removed"
else
  warn "No pm2 process found — skipping"
fi

step "Removing installation directory"
if [[ -d "${INSTALL_DIR}" ]]; then
  rm -rf "${INSTALL_DIR}"
  ok "Removed ${INSTALL_DIR}"
else
  warn "${INSTALL_DIR} not found — already removed?"
fi

echo
echo -e "${BOLD}${GREEN}FreeLLMAPI uninstalled.${NC}"
