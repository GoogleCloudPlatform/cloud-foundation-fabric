# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "kms_regional_primary" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = var.regions.primary
    name     = "keyring-primary"
  }
  keys = {
    "key-a" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      "serviceAccount:service-${var.project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@serverless-robot-prod.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
    ]
  }
}

module "kms_regional_secondary" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = var.regions.secondary
    name     = "keyring-secondary"
  }
  keys = {
    "key-b" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      "serviceAccount:service-${var.project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@serverless-robot-prod.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
    ]
  }
}

module "kms_global" {
  source     = "./fabric/modules/kms"
  project_id = var.project_id
  keyring = {
    location = "global"
    name     = "keyring-gl"
  }
  keys = {
    "key-global" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      "serviceAccount:service-${var.project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@serverless-robot-prod.iam.gserviceaccount.com",
      "serviceAccount:service-${var.project_number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
    ]
  }
}
