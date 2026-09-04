# Copyright 2026 Google LLC
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

project_id   = "test-project"
prefix       = "foo"
name         = "test-pool"
display_name = "Test WIF Pool"
description  = "Test WIF Pool description"
iam = {
  "roles/iam.workloadIdentityPoolViewer" = ["user:admin@example.com"]
}
identity_providers = {
  github = {
    display_name = "GitHub Actions"
    description  = "GitHub provider"
    attribute_mapping = {
      "google.subject"             = "assertion.sub"
      "attribute.repository"       = "assertion.repository"
      "attribute.repository_owner" = "assertion.repository_owner"
    }
    attribute_condition = "assertion.repository_owner == 'test-org'"
    oidc = {
      issuer_uri = "https://token.actions.githubusercontent.com"
    }
  }
}
service_account_impersonation = {
  ci = {
    service_account_id = "test-sa@test-project.iam.gserviceaccount.com"
    attribute_members  = ["attribute.repository/test-org/test-repo"]
  }
}
