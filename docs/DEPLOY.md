# Guide de déploiement automatisé

Ce guide explique comment déployer ce lab Wazuh (Manager + Indexer + Dashboard
sur une machine, Agent sur une autre) **de façon automatique et reproductible**,
avec vos propres informations — aucune info du dépôt d'origine n'est réutilisée.

## Ce que ça automatise (et ce que ça n'automatise pas)

- ✅ Installation de Wazuh (manager/indexer/dashboard all-in-one + agent) via
  l'installeur officiel Wazuh.
- ✅ Enrôlement automatique de l'agent auprès du manager.
- ✅ Restriction des ports côté OS (ufw/iptables) selon vos règles.
- ❌ La création des machines elles-mêmes (OCI, AWS, VirtualBox...) — vous
  devez avoir 2 VM Ubuntu 22.04/24.04 déjà prêtes, joignables en SSH avec un
  utilisateur sudo.
- ❌ Le firewall **cloud** (ex: OCI Security Lists / NSG, AWS Security
  Groups). Il reste spécifique à votre fournisseur et doit autoriser les
  mêmes ports que `install/03-configure-firewall.sh` configure côté OS :
  `22`, `443`, `1514/tcp+udp`, `1515/tcp`, `55000/tcp`.

## Prérequis sur votre poste (celui qui lance le déploiement)

- `bash`, `ssh`, `scp` (déjà présents sur Linux/macOS ; sous Windows, utilisez
  WSL ou Git Bash)
- Une clé SSH valide pour chacune des deux machines

## Étapes

1. **Cloner le dépôt et récupérer les scripts**
   ```bash
   git clone https://github.com/Nappyboy23/soc-homelab-wazuh.git
   cd soc-homelab-wazuh
   ```

2. **Créer votre fichier de configuration personnel**
   ```bash
   cp config/deploy.env.example config/deploy.env
   ```
   Ce fichier est listé dans `.gitignore` : il ne sera **jamais** commité.

3. **Remplir `config/deploy.env` avec vos informations**
   - IP des deux machines, utilisateur SSH, chemin vers vos clés privées
   - Votre IP publique en `/32` pour `ALLOWED_ADMIN_CIDR` (récupérable via
     `curl ifconfig.me`)

4. **Ouvrir les ports nécessaires côté cloud** (OCI Security List, AWS SG...)
   depuis `ALLOWED_ADMIN_CIDR` pour `22`/`443`/`55000`, et entre les deux
   machines pour `1514`/`1515`.

5. **Lancer le déploiement**
   ```bash
   ./deploy.sh
   ```
   Cela installe le manager, configure son pare-feu local, installe et
   enrôle l'agent, puis configure son pare-feu local. Compter 10-15 minutes.

6. **Récupérer les identifiants du dashboard**
   Le script affiche à la fin la commande exacte pour les extraire du
   manager (ils sont générés aléatoirement par l'installeur officiel Wazuh,
   jamais choisis ou transmis par ce projet) :
   ```bash
   ssh -i <votre_cle> <user>@<manager_ip> \
     'sudo tar -xO -f /root/wazuh-install/wazuh-install-files.tar wazuh-passwords.txt'
   ```

7. **Vérifier**
   - Dashboard : `https://<MANAGER_HOST>/`
   - Agent enregistré : `sudo /var/ossec/bin/manage_agents -l` sur le manager

## Dépannage

| Symptôme | Piste |
|---|---|
| `ssh: connect to host ... port 22: Connection timed out` | Firewall cloud ne laisse pas passer votre IP |
| Agent absent de `manage_agents -l` | Vérifier `systemctl status wazuh-agent` sur l'agent, et que le port 1515 est ouvert côté manager |
| Dashboard inaccessible en HTTPS | Vérifier que le port 443 est ouvert côté cloud ET que `ALLOWED_ADMIN_CIDR` correspond bien à votre IP actuelle |
| Script relancé après un échec | Les scripts sont pensés pour être ré-exécutables sans casser un état existant (`wazuh-install.sh` gère la reprise) |

## Relancer uniquement une étape

Les scripts d'`install/` peuvent être exécutés indépendamment, directement
sur chaque machine si vous préférez ne pas passer par `deploy.sh` :

```bash
# sur le manager
sudo WAZUH_VERSION=4.9 ./install/01-install-manager.sh
sudo ROLE=manager ALLOWED_ADMIN_CIDR=<votre_ip>/32 ./install/03-configure-firewall.sh

# sur l'agent
sudo MANAGER_IP=<ip_manager> AGENT_NAME=endpoint-01 ./install/02-install-agent.sh
sudo ROLE=agent ALLOWED_ADMIN_CIDR=<votre_ip>/32 ./install/03-configure-firewall.sh
```

## Roadmap

- [ ] Scripts optionnels pour rejouer les scénarios de détection (Nmap,
      Hydra) en mode encadré/opt-in
- [ ] Module Terraform (OCI) pour provisionner aussi les deux VM
- [ ] Intégration Suricata pour la détection réseau pure (cf. README,
      section "Enseignements clés")
