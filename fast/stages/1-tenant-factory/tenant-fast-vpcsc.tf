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

# tfdoc:file:description Per-tenant VPC-SC resources.

module "tenant-vpcsc-policy" {
  source = "../../../modules/vpc-sc"
  for_each = {
    for k, v in local.tenants : k => v if v.vpc_sc_policy_create == true
  }
  access_policy = null
  access_policy_create = {
    parent = "organizations/${var.organization.id}"
    title  = "tenant-${each.key}"
    scopes = [module.tenant-core-folder[each.key].id]
  }
  iam_bindings_additive = merge(
    {
      tenant_admins = {
        role   = "roles/accesscontextmanager.policyAdmin"
        member = each.value.admin_principal
      }
      tenant_sa = {
        role   = "roles/accesscontextmanager.policyAdmin"
        member = module.tenant-sa[each.key].iam_email
      }
    },
    each.value.fast_config == null ? {} : {
      tenant_sa_resman = {
        role   = "roles/accesscontextmanager.policyAdmin"
        member = module.tenant-automation-tf-resman-sa[each.key].iam_email
      }
      tenant_sa_security = {
        role   = "roles/accesscontextmanager.policyAdmin"
        member = module.tenant-automation-tf-security-sa[each.key].iam_email
      }
      tenant_sa_security_r = {
        role   = "roles/accesscontextmanager.policyReader"
        member = module.tenant-automation-tf-security-r-sa[each.key].iam_email
      }
    }
  )
}
