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
  access_policy_name = try(google_access_context_manager_access_policy.default[var.access_policy_title].name, null)

  iam_additive_pairs = flatten([
    for member, roles in var.iam_additive_bindings : [
      for role in roles :
      { role = role, member = member }
    ]
  ])
  iam_additive = {
    for pair in local.iam_additive_pairs :
    "${pair.role}-${pair.member}" => pair
  }

  standard_perimeters = {
    for key, value in var.vpc_sc_perimeters :
    key => value if value.type == "PERIMETER_TYPE_REGULAR"
  }

  bridge_perimeters = {
    for key, value in var.vpc_sc_perimeters :
    key => value if value.type == "PERIMETER_TYPE_BRIDGE"
  }

  perimeters_access_levels = try(transpose(var.vpc_sc_access_levels_perimeters), null)
}

resource "google_access_context_manager_access_policy" "default" {
  for_each  = toset([var.access_policy_title])
  parent    = "organizations/${var.org_id}"
  title     = each.key
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
      conditions         {
        ip_subnetworks   = try(basic.value.ip_subnetworks,null)
        members          = try(basic.value.members,null)
        negate           = try(basic.value.negate,null)
      }
    }
  }
}

resource "google_access_context_manager_service_perimeter" "standard" {
  for_each       = local.standard_perimeters
  parent         = "accessPolicies/${local.access_policy_name}"
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type
  status {
    resources           = formatlist("projects/%s", lookup(var.vpc_sc_perimeter_projects, each.key, []))
    restricted_services = each.value.enforced_config.restricted_services
    access_levels       = formatlist("accessPolicies/${local.access_policy_name}/accessLevels/%s", lookup(local.perimeters_access_levels, each.key, []))

    dynamic "vpc_accessible_services" {
      for_each = each.value.enforced_config.vpc_accessible_services != [] ? [""] : []

      content {
        enable_restriction = true
        allowed_services = each.value.enforced_config.vpc_accessible_services
      }
    }
  }
  use_explicit_dry_run_spec = each.value.dry_run_config != [] ? true : false
  dynamic "spec" {
    for_each = each.value.dry_run_config != [] ? [""] : []

    content {
      resources           = formatlist("projects/%s", lookup(var.vpc_sc_perimeter_projects, each.key, []))
      restricted_services = try(each.value.dry_run_config.restricted_services, null)

      dynamic "vpc_accessible_services" {
        for_each = try(each.value.dry_run_config.vpc_accessible_services != [] ? [""] : [],[])

        content {
          enable_restriction = true
          allowed_services = try(each.value.dry_run_config.vpc_accessible_services, null)
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
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type
  status {
    resources           = formatlist("projects/%s", lookup(var.vpc_sc_perimeter_projects, each.key, []))
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

resource "google_organization_iam_custom_role" "roles" {
  for_each    = var.custom_roles
  org_id      = var.org_id
  role_id     = each.key
  title       = "Custom role ${each.key}"
  description = "Terraform-managed"
  permissions = each.value
}

resource "google_organization_iam_binding" "authoritative" {
  for_each = toset(var.iam_roles)
  org_id   = var.org_id
  role     = each.value
  members  = lookup(var.iam_members, each.value, [])
}

resource "google_organization_iam_member" "additive" {
  for_each = length(var.iam_additive_bindings) > 0 ? local.iam_additive : {}
  org_id   = var.org_id
  role     = each.value.role
  member   = each.value.member
}

resource "google_organization_iam_audit_config" "config" {
  for_each = var.iam_audit_config
  org_id   = var.org_id
  service  = each.key
  dynamic audit_log_config {
    for_each = each.value
    iterator = config
    content {
      log_type         = config.key
      exempted_members = config.value
    }
  }
}

resource "google_organization_policy" "boolean" {
  for_each   = var.policy_boolean
  org_id     = var.org_id
  constraint = each.key

  dynamic boolean_policy {
    for_each = each.value == null ? [] : [each.value]
    iterator = policy
    content {
      enforced = policy.value
    }
  }

  dynamic restore_policy {
    for_each = each.value == null ? [""] : []
    content {
      default = true
    }
  }
}

resource "google_organization_policy" "list" {
  for_each   = var.policy_list
  org_id     = var.org_id
  constraint = each.key

  dynamic list_policy {
    for_each = each.value.status == null ? [] : [each.value]
    iterator = policy
    content {
      inherit_from_parent = policy.value.inherit_from_parent
      suggested_value     = policy.value.suggested_value
      dynamic allow {
        for_each = policy.value.status ? [""] : []
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
      dynamic deny {
        for_each = policy.value.status ? [] : [""]
        content {
          values = (
            try(length(policy.value.values) > 0, false)
            ? policy.value.values
            : null
          )
          all = (
            try(length(policy.value.values) > 0, false)
            ? null
            : true
          )
        }
      }
    }
  }

  dynamic restore_policy {
    for_each = each.value.status == null ? [true] : []
    content {
      default = true
    }
  }
}
