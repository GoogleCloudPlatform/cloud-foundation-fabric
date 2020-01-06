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

data "template_file" "cloud-config" {
  template = file("${path.module}/cloud-config.yaml")

  vars = {
    corefile = file(
      var.coredns_corefile == null
      ? "${path.module}/Corefile"
      : var.coredns_corefile
    )
    image      = var.coredns_image
    log_driver = var.coredns_log_driver
  }
}

module "cos-coredns" {
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
