## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "mm2_config" {

  depends_on = [oci_core_instance.mm2_instance, oci_streaming_stream_pool.target, oci_streaming_stream_pool.source, oci_streaming_connect_harness.mm2_connect_harness]

  template = file("./config/mm2.config")

  vars = {
    SOURCE_REGION        = var.region
    TARGET_REGION        = var.targetRegion
    CONNECT_HARNESS_OCID = oci_streaming_connect_harness.mm2_connect_harness.id
    TENANCY_NAME         = data.oci_identity_tenancy.current_user_tenancy.name
    USER_NAME            = data.oci_identity_user.current_user.name
    AUTH_CODE            = oci_identity_auth_token.stream_auth_token.token
    SOURCE_STREAM_POOL   = oci_streaming_stream_pool.source.id
    TARGET_STREAM_POOL   = oci_streaming_stream_pool.target.id
  }
}

data "template_file" "producer_config" {

  depends_on = [oci_core_instance.mm2_instance, oci_streaming_stream_pool.target, oci_streaming_stream_pool.source, oci_streaming_connect_harness.mm2_connect_harness]

  template = file("./config/producer.config")

  vars = {
    SOURCE_REGION      = var.region
    TENANCY_NAME       = data.oci_identity_tenancy.current_user_tenancy.name
    USER_NAME          = data.oci_identity_user.current_user.name
    AUTH_CODE          = oci_identity_auth_token.stream_auth_token.token
    SOURCE_STREAM_POOL = oci_streaming_stream_pool.source.id
  }
}

resource "null_resource" "run_scripts" {

  depends_on = [oci_core_instance.mm2_instance, oci_streaming_stream_pool.target, oci_streaming_stream_pool.source, oci_streaming_connect_harness.mm2_connect_harness]

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.mm2_instance.public_ip
      private_key = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.private_key_pem : file (var.private_ssh_key_path)
      #private_key = tls_private_key.public_private_key_pair.private_key_pem
      agent       = false
      timeout     = "10m"
    }
    content     = data.template_file.mm2_config.rendered
    destination = "/home/opc/mm2.config"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.mm2_instance.public_ip
      private_key = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.private_key_pem : file (var.private_ssh_key_path)
      #private_key = tls_private_key.public_private_key_pair.private_key_pem
      agent       = false
      timeout     = "10m"
    }
    content     = data.template_file.producer_config.rendered
    destination = "/home/opc/producer.config"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.mm2_instance.public_ip
      private_key = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.private_key_pem : file (var.private_ssh_key_path)
      #private_key = tls_private_key.public_private_key_pair.private_key_pem
      agent       = false
      timeout     = "10m"
    }
    inline = [
      # "sudo yum update -y",
      "sudo yum install java-1.8.0-openjdk.x86_64 -y",
      "wget https://archive.apache.org/dist/kafka/2.5.1/kafka_2.12-2.5.1.tgz",
      "tar -xvf kafka_2.12-2.5.1.tgz",
      "mv kafka_2.12-2.5.1 kafka",
      "chmod u+x ./kafka/bin/connect-mirror-maker.sh",
      "echo 'Starrting MM2'",
      "nohup ./kafka/bin/connect-mirror-maker.sh mm2.config --clusters target_cluster >> mm2.logs &",
      "sleep 2",
      "echo 'Starrting Producer'",
      "nohup ./kafka/bin/kafka-producer-perf-test.sh --producer.config producer.config --topic sample_topic --num-records 1000 --record-size 1024 --throughput 5 >> producer.log &",
      "sleep 2"
    ]
  }

}
