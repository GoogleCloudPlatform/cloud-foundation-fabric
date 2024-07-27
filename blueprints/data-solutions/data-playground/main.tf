# Copyright 2024 Google LLC
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

###############################################################################
#                                   Project                                   #
###############################################################################
locals {
  shared_vpc_project = try(var.network_config.host_project, null)

  subnet = (
    local.use_shared_vpc
    ? var.network_config.subnet_self_link
    : values(module.vpc[0].subnet_self_links)[0]
  )
  vpc = (
    local.use_shared_vpc
    ? var.network_config.network_self_link
    : module.vpc[0].self_link
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

module "project" {
  source          = "../../../modules/project"
  name            = var.project_id
  parent          = try(var.project_create.parent, null)
  billing_account = try(var.project_create.billing_account_id, null)
  project_create  = var.project_create != null
  prefix          = var.project_create == null ? null : var.prefix
  services = [
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "dialogflow.googleapis.com",
    "dataflow.googleapis.com",
    "ml.googleapis.com",
    "notebooks.googleapis.com",
    "orgpolicy.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com"
  ]

  shared_vpc_service_config = local.shared_vpc_project == null ? null : {
    attach       = true
    host_project = local.shared_vpc_project
  }

  org_policies = {
    # "compute.requireOsLogin" = {
    #   rules = [{ enforce = false }]
    # }
    # Example of applying a project wide policy, mainly useful for Composer 1
  }
  service_encryption_key_ids = {
    "compute.googleapis.com"  = compact([var.service_encryption_keys.compute])
    "bigquery.googleapis.com" = compact([var.service_encryption_keys.bq])
    "storage.googleapis.com"  = compact([var.service_encryption_keys.storage])
  }
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
}

###############################################################################
#                                Networking                                   #
###############################################################################

module "vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/20"
      name          = "${var.prefix}-subnet"
      region        = var.region
    }
  ]
}

module "vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  network    = module.vpc[0].name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/20"]
  }
  ingress_rules = {
    #TODO Remove and rely on 'ssh' tag once terraform-provider-google/issues/9273 is fixed
    ("${var.prefix}-iap") = {
      description   = "Enable SSH from IAP on Notebooks."
      source_ranges = ["35.235.240.0/20"]
      targets       = ["notebook-instance"]
      rules         = [{ protocol = "tcp", ports = [22] }]
    }
  }
}

module "cloudnat" {
  source         = "../../../modules/net-cloudnat"
  count          = local.use_shared_vpc ? 0 : 1
  project_id     = module.project.project_id
  name           = "${var.prefix}-default"
  region         = var.region
  router_network = module.vpc[0].name
}

resource "google_project_iam_member" "shared_vpc" {
  count   = local.use_shared_vpc ? 1 : 0
  project = var.network_config.host_project
  role    = "roles/compute.networkUser"
  member  = module.project.service_agents.notebooks.iam_email
}


###############################################################################
#                              Storage                                        #
###############################################################################

module "bucket" {
  source         = "../../../modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.prefix
  location       = var.location
  name           = "data"
  encryption_key = var.service_encryption_keys.storage
  force_destroy  = !var.deletion_protection
}

module "dataset" {
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.project.project_id
  id             = "${replace(var.prefix, "-", "_")}_data"
  encryption_key = var.service_encryption_keys.bq
}

###############################################################################
#                         Vertex AI Notebook                                   #
###############################################################################

module "service-account-notebook" {
  source     = "../../../modules/iam-service-account"
  project_id = module.project.project_id
  name       = "notebook-sa"
  iam_project_roles = {
    (module.project.project_id) = [
      "roles/bigquery.admin",
      "roles/bigquery.jobUser",
      "roles/bigquery.dataEditor",
      "roles/bigquery.user",
      "roles/dialogflow.client",
      "roles/storage.admin",
    ]
  }
}

resource "google_notebooks_instance" "playground" {
  name         = "${var.prefix}-notebook"
  location     = format("%s-%s", var.region, "b")
  machine_type = "e2-medium"
  project      = module.project.project_id

  container_image {
    repository = "gcr.io/deeplearning-platform-release/base-cpu"
    tag        = "latest"
  }

  install_gpu_driver = true
  boot_disk_type     = "PD_SSD"
  boot_disk_size_gb  = 110
  disk_encryption    = var.service_encryption_keys.compute != null ? "CMEK" : null
  kms_key            = var.service_encryption_keys.compute

  no_public_ip    = true
  no_proxy_access = false

  network = local.vpc
  subnet  = local.subnet

  service_account = module.service-account-notebook.email

  # Remove once terraform-provider-google/issues/9164 is fixed
  lifecycle {
    ignore_changes = [disk_encryption, kms_key]
  }

  #TODO Uncomment once terraform-provider-google/issues/9273 is fixed
  # tags = ["ssh"]
  depends_on = [
    google_project_iam_member.shared_vpc,
  ]
}
