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

locals {
  prod_kms_restricted_admins = [
    for sa in distinct(compact([
      var.service_accounts.data-platform-prod,
      var.service_accounts.project-factory-prod
    ])) : "serviceAccount:${sa}"
  ]
}

module "prod-sec-project" {
  source          = "../../../modules/project"
  name            = "prod-sec-core-0"
  parent          = var.folder_ids.security
  prefix          = var.prefix
  billing_account = var.billing_account.id
  iam = {
    "roles/cloudkms.viewer" = local.prod_kms_restricted_admins
  }
  iam_bindings_additive = {
    for member in local.prod_kms_restricted_admins :
    "kms_restricted_admin.${member}" => merge(local.kms_restricted_admin_template, {
      member = member
    })
  }
  labels   = { environment = "prod", team = "security" }
  services = local.project_services
}

module "prod-sec-kms" {
  for_each   = toset(local.kms_locations)
  source     = "../../../modules/kms"
  project_id = module.prod-sec-project.project_id
  keyring = {
    location = each.key
    name     = "prod-${each.key}"
  }
  keys = local.kms_locations_keys[each.key]
}
