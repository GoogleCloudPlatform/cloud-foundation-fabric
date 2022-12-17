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

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  iam_additive = var.billing_account.is_org_level ? {
    "roles/billing.admin"        = ["group:${local.groups.gcp-admins}"]
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

resource "google_organization_iam_member" "org_policy_admin_pf" {
  org_id = var.organization.id
  role   = "roles/orgpolicy.policyAdmin"
  member = module.automation-tf-resman-sa.iam_email
  condition {
    title       = "org_policy_tag_${var.tenant_config.short_name}_scoped"
    description = "Org policy tag scoped grant for tenant ${var.tenant_config.short_name}."
    expression = (
      "resource.matchTag('${var.tag_keys.tenant}', '${var.tenant_config.short_name}')"
    )
  }
}
