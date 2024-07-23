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

resource "random_id" "database_kms" {
  count       = var.apigee_config.organization.database_encryption_key_config.auto_create ? 1 : 0
  byte_length = 4
}

resource "random_id" "control_plane_kms" {
  count = (var.apigee_config.organization.control_plane_encryption_key_config.auto_create &&
  local.control_plan_in_eu_or_us) ? 1 : 0
  byte_length = 4
}

resource "random_id" "api_consumer_data_kms" {
  count       = var.apigee_config.organization.api_consumer_data_encryption_key_config.auto_create ? 1 : 0
  byte_length = 4
}

resource "random_id" "disks_kms" {
  for_each    = toset([for k, v in var.apigee_config.instances : k if v.disk_encryption_key_config.auto_create])
  byte_length = 4
}

module "database_kms" {
  count      = var.apigee_config.organization.database_encryption_key_config.auto_create ? 1 : 0
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.apigee_config.organization.api_consumer_data_location == null ? "global" : var.apigee_config.organization.api_consumer_data_location
    name     = "apigee-database-${random_id.database_kms[0].hex}"
  }
  keys = {
    database-key = {
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "2592000s"
      labels          = null
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          module.project.service_agents.apigee.iam_email
        ]
      }
    }
  }
}

module "api_consumer_data_kms" {
  count      = var.apigee_config.organization.api_consumer_data_encryption_key_config.auto_create ? 1 : 0
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.apigee_config.organization.api_consumer_data_location
    name     = "apigee-api-consumer-data-${random_id.api_consumer_data_kms[0].hex}"
  }
  keys = {
    api-consumer-data-key = {
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "2592000s"
      labels          = null
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          module.project.service_agents.apigee.iam_email
        ]
      }
    }
  }
}

module "control_plane_kms" {
  count = (var.apigee_config.organization.control_plane_encryption_key_config.auto_create
  && local.control_plan_in_eu_or_us ? 1 : 0)
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.apigee_config.organization.api_consumer_data_location
    name     = "apigee-control-plane-${random_id.control_plane_kms[0].hex}"
  }
  keys = {
    control-plane-key = {
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "2592000s"
      labels          = null
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          module.project.service_agents.apigee.iam_email
        ]
      }
    }
  }
}

module "disks_kms" {
  for_each   = toset([for k, v in var.apigee_config.instances : k if v.disk_encryption_key_config.auto_create])
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = each.key
    name     = "apigee-disk-${each.value}-${random_id.disks_kms[each.value].hex}"
  }
  keys = {
    disk-key = {
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "2592000s"
      labels          = null
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          module.project.service_agents.apigee.iam_email
        ]
      }
    }
  }
}
