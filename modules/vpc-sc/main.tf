/**
 * Copyright 2021 Google LLC
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
  access_policy_name = google_access_context_manager_access_policy.default.name

  standard_perimeters = {
    for key, value in var.perimeters :
    key => value if value.type == "PERIMETER_TYPE_REGULAR"
  }

  bridge_perimeters = {
    for key, value in var.perimeters :
    key => value if value.type == "PERIMETER_TYPE_BRIDGE"
  }

  perimeter_access_levels_enforced = try(transpose(var.access_level_perimeters.enforced), null)
  perimeter_access_levels_dry_run  = try(transpose(var.access_level_perimeters.dry_run), null)
}

resource "google_access_context_manager_access_policy" "default" {
  parent = var.organization_id
  title  = var.access_policy_title
}

resource "google_access_context_manager_access_level" "default" {
  for_each = var.access_levels
  parent   = "accessPolicies/${local.access_policy_name}"
  name     = "accessPolicies/${local.access_policy_name}/accessLevels/${each.key}"
  title    = each.key

  dynamic "basic" {
    for_each = try(toset(each.value.conditions), [])

    content {
      combining_function = try(each.value.combining_function, null)
      conditions {
        ip_subnetworks         = try(basic.value.ip_subnetworks, null)
        required_access_levels = try(basic.value.required_access_levels, null)
        members                = try(basic.value.members, null)
        negate                 = try(basic.value.negate, null)
        device_policy          = try(basic.value.device_policy, null)
        regions                = try(basic.value.regions, null)
      }
    }
  }
}

resource "google_access_context_manager_service_perimeter" "standard" {
  for_each       = local.standard_perimeters
  parent         = "accessPolicies/${local.access_policy_name}"
  description    = "Terraform managed."
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type

  # Enforced mode configuration
  dynamic "status" {
    for_each = each.value.enforced_config != null ? [""] : []

    content {
      resources = formatlist(
        "projects/%s", try(lookup(var.perimeter_projects, each.key, {}).enforced, [])
      )
      restricted_services = each.value.enforced_config.restricted_services
      access_levels = formatlist(
        "accessPolicies/${local.access_policy_name}/accessLevels/%s",
        try(lookup(local.perimeter_access_levels_enforced, each.key, []), [])
      )

      dynamic "vpc_accessible_services" {
        for_each = each.value.enforced_config.vpc_accessible_services != [] ? [""] : []

        content {
          enable_restriction = true
          allowed_services   = each.value.enforced_config.vpc_accessible_services
        }
      }
    }
  }

  # Dry run mode configuration
  use_explicit_dry_run_spec = each.value.dry_run_config != null ? true : false
  dynamic "spec" {
    for_each = each.value.dry_run_config != null ? [""] : []

    content {
      resources = formatlist(
        "projects/%s", try(lookup(var.perimeter_projects, each.key, {}).dry_run, [])
      )
      restricted_services = try(each.value.dry_run_config.restricted_services, null)
      access_levels = formatlist(
        "accessPolicies/${local.access_policy_name}/accessLevels/%s",
        try(lookup(local.perimeter_access_levels_dry_run, each.key, []), [])
      )

      dynamic "vpc_accessible_services" {
        for_each = try(each.value.dry_run_config.vpc_accessible_services != [] ? [""] : [], [])

        content {
          enable_restriction = true
          allowed_services   = try(each.value.dry_run_config.vpc_accessible_services, null)
        }
      }
    }
  }

  # Uncomment if used alongside `google_access_context_manager_service_perimeter_resource`,
  # so they don't fight over which resources should be in the policy.
  # lifecycle {
  #   ignore_changes = [status[0].resources]
  # }

  depends_on = [
    google_access_context_manager_access_level.default,
  ]
}

resource "google_access_context_manager_service_perimeter" "bridge" {
  for_each       = local.bridge_perimeters
  parent         = "accessPolicies/${local.access_policy_name}"
  description    = "Terraform managed."
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type

  # Enforced mode configuration
  dynamic "status" {
    for_each = try(lookup(var.perimeter_projects, each.key, {}).enforced, []) != null ? [""] : []

    content {
      resources = formatlist("projects/%s", try(lookup(var.perimeter_projects, each.key, {}).enforced, []))
    }
  }

  # Dry run mode configuration
  dynamic "spec" {
    for_each = try(lookup(var.perimeter_projects, each.key, {}).dry_run, []) != null ? [""] : []

    content {
      resources = formatlist("projects/%s", try(lookup(var.perimeter_projects, each.key, {}).dry_run, []))
    }
  }

  # Uncomment if used alongside `google_access_context_manager_service_perimeter_resource`,
  # so they don't fight over which resources should be in the policy.
  # lifecycle {
  #   ignore_changes = [status[0].resources]
  # }

  depends_on = [
    google_access_context_manager_service_perimeter.standard,
    google_access_context_manager_access_level.default,
  ]
}
