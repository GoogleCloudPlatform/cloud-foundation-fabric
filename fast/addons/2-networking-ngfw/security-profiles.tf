/**
 * Copyright 2025 Google LLC
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

# tfdoc:file:description Organization-level network security profiles.

locals {
  security_profiles = {
    for k, v in var.security_profiles : k => merge(v, {
      has_profiles = (
        v.threat_prevention_profile.severity_overrides != null ||
        v.threat_prevention_profile.threat_overrides != null
      )
    })
  }
}

resource "google_network_security_security_profile" "default" {
  for_each    = local.security_profiles
  name        = each.key
  description = each.value.description
  parent      = "organizations/${var.organization.id}"
  location    = "global"
  type        = "THREAT_PREVENTION"
  dynamic "threat_prevention_profile" {
    for_each = each.value.has_profiles ? [""] : []
    iterator = profiles
    content {
      dynamic "severity_overrides" {
        for_each = coalesce(each.value.threat_prevention_profile.severity_overrides, {})
        content {
          action   = severity_overrides.value.action
          severity = severity_overrides.value.severity
        }
      }
      dynamic "threat_overrides" {
        for_each = coalesce(each.value.threat_prevention_profile.threat_overrides, {})
        content {
          action    = threat_overrides.value.action
          threat_id = threat_overrides.value.threat_id
        }
      }
    }
  }
}

resource "google_network_security_security_profile_group" "default" {
  for_each                  = var.security_profiles
  name                      = each.key
  description               = each.value.description
  parent                    = "organizations/${var.organization.id}"
  location                  = "global"
  threat_prevention_profile = google_network_security_security_profile.default[each.key].id
}
