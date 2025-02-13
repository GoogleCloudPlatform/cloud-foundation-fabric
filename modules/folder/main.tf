/**
 * Copyright 2023 Google LLC
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
  folder_id = (
    var.assured_workload_config == null
    ? (
      var.folder_create
      ? try(google_folder.folder[0].id, null)
      : var.id
    )
    : format("folders/%s", try(google_assured_workloads_workload.folder[0].resources[0].resource_id, ""))
  )
  aw_parent = (
    # Assured Workload only accepls folder as a parent and uses organization as a parent when no value provided.
    var.parent == null
    ? null
    : (
      try(startswith(var.parent, "folders/"))
      ? var.parent
      : null
    )
  )
}

resource "google_folder" "folder" {
  count               = var.folder_create && var.assured_workload_config == null ? 1 : 0
  display_name        = var.name
  parent              = var.parent
  deletion_protection = var.deletion_protection
}

resource "google_essential_contacts_contact" "contact" {
  provider                            = google-beta
  for_each                            = var.contacts
  parent                              = local.folder_id
  email                               = each.key
  language_tag                        = "en"
  notification_category_subscriptions = each.value
  depends_on = [
    google_folder_iam_binding.authoritative,
    google_folder_iam_binding.bindings,
    google_folder_iam_member.bindings
  ]
}

resource "google_compute_firewall_policy_association" "default" {
  count             = var.firewall_policy == null ? 0 : 1
  attachment_target = local.folder_id
  name              = var.firewall_policy.name
  firewall_policy   = var.firewall_policy.policy
}

resource "google_assured_workloads_workload" "folder" {
  count                     = (var.assured_workload_config != null && var.folder_create) ? 1 : 0
  compliance_regime         = var.assured_workload_config.compliance_regime
  display_name              = var.assured_workload_config.display_name
  location                  = var.assured_workload_config.location
  organization              = var.assured_workload_config.organization
  enable_sovereign_controls = var.assured_workload_config.enable_sovereign_controls
  labels                    = var.assured_workload_config.labels
  partner                   = var.assured_workload_config.partner
  dynamic "partner_permissions" {
    for_each = try(var.assured_workload_config.partner_permissions, null) == null ? [] : [""]
    content {
      assured_workloads_monitoring = var.assured_workload_config.partner_permissions.assured_workloads_monitoring
      data_logs_viewer             = var.assured_workload_config.partner_permissions.data_logs_viewer
      service_access_approver      = var.assured_workload_config.partner_permissions.service_access_approver
    }
  }

  provisioned_resources_parent = local.aw_parent

  resource_settings {
    display_name  = var.name
    resource_type = "CONSUMER_FOLDER"
  }
  violation_notifications_enabled = var.assured_workload_config.violation_notifications_enabled
}
