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

module "kms" {
  count      = var.cmek_encryption ? 1 : 0
  source     = "../../../modules/kms"
  project_id = module.project.project_id
  keyring = {
    name     = "${var.prefix}-keyring"
    location = var.region
  }
  keys = {
    key-df = {
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          module.project.service_agents.dataflow.iam_email,
          module.project.service_agents.compute.iam_email,
        ]
      }
    }
    key-gcs = {
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          module.project.service_agents.storage.iam_email
        ]
      }
    }
    key-bq = {
      iam = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
          module.project.service_agents.bq.iam_email
        ]
      }
    }
  }
}
