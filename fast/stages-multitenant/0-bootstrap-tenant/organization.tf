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

# tfdoc:file:description Organization tag and conditional IAM grant.

locals {
  iam_tenant_condition = format(
    "resource.matchTag('%s', '%s')",
    local.tag_keys.tenant,
    var.tenant_config.short_name
  )
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  iam_bindings_additive = merge(
    # admin group IAM
    {
      admins_org_viewer = {
        member = local.principals.gcp-admins
        role   = "roles/resourcemanager.organizationViewer"
      }
      admins_org_policy_admin = {
        member = local.principals.gcp-admins
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title = "org_policy_tag_${var.tenant_config.short_name}_scoped_admins"
          description = format(
            "Org policy tag scoped grant for tenant %s.",
            var.tenant_config.short_name
          )
          expression = local.iam_tenant_condition
        }
      }
    },
    local.billing_mode != "org" ? {} : {
      admins_billing_admin = {
        member = local.principals.gcp-admins
        role   = "roles/billing.admin"
      }
      admins_billing_costs_manager = {
        member = local.principals.gcp-admins
        role   = "roles/billing.costsManager"
      }
    },
    # resman servica account IAM
    {
      sa_resman_org_policy_admin = {
        member = module.automation-tf-resman-sa.iam_email
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title = (
            "org_policy_tag_${var.tenant_config.short_name}_scoped_sa_resman"
          )
          description = format(
            "Org policy tag scoped grant for tenant %s.",
            var.tenant_config.short_name
          )
          expression = local.iam_tenant_condition
        }
      }
    },
    local.billing_mode != "org" ? {} : {
      sa_resman_billing_admin = {
        member = module.automation-tf-resman-sa.iam_email
        role   = "roles/billing.admin"
      }
    },
    # stage 2/3 service accounts IAM
    {
      for k, v in module.automation-tf-resman-sa-stage2-3 :
      "sa_${k}_org_policy_admin" => {
        member = v.iam_email
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title = "org_policy_tag_${var.tenant_config.short_name}_${k}_scoped"
          description = format(
            "Org policy tag scoped grant for tenant %s (%s).",
            var.tenant_config.short_name,
            local.branch_sas[k].description
          )
          expression = join(" && ", [
            local.iam_tenant_condition,
            local.branch_sas[k].condition
          ])
        }
      }
    }
  )
  tags = merge(
    # tenant tag value for this tenant
    {
      (var.tag_names.tenant) = {
        id = var.tag_keys.tenant
        values = {
          (var.tenant_config.short_name) = {}
        }
      }
    },
    {
      # TODO: tenant-level tag hierarchy
    }
  )
}
