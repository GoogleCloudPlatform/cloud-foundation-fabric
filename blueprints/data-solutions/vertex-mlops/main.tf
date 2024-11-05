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
  iam_principals = merge(
    var.groups.gcp-ml-viewer == null ? {} : {
      "group:${var.groups.gcp-ml-viewer}" = [
        "roles/aiplatform.viewer",
        "roles/artifactregistry.reader",
        "roles/dataflow.viewer",
        "roles/logging.viewer",
        "roles/storage.objectViewer"
      ]
    },
    var.groups.gcp-ml-ds == null ? {} : {
      "group:${var.groups.gcp-ml-ds}" = [
        "roles/aiplatform.admin",
        "roles/artifactregistry.admin",
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/bigquery.user",
        "roles/cloudbuild.builds.editor",
        "roles/cloudfunctions.developer",
        "roles/dataflow.developer",
        "roles/dataflow.worker",
        "roles/iam.serviceAccountUser",
        "roles/logging.logWriter",
        "roles/logging.viewer",
        "roles/notebooks.admin",
        "roles/pubsub.editor",
        "roles/serviceusage.serviceUsageConsumer",
        "roles/storage.admin"
      ]
    },
    var.groups.gcp-ml-eng == null ? {} : {
      "group:${var.groups.gcp-ml-eng}" = [
        "roles/aiplatform.admin",
        "roles/artifactregistry.admin",
        "roles/bigquery.dataEditor",
        "roles/bigquery.jobUser",
        "roles/bigquery.user",
        "roles/dataflow.developer",
        "roles/dataflow.worker",
        "roles/iam.serviceAccountUser",
        "roles/logging.logWriter",
        "roles/logging.viewer",
        "roles/serviceusage.serviceUsageConsumer",
        "roles/storage.admin"
      ]
    }
  )

  shared_vpc_project = try(var.network_config.host_project, null)

  subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_link
    : values(module.vpc-local[0].subnet_self_links)[0]
  )
  vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.vpc-local[0].self_link
  )
  use_shared_vpc = var.network_config != null

  shared_vpc_bindings = {
    "roles/compute.networkUser" = [
      "robot-df", "notebooks"
    ]
  }

  shared_vpc_role_members = {
    robot-df  = module.project.service_agents.dataflow.iam_email
    notebooks = module.project.service_agents.notebooks.iam_email
  }

  # reassemble in a format suitable for for_each
  shared_vpc_bindings_map = {
    for binding in flatten([
      for role, members in local.shared_vpc_bindings : [
        for member in members : { role = role, member = member }
      ]
    ]) : "${binding.role}-${binding.member}" => binding
  }
}

module "gcs-bucket" {
  count          = var.bucket_name == null ? 0 : 1
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  name           = var.bucket_name
  prefix         = var.prefix
  location       = var.region
  storage_class  = "REGIONAL"
  versioning     = false
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
}

# Default bucket for Cloud Build to prevent error: "'us' violates constraint ‘gcp.resourceLocations’"
# https://stackoverflow.com/questions/53206667/cloud-build-fails-with-resource-location-constraint
module "gcs-bucket-cloudbuild" {
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  name           = "${module.project.project_id}_cloudbuild"
  location       = var.region
  storage_class  = "REGIONAL"
  versioning     = false
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
}

module "bq-dataset" {
  count          = var.dataset_name == null ? 0 : 1
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.project.project_id
  id             = var.dataset_name
  location       = var.region
  encryption_key = var.service_encryption_keys.bq
}

module "vpc-local" {
  count      = local.use_shared_vpc ? 0 : 1
  source     = "../../../modules/net-vpc"
  project_id = module.project.project_id
  name       = "vertex"
  subnets = [
    {
      name                  = "subnet-${var.region}",
      region                = var.region,
      ip_cidr_range         = "10.5.0.0/24"
      enable_private_access = true
    }
  ]
  psa_configs = [{
    ranges = {
      "vertex" : "10.13.0.0/18"
    }
    routes = null
  }]
}

