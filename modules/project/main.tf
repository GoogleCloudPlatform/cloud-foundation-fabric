/**
 * Copyright 2018 Google LLC
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
    for member, roles in var.iam_additive_bindings : [
      for role in roles :
      { role = role, member = member }
    ]
  ])
  iam_additive = {
    for pair in local.iam_additive_pairs :
    "${pair.role}-${pair.member}" => pair
  }
  parent_type = var.parent == null ? null : split("/", var.parent)[0]
  parent_id   = var.parent == null ? null : split("/", var.parent)[1]
  prefix      = var.prefix == null ? "" : "${var.prefix}-"
  project = (
    var.project_create
    ? try(google_project.project.0, null)
    : try(data.google_project.project.0, null)
  )
}

data "google_project" "project" {
  count      = var.project_create ? 0 : 1
  project_id = "${local.prefix}${var.name}"
}

resource "google_project" "project" {
  count               = var.project_create ? 1 : 0
  org_id              = local.parent_type == "organizations" ? local.parent_id : null
  folder_id           = local.parent_type == "folders" ? local.parent_id : null
  project_id          = "${local.prefix}${var.name}"
  name                = "${local.prefix}${var.name}"
  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network
  labels              = var.labels
}

resource "google_project_iam_custom_role" "roles" {
  for_each    = var.custom_roles
  project     = local.project.project_id
  role_id     = each.key
  title       = "Custom role ${each.key}"
  description = "Terraform-managed"
  permissions = each.value
}

resource "google_compute_project_metadata_item" "oslogin_meta" {
  count   = var.oslogin ? 1 : 0
  project = local.project.project_id
  key     = "enable-oslogin"
  value   = "TRUE"
  # depend on services or it will fail on destroy
  depends_on = [google_project_service.project_services]
}

resource "google_resource_manager_lien" "lien" {
  count        = var.lien_reason != "" ? 1 : 0
  parent       = "projects/${local.project.number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "created-by-terraform"
  reason       = var.lien_reason
}

resource "google_project_service" "project_services" {
  for_each                   = toset(var.services)
  project                    = local.project.project_id
  service                    = each.value
  disable_on_destroy         = var.service_config.disable_on_destroy
  disable_dependent_services = var.service_config.disable_dependent_services
}

# IAM notes:
# - external users need to have accepted the invitation email to join
# - oslogin roles also require role to list instances
# - additive (non-authoritative) roles might fail due to dynamic values

resource "google_project_iam_binding" "authoritative" {
  for_each = toset(var.iam_roles)
  project  = local.project.project_id
  role     = each.value
  members  = lookup(var.iam_members, each.value, [])
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles
  ]
}

resource "google_project_iam_member" "additive" {
  for_each = length(var.iam_additive_bindings) > 0 ? local.iam_additive : {}
  project  = local.project.project_id
  role     = each.value.role
  member   = each.value.member
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles
  ]
}

resource "google_project_iam_member" "oslogin_iam_serviceaccountuser" {
  for_each = var.oslogin ? toset(distinct(concat(var.oslogin_admins, var.oslogin_users))) : toset([])
  project  = local.project.project_id
  role     = "roles/iam.serviceAccountUser"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_compute_viewer" {
  for_each = var.oslogin ? toset(distinct(concat(var.oslogin_admins, var.oslogin_users))) : toset([])
  project  = local.project.project_id
  role     = "roles/compute.viewer"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_admins" {
  for_each = var.oslogin ? toset(var.oslogin_admins) : toset([])
  project  = local.project.project_id
  role     = "roles/compute.osAdminLogin"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_users" {
  for_each = var.oslogin ? toset(var.oslogin_users) : toset([])
  project  = local.project.project_id
  role     = "roles/compute.osLogin"
  member   = each.value
}

resource "google_project_organization_policy" "boolean" {
  for_each   = var.policy_boolean
  project    = local.project.project_id
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

resource "google_project_organization_policy" "list" {
  for_each   = var.policy_list
  project    = local.project.project_id
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

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  count   = try(var.shared_vpc_config.enabled, false) ? 1 : 0
  project = local.project.project_id
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  for_each = (
    try(var.shared_vpc_config.enabled, false)
    ? toset(var.shared_vpc_config.service_projects)
    : toset([])
  )
  host_project    = local.project.project_id
  service_project = each.value
  depends_on      = [google_compute_shared_vpc_host_project.shared_vpc_host]
}
