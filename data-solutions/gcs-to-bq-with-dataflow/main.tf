# Copyright 2021 Google LLC
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

locals {
  vm-startup-script = join("\n", [
    "#! /bin/bash",
    "apt-get update && apt-get install -y bash-completion git python3-venv gcc build-essential python-dev python3-dev",
    "pip3 install --upgrade setuptools pip"
  ])
}

###############################################################################
#                          Projects - Centralized                             #
###############################################################################

module "project-service" {
  source          = "../../modules/project"
  name            = var.project_service_name
  parent          = var.root_node
  billing_account = var.billing_account
  services = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage-component.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "dataflow.googleapis.com",
    "cloudkms.googleapis.com",
  ]
  oslogin = true
}

module "project-kms" {
  source          = "../../modules/project"
  name            = var.project_kms_name
  parent          = var.root_node
  billing_account = var.billing_account
  services = [
    "cloudkms.googleapis.com",
  ]
}

###############################################################################
#                         Project Service Accounts                            #
###############################################################################

module "service-account-bq" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "bq-test"
  iam_project_roles = {
    (var.project_service_name) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/bigquery.admin"
    ]
  }
}

module "service-account-gce" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "gce-test"
  iam_project_roles = {
    (var.project_service_name) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/dataflow.admin",
      "roles/iam.serviceAccountUser",
      "roles/bigquery.dataOwner",
      "roles/bigquery.jobUser" # Needed to import data using 'bq' command
    ]
  }
}

module "service-account-df" {
  source     = "../../modules/iam-service-account"
  project_id = module.project-service.project_id
  name       = "df-test"
  iam_project_roles = {
    (var.project_service_name) = [
      "roles/dataflow.worker",
      "roles/bigquery.dataOwner",
      "roles/bigquery.metadataViewer",
      "roles/storage.objectViewer",
      "roles/bigquery.jobUser"
    ]
  }
}

# data "google_bigquery_default_service_account" "bq_sa" {
#   project = module.project-service.project_id
# }

# data "google_storage_project_service_account" "gcs_account" {
#   project = module.project-service.project_id
# }

###############################################################################
#                                   KMS                                       #
###############################################################################

module "kms" {
  source     = "../../modules/kms"
  project_id = module.project-kms.project_id
  keyring = {
    name     = "my-keyring",
    location = var.location
  }
  keys = { key-gce = null, key-gcs = null, key-bq = null }
  key_iam = {
    key-gce = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project-service.service_accounts.robots.compute}",
      ]
    },
    key-gcs = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project-service.service_accounts.robots.storage}",
        #"serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
      ]
    },
    key-bq = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project-service.service_accounts.robots.bq}",
        #"serviceAccount:${data.google_bigquery_default_service_account.bq_sa.email}",
      ]
    },
  }
}

module "kms-regional" {
  source     = "../../modules/kms"
  project_id = module.project-kms.project_id
  keyring = {
    name     = "my-keyring-regional",
    location = var.region
  }
  keys = { key-df = null }
  key_iam = {
    key-df = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project-service.service_accounts.robots.dataflow}",
        "serviceAccount:${module.project-service.service_accounts.robots.compute}",
      ]
    }
  }
}

###############################################################################
#                                   Networking                                #
###############################################################################

module "vpc" {
  source     = "../../modules/net-vpc"
  project_id = module.project-service.project_id
  name       = var.vpc_name
  subnets = [
    {
      ip_cidr_range      = var.vpc_ip_cidr_range
      name               = var.vpc_subnet_name
      region             = var.region
      secondary_ip_range = {}
    }
  ]
}

module "vpc-firewall" {
  source               = "../../modules/net-vpc-firewall"
  project_id           = module.project-service.project_id
  network              = module.vpc.name
  admin_ranges_enabled = true
  admin_ranges         = [var.vpc_ip_cidr_range]
}

module "nat" {
  source         = "../../modules/net-cloudnat"
  project_id     = module.project-service.project_id
  region         = var.region
  name           = "default"
  router_network = module.vpc.name
}

###############################################################################
#                                   GCE                                       #
###############################################################################

module "vm_example" {
  source     = "../../modules/compute-vm"
  project_id = module.project-service.project_id
  region     = var.region
  name       = "vm-example"
  network_interfaces = [{
    network    = module.vpc.self_link,
    subnetwork = module.vpc.subnet_self_links["${var.region}/${var.vpc_subnet_name}"],
    nat        = false,
    addresses  = null
    alias_ips  = null
  }]
  attached_disks = [
    {
      name        = "attacheddisk"
      size        = 10
      source      = null
      source_type = null
      options     = null
    }
  ]
  instance_count = 2
  boot_disk = {
    image        = "projects/debian-cloud/global/images/family/debian-10"
    type         = "pd-ssd"
    size         = 10
    encrypt_disk = true
  }
  encryption = {
    encrypt_boot            = true
    disk_encryption_key_raw = null
    kms_key_self_link       = module.kms.key_self_links.key-gce
  }
  metadata               = { startup-script = local.vm-startup-script }
  service_account        = module.service-account-gce.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  tags                   = ["ssh"]
}

###############################################################################
#                                   GCS                                       #
###############################################################################

module "kms-gcs" {
  source = "../../modules/gcs"
  for_each = {
    data = {
      members = {
        "roles/storage.admin" = [
          "serviceAccount:${module.service-account-gce.email}",
        ],
        "roles/storage.objectViewer" = [
          "serviceAccount:${module.service-account-df.email}",
        ]
      }
    }
    df-tmplocation = {
      members = {
        "roles/storage.admin" = [
          "serviceAccount:${module.service-account-gce.email}",
          "serviceAccount:${module.service-account-df.email}",
        ]
      }
    }
  }
  project_id     = module.project-service.project_id
  prefix         = module.project-service.project_id
  name           = each.key
  iam            = each.value.members
  encryption_key = module.kms.keys.key-gcs.self_link
  force_destroy  = true
}

###############################################################################
#                                   BQ                                        #
###############################################################################

module "bigquery-dataset" {
  source     = "../../modules/bigquery-dataset"
  project_id = module.project-service.project_id
  id         = "bq_dataset"
  access = {
    reader-group = { role = "READER", type = "user" }
    owner        = { role = "OWNER", type = "user" }
  }
  access_identities = {
    reader-group = module.service-account-bq.email
    owner        = module.service-account-bq.email
  }
  encryption_key = module.kms.keys.key-bq.self_link
  tables = {
    bq_import = {
      friendly_name = "BQ import"
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = null
      }
      schema = file("${path.module}/schema_bq_import.json")
      options = {
        clustering      = null
        expiration_time = null
        encryption_key  = module.kms.keys.key-bq.self_link
      }
      deletion_protection = true
    },
    df_import = {
      friendly_name = "Dataflow import"
      labels        = {}
      options       = null
      partitioning = {
        field = null
        range = null # use start/end/interval for range
        time  = null
      }
      schema = file("${path.module}/schema_df_import.json")
      options = {
        clustering      = null
        expiration_time = null
        encryption_key  = module.kms.keys.key-bq.self_link
      }
      deletion_protection = true
    }
  }
}
