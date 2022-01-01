/**
 * Copyright 2022 Google LLC
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
  folder_roles = concat(var.iam_enviroment_roles, local.sa_xpn_folder_roles)
  iam          = var.iam == null ? {} : var.iam
  folder_iam_service_account_bindings = {
    for pair in setproduct(keys(var.environments), local.folder_roles) :
    "${pair.0}-${pair.1}" => { environment = pair.0, role = pair.1 }
  }
  org_iam_service_account_bindings = {
    for pair in setproduct(keys(var.environments), concat(
      local.sa_xpn_org_roles,
      local.sa_billing_org_roles,
    local.sa_billing_org_roles)) :
    "${pair.0}-${pair.1}" => { environment = pair.0, role = pair.1 }
  }
  billing_iam_service_account_bindings = {
    for pair in setproduct(keys(var.environments), local.sa_billing_account_roles) :
    "${pair.0}-${pair.1}" => { environment = pair.0, role = pair.1 }
  }
  service_accounts = {
    for key, sa in google_service_account.environment :
    key => "serviceAccount:${sa.email}"
  }
  sa_billing_account_roles = (
    var.iam_billing_config.target_org ? [] : ["roles/billing.user"]
  )
  sa_billing_org_roles = (
    !var.iam_billing_config.target_org ? [] : ["roles/billing.user"]
  )
  sa_xpn_folder_roles = (
    local.sa_xpn_target_org ? [] : ["roles/compute.xpnAdmin"]
  )
  sa_xpn_org_roles = (
    local.sa_xpn_target_org
    ? ["roles/compute.xpnAdmin", "roles/resourcemanager.organizationViewer"]
    : ["roles/resourcemanager.organizationViewer"]
  )
  sa_xpn_target_org = (
    var.iam_xpn_config.target_org
    ||
    substr(var.root_node, 0, 13) == "organizations"
  )
}
