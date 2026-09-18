output "manager_public_ip" {
  description = "IP publique de l'instance manager"
  value       = oci_core_instance.manager.public_ip
}

output "agent_public_ip" {
  description = "IP publique de l'instance agent"
  value       = oci_core_instance.agent.public_ip
}

output "manager_ssh_command" {
  description = "Commande pour se connecter au manager"
  value       = "ssh -i <votre_cle_privee> ubuntu@${oci_core_instance.manager.public_ip}"
}

output "agent_ssh_command" {
  description = "Commande pour se connecter à l'agent"
  value       = "ssh -i <votre_cle_privee> ubuntu@${oci_core_instance.agent.public_ip}"
}

output "next_step" {
  description = "Prochaine étape : installer Wazuh"
  value       = <<-EOT
    Renseignez ces IP dans config/deploy.env (à la racine du dépôt) :
      MANAGER_HOST="${oci_core_instance.manager.public_ip}"
      AGENT_HOST="${oci_core_instance.agent.public_ip}"

    Puis, depuis la racine du dépôt :
      ./deploy.sh
  EOT
}
