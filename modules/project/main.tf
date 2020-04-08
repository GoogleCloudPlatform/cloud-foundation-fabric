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
  cloudsvc_service_account = "${google_project.project.number}@cloudservices.gserviceaccount.com"
  gce_service_account      = "${google_project.project.number}-compute@developer.gserviceaccount.com"
  gcr_service_account      = "service-${google_project.project.number}@containerregistry.iam.gserviceaccount.com"
  gke_service_account      = "service-${google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
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
  parent_type = split("/", var.parent)[0]
  parent_id   = split("/", var.parent)[1]
  prefix      = var.prefix == null ? "" : "${var.prefix}-"
}

resource "google_project" "project" {
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
  project     = google_project.project.project_id
  role_id     = each.key
  title       = "Custom role ${each.key}"
  description = "Terraform-managed"
  permissions = each.value
}

resource "google_compute_project_metadata_item" "oslogin_meta" {
  count   = var.oslogin ? 1 : 0
  project = google_project.project.project_id
  key     = "enable-oslogin"
  value   = "TRUE"
  # depend on services or it will fail on destroy
  depends_on = [google_project_service.project_services]
}

resource "google_resource_manager_lien" "lien" {
  count        = var.lien_reason != "" ? 1 : 0
  parent       = "projects/${google_project.project.number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "created-by-terraform"
  reason       = var.lien_reason
}

resource "google_project_service" "project_services" {
  for_each                   = toset(var.services)
  project                    = google_project.project.project_id
  service                    = each.value
  disable_on_destroy         = true
  disable_dependent_services = true
}

# IAM notes:
# - external users need to have accepted the invitation email to join
# - oslogin roles also require role to list instances
# - additive (non-authoritative) roles might fail due to dynamic values

resource "google_project_iam_binding" "authoritative" {
  for_each = toset(var.iam_roles)
  project  = google_project.project.project_id
  role     = each.value
  members  = lookup(var.iam_members, each.value, [])
  depends_on = [
    google_project_service.project_services,
    google_project_iam_custom_role.roles
  ]
}

resource "google_project_iam_member" "additive" {
  for_each = length(var.iam_additive_roles) > 0 ? local.iam_additive : {}
  project  = google_project.project.project_id
  role     = each.value.role
  member   = each.value.member
}

resource "google_project_iam_member" "oslogin_iam_serviceaccountuser" {
  for_each = var.oslogin ? toset(distinct(concat(var.oslogin_admins, var.oslogin_users))) : toset([])
  project  = google_project.project.project_id
  role     = "roles/iam.serviceAccountUser"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_compute_viewer" {
  for_each = var.oslogin ? toset(distinct(concat(var.oslogin_admins, var.oslogin_users))) : toset([])
  project  = google_project.project.project_id
  role     = "roles/compute.viewer"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_admins" {
  for_each = var.oslogin ? toset(var.oslogin_admins) : toset([])
  project  = google_project.project.project_id
  role     = "roles/compute.osAdminLogin"
  member   = each.value
}

resource "google_project_iam_member" "oslogin_users" {
  for_each = var.oslogin ? toset(var.oslogin_users) : toset([])
  project  = google_project.project.project_id
  role     = "roles/compute.osLogin"
  member   = each.value
}

resource "google_project_organization_policy" "boolean" {
  for_each   = var.policy_boolean
  project    = google_project.project.project_id
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
  project    = google_project.project.project_id
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
