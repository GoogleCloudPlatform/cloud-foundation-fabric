# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Cloud Run resources.

module "service_account_cr" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "${var.prefix}-sa-cf"
}

module "cloud_run" {
  source     = "../../../modules/cloud-run"
  project_id = module.project.project_id
  name       = "webhook"
  containers = {
    default = {
      image = var.webhook_config.image != null ? var.webhook_config.image : "${var.region}-docker.pkg.dev/${module.project.project_id}/repository/webhook:v1"
    }
  }
  ingress_settings = "internal"
  vpc_connector_create = {
    subnet = {
      name       = split("/", local.subnets["connector"])[length(split("/", local.subnets["connector"])) - 1]
      project_id = local.vpc_project
    }
  }
  service_account = module.service_account_cr.email
  depends_on      = [null_resource.sp]
}

resource "google_artifact_registry_repository" "repo" {
  project       = module.project.project_id
  location      = var.region
  repository_id = "repository"
  description   = "example docker repository"
  format        = "DOCKER"
}

resource "null_resource" "sp" {
  triggers = {
    policy_sha1 = <<EOT
      ${sha1(file("./cr/app.py"))}
      ${sha1(file("./cr/Dockerfile"))}
      ${sha1(file("./cr/requirements.txt"))}
    EOT
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<EOT
      gcloud builds submit \
        --region=${var.region} \
        --project=${module.project.project_id} \
        --tag ${var.region}-docker.pkg.dev/${module.project.project_id}/${google_artifact_registry_repository.repo.name}/webhook:v1 \
        ./cr
    EOT
  }
}
