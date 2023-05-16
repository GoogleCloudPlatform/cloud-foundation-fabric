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

# tfdoc:file:description Output variables.

output "bigquery-datasets" {
  description = "BigQuery datasets."
  value = {
    curated = module.cur-bq-0.dataset_id,
  }
}

output "dataproc-history-server" {
  description = "List of bucket names which have been assigned to the cluster."
  value       = one(module.processing-dp-historyserver)
}

output "gcs-buckets" {
  description = "GCS buckets."
  sensitive   = true
  value = {
    landing-cs-0    = module.land-sa-cs-0,
    processing-cs-0 = module.processing-cs-0,
    cur-cs-0        = module.cur-cs-0,
  }
}

output "kms_keys" {
  description = "Cloud MKS keys."
  value       = var.service_encryption_keys
}

output "projects" {
  description = "GCP Projects informations."
  value = {
    project_number = {
      landing    = module.land-project.number,
      common     = module.common-project.number,
      curated    = module.cur-project.number,
      processing = module.processing-project.number,
    }
    project_id = {
      landing    = module.land-project.project_id,
      common     = module.common-project.project_id,
      curated    = module.cur-project.project_id,
      processing = module.processing-project.project_id,
    }
  }
}

output "vpc_network" {
  description = "VPC network."
  value = {
    processing_transformation = local.processing_vpc
    processing_composer       = local.processing_vpc
  }
}

output "vpc_subnet" {
  description = "VPC subnetworks."
  value = {
    processing_transformation = local.processing_subnet
    processing_composer       = local.processing_subnet
  }
}
