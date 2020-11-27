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

resource "google_access_context_manager_access_level" "level" {
  count  = var.policy != null ? 1 : 0
  name   = var.policy != null ? "${var.policy}/accessLevels/${replace(var.title, "-", "_")}" : null
  parent = var.policy
  title  = var.title

  basic {
    dynamic "conditions" {
      for_each = contains(keys(var.device_policies), "require_admin_approval") ? ["present"] : []
      content {
        dynamic "device_policy" {
          for_each = contains(keys(var.device_policies), "require_admin_approval") ? ["present"] : []
          content {
            require_admin_approval = var.device_policies["require_admin_approval"]
          }
        }
      }
    }

    dynamic "conditions" {
      for_each = contains(keys(var.device_policies), "require_corp_owned") ? ["present"] : []
      content {
        dynamic "device_policy" {
          for_each = contains(keys(var.device_policies), "require_corp_owned") ? ["present"] : []
          content {
            require_corp_owned = var.device_policies["require_corp_owned"]
          }
        }
      }
    }

    dynamic "conditions" {
      for_each = var.ip_ranges == null ? [] : ["present"]
      content {
        ip_subnetworks = var.ip_ranges
      }
    }

    dynamic "conditions" {
      for_each = var.members == null ? [] : ["present"]
      content {
        members = var.members
      }
    }
  }
}
