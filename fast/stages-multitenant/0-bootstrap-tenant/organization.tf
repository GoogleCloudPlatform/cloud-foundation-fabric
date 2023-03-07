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
  iam_additive = merge(
    {
      "roles/resourcemanager.organizationViewer" = [
        "group:${local.groups.gcp-admins}"
      ]
    },
    local.billing_mode == "org" ? {
      "roles/billing.admin" = [
        "group:${local.groups.gcp-admins}",
        module.automation-tf-resman-sa.iam_email
      ]
      "roles/billing.costsManager" = ["group:${local.groups.gcp-admins}"]
    } : {}
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
    expression  = local.iam_tenant_condition
  }
}

# tag-based condition for service accounts is in the automation-sa file
