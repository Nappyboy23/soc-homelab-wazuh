#!/usr/bin/env bash
# Orchestre le deploiement complet (manager + agent) depuis VOTRE poste,
# via SSH vers vos deux machines. Ne contient et ne recoit aucune info
# personnelle : tout vient de config/deploy.env (que vous remplissez et
# qui n'est jamais commite - voir .gitignore).
#
# Prerequis :
#   - 2 machines Ubuntu 22.04/24.04 deja provisionnees, joignables en SSH
#     avec un utilisateur sudo (OCI, AWS, VirtualBox, bare metal... peu importe)
#   - Les ports necessaires ouverts au niveau du firewall cloud
#     (22, 443, 1514, 1515, 55000 depuis votre IP / entre les deux machines)
#
# Usage :
#   cp config/deploy.env.example config/deploy.env
#   $EDITOR config/deploy.env          # renseignez VOS informations
#   ./deploy.sh
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ROOT_DIR}/config/deploy.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "[ERROR] ${ENV_FILE} introuvable."
  echo "        Copiez config/deploy.env.example vers config/deploy.env et completez-le."
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

for v in MANAGER_HOST MANAGER_SSH_USER MANAGER_SSH_KEY AGENT_HOST AGENT_SSH_USER AGENT_SSH_KEY ALLOWED_ADMIN_CIDR; do
  if [ -z "${!v:-}" ]; then
    echo "[ERROR] Variable manquante dans deploy.env : $v"
    exit 1
  fi
done

WAZUH_VERSION="${WAZUH_VERSION:-4.9}"
AGENT_NAME="${AGENT_NAME:-endpoint-01}"
CONFIGURE_FIREWALL="${CONFIGURE_FIREWALL:-true}"
MANAGER_SSH_PORT="${MANAGER_SSH_PORT:-22}"
AGENT_SSH_PORT="${AGENT_SSH_PORT:-22}"

remote_copy() {
  local host="$1" user="$2" key="$3" port="$4" local_path="$5" remote_path="$6"
  scp -r -i "$key" -P "$port" -o StrictHostKeyChecking=accept-new "$local_path" "${user}@${host}:${remote_path}"
}

remote_run() {
  local host="$1" user="$2" key="$3" port="$4" cmd="$5"
  ssh -i "$key" -p "$port" -o StrictHostKeyChecking=accept-new "${user}@${host}" "$cmd"
}

echo "=== 1/4 - Copie des scripts vers le manager (${MANAGER_HOST}) ==="
remote_run  "$MANAGER_HOST" "$MANAGER_SSH_USER" "$MANAGER_SSH_KEY" "$MANAGER_SSH_PORT" \
  "rm -rf /tmp/wazuh-deploy && mkdir -p /tmp/wazuh-deploy"
remote_copy "$MANAGER_HOST" "$MANAGER_SSH_USER" "$MANAGER_SSH_KEY" "$MANAGER_SSH_PORT" \
  "${ROOT_DIR}/install" "/tmp/wazuh-deploy/"

echo "=== 2/4 - Installation Wazuh manager + indexer + dashboard ==="
remote_run "$MANAGER_HOST" "$MANAGER_SSH_USER" "$MANAGER_SSH_KEY" "$MANAGER_SSH_PORT" \
  "sudo WAZUH_VERSION='${WAZUH_VERSION}' bash /tmp/wazuh-deploy/install/01-install-manager.sh"

if [ "$CONFIGURE_FIREWALL" = "true" ]; then
  remote_run "$MANAGER_HOST" "$MANAGER_SSH_USER" "$MANAGER_SSH_KEY" "$MANAGER_SSH_PORT" \
    "sudo ROLE=manager ALLOWED_ADMIN_CIDR='${ALLOWED_ADMIN_CIDR}' bash /tmp/wazuh-deploy/install/03-configure-firewall.sh"
fi

echo "=== 3/4 - Copie des scripts vers l'agent (${AGENT_HOST}) et installation ==="
remote_run  "$AGENT_HOST" "$AGENT_SSH_USER" "$AGENT_SSH_KEY" "$AGENT_SSH_PORT" \
  "rm -rf /tmp/wazuh-deploy && mkdir -p /tmp/wazuh-deploy"
remote_copy "$AGENT_HOST" "$AGENT_SSH_USER" "$AGENT_SSH_KEY" "$AGENT_SSH_PORT" \
  "${ROOT_DIR}/install" "/tmp/wazuh-deploy/"
remote_run "$AGENT_HOST" "$AGENT_SSH_USER" "$AGENT_SSH_KEY" "$AGENT_SSH_PORT" \
  "sudo MANAGER_IP='${MANAGER_HOST}' AGENT_NAME='${AGENT_NAME}' WAZUH_VERSION='${WAZUH_VERSION}' bash /tmp/wazuh-deploy/install/02-install-agent.sh"

if [ "$CONFIGURE_FIREWALL" = "true" ]; then
  remote_run "$AGENT_HOST" "$AGENT_SSH_USER" "$AGENT_SSH_KEY" "$AGENT_SSH_PORT" \
    "sudo ROLE=agent ALLOWED_ADMIN_CIDR='${ALLOWED_ADMIN_CIDR}' bash /tmp/wazuh-deploy/install/03-configure-firewall.sh"
fi

echo
echo "=== 4/4 - Deploiement termine ==="
echo "Dashboard : https://${MANAGER_HOST}/"
echo
echo "Identifiants generes automatiquement par l'installeur Wazuh (a recuperer UNE FOIS) :"
echo "  ssh -i ${MANAGER_SSH_KEY} -p ${MANAGER_SSH_PORT} ${MANAGER_SSH_USER}@${MANAGER_HOST} \\"
echo "    'sudo tar -xO -f /root/wazuh-install/wazuh-install-files.tar wazuh-passwords.txt'"
echo
echo "Verifiez que l'agent est bien enregistre :"
echo "  ssh -i ${MANAGER_SSH_KEY} -p ${MANAGER_SSH_PORT} ${MANAGER_SSH_USER}@${MANAGER_HOST} \\"
echo "    'sudo /var/ossec/bin/manage_agents -l'"
