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


module "cos-coredns" {
  source         = "../compute-vm-cos"
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
  })
  min_cpu_platform      = var.min_cpu_platform
  network_interfaces    = var.network_interfaces
  options               = var.options
  service_account       = var.service_account
  tags                  = var.tags
  log_driver            = var.coredns_log_driver
  use_instance_template = var.use_instance_template
  cos_config            = var.cos_config
  image                 = var.coredns_image
  files = {
    "/etc/systemd/resolved.conf" : {
      content    = <<-EOT
        [Resolve]
        LLMNR=no
        DNSStubListener=no
      EOT
      attributes = null
    }
    "/etc/coredns/Corefile" : {
      content = (var.coredns_corefile == null
        ? file("${path.module}/Corefile")
        : var.coredns_corefile
      )
      attributes = null
    }
  }
  volumes = {
    "/etc/coredns" : "/etc/coredns"
  }
  pre_runcmds = [
    "systemctl restart systemd-resolved.service"
  ]
  extra_args = "-conf /etc/coredns/Corefile"
  exposed_ports = {
    tcp = [53]
    udp = [53]
  }
}
