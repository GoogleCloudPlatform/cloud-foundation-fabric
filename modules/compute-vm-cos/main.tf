/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  files = {
    for path, data in var.files :
    path => merge(data, {
      attributes = (
        data.attributes == null
        ? { owner = "root", permissions = "0644" }
        : data.attributes
      )
    })
  }
  files_yaml = join("\n", [
    for _, data in data.template_file.cloud-config-files : data.rendered
  ])
  volumes = join(" ", [
    for host_path, mount_path in var.volumes : "-v ${host_path}:${mount_path}"
  ])
  tcp_ports = [
    for port in coalesce(var.exposed_ports.tcp, [])
    : "- iptables -I INPUT 1 -p tcp -m tcp --dport ${port} -m state --state NEW,ESTABLISHED -j ACCEPT"
  ]
  udp_ports = [
    for port in coalesce(var.exposed_ports.udp, [])
    : "- iptables -I INPUT 1 -p udp -m udp --dport ${port} -m state --state NEW,ESTABLISHED -j ACCEPT"
  ]
  pre_runcmds = [
    for cmd in var.pre_runcmds : "- ${cmd}"
  ]
  post_runcmds = [
    for cmd in var.post_runcmds : "- ${cmd}"
  ]
  fw_runcmds_yaml   = join("\n", concat(local.tcp_ports, local.udp_ports))
  pre_runcmds_yaml  = join("\n", local.pre_runcmds)
  post_runcmds_yaml = join("\n", local.post_runcmds)
}

data "template_file" "cloud-config-files" {
  for_each = local.files
  template = file("${path.module}/cloud-config-file.yaml")
  vars = {
    path        = each.key
    content     = each.value.content
    owner       = each.value.attributes.owner
    permissions = each.value.attributes.permissions
  }
}

data "template_file" "cloud-config" {
  template = file("${path.module}/cloud-config.yaml")
  vars = {
    files        = local.files_yaml
    volumes      = local.volumes
    extra_args   = var.extra_args
    image        = var.image
    log_driver   = var.log_driver
    fw_runcmds   = local.fw_runcmds_yaml
    pre_runcmds  = local.pre_runcmds_yaml
    post_runcmds = local.post_runcmds_yaml
  }
}

# output "rendered" {
#   value = data.template_file.cloud-config.rendered
# }


module "vm" {
  source         = "../compute-vm"
  project_id     = var.project_id
  region         = var.region
  zone           = var.zone
  name           = var.name
  boot_disk      = var.boot_disk
  hostname       = var.hostname
  instance_count = var.instance_count
  instance_type  = var.instance_type
  labels         = var.labels
  metadata = merge(var.metadata, {
    google-logging-enabled    = var.cos_config.logging
    google-monitoring-enabled = var.cos_config.monitoring
    user-data                 = data.template_file.cloud-config.rendered
  })
  min_cpu_platform      = var.min_cpu_platform
  network_interfaces    = var.network_interfaces
  options               = var.options
  service_account       = var.service_account
  tags                  = var.tags
  use_instance_template = var.use_instance_template
}
