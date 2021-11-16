/**
 * Copyright 2021 Google LLC
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

locals {
  permissions = setproduct(var.environments, var.project_permissions)
}

resource "google_project_iam_member" "sa-project-permissions" {
  count = length(local.permissions)

  project = var.project_ids_full[local.permissions[count.index][0]]
  role    = local.permissions[count.index][1]

  member = format("serviceAccount:%s", var.service_accounts[local.permissions[count.index][0]])
}
