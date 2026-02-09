#!/bin/bash

#===============================================================================
#  🧹 LINUX TREASURE HUNT - Cleanup Script
#  Rimuove tutti i file della caccia al tesoro
#===============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Questo script deve essere eseguito con sudo!${NC}"
   exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo -e "${YELLOW}🧹 Pulizia ambiente Treasure Hunt...${NC}"

# Killa processi phantom
pkill -f "treasure_phantom" 2>/dev/null || true

# Rimuovi directory
rm -rf /opt/treasure_hunt 2>/dev/null || true
rm -rf /var/log/treasure 2>/dev/null || true
rm -rf /tmp/treasure_* 2>/dev/null || true
rm -rf /tmp/extracted 2>/dev/null || true
rm -f /tmp/.phantom_process.pid 2>/dev/null || true
rm -f /tmp/.treasure_phantom_runner.sh 2>/dev/null || true
rm -rf "$REAL_HOME/.treasure_config" 2>/dev/null || true
rm -f /etc/phantom_service.log 2>/dev/null || true

# Rimuovi file password nascosto
find /var/cache -name ".quantum_cache_*" -delete 2>/dev/null || true

echo -e "${GREEN}✅ Pulizia completata!${NC}"
echo ""
echo "Per reinstallare la caccia al tesoro, esegui:"
echo "  sudo ./setup.sh"
