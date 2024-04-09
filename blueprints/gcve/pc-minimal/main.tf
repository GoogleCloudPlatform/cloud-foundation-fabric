/**
 * Copyright 2024 Google LLC
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

# tfdoc:file:description Project.

module "gcve-project-0" {
  source          = "../../../modules/project"
  billing_account = var.billing_account_id
  name            = var.project_id
  parent          = var.folder_id
  prefix          = var.prefix
  iam_by_principals = merge({
    (var.groups.gcp-gcve-admins)  = ["roles/vmwareengine.vmwareengineAdmin"]
    (var.groups.gcp-gcve-viewers) = ["roles/vmwareengine.vmwareengineViewer"]
    },
    var.iam_by_principals
  )
  iam    = var.iam
  labels = var.labels
  services = concat([
    "vmwareengine.googleapis.com",
    ],
    var.project_services
  )
}
