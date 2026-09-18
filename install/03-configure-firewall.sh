#!/usr/bin/env bash
# Restreint les ports exposes selon le role (manager ou agent).
# Complementaire (pas un substitut) du firewall cloud (OCI Security Lists,
# AWS Security Groups, etc.) qui doit etre configure separement.
#
# Usage :
#   sudo ROLE=manager ALLOWED_ADMIN_CIDR=203.0.113.10/32 ./03-configure-firewall.sh
#   sudo ROLE=agent   ALLOWED_ADMIN_CIDR=203.0.113.10/32 ./03-configure-firewall.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_var ROLE
require_var ALLOWED_ADMIN_CIDR

if [ "$ROLE" != "manager" ] && [ "$ROLE" != "agent" ]; then
  die "ROLE doit valoir 'manager' ou 'agent' (recu: ${ROLE})"
fi

if command -v ufw >/dev/null 2>&1; then
  log_info "Configuration via ufw (role=${ROLE})"
  ufw --force reset >/dev/null
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow from "$ALLOWED_ADMIN_CIDR" to any port 22 proto tcp comment 'SSH admin'

  if [ "$ROLE" = "manager" ]; then
    ufw allow from "$ALLOWED_ADMIN_CIDR" to any port 443 proto tcp comment 'Wazuh dashboard'
    ufw allow 1514/tcp comment 'Wazuh agent events'
    ufw allow 1514/udp comment 'Wazuh agent events'
    ufw allow 1515/tcp comment 'Wazuh agent enrollment'
    ufw allow from "$ALLOWED_ADMIN_CIDR" to any port 55000 proto tcp comment 'Wazuh API'
  fi

  ufw --force enable
  log_info "Regles ufw actives :"
  ufw status verbose
else
  log_warn "ufw indisponible, utilisation d'iptables brut (non persistant sans iptables-persistent)."
  iptables -P INPUT DROP
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -p tcp -s "$ALLOWED_ADMIN_CIDR" --dport 22 -j ACCEPT

  if [ "$ROLE" = "manager" ]; then
    iptables -A INPUT -p tcp -s "$ALLOWED_ADMIN_CIDR" --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp --dport 1514 -j ACCEPT
    iptables -A INPUT -p udp --dport 1514 -j ACCEPT
    iptables -A INPUT -p tcp --dport 1515 -j ACCEPT
    iptables -A INPUT -p tcp -s "$ALLOWED_ADMIN_CIDR" --dport 55000 -j ACCEPT
  fi
  log_info "Regles iptables appliquees."
  log_warn "Installez iptables-persistent pour les conserver au redemarrage :"
  log_warn "  sudo apt-get install -y iptables-persistent && sudo netfilter-persistent save"
fi
