/**
 * Copyright 2023 Google LLC
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
  _runner_config_type = [
    for key, value in var.gitlab_runner_config.runners_config : key if value != null
  ][0]

  runner_startup_script_config = {
    gitlab_hostname      = var.gitlab_config.hostname
    gitlab_ca_cert       = base64encode(var.gitlab_config.ca_cert_pem)
    token                = var.gitlab_runner_config.authentication_token
    gitlab_runner_config = base64encode(templatefile("${path.module}/assets/config/${local._runner_config_type}_config.toml.tpl", var.gitlab_runner_config.runners_config[local._runner_config_type]))
  }
}

module "gitlab-runner" {
  source     = "../../../modules/compute-vm"
  project_id = var.vm_config.project_id
  boot_disk  = {
    initialize_params = {
      size = var.vm_config.boot_disk_size
    }
  }
  instance_type      = var.vm_config.instance_type
  name               = var.vm_config.name
  tags               = var.vm_config.network_tags
  zone               = var.vm_config.zone
  network_interfaces = [
    {
      network    = var.network_config.network_self_link
      subnetwork = var.network_config.subnet_self_link
    }
  ]
  metadata = {
    startup-script = templatefile("${path.module}/assets/startup-script.sh.tpl", local.runner_startup_script_config)
  }
  service_account = {
    auto_create = true
  }
}
