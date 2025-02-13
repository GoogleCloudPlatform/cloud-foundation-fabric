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
  gitlab_runner_auth_token_secret_id = "gitlab_runner_auth_token"
}

module "runner-sa" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "gitlab-runner-sa"
}

module "runner-mig-sa" {
  count      = local.runner_config_type == "docker_autoscaler" ? 1 : 0
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "gitlab-runner-sa"
  iam = {
    "roles/iam.serviceAccountUser" = [
      "serviceAccount:${module.runner-sa.email}"
    ]
  }
}

module "runner-secrets" {
  source     = "../../../modules/secret-manager"
  project_id = module.project.project_id
  secrets = {
    (local.gitlab_runner_auth_token_secret_id) = {
      locations = [var.region]
    }
  }
  versions = {
    (local.gitlab_runner_auth_token_secret_id) = {
      latest = {
        enabled = true, data = var.gitlab_runner_config.authentication_token
      }
    }
  }
  iam = {
    (local.gitlab_runner_auth_token_secret_id) = {
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:${module.runner-sa.email}"
      ]
    }
  }
}

module "gitlab-runner" {
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  boot_disk = {
    initialize_params = {
      size = var.vm_config.boot_disk_size
    }
  }
  instance_type = var.vm_config.instance_type
  name          = var.vm_config.name
  tags          = var.vm_config.network_tags
  zone          = var.vm_config.zone
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
    email = module.runner-sa.email
  }
}

module "gitlab-runner-template" {
  count      = local.runner_config_type == "docker_autoscaler" ? 1 : 0
  source     = "../../../modules/compute-vm"
  project_id = module.project.project_id
  name       = var.gitlab_runner_config.executors_config.docker_autoscaler.mig_name
  zone       = var.gitlab_runner_config.executors_config.docker_autoscaler.zone
  tags       = ["ssh"]
  network_interfaces = [
    {
      network    = var.network_config.network_self_link
      subnetwork = var.network_config.subnet_self_link
    }
  ]
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }
  service_account = {
    email = module.runner-mig-sa.0.email
  }
  create_template = true
}

module "gitlab-runner-mig" {
  count             = local.runner_config_type == "docker_autoscaler" ? 1 : 0
  source            = "../../../modules/compute-mig"
  project_id        = module.project.project_id
  location          = var.gitlab_runner_config.executors_config.docker_autoscaler.zone
  name              = var.gitlab_runner_config.executors_config.docker_autoscaler.mig_name
  target_size       = 1
  instance_template = module.gitlab-runner-template.0.template.self_link
}
