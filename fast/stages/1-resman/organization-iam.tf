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

# tfdoc:file:description Organization-level IAM bindings locals.

locals {
  iam_bindings_additive = merge(
    # network and security
    {
      sa_net_fw_policy_admin = {
        member = module.branch-network-sa.iam_email
        role   = "roles/compute.orgFirewallPolicyAdmin"
      }
      sa_net_xpn_admin = {
        member = module.branch-network-sa.iam_email
        role   = "roles/compute.xpnAdmin"
      }
      sa_sec_asset_viewer = {
        member = module.branch-security-sa.iam_email
        role   = "roles/cloudasset.viewer"
      }
      sa_sec_vpcsc_admin = {
        member = module.branch-security-sa.iam_email
        role   = "roles/accesscontextmanager.policyAdmin"
      }
    },
    # optional billing roles for network and security
    local.billing_mode != "org" ? {} : {
      sa_net_billing = {
        member = module.branch-network-sa.iam_email
        role   = "roles/billing.user"
      }
      sa_sec_billing = {
        member = module.branch-security-sa.iam_email
        role   = "roles/billing.user"
      }
    },
    # optional billing roles for data platform
    local.billing_mode != "org" || !var.fast_features.data_platform ? {} : {
      sa_dp_dev_billing = {
        member = module.branch-dp-dev-sa[0].iam_email
        role   = "roles/billing.user"
      }
      sa_dp_prod_billing = {
        member = module.branch-dp-prod-sa[0].iam_email
        role   = "roles/billing.user"
      }
    },
    # optional billing roles for GKE
    local.billing_mode != "org" || !var.fast_features.gke ? {} : {
      sa_gke_dev_billing = {
        member = module.branch-gke-dev-sa[0].iam_email
        role   = "roles/billing.user"
      }
      sa_gke_prod_billing = {
        member = module.branch-gke-prod-sa[0].iam_email
        role   = "roles/billing.user"
      }
    },
    # optional billing roles for project factory
    local.billing_mode != "org" || !var.fast_features.project_factory ? {} : {
      sa_pf_dev_billing = {
        member = module.branch-pf-dev-sa[0].iam_email
        role   = "roles/billing.user"
      }
      sa_pf_dev_costs_manager = {
        member = module.branch-pf-dev-sa[0].iam_email
        role   = "roles/billing.costsManager"
      }
      sa_pf_prod_billing = {
        member = module.branch-pf-prod-sa[0].iam_email
        role   = "roles/billing.user"
      }
      sa_pf_prod_costs_manager = {
        member = module.branch-pf-prod-sa[0].iam_email
        role   = "roles/billing.costsManager"
      }
    },
    # scoped org policy admin grants for project factory
    !var.fast_features.project_factory ? {} : {
      sa_pf_dev_conditional_org_policy = {
        member = module.branch-pf-dev-sa[0].iam_email
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title       = "org_policy_tag_pf_scoped_dev"
          description = "Org policy tag scoped grant for project factory dev."
          expression  = <<-END
            resource.matchTag('${var.organization.id}/${var.tag_names.context}', 'teams')
            &&
            resource.matchTag('${var.organization.id}/${var.tag_names.environment}', 'development')
          END
        }
      }
      sa_pf_prod_conditional_org_policy = {
        member = module.branch-pf-prod-sa[0].iam_email
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title       = "org_policy_tag_pf_scoped_prod"
          description = "Org policy tag scoped grant for project factory prod."
          expression  = <<-END
            resource.matchTag('${var.organization.id}/${var.tag_names.context}', 'teams')
          END
        }
      }
    },
    # lightweight tenant roles
    {
      for k, v in var.tenants : "oslogin_ext_user-tenant_${k}" => {
        member = "domain:${v.organization.domain}"
        role   = "roles/compute.osLoginExternalUser"
      } if v.organization != null
    },
    {
      for k, v in var.tenants : "org-viewer-tenant_${k}_domain" => {
        member = "domain:${v.organization.domain}"
        role   = "roles/resourcemanager.organizationViewer"
      } if v.organization != null
    },
    {
      for k, v in var.tenants : "org-viewer-tenant_${k}_admin" => {
        member = v.admin_principal
        role   = "roles/resourcemanager.organizationViewer"
      }
    },
    local.billing_mode != "org" ? {} : {
      for k, v in var.tenants : "billing_user-tenant_${k}_billing_admin" => {
        member = v.admin_principal
        role   = "roles/billing.user"
      }
    },
  )
}
