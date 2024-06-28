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

module "project" {
  source = "../../../modules/project"
  billing_account = (var.project_create != null
    ? var.project_create.billing_account_id
    : null
  )
  parent = (var.project_create != null
    ? var.project_create.parent
    : null
  )
  project_create = var.project_create != null
  name           = var.project_id
  services = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com"
  ]
  iam = {
    "roles/monitoring.viewer"            = [module.monitoring_sa.iam_email]
    "roles/container.nodeServiceAccount" = [module.node_sa.iam_email]
    "roles/container.admin"              = [module.mgmt_server.service_account_iam_email]
    "roles/storage.admin"                = [module.mgmt_server.service_account_iam_email]
    "roles/cloudbuild.builds.editor"     = [module.mgmt_server.service_account_iam_email]
    "roles/viewer"                       = [module.mgmt_server.service_account_iam_email]
  }
}

module "monitoring_sa" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "sa-monitoring"
  iam = {
    "roles/iam.workloadIdentityUser" = [
      "serviceAccount:${module.cluster.workload_identity_pool}[monitoring/frontend]",
      "serviceAccount:${module.cluster.workload_identity_pool}[monitoring/custom-metrics-stackdriver-adapter]"
    ]
  }
}

module "docker_artifact_registry" {
  source     = "../../../modules/artifact-registry"
  project_id = module.project.project_id
  location   = var.region
  name       = "registry"
  format     = { docker = { standard = {} } }
  iam = {
    "roles/artifactregistry.reader" = [module.node_sa.iam_email]
  }
}
