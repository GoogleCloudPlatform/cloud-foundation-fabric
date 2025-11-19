/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "terraform_data" "precondition-cicd" {
  lifecycle {
    precondition {
      condition = alltrue([
        for k, v in local.cicd_workflows :
        v.repository.name != null && v.repository.type != null
      ])
      error_message = "Incomplete repository configuration in CI/CD workflows."
    }
    precondition {
      condition = alltrue([
        for k, v in local.cicd_workflows :
        v.provider_files.apply != null && v.provider_files.plan != null
      ])
      error_message = "Incomplete provider files configuration in CI/CD workflows."
    }
    precondition {
      condition = alltrue([
        for k, v in local.cicd_workflows :
        v.service_accounts.apply != null && v.service_accounts.plan != null
      ])
      error_message = "Incomplete service account configuration in CI/CD workflows."
    }
    precondition {
      condition = alltrue([
        for k, v in local.cicd_workflows : (
          v.workload_identity.provider != null &&
          v.workload_identity.iam_principalsets.plan != null
        )
      ])
      error_message = "Incomplete workload identity configuration in CI/CD workflows."
    }
    precondition {
      condition = alltrue([
        for k, v in local.cicd_workflows : (
          length(v.repository.apply_branches) == 0 ||
          v.workload_identity.iam_principalsets.apply != null
        )
      ])
      error_message = "Missing apply principalset in CI/CD workflows."
    }
  }
}
