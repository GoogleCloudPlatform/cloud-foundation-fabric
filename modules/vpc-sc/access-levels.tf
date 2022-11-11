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

# tfdoc:file:description Access level resources.

# this code implements "additive" access levels, if "authoritative"
# access levels are needed, switch to the
# google_access_context_manager_access_levels resource

resource "google_access_context_manager_access_level" "basic" {
  for_each    = var.access_levels
  parent      = "accessPolicies/${local.access_policy}"
  name        = "accessPolicies/${local.access_policy}/accessLevels/${each.key}"
  title       = each.key
  description = each.value.description

  basic {
    combining_function = each.value.combining_function

    dynamic "conditions" {
      for_each = toset(each.value.conditions)
      iterator = c
      content {
        ip_subnetworks         = c.value.ip_subnetworks
        members                = c.value.members
        negate                 = c.value.negate
        regions                = c.value.regions
        required_access_levels = coalesce(c.value.required_access_levels, [])

        dynamic "device_policy" {
          for_each = c.value.device_policy == null ? [] : [c.value.device_policy]
          iterator = dp
          content {

            allowed_device_management_levels = (
              dp.value.allowed_device_management_levels
            )
            allowed_encryption_statuses = (
              dp.value.allowed_encryption_statuses
            )
            require_admin_approval = dp.value.key.require_admin_approval
            require_corp_owned     = dp.value.require_corp_owned
            require_screen_lock    = dp.value.require_screen_lock

            dynamic "os_constraints" {
              for_each = toset(
                dp.value.os_constraints == null
                ? []
                : dp.value.os_constraints
              )
              iterator = oc
              content {
                minimum_version            = oc.value.minimum_version
                os_type                    = oc.value.os_type
                require_verified_chrome_os = oc.value.require_verified_chrome_os
              }
            }

          }
        }

      }
    }

  }
}
