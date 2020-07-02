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
  iam_additive_pairs = flatten([
    for role in var.iam_additive_roles : [
      for member in lookup(var.iam_additive_members, role, []) :
      { role = role, member = member }
    ]
  ])
  iam_additive = {
    for pair in local.iam_additive_pairs :
    "${pair.role}-${pair.member}" => pair
  }

  standard_perimeters = {
    for key, value in var.vpc_sc_perimeters :
    key => value
    if value.type == "PERIMETER_TYPE_REGULAR"
  }

  perimeter_create = var.access_policy_name != null || var.access_policy_title != null ? true : false

  bridge_perimeters = {
    for key, value in var.vpc_sc_perimeters :
    key => value
    if value.type == "PERIMETER_TYPE_BRIDGE"
  }

  access_policy_name = (
    var.access_policy_name == null
    ? try(google_access_context_manager_access_policy.default.0.name, null)
    : try(var.access_policy_name, null)
  )
}

resource "google_access_context_manager_access_policy" "default" {
  count  = var.access_policy_name == null ? 1 : 0
  parent = format("organizations/%s", var.org_id)
  title  = var.access_policy_title
}

resource "google_access_context_manager_service_perimeter" "standard" {
  for_each       = local.perimeter_create ? local.standard_perimeters : {}
  parent         = "accessPolicies/${local.access_policy_name}"
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type
  status {
    resources           = formatlist("projects/%s", lookup(var.vpc_sc_perimeters_projects, each.key, []))
    restricted_services = each.value.restricted_services
  }
  
  lifecycle {
    ignore_changes = [status[0].resources]
  }  
}

resource "google_access_context_manager_service_perimeter" "bridge" {
  for_each       = local.perimeter_create != null ? local.bridge_perimeters : {}
  parent         = "accessPolicies/${local.access_policy_name}"
  name           = "accessPolicies/${local.access_policy_name}/servicePerimeters/${each.key}"
  title          = each.key
  perimeter_type = each.value.type
  status {
    resources           = formatlist("projects/%s", lookup(var.vpc_sc_perimeters_projects, each.key, []))
    restricted_services = each.value.restricted_services
  }

  lifecycle {
    ignore_changes = [status[0].resources]
  }

  depends_on = [
    google_access_context_manager_service_perimeter.standard,
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
  for_each = length(var.iam_additive_roles) > 0 ? local.iam_additive : {}
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
