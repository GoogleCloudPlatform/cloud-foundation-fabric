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
  runner_startup_script_config = {
    gitlab_hostname     = var.gitlab_hostname
    gitlab_ca_cert      = base64encode(file("${path.module}/certs/${var.gitlab_hostname}.ca.crt"))
    gitlab_ca_cert_name = "ca.crt"
    token               = gitlab_user_runner.docker_runner.token
  }
}

resource "gitlab_user_runner" "docker_runner" {
  runner_type = "instance_type"
  description = "${var.prefix}-gitlab-runner"
  tag_list    = ["docker"]
}

module "gitlab-runner" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/compute-vm"
  project_id = module.project.project_id
  boot_disk  = {
    initialize_params = {
      size = "100"
    }
  }
  instance_type      = var.gitlab_runner_vm_config.instance_type
  name               = "${var.prefix}-${var.gitlab_runner_vm_config.name}"
  tags               = var.gitlab_runner_vm_config.network_tags
  zone               = "${var.region}-a"
  network_interfaces = [
    {
      network    = var.vpc_self_links.dev-spoke-0
      subnetwork = var.subnet_self_links.dev-spoke-0["${var.region}/gitlab"]
      addresses  = {
        internal = var.gitlab_runner_vm_config.private_ip
      }
    }
  ]
  metadata = {
    startup-script = templatefile("${path.module}/assets/startup-script.sh.tpl", local.runner_startup_script_config)
  }
  service_account = {
    auto_create = true
  }
}
