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
  cc     = var.cloud_config
  ccvars = var.cloud_config.variables

  use_generic_template = local.cc.template_path == "preset:generic.yaml"
  template_path        = replace(local.cc.template_path, "/preset:/", "${path.module}/cloud-config/")

  generic_config_vars = {
    image        = lookup(local.ccvars, "image", "")
    extra_args   = lookup(local.ccvars, "extra_args", "")
    log_driver   = lookup(local.ccvars, "log_driver", "gcplogs")
    volumes      = lookup(local.ccvars, "volumes", {})
    pre_runcmds  = lookup(local.ccvars, "pre_runcmds", [])
    post_runcmds = lookup(local.ccvars, "post_runcmds", [])
    fw_runcmds   = lookup(local.ccvars, "exposed_ports", [])
    files        = lookup(local.ccvars, "files", {})
  }

  cloud_config_content = (
    local.use_generic_template
    ? templatefile(local.template_path, local.generic_config_vars)
    : templatefile(local.template_path, var.cloud_config.variables)
  )
}

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
    user-data                 = local.cloud_config_content
  })
  min_cpu_platform      = var.min_cpu_platform
  network_interfaces    = var.network_interfaces
  options               = var.options
  service_account       = var.service_account
  tags                  = var.tags
  use_instance_template = var.use_instance_template
}
