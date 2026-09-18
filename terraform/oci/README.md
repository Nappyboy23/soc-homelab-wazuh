# Provisioning OCI (Terraform)

Ce module crée l'infrastructure réseau et les deux instances du lab
(manager + agent) sur Oracle Cloud Infrastructure, dans les limites du
**Always Free Tier**. Il ne fait **que** l'infrastructure — l'installation
de Wazuh reste gérée par `../../deploy.sh` (voir la dernière étape).

## Ce qui est créé

- 1 VCN dédié + passerelle internet + table de routage
- 1 subnet public partagé
- 2 groupes de sécurité réseau (NSG) différenciés :
  - **manager** : SSH (22) et dashboard (443) et API (55000) ouverts
    uniquement depuis `admin_cidr` ; ports d'enrôlement agent (1514/1515)
    ouverts uniquement depuis le subnet interne
  - **agent** : uniquement SSH (22) depuis `admin_cidr`
- 2 instances Ubuntu 22.04 :
  - **manager** — shape ARM Ampere `VM.Standard.A1.Flex` (2 OCPU / 12 Go par
    défaut, Always Free jusqu'à 4 OCPU / 24 Go au total)
  - **agent** — shape x86 `VM.Standard.E2.1.Micro` (Always Free)

Les OCID des images Ubuntu ne sont jamais codés en dur : ils sont résolus
dynamiquement à chaque `apply` (ils changent à chaque nouvelle version et
diffèrent par région).

## Prérequis

- Un compte OCI (le Free Tier suffit)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- Une paire de clés SSH (`ssh-keygen` si vous n'en avez pas)

## 1. Créer une clé API OCI

Dans la console OCI : icône de profil (en haut à droite) → **My profile**
→ **API keys** → **Add API key** → laissez OCI générer la paire de clés,
téléchargez la clé privée (ex: `~/.oci/oci_api_key.pem`), puis copiez le
bloc de configuration affiché : il contient `user`, `fingerprint`,
`tenancy`, `region`.

## 2. Récupérer les OCID nécessaires

| Variable | Où le trouver |
|---|---|
| `tenancy_ocid` | Bloc de config affiché à l'étape 1, ou **Administration → Tenancy details** |
| `user_ocid` | Même bloc de config, ou **Profile → My profile** |
| `fingerprint` | Même bloc de config |
| `compartment_ocid` | **Identity & Security → Compartments** (le compartiment root a le même OCID que la tenancy si vous n'en avez pas créé d'autre) |

## 3. Configurer

```bash
cd terraform/oci
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars   # vos OCID, votre IP admin, chemin de vos clés
```

`terraform.tfvars` est ignoré par git — vos identifiants ne seront jamais
commités.

## 4. Déployer

```bash
terraform init
terraform plan     # vérifiez ce qui va être créé
terraform apply
```

À la fin, notez les IP affichées (`manager_public_ip`, `agent_public_ip`)
ou relancez `terraform output` à tout moment.

## 5. Installer Wazuh

Depuis la **racine du dépôt** (pas ce dossier) :

```bash
cd ../..
cp config/deploy.env.example config/deploy.env
$EDITOR config/deploy.env   # collez les IP obtenues ci-dessus
./deploy.sh
```

## Détruire le lab

Pour ne pas laisser tourner des ressources inutilement (et rester dans les
limites du Free Tier si vous avez d'autres projets OCI) :

```bash
terraform destroy
```

## Notes Free Tier

- Le shape ARM `A1.Flex` est parfois indisponible ("Out of host capacity")
  sur certaines régions aux heures de forte demande — réessayez plus tard,
  ou réduisez `manager_ocpus`/`manager_memory_in_gbs`.
- Les 4 OCPU / 24 Go ARM et les 2 instances `E2.1.Micro` sont partagés
  entre **toutes** vos ressources Always Free de la tenancy — si vous avez
  déjà d'autres instances, ajustez les valeurs dans `terraform.tfvars`.
- Le volume de boot (`boot_volume_size_in_gbs`, 50 Go par défaut × 2
  instances = 100 Go) reste dans la limite Always Free de 200 Go cumulés.
