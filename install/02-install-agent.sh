#!/usr/bin/env bash
# Installe et enrole un agent Wazuh vers un manager existant.
#
# A executer EN ROOT sur la machine "endpoint" a surveiller.
# Aucune information personnelle codee en dur : MANAGER_IP et AGENT_NAME
# sont fournis par celui qui deploie, via config/deploy.env.
#
# Usage direct :
#   sudo MANAGER_IP=1.2.3.4 AGENT_NAME=endpoint-01 ./02-install-agent.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_cmd curl
require_cmd gpg
require_var MANAGER_IP

AGENT_NAME="${AGENT_NAME:-$(hostname)}"
WAZUH_VERSION="${WAZUH_VERSION:-4.9}"

log_info "Enrolement de l'agent '${AGENT_NAME}' vers le manager ${MANAGER_IP}"

if [ ! -f /usr/share/keyrings/wazuh.gpg ]; then
  log_info "Ajout du depot officiel Wazuh"
  curl -sS https://packages.wazuh.com/key/GPG-KEY-WAZUH | \
    gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
  chmod 644 /usr/share/keyrings/wazuh.gpg
  echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/${WAZUH_VERSION}/apt/ stable main" \
    > /etc/apt/sources.list.d/wazuh.list
  apt-get update -qq
fi

log_info "Installation du paquet wazuh-agent"
WAZUH_MANAGER="${MANAGER_IP}" \
WAZUH_AGENT_NAME="${AGENT_NAME}" \
apt-get install -y wazuh-agent

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

echo
log_info "Agent installe et demarre."
log_info "Verification cote manager :"
log_info "  sudo /var/ossec/bin/manage_agents -l"
log_info "Verification cote agent :"
log_info "  sudo systemctl status wazuh-agent"
