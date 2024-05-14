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
  byte_length = 4
}

resource "random_id" "disks_kms" {
  for_each    = var.apigee_config.instances
  byte_length = 4
}

module "database_kms" {
  count      = try(var.apigee_config.organization.database_encryption_key, null) == null ? 1 : 0
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = "global"
    name     = "apigee-${random_id.database_kms.hex}"
  }
  keys = {
    database-key = {
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "2592000s"
      labels          = null
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["serviceAccount:${module.project.service_accounts.robots.apigee}"]
      }
    }
  }
}

module "disks_kms" {
  for_each   = var.apigee_config.instances
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = each.key
    name     = "apigee-${each.key}-${random_id.disks_kms[each.key].hex}"
  }
  keys = {
    disk-key = {
      purpose         = "ENCRYPT_DECRYPT"
      rotation_period = "2592000s"
      labels          = null
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = ["serviceAccount:${module.project.service_accounts.robots.apigee}"]
      }
    }
  }
}
