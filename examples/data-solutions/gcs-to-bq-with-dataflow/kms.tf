# Copyright 2022 Google LLC
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

module "kms" {
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    name     = "${var.prefix}-keyring",
    location = var.region
  }
  keys = {
    key-df  = null
    key-gce = null
    key-gcs = null
    key-bq  = null
  }
  key_iam = {
    key-gce = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project.service_accounts.robots.compute}"
      ]
    },
    key-gcs = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project.service_accounts.robots.storage}"
      ]
    },
    key-bq = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project.service_accounts.robots.bq}"
      ]
    },
    key-df = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.project.service_accounts.robots.dataflow}",
        "serviceAccount:${module.project.service_accounts.robots.compute}",
      ]
    }
  }
}

# module "kms-regional" {
#   source     = "../../../modules/kms"
#   project_id = module.project-kms.project_id
#   keyring = {
#     name     = "my-keyring-regional",
#     location = var.region
#   }
#   keys = { key-df = null }
#   key_iam = {
#   }
# }
