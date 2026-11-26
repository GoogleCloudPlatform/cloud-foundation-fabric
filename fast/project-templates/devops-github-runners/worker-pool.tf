/**
 * Copyright 2026 Google LLC
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
  runner_image_uri = join("/", [
    "${local.location}-docker.pkg.dev",
    module.project.project_id,
    module.artifact-registry.name,
    "${var.runner_config.image_name}:${var.runner_config.image_tag}"
  ])
}

module "worker-pool" {
  source              = "../../../modules/cloud-run-v2"
  project_id          = module.project.project_id
  region              = local.location
  name                = "${local.prefix}${var.runner_config.worker_pool_name}"
  type                = "WORKERPOOL"
  managed_revision    = false
  deletion_protection = var.runner_config.deletion_protection
  service_account_config = {
    create = false
    email  = local.worker_sa_email
  }
  workerpool_config = {
    scaling = {
      mode                  = "MANUAL"
      manual_instance_count = var.runner_config.min_replicas
    }
  }
  containers = {
    runner = {
      image = local.runner_image_uri
      resources = {
        limits = {
          cpu    = var.runner_config.cpu
          memory = var.runner_config.memory
        }
      }
      env = {
        GITHUB_APP_ID               = var.github_config.app_id
        GITHUB_APP_INSTALLATION_ID  = var.github_config.installation_id
        GITHUB_APP_PRIVATE_KEY_PATH = "/secrets/github-app-private-key"
        GITHUB_ORG                  = var.github_config.org
        PROJECT_ID                  = module.project.project_id
        RUNNER_GROUP_ID             = tostring(var.runner_config.group_id)
        RUNNER_LABELS               = var.runner_config.labels
      }
      volume_mounts = {
        "github-app-key-volume" = "/secrets"
      }
    }
  }
  volumes = {
    github-app-key-volume = {
      secret = {
        name    = module.secrets.secrets["github-app-private-key"].secret_id
        path    = "github-app-private-key"
        version = "latest"
      }
    }
  }
}
