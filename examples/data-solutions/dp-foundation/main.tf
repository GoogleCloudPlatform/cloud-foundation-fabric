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

locals {
  groups                  = { for k, v in var.groups : k => "${v}@${var.organization.domain}" }
  groups_iam              = { for k, v in local.groups : k => "group:${v}" }
  service_encryption_keys = var.service_encryption_keys

  # Uncomment this section and assigne comment the previous line

  # service_encryption_keys = {
  #   bq       = module.sec-kms-1.key_ids.bq
  #   composer = module.sec-kms-2.key_ids.composer
  #   dataflow = module.sec-kms-2.key_ids.dataflow
  #   storage  = module.sec-kms-1.key_ids.storage
  #   pubsub   = module.sec-kms-0.key_ids.pubsub
  # }
}
