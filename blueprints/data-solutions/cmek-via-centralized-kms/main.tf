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

locals {
  # Needed when you create KMS keys and encrypted resources in the same terraform state but different projects.
  kms_keys = {
    gce = "projects/${module.project-kms.project_id}/locations/${var.region}/keyRings/${var.prefix}-${var.region}/cryptoKeys/key-gcs"
    gcs = "projects/${module.project-kms.project_id}/locations/${var.region}/keyRings/${var.prefix}-${var.region}/cryptoKeys/key-gcs"
  }
}

###############################################################################
#                                   Projects                                  #
###############################################################################

module "project-service" {
  source          = "../../../modules/project"
  name            = var.project_config.project_ids.service
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  services = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
    "storage-component.googleapis.com",
  ]
  service_encryption_key_ids = {
    "compute.googleapis.com" = [local.kms_keys.gce]
    "storage.googleapis.com" = [local.kms_keys.gcs]
  }
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
  depends_on = [
    module.kms
  ]
}

module "project-kms" {
  source          = "../../../modules/project"
  name            = var.project_config.project_ids.encryption
  parent          = var.project_config.parent
  billing_account = var.project_config.billing_account_id
  project_create  = var.project_config.billing_account_id != null
  prefix          = var.project_config.billing_account_id == null ? null : var.prefix
  services = [
    "cloudkms.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
  service_config = {
    disable_on_destroy = false, disable_dependent_services = false
  }
}

###############################################################################
#                                   Networking                                #
###############################################################################

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = module.project-service.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/20"
      name          = "${var.prefix}-${var.region}"
      region        = var.region
    }
  ]
}

module "vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  project_id = module.project-service.project_id
  network    = module.vpc.name
  default_rules_config = {
    admin_ranges = ["10.0.0.0/20"]
  }
}

###############################################################################
#                                   KMS                                       #
###############################################################################

module "kms" {
  source     = "../../../modules/kms"
  project_id = module.project-kms.project_id
  keyring = {
    name     = "${var.prefix}-${var.region}",
    location = var.region
  }
  keys = {
    key-gce = {}
    key-gcs = {}
  }
}

###############################################################################
#                                   GCE                                       #
###############################################################################

module "vm_example" {
  source     = "../../../modules/compute-vm"
  project_id = module.project-service.project_id
  zone       = "${var.region}-b"
  name       = "${var.prefix}-vm"
  network_interfaces = [{
    network    = module.vpc.self_link,
    subnetwork = module.vpc.subnet_self_links["${var.region}/${var.prefix}-${var.region}"],
    nat        = false,
    addresses  = null
  }]
  attached_disks = [
    {
      name        = "data"
      size        = 10
      source      = null
      source_type = null
      options     = null
    }
  ]
  boot_disk = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/debian-10"
      type  = "pd-ssd"
      size  = 10
    }
  }
  tags = ["ssh"]
  encryption = {
    encrypt_boot            = true
    disk_encryption_key_raw = null
    kms_key_self_link       = local.kms_keys.gce
  }
}

###############################################################################
#                                   GCS                                       #
###############################################################################

module "kms-gcs" {
  source         = "../../../modules/gcs"
  project_id     = module.project-service.project_id
  prefix         = var.prefix
  name           = "${var.prefix}-bucket"
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = local.kms_keys.gcs
  force_destroy  = !var.deletion_protection
}
