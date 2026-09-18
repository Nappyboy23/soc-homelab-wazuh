data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

# Images Ubuntu résolues dynamiquement (jamais d'OCID d'image codé en dur :
# ils sont spécifiques à chaque région et changent à chaque nouvelle version).

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order                = "DESC"
}

data "oci_core_images" "ubuntu_x86" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.agent_shape
  sort_by                  = "TIMECREATED"
  sort_order                = "DESC"
}

# --- Manager : Wazuh Manager + Indexer + Dashboard (ARM Ampere, Always Free) ---

resource "oci_core_instance" "manager" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name         = "${var.instance_display_name_prefix}-manager"
  shape                 = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.manager_ocpus
    memory_in_gbs = var.manager_memory_in_gbs
  }

  create_vnic_details {
    subnet_id         = oci_core_subnet.public.id
    assign_public_ip   = true
    nsg_ids             = [oci_core_network_security_group.manager.id]
    display_name       = "${var.instance_display_name_prefix}-manager-vnic"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

# --- Agent : endpoint surveillé (x86 Always Free) ---

resource "oci_core_instance" "agent" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  display_name         = "${var.instance_display_name_prefix}-agent"
  shape                 = var.agent_shape

  create_vnic_details {
    subnet_id         = oci_core_subnet.public.id
    assign_public_ip   = true
    nsg_ids             = [oci_core_network_security_group.agent.id]
    display_name       = "${var.instance_display_name_prefix}-agent-vnic"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_x86.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}
