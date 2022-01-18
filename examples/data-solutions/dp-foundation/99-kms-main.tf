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
  count      = var.cmek_encryption ? 1 : 0
  source     = "../../../modules/kms"
  project_id = module.lnd-prj.project_id
  keyring = {
    name     = "${var.prefix}-keyring",
    location = var.region
  }
  keys = {
    key-bq  = null
    key-cmp = null
    key-df  = null
    key-gcs = null
    key-ps  = null
  }
  key_iam = {
    key-bq = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.lnd-prj.service_accounts.robots.bq}",
        "serviceAccount:${module.dtl-0-prj.service_accounts.robots.bq}",
        "serviceAccount:${module.dtl-1-prj.service_accounts.robots.bq}",
        "serviceAccount:${module.dtl-2-prj.service_accounts.robots.bq}",
        "serviceAccount:${module.dtl-exp-prj.service_accounts.robots.bq}",
      ]
    },
    key-cmp = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.orc-prj.service_accounts.robots.artifactregistry}",
        "serviceAccount:${module.orc-prj.service_accounts.robots.container-engine}",
        "serviceAccount:${module.orc-prj.service_accounts.robots.compute}",
        "serviceAccount:${module.orc-prj.service_accounts.robots.composer}",
        "serviceAccount:${module.orc-prj.service_accounts.robots.pubsub}",
        "serviceAccount:${module.orc-prj.service_accounts.robots.storage}",

      ]
    },
    key-df = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.lod-prj.service_accounts.robots.dataflow}",
        "serviceAccount:${module.lod-prj.service_accounts.robots.compute}",
        "serviceAccount:${module.trf-prj.service_accounts.robots.dataflow}",
        "serviceAccount:${module.trf-prj.service_accounts.robots.compute}",
      ]
    }
    key-gcs = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.dtl-0-prj.service_accounts.robots.storage}",
        "serviceAccount:${module.dtl-1-prj.service_accounts.robots.storage}",
        "serviceAccount:${module.dtl-2-prj.service_accounts.robots.storage}",
        "serviceAccount:${module.dtl-exp-prj.service_accounts.robots.storage}",
        "serviceAccount:${module.lnd-prj.service_accounts.robots.storage}",
        "serviceAccount:${module.lod-prj.service_accounts.robots.storage}",
        "serviceAccount:${module.orc-prj.service_accounts.robots.storage}",
        "serviceAccount:${module.trf-prj.service_accounts.robots.storage}",
      ]
    },
    key-ps = {
      "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
        "serviceAccount:${module.lnd-prj.service_accounts.robots.pubsub}"
      ]
    }
  }
}
