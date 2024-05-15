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

# tfdoc:file:description Per-tenant billing IAM.

locals {
  # additive only since these operate at org level or BA level
  _billing_bindings = flatten([
    for k, v in local.tenants : [
      v.fast_config == null
      # non-fast tenant
      ? [
        {
          role   = "roles/billing.user"
          member = v.admin_principal
          tenant = k
        }
      ]
      # fast tenant
      : [
        {
          role   = "roles/billing.admin"
          member = local.fast_tenants[k].principals.gcp-billing-admins
          tenant = k
        },
        {
          role   = "roles/billing.admin"
          member = local.fast_tenants[k].principals.gcp-organization-admins
          tenant = k
        },
        {
          role   = "roles/billing.admin"
          member = module.tenant-automation-tf-resman-sa[k].iam_email
          tenant = k
        },
        {
          role   = "roles/billing.viewer"
          member = module.tenant-automation-tf-resman-r-sa[k].iam_email
          tenant = k
        },
      ]
    ] if v.billing_account.no_iam == false
  ])
  # group bindings applied per billing account
  _billing_ba_bindings = {
    for v in local._billing_bindings :
    local.tenants[v.tenant].billing_account.id => v...
    if local.tenants[v.tenant].billing_account.is_org_level != true
  }
  # convert billing account grouped lists to maps
  billing_ba_bindings = {
    for k, v in local._billing_ba_bindings : k => {
      for vv in v :
      "${vv.tenant}-${vv.role}-${vv.member}" => vv
    }
  }
  # convert org bindings to a map
  billing_org_bindings = {
    for v in local._billing_bindings :
    "${v.tenant}-${v.role}-${v.member}" => v
    if local.tenants[v.tenant].billing_account.is_org_level == true
  }
}

module "billing-account" {
  source                = "../../../modules/billing-account"
  for_each              = local.billing_ba_bindings
  id                    = each.key
  iam_bindings_additive = each.value
}

module "organization-billing" {
  source                = "../../../modules/organization"
  organization_id       = "organizations/${var.organization.id}"
  iam_bindings_additive = local.billing_org_bindings
}
