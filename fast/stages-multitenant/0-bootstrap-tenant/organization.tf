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

# tfdoc:file:description Organization tag and conditional IAM grant.

locals {
  tag_keys = {
    for k, v in var.tag_names : k => "${var.organization.id}/${v}"
  }
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  iam_additive = var.billing_account.is_org_level ? {
    "roles/billing.admin" = [
      "group:${local.groups.gcp-admins}",
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/billing.costsManager" = ["group:${local.groups.gcp-admins}"]
  } : {}
  tags = {
    tenant = {
      id = var.tag_keys.tenant
      values = {
        (var.tenant_config.short_name) = {}
      }
    }
  }
}

# assign org policy admin with a tag-based condition to admin group and stage 1 SA

resource "google_organization_iam_member" "org_policy_admin_stage0" {
  for_each = toset([
    "group:${local.groups.gcp-admins}",
    module.automation-tf-resman-sa.iam_email
  ])
  org_id = var.organization.id
  role   = "roles/orgpolicy.policyAdmin"
  member = each.key
  condition {
    title       = "org_policy_tag_${var.tenant_config.short_name}_scoped"
    description = "Org policy tag scoped grant for tenant ${var.tenant_config.short_name}."
    expression = (
      "resource.matchTag('${local.tag_keys.tenant}', '${var.tenant_config.short_name}')"
    )
  }
}

# assign org policy admin with a tag-based condition to stage 2 and 3 SAs

resource "google_organization_iam_member" "org_policy_admin_stage2_3" {
  for_each = {
    for k, v in local.branch_sas : k => v if var.fast_features[v.flag]
  }
  org_id = var.organization.id
  role   = "roles/orgpolicy.policyAdmin"
  member = module.automation-tf-resman-sa-stage2-3[each.key].iam_email
  condition {
    title       = "org_policy_tag_${var.tenant_config.short_name}_${each.key}_scoped"
    description = "Org policy tag scoped grant for tenant ${var.tenant_config.short_name} ${each.value.description}."
    expression  = each.value.condition
  }
}

