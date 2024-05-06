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
  _tenants = {
    for k, v in var.tenant_configs : k => merge(v, {
      billing_account = coalesce(v.billing_account, var.billing_account.id)
      locations       = coalesce(v.locations, var.locations)
      organization    = coalesce(v.cloud_identity, var.organization)
    })
  }
  tenants = {
    for k, v in local._tenants : k => merge(v, {
      gcs_storage_class = (
        length(split("-", v.locations.gcs)) < 2
        ? "MULTI_REGIONAL"
        : "REGIONAL"
      )
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
