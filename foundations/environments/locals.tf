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
  folder_roles    = concat(var.iam_folder_roles, local.sa_xpn_folder_role)
  organization_id = element(split("/", var.organization_id), 1)
  sa_billing_account_role = (
    var.iam_billing_config.target_org ? [] : ["roles/billing.user"]
  )
  sa_billing_org_role = (
    !var.iam_billing_config.target_org ? [] : ["roles/billing.user"]
  )
  sa_xpn_folder_role = (
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
  logging_sinks = {
    audit-logs = {
      type             = "bigquery"
      destination      = module.audit-dataset.id
      filter           = var.audit_filter
      iam              = true
      include_children = true
    }
  }
  root_node_type = split("/", var.root_node)[0]
}
