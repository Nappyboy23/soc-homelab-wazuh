#!/usr/bin/env bash
# Installe Wazuh Manager + Indexer + Dashboard (mode "all-in-one" mono-noeud)
# via l'installeur officiel Wazuh (packages.wazuh.com).
#
# A executer EN ROOT sur la machine destinee a devenir le "manager".
# N'importe qui peut lancer ce script : aucune information personnelle
# n'est codee en dur, tout vient des variables d'environnement ci-dessous.
#
# Usage direct :
#   sudo WAZUH_VERSION=4.9 ./01-install-manager.sh
#
# Generalement appele automatiquement par ../deploy.sh depuis votre poste.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_cmd curl

WAZUH_VERSION="${WAZUH_VERSION:-4.9}"
WORKDIR="/root/wazuh-install"

log_info "Installation Wazuh ${WAZUH_VERSION} (manager + indexer + dashboard)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [ ! -f wazuh-install.sh ]; then
  log_info "Telechargement de l'installeur officiel Wazuh..."
  curl -sSO "https://packages.wazuh.com/${WAZUH_VERSION}/wazuh-install.sh"
fi

log_info "Lancement de l'installation all-in-one (peut prendre 10-15 min)..."
bash wazuh-install.sh -a

echo
log_info "Installation terminee."
log_info "Les identifiants generes automatiquement par l'installeur se trouvent dans :"
log_info "  ${WORKDIR}/wazuh-install-files.tar"
echo
log_info "Pour les recuperer UNE SEULE FOIS puis les stocker en lieu sur (ex: gestionnaire de mots de passe) :"
log_info "  sudo tar -xO -f ${WORKDIR}/wazuh-install-files.tar wazuh-passwords.txt"
echo
log_warn "Ne copiez JAMAIS ce fichier dans un depot Git ni ailleurs en clair."
log_warn "Envisagez de le supprimer du serveur une fois les identifiants recuperes :"
log_warn "  sudo rm ${WORKDIR}/wazuh-install-files.tar"
