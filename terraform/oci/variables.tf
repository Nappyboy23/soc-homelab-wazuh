# --- Authentification OCI (voir terraform/oci/README.md pour comment les obtenir) ---

variable "tenancy_ocid" {
  description = "OCID de votre tenancy OCI"
  type        = string
}

variable "user_ocid" {
  description = "OCID de votre utilisateur OCI"
  type        = string
}

variable "fingerprint" {
  description = "Empreinte de la clé API OCI (générée avec la clé)"
  type        = string
}

variable "private_key_path" {
  description = "Chemin local vers la clé privée API OCI (ex: ~/.oci/oci_api_key.pem)"
  type        = string
}

variable "region" {
  description = "Région OCI (ex: eu-marseille-1, eu-paris-1, us-ashburn-1...)"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID du compartiment dans lequel créer les ressources"
  type        = string
}

# --- Accès SSH ---

variable "ssh_public_key_path" {
  description = "Chemin vers votre clé publique SSH (ex: ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR autorisé à atteindre SSH (22), le dashboard (443) et l'API Wazuh (55000). Utilisez votre IP publique en /32, jamais 0.0.0.0/0."
  type        = string
}

# --- Réseau ---

variable "vcn_cidr" {
  description = "CIDR du VCN dédié à ce lab"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR du subnet public partagé par les deux instances"
  type        = string
  default     = "10.0.0.0/24"
}

# --- Dimensionnement ---

variable "manager_ocpus" {
  description = "Nombre d'OCPU pour le manager (shape ARM Ampere A1.Flex, Always Free jusqu'à 4 OCPU au total)"
  type        = number
  default     = 2
}

variable "manager_memory_in_gbs" {
  description = "Mémoire (Go) pour le manager (shape ARM Ampere A1.Flex, Always Free jusqu'à 24 Go au total)"
  type        = number
  default     = 12
}

variable "agent_shape" {
  description = "Shape de l'instance agent (VM.Standard.E2.1.Micro = Always Free x86)"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "boot_volume_size_in_gbs" {
  description = "Taille du volume de boot par instance, en Go (Always Free jusqu'à 200 Go cumulés)"
  type        = number
  default     = 50
}

variable "instance_display_name_prefix" {
  description = "Préfixe des noms affichés dans la console OCI"
  type        = string
  default     = "wazuh"
}
