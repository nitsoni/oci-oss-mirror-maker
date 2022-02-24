## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_virtual_network" "vcn" {
  provider       = oci.targetRegion
  cidr_block     = var.VCN-CIDR
  dns_label      = "vcn"
  compartment_id = var.compartment_ocid
  display_name   = "vcn"
}

resource "oci_core_internet_gateway" "igw" {
  provider       = oci.targetRegion
  compartment_id = var.compartment_ocid
  display_name   = "igw"
  vcn_id         = oci_core_virtual_network.vcn.id
}


resource "oci_core_route_table" "rt_via_igw" {
  provider       = oci.targetRegion
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "rt_via_igw"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_dhcp_options" "dhcpoptions1" {
  provider       = oci.targetRegion
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "dhcpoptions1"

  // required
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }

}

resource "oci_core_subnet" "mirrormakersubnet" {
  provider       = oci.targetRegion
  
  cidr_block        = var.mirrormaker-CIDR
  display_name      = "mirrormakersubnet"
  dns_label         = "mirrormakersub"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.vcn.id
  route_table_id    = oci_core_route_table.rt_via_igw.id
  dhcp_options_id   = oci_core_dhcp_options.dhcpoptions1.id
  security_list_ids = [oci_core_virtual_network.vcn.default_security_list_id]
}

