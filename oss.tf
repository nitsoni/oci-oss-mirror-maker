## Copyright (c) 2020, Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
resource "oci_streaming_stream_pool" "source" {
  compartment_id = var.compartment_ocid
  name           = var.source_stream_pool

  kafka_settings {
    auto_create_topics_enable = true
  }
  provider = oci.sourceRegion
}

resource "oci_streaming_stream_pool" "target" {
  compartment_id = var.compartment_ocid
  name           = var.Target_stream_pool

  kafka_settings {
    auto_create_topics_enable = true
  }
  provider = oci.targetRegion
}

resource "oci_streaming_connect_harness" "mm2_connect_harness" {
  provider       = oci.targetRegion
  compartment_id = var.compartment_ocid
  name           = "mm2-connect-harness"
}
