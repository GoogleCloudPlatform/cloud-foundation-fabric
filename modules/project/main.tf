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

locals {
  # descriptive_name cannot contain colons, so we omit the universe from the default
  _observability_factory_path = pathexpand(coalesce(
    var.factories_config.observability, "-"
  ))
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    } if k != "condition_vars"
  }
  ctx_p = "$"
  descriptive_name = (
    var.descriptive_name != null ? var.descriptive_name : "${local.prefix}${var.name}"
  )
  observability_factory_data_raw = [
    for f in try(fileset(local._observability_factory_path, "*.yaml"), []) :
    yamldecode(file("${local._observability_factory_path}/${f}"))
  ]
  parent_type = (
    var.parent == null
    ? null
    : (
      startswith(var.parent, "organizations")
      ? "organizations"
      : "folders"
    )
  )
  parent_id = (
    var.parent == null || startswith(coalesce(var.parent, "-"), "$")
    ? var.parent
    : split("/", var.parent)[1]
  )
  prefix = var.prefix == null ? "" : "${var.prefix}-"
  project = (
    var.project_reuse == null
    ? {
      project_id = try(google_project.project[0].project_id, null)
      number     = try(google_project.project[0].number, null)
      name       = try(google_project.project[0].name, null)
    }
    : (
      try(var.project_reuse.use_data_source, null) == false
      ? {
        project_id = local.project_id
        number     = try(var.project_reuse.attributes.number, null)
        name       = try(var.project_reuse.attributes.name, null)
      }
      : {
        project_id = local.project_id
        number     = try(data.google_project.project[0].number, null)
        name       = try(data.google_project.project[0].name, null)
      }
    )
  )
  project_id         = "${local.universe_prefix}${local.prefix}${var.name}"
  universe_prefix    = var.universe == null ? "" : "${var.universe.prefix}:"
  available_services = tolist(setsubtract(var.services, try(var.universe.unavailable_services, [])))
}

data "google_project" "project" {
  count      = try(var.project_reuse.use_data_source, null) == true ? 1 : 0
  project_id = local.project_id
}

resource "google_project" "project" {
  count  = var.project_reuse == null ? 1 : 0
  org_id = local.parent_type == "organizations" ? local.parent_id : null
  folder_id = (
    local.parent_type == "folders"
    ? lookup(local.ctx.folder_ids, local.parent_id, local.parent_id)
    : null
  )
  project_id          = local.project_id
  name                = local.descriptive_name
  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network
  labels              = var.labels
  deletion_policy     = var.deletion_policy

  lifecycle {
    precondition {
      condition     = var.skip_delete == null
      error_message = "skip_delete is deprecated. Use deletion_policy."
    }
  }
}

resource "google_project_service" "project_services" {
  for_each                   = toset(local.available_services)
  project                    = local.project.project_id
  service                    = each.value
  disable_on_destroy         = var.service_config.disable_on_destroy
  disable_dependent_services = var.service_config.disable_dependent_services
  depends_on                 = [google_org_policy_policy.default]
}

resource "google_compute_project_metadata_item" "default" {
  for_each = (
    contains(local.available_services, "compute.googleapis.com") ? var.compute_metadata : {}
  )
  project    = local.project.project_id
  key        = each.key
  value      = each.value
  depends_on = [google_project_service.project_services]
}

resource "google_resource_manager_lien" "lien" {
  count        = var.lien_reason != null ? 1 : 0
  parent       = "projects/${local.project.number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "created-by-terraform"
  reason       = var.lien_reason
}

resource "google_essential_contacts_contact" "contact" {
  provider                            = google-beta
  for_each                            = var.contacts
  parent                              = "projects/${local.project.project_id}"
  email                               = each.key
  language_tag                        = "en"
  notification_category_subscriptions = each.value
  depends_on = [
    google_project_iam_binding.authoritative,
    google_project_iam_binding.bindings,
    google_project_iam_member.bindings
  ]
}

resource "google_monitoring_monitored_project" "primary" {
  provider      = google-beta
  for_each      = toset(var.metric_scopes)
  metrics_scope = each.value
  name          = local.project.project_id
}

resource "google_compute_project_default_network_tier" "default_network_tier" {
  count        = var.default_network_tier == null ? 0 : 1
  network_tier = var.default_network_tier
  project      = local.project.project_id
}