module "firewall" {
  count      = local.use_shared_vpc ? 0 : 1
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

module "cloudnat" {
  count          = local.use_shared_vpc ? 0 : 1
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  region         = var.region
  name           = "default"
  router_network = module.vpc-local[0].self_link
}

module "project" {
  source            = "../../../modules/project"
  name              = var.project_config.project_id
  parent            = var.project_config.parent
  billing_account   = var.project_config.billing_account_id
  project_create    = var.project_config.billing_account_id != null
  prefix            = var.prefix
  iam_by_principals = local.iam_principals
  iam_bindings_additive = {
    # we manage aiplatform.user additively since it is also granted to
    # the vertex-shtune service agent by the project module
    aiplatform-user-mlops = {
      member = module.service-account-mlops.iam_email
      role   = "roles/aiplatform.user"
    }
    aiplatform-user-notebook = {
      member = module.service-account-notebook.iam_email
      role   = "roles/aiplatform.user"
    }
  }
  iam = {
    "roles/artifactregistry.reader" = [module.service-account-mlops.iam_email]
    "roles/artifactregistry.writer" = [module.service-account-github.iam_email]
    "roles/bigquery.dataEditor" = [
      module.service-account-mlops.iam_email,
      module.service-account-notebook.iam_email
    ]
    "roles/bigquery.jobUser" = [
      module.service-account-mlops.iam_email,
      module.service-account-notebook.iam_email
    ]
    "roles/bigquery.user" = [module.service-account-mlops.iam_email, module.service-account-notebook.iam_email]
    "roles/cloudbuild.builds.editor" = [
      module.service-account-mlops.iam_email,
      module.service-account-github.iam_email
    ]

    "roles/cloudfunctions.invoker" = [module.service-account-mlops.iam_email]
    "roles/dataflow.developer"     = [module.service-account-mlops.iam_email]
    "roles/dataflow.worker"        = [module.service-account-mlops.iam_email]
    "roles/iam.serviceAccountUser" = [
      module.service-account-mlops.iam_email,
      module.service-account-notebook.iam_email,
      module.service-account-github.iam_email,
      module.project.service_agents.cloudbuild.iam_email
    ]
    "roles/logging.logWriter" = [
      module.service-account-notebook.iam_email,
    ]
    "roles/monitoring.metricWriter" = [
      module.service-account-mlops.iam_email,
      module.service-account-notebook.iam_email,
    ]
    "roles/run.invoker" = [module.service-account-mlops.iam_email]
    "roles/serviceusage.serviceUsageConsumer" = [
      module.service-account-mlops.iam_email,
      module.service-account-github.iam_email,
      module.service-account-notebook.iam_email,
    ]
    "roles/storage.admin" = [
      module.service-account-mlops.iam_email,
      module.service-account-github.iam_email,
      module.service-account-notebook.iam_email
    ]
  }
  labels = var.labels

  service_encryption_key_ids = {
    "aiplatform.googleapis.com" = compact([var.service_encryption_keys.aiplatform])
    "bigquery.googleapis.com"   = compact([var.service_encryption_keys.bq])
    "compute.googleapis.com"    = compact([var.service_encryption_keys.notebooks])
    #"cloudbuild.googleapis.com"    = compact([var.service_encryption_keys.storage])
    "notebooks.googleapis.com"     = compact([var.service_encryption_keys.notebooks])
    "secretmanager.googleapis.com" = compact([var.service_encryption_keys.secretmanager])
    "storage.googleapis.com"       = compact([var.service_encryption_keys.storage])
  }

  services = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerfilesystem.googleapis.com",
    "compute.googleapis.com",
    "datacatalog.googleapis.com",
    "dataflow.googleapis.com",
    "iam.googleapis.com",
    "ml.googleapis.com",
    "monitoring.googleapis.com",
    "notebooks.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ]
  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }

}

module "service-account-mlops" {
  source     = "../../../modules/iam-service-account"
  name       = "${var.prefix}-sa-mlops"
  project_id = module.project.project_id
}

resource "google_project_iam_member" "shared_vpc" {
  count   = local.use_shared_vpc ? 1 : 0
  project = var.network_config.host_project
  role    = "roles/compute.networkUser"
  member  = module.project.service_agents.notebooks.iam_email
}

resource "google_sourcerepo_repository" "code-repo" {
  count   = var.repo_name == null ? 0 : 1
  name    = var.repo_name
  project = module.project.project_id
}
