#!/usr/bin/env bash
# Fonctions partagées par les scripts d'installation.
# Ce fichier est destiné à être "sourcé", pas exécuté directement.

log_info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
log_warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*" >&2; }
log_error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }
die()       { log_error "$*"; exit 1; }

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "Ce script doit être exécuté en root (sudo)."
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Commande requise introuvable : $1"
}

require_var() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    die "Variable requise non définie : \$${name} (voir config/deploy.env.example)"
  fi
}
