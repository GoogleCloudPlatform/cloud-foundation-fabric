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

output "project_id" {
  description = "GCP Project ID."
  value       = module.project.project_id
}

output "tfc_workspace_wariables" {
  description = "Variables to be set on the TFC workspace."
  value = {
    TFC_GCP_PROVIDER_AUTH             = "true",
    TFC_GCP_PROJECT_NUMBER            = module.project.number,
    TFC_GCP_WORKLOAD_POOL_ID          = google_iam_workload_identity_pool.tfc-pool.workload_identity_pool_id,
    TFC_GCP_WORKLOAD_PROVIDER_ID      = google_iam_workload_identity_pool_provider.tfc-pool-provider.workload_identity_pool_provider_id,
    TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL = module.sa-tfc.email
  }
}
