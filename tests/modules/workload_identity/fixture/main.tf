# Copyright 2022 Google LLC
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

module "workload-identity-federation" {
  source                    = "../../../../modules/workload-identity"
  project_id                = "my-project"
  workload_identity_pool_id = "example-pool"
  workload_identity_pool_providers = {
    example-provider = {
      display_name        = null
      description         = null
      disabled            = false
      attribute_condition = null
      attribute_mapping = {
        "google.subject" = "assertion.sub"
      }
      aws = null
      oidc = {
        allowed_audiences = null
        issuer_uri        = "https://sts.windows.net/7d49d473-6f59-49d5-b395-84fafaff49a8"
      }
    }
  }
}
