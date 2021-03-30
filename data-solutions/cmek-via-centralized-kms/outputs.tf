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

output "bucket" {
  description = "GCS Bucket URL."
  value       = module.kms-gcs.url
}

output "bucket_keys" {
  description = "GCS Bucket Cloud KMS crypto keys."
  value       = module.kms-gcs.bucket.encryption
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
    for instance in module.kms_vm_example.instances :
    instance.name => instance.network_interface.0.network_ip
  }
}

output "vm_keys" {
  description = "GCE VM Cloud KMS crypto keys."
  value = {
    for instance in module.kms_vm_example.instances :
    instance.name => instance.boot_disk.0.kms_key_self_link
  }
}
