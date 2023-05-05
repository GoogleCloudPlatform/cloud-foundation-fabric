# Copyright 2023 Google LLC
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

output "folders" {
  description = "Folders id."
  value = {
    shielded-folder = module.folder.id
    workload-folder = module.folder-workload.id
  }
}

output "folders_sink_writer_identities" {
  description = "Folders id."
  value = {
    shielded-folder = module.folder.sink_writer_identities
    workload-folder = module.folder-workload.sink_writer_identities
  }
}

output "kms_keys" {
  description = "Cloud KMS encryption keys created."
  value       = { for k, v in module.sec-kms : k => v.key_ids }
}
