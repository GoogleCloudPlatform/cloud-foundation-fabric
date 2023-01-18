/**
 * Copyright 2022 Google LLC
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
  # internal structure for Shared VPC service project IAM bindings
  _vpc_subnet_bindings = (
    local.vpc.subnets_iam == null || local.vpc.host_project == null
    ? []
    : flatten([
      for subnet, members in local.vpc.subnets_iam : [
        for member in members : {
          region = split("/", subnet)[0]
          subnet = split("/", subnet)[1]
          member = member
        }
      ]
    ])
  )

  # structures for Shared VPC resources in host project
  vpc = coalesce(var.vpc, {
    host_project = null, gke_setup = null, subnets_iam = null
  })
  vpc_cloudservices = (
    local.vpc_gke_service_agent
  )
  vpc_gke_security_admin = coalesce(
    try(local.vpc.gke_setup.enable_security_admin, null), false
  )
  vpc_gke_service_agent = coalesce(
    try(local.vpc.gke_setup.enable_host_service_agent, null), false
  )
  vpc_subnet_bindings = {
    for binding in local._vpc_subnet_bindings :
    "${binding.subnet}:${binding.member}" => binding
  }

}


module "gcs-bucket" {
  count         = var.bucket_name == null ? 0 : 1
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  name          = var.bucket_name
  prefix        = var.prefix
  location      = var.region
  storage_class = "REGIONAL"
  versioning    = false
}

module "gcs-bucket-cloudbuild" {
  # Default bucket for Cloud Build to prevent error: "'us' violates constraint ‘constraints/gcp.resourceLocations’"
  # https://stackoverflow.com/questions/53206667/cloud-build-fails-with-resource-location-constraint
  source        = "../../../modules/gcs"
  project_id    = module.project.project_id
  name          = "${var.project_id}_cloudbuild"
  prefix        = var.prefix
  location      = var.region
  storage_class = "REGIONAL"
  versioning    = false
}

module "bq-dataset" {
  count      = var.dataset_name == null ? 0 : 1
  source     = "../../../modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = var.dataset_name
  location   = var.region
}

module "vpc-local" {
  count      = var.vpc_local == null ? 0 : 1
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = var.vpc_local.name
  subnets    = var.vpc_local.subnets
  psa_config = {
    ranges = var.vpc_local.psa_config_ranges
    routes = null
  }
}

module "firewall" {
  count      = var.vpc_local == null ? 0 : 1
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project.project_id
  network    = module.vpc-local[0].name
  default_rules_config = {
    disabled = true
  }
  ingress_rules = {
    dataflow-ingress = {
      description          = "Dataflow service."
      direction            = "INGRESS"
      action               = "allow"
      sources              = ["dataflow"]
      targets              = ["dataflow"]
      ranges               = []
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = ["12345-12346"] }]
      extra_attributes     = {}
    }
  }

}


module "nat-ew1" {
  count                 = var.vpc_local == null ? 0 : 1
  source                = "../../../modules/net-cloudnat"
  project_id            = module.project.project_id
  region                = "europe-west1"
  name                  = "default"
  router_network        = module.vpc-local[0].name
  config_source_subnets = "LIST_OF_SUBNETWORKS"
  subnetworks = [
    {
      self_link            = module.vpc-local[0].subnets["europe-west1/default"].self_link
      config_source_ranges = ["ALL_IP_RANGES"]
      secondary_ranges     = null
    },
  ]
}

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.prefix
  group_iam       = var.group_iam
  iam = {
    "roles/aiplatform.user"         = [module.service-account-mlops.iam_email]
    "roles/artifactregistry.reader" = [module.service-account-mlops.iam_email]
    "roles/artifactregistry.writer" = [module.service-account-github.iam_email]
    "roles/bigquery.dataEditor"     = [module.service-account-mlops.iam_email]
    "roles/bigquery.jobUser"        = [module.service-account-mlops.iam_email]
    "roles/bigquery.user"           = [module.service-account-mlops.iam_email]
    "roles/cloudbuild.builds.editor" = [
      module.service-account-mlops.iam_email,
      module.service-account-github.iam_email
    ]

    "roles/cloudfunctions.invoker" = [module.service-account-mlops.iam_email]
    "roles/dataflow.developer"     = [module.service-account-mlops.iam_email]
    "roles/dataflow.worker"        = [module.service-account-mlops.iam_email]
    "roles/iam.serviceAccountUser" = [
      module.service-account-mlops.iam_email,
      "serviceAccount:${module.project.service_accounts.robots.cloudbuild}"
    ]
    "roles/monitoring.metricWriter" = [module.service-account-mlops.iam_email]
    "roles/run.invoker"             = [module.service-account-mlops.iam_email]
    "roles/serviceusage.serviceUsageConsumer" = [
      module.service-account-mlops.iam_email,
      module.service-account-github.iam_email
    ]
    "roles/storage.admin" = [
      module.service-account-mlops.iam_email,
      module.service-account-github.iam_email
    ]
  }
  labels                     = var.labels
  service_encryption_key_ids = var.kms_service_agents
  services                   = var.project_services
  shared_vpc_service_config = var.vpc == null ? null : {
    host_project = local.vpc.host_project
    # these are non-authoritative
    service_identity_iam = {
      "roles/compute.networkUser" = compact([
        local.vpc_gke_service_agent ? "container-engine" : null,
        local.vpc_cloudservices ? "cloudservices" : null
      ])
      "roles/compute.securityAdmin" = compact([
        local.vpc_gke_security_admin ? "container-engine" : null,
      ])
      "roles/container.hostServiceAgentUser" = compact([
        local.vpc_gke_service_agent ? "container-engine" : null
      ])
    }
  }

}

module "service-account-mlops" {
  source     = "../../../modules/iam-service-account"
  name       = var.sa_mlops_name
  project_id = module.project.project_id
  iam = {
    "roles/iam.serviceAccountUser" = [module.service-account-github.iam_email]
  }
}

resource "google_compute_subnetwork_iam_member" "default" {
  for_each   = local.vpc_subnet_bindings
  project    = local.vpc.host_project
  subnetwork = "projects/${local.vpc.host_project}/regions/${each.value.region}/subnetworks/${each.value.subnet}"
  region     = each.value.region
  role       = "roles/compute.networkUser"
  member     = each.value.member
}

resource "google_sourcerepo_repository" "code-repo" {
  count   = var.repo_name == null ? 0 : 1
  name    = var.repo_name
  project = module.project.project_id
}


