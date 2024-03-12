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

    (var.tag_names.tenant) = {
      description = "Organization tenant."
      values = {
        for k, v in var.tenants : k => {
          description = v.descriptive_name
          iam = {
            "roles/resourcemanager.tagViewer" = local.tenant_iam[k]
          }
        }
      }
    }
