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

output "bq_tables" {
  description = "Bigquery Tables."
  value       = module.bigquery-dataset.table_ids
}

output "buckets" {
  description = "GCS Bucket Cloud KMS crypto keys."
  value = {
    for name, bucket in module.kms-gcs :
    bucket.name => bucket.url
  }
}

output "projects" {
  description = "Project ids."
  value = {
    service-project = module.project-service.project_id
    kms-project     = module.project-kms.project_id
  }
}

output "vm" {
  description = "GCE VMs."
  value = {
    for instance in module.vm_example.instances :
    instance.name => instance.network_interface.0.network_ip
  }
}
