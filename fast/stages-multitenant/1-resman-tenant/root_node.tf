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

# tfdoc:file:description Tenant root folder configuration.

module "root-folder" {
  source        = "../../../modules/folder"
  id            = var.root_node
  folder_create = var.test_skip_data_sources
  # start test attributes
  parent = (
    var.test_skip_data_sources ? "organizations/${var.organization.id}" : null
  )
  name = var.test_skip_data_sources ? "Test" : null
  # end test attributes
  iam_bindings_additive = {
    sa_net_fw_policy_admin = {
      member = local.automation_sas_iam.networking
      role   = "roles/compute.orgFirewallPolicyAdmin"
    }
    sa_net_xpn_admin = {
      member = local.automation_sas_iam.networking
      role   = "roles/compute.xpnAdmin"
    }
    sa_sec_vpcsc_admin = {
      member = local.automation_sas_iam.security
      role   = "roles/accesscontextmanager.policyAdmin"
    }
  }
  org_policies_data_path = var.organization_policy_data_path
}
