/**
 * Copyright 2023 Google LLC
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

locals {
  groups = {
    for k, v in var.groups_gcve : k => "${v}@${var.organization_domain}"
  }
  groups_iam = {
    for k, v in local.groups : k => "group:${v}"
  }
}

module "gcve-project-0" {
  source          = "../../../modules/project"
  billing_account = var.billing_account_id
  name            = var.project_id
  parent          = var.folder_id
  prefix          = var.prefix
  group_iam = merge(var.group_iam, {
    "roles/vmwareengine.vmwareengineAdmin" = [ ##
      local.groups_iam.gcp-gcve-admin
    ]
    "roles/vmwareengine.vmwareengineViewer" = [ ##
      local.groups_iam.gcp-gcve-viewers
    ] 
    }
  )
  labels = var.labels
  iam    = var.iam
  services = concat(
    [
      "vmwareengine.googleapis.com",
    ],
    var.project_services
  )
  # specify project-level org policies here if you need them
}
