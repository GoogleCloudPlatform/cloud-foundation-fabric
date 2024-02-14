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
  iam_tenant_condition = "resource.matchTag('${local.tag_keys.tenant}', '${var.tenant_config.short_name}')"
  tag_keys = {
    for k, v in var.tag_names : k => "${var.organization.id}/${v}"
  }
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  iam_bindings_additive = merge(
    {
      admins_org_viewer = {
        member = "group:${local.groups.gcp-admins}"
        role   = "roles/resourcemanager.organizationViewer"
      }
      admins_org_policy_admin = {
        member = "group:${local.groups.gcp-admins}"
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title       = "org_policy_tag_${var.tenant_config.short_name}_scoped_admins"
          description = "Org policy tag scoped grant for tenant ${var.tenant_config.short_name}."
          expression  = local.iam_tenant_condition
        }
      }
      sa_resman_org_policy_admin = {
        member = module.automation-tf-resman-sa.iam_email
        role   = "roles/orgpolicy.policyAdmin"
        condition = {
          title       = "org_policy_tag_${var.tenant_config.short_name}_scoped_sa_resman"
          description = "Org policy tag scoped grant for tenant ${var.tenant_config.short_name}."
          expression  = local.iam_tenant_condition
        }
      }
    },
    local.billing_mode != "org" ? {} : {
      admins_billing_admin = {
        member = "group:${local.groups.gcp-admins}"
        role   = "roles/billing.admin"
      }
      admins_billing_costs_manager = {
        member = "group:${local.groups.gcp-admins}"
        role   = "roles/billing.costsManager"
      }
      sa_resman_billing_admin = {
        member = module.automation-tf-resman-sa.iam_email
        role   = "roles/billing.admin"
      }
    }
  )
  tags = {
    tenant = {
      id = var.tag_keys.tenant
      values = {
        (var.tenant_config.short_name) = {}
      }
    }
  }
}

# TODO: use tag IAM with id in the organization module

resource "google_tags_tag_value_iam_member" "resman_tag_user" {
  for_each  = var.tag_values
  tag_value = each.value
  role      = "roles/resourcemanager.tagUser"
  member    = module.automation-tf-resman-sa.iam_email
}

resource "google_tags_tag_value_iam_member" "admins_tag_viewer" {
  for_each  = var.tag_values
  tag_value = each.value
  role      = "roles/resourcemanager.tagViewer"
  member    = "group:${local.groups.gcp-admins}"
}

# tag-based condition for service accounts is in the automation-sa file
