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

locals {
  tenants = {
    for k, v in var.tenant_configs : k => merge(v, {
      billing_account = merge(v.billing_account, {
        id = coalesce(v.billing_account.id, var.billing_account.id)
        # only set is_org_level when using the org billing account
        is_org_level = (
          v.billing_account.id == null ||
          v.billing_account.id == var.billing_account.id
        ) ? var.billing_account.is_org_level : false
      })
      locations    = coalesce(v.locations, var.locations)
      organization = coalesce(v.cloud_identity, var.organization)
    })
  }
}

module "organization" {
  source          = "../../../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  tags = {
    (var.tag_names.tenant) = {
      description = "Resource management tenant."
      values = {
        for k, v in local.tenants : k => {
          description = v.descriptive_name
        }
      }
    }
  }
}
