# --- VCN, passerelle internet, routage ---

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${var.instance_display_name_prefix}-vcn"
  dns_label      = "wazuhvcn"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.instance_display_name_prefix}-igw"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.instance_display_name_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.subnet_cidr
  display_name               = "${var.instance_display_name_prefix}-public-subnet"
  dns_label                  = "wazuhsub"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false
}

# --- NSG manager : SSH admin, dashboard, API, ports d'enrôlement agent ---

resource "oci_core_network_security_group" "manager" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.instance_display_name_prefix}-manager-nsg"
}

resource "oci_core_network_security_group_security_rule" "manager_ssh" {
  network_security_group_id = oci_core_network_security_group.manager.id
  direction                  = "INGRESS"
  protocol                    = "6" # TCP
  source                      = var.admin_cidr
  source_type                 = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_dashboard" {
  network_security_group_id = oci_core_network_security_group.manager.id
  direction                  = "INGRESS"
  protocol                    = "6"
  source                      = var.admin_cidr
  source_type                 = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_api" {
  network_security_group_id = oci_core_network_security_group.manager.id
  direction                  = "INGRESS"
  protocol                    = "6"
  source                      = var.admin_cidr
  source_type                 = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 55000
      max = 55000
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_agent_enrollment" {
  network_security_group_id = oci_core_network_security_group.manager.id
  direction                  = "INGRESS"
  protocol                    = "6"
  source                      = var.subnet_cidr
  source_type                 = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 1515
      max = 1515
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_agent_events_tcp" {
  network_security_group_id = oci_core_network_security_group.manager.id
  direction                  = "INGRESS"
  protocol                    = "6"
  source                      = var.subnet_cidr
  source_type                 = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 1514
      max = 1514
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_agent_events_udp" {
  network_security_group_id = oci_core_network_security_group.manager.id
  direction                  = "INGRESS"
  protocol                    = "17" # UDP
  source                      = var.subnet_cidr
  source_type                 = "CIDR_BLOCK"

  udp_options {
    destination_port_range {
      min = 1514
      max = 1514
    }
  }
}

resource "oci_core_network_security_group_security_rule" "manager_egress_all" {
  network_security_group_id = oci_core_network_security_group.manager.id
  direction                  = "EGRESS"
  protocol                    = "all"
  destination                 = "0.0.0.0/0"
  destination_type            = "CIDR_BLOCK"
}

# --- NSG agent : uniquement SSH admin en entrée ---

resource "oci_core_network_security_group" "agent" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.instance_display_name_prefix}-agent-nsg"
}

resource "oci_core_network_security_group_security_rule" "agent_ssh" {
  network_security_group_id = oci_core_network_security_group.agent.id
  direction                  = "INGRESS"
  protocol                    = "6"
  source                      = var.admin_cidr
  source_type                 = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "agent_egress_all" {
  network_security_group_id = oci_core_network_security_group.agent.id
  direction                  = "EGRESS"
  protocol                    = "all"
  destination                 = "0.0.0.0/0"
  destination_type            = "CIDR_BLOCK"
}
