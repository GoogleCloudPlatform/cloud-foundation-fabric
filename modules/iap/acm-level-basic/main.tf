/**
 * Copyright 2020 Google LLC
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
  device_policies = var.device_policies
  ip_ranges       = var.ip_ranges
  members         = var.members
  name            = local.policy != null ? "${local.policy}/accessLevels/${replace(local.title, "-", "_")}" : null
  policy          = var.policy
  title           = var.title
}

resource "google_access_context_manager_access_level" "level" {
  count  = local.policy != null ? 1 : 0
  name   = local.name
  parent = local.policy
  title  = local.title

  basic {
    dynamic "conditions" {
      for_each = contains(keys(local.device_policies), "require_admin_approval") ? ["present"] : []
      content {
        dynamic "device_policy" {
          for_each = contains(keys(local.device_policies), "require_admin_approval") ? ["present"] : []
          content {
            require_admin_approval = local.device_policies["require_admin_approval"]
          }
        }
      }
    }

    dynamic "conditions" {
      for_each = contains(keys(local.device_policies), "require_corp_owned") ? ["present"] : []
      content {
        dynamic "device_policy" {
          for_each = contains(keys(local.device_policies), "require_corp_owned") ? ["present"] : []
          content {
            require_corp_owned = local.device_policies["require_corp_owned"]
          }
        }
      }
    }

    dynamic "conditions" {
      for_each = local.ip_ranges == null ? [] : ["present"]
      content {
        ip_subnetworks = local.ip_ranges
      }
    }

    dynamic "conditions" {
      for_each = local.members == null ? [] : ["present"]
      content {
        members = local.members
      }
    }
  }
}
