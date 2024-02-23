/**
 * Copyright 2024 Google LLC
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
  role_id            = "projects/${module.project.project_id}/roles/${local.role_name}"
  role_name          = "gitlab_runner_manager_role"
  runner_config_type = [for key, value in var.gitlab_runner_config.executors_config : key if value != null][0]
  runner_startup_script_config = {
    gitlab_hostname      = var.gitlab_config.hostname
    gitlab_ca_cert       = base64encode(var.gitlab_config.ca_cert_pem)
    token                = var.gitlab_runner_config.authentication_token
    gitlab_runner_config = base64encode(templatefile("${path.module}/assets/config/${local.runner_config_type}_config.toml.tpl", var.gitlab_runner_config.executors_config[local.runner_config_type]))
    gitlab_executor_type = replace(local.runner_config_type, "_", "-")
  }
}

resource "google_service_account_iam_member" "admin-account-iam" {
  count              = local.runner_config_type == "docker_autoscaler" ? 1 : 0
  service_account_id = module.gitlab-runner-template.0.service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.gitlab-runner.service_account.email}"
}

module "project" {
  source          = "../../../modules/project"
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  prefix          = var.project_create == null ? null : var.prefix
  name            = var.project_id
  project_create  = var.project_create != null
  custom_roles = {
    (local.role_name) = [
      "compute.instanceGroupManagers.get",
      "compute.instanceGroupManagers.update",
      "compute.instances.get",
      "compute.instances.setMetadata"
    ]
  }
  iam = {
    (local.role_id) = ["serviceAccount:${module.gitlab-runner.service_account.email}"]
  }
  services = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "stackdriver.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
  ]
  shared_vpc_service_config = {
    attach       = true
    host_project = var.network_config.host_project
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "compute"
      ]
    }
    network_users = var.admin_principals
  }
}
