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

# Test for $iam_principals interpolation within tags
# This test demonstrates the bug where if a service account created by the same
# project-factory is referenced via $iam_principals:service_accounts/... in tags,
# the interpolation fails because the context doesn't have the key at the time
# tags is processed (tags are processed in module "projects", but iam_principals
# for the project's own service accounts are only added in module "projects-iam").

# Case 1: iam_principals key IS present in context - should work
context = {
  iam_principals = {
    # Simulate service accounts created by project-factory with nested paths
    "service_accounts/my-project/automation/rw" = "serviceAccount:my-project-rw@my-project.iam.gserviceaccount.com"
  }
}

tags = {
  allow-key-creation = {
    description = "Allow key creation for automation service account"
    values = {
      allow = {
        description = "Allow key creation"
        iam = {
          "roles/resourcemanager.tagUser" = [
            "$iam_principals:service_accounts/my-project/automation/rw"
          ]
        }
      }
    }
  }
}
