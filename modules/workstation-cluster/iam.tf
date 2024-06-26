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

# tfdoc:file:description IAM bindings

locals {
  workstation_config_iam = merge([for k1, v1 in var.workstation_configs : { for k2, v2 in v1.iam :
    "${k1}-${k2}" => {
      workstation_config_id = k1
      role                  = k2
      members               = v2
  } }]...)
  workstation_config_iam_bindings = merge([for k1, v1 in var.workstation_configs : { for k2, v2 in v1.iam_bindings :
    "${k1}-${k2}" => merge(v2, {
      workstation_config_id = k1
  }) }]...)
  workstation_config_iam_bindings_additive = merge([for k1, v1 in var.workstation_configs : { for k2, v2 in v1.iam_bindings_additive :
    "${k1}-${k2}" => merge(v2, {
      workstation_config_id = k1
  }) }]...)
  workstation_iam = merge(flatten([for k1, v1 in var.workstation_configs : [for k2, v2 in v1.workstations :
    { for k3, v3 in v2.iam : "${k1}-${k2}-${k3}" => {
      workstation_config_id = k1
      workstation_id        = k2
      role                  = k3
      members               = v3
  } }]])...)
  workstation_iam_bindings = merge(flatten([for k1, v1 in var.workstation_configs : [for k2, v2 in v1.workstations :
    { for k3, v3 in v2.iam_bindings : "${k1}-${k2}-${k3}" => merge(v3, {
      workstation_config_id = k1
      workstation_id        = k2
  }) }]])...)
  workstation_iam_bindings_additive = merge(flatten([for k1, v1 in var.workstation_configs : [for k2, v2 in v1.workstations :
    { for k3, v3 in v2.iam_bindings_additive : "${k1}-${k2}-${k3}" => merge(v3, {
      workstation_config_id = k1
      workstation_id        = k2
  }) }]])...)
}

resource "google_workstations_workstation_config_iam_binding" "authoritative" {
  provider               = google-beta
  for_each               = local.workstation_config_iam
  project                = google_workstations_workstation_config.configs[each.value.workstation_config_id].project
  location               = google_workstations_workstation_config.configs[each.value.workstation_config_id].location
  workstation_cluster_id = google_workstations_workstation_config.configs[each.value.workstation_config_id].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.configs[each.value.workstation_config_id].workstation_config_id
  role                   = each.value.role
  members                = each.value.members
}

resource "google_workstations_workstation_config_iam_binding" "bindings" {
  provider               = google-beta
  for_each               = local.workstation_config_iam_bindings
  project                = google_workstations_workstation_config.configs[each.value.workstation_config_id].project
  location               = google_workstations_workstation_config.configs[each.value.workstation_config_id].location
  workstation_cluster_id = google_workstations_workstation_config.configs[each.value.workstation_config_id].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.configs[each.value.workstation_config_id].workstation_config_id
  role                   = each.value.role
  members                = each.value.members
}

resource "google_workstations_workstation_config_iam_member" "bindings" {
  provider               = google-beta
  for_each               = local.workstation_config_iam_bindings_additive
  project                = google_workstations_workstation_config.configs[each.value.workstation_config_id].project
  location               = google_workstations_workstation_config.configs[each.value.workstation_config_id].location
  workstation_cluster_id = google_workstations_workstation_config.configs[each.value.workstation_config_id].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.configs[each.value.workstation_config_id].workstation_config_id
  role                   = each.value.role
  member                 = each.value.member
}

resource "google_workstations_workstation_iam_binding" "authoritative" {
  provider               = google-beta
  for_each               = local.workstation_iam
  project                = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].project
  location               = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].location
  workstation_cluster_id = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_config_id
  workstation_id         = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_id
  role                   = each.value.role
  members                = each.value.members
}

resource "google_workstations_workstation_iam_binding" "bindings" {
  provider               = google-beta
  for_each               = local.workstation_iam_bindings
  project                = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].project
  location               = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].location
  workstation_cluster_id = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_config_id
  workstation_id         = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_id
  role                   = each.value.role
  members                = each.value.members
}

resource "google_workstations_workstation_iam_member" "bindings" {
  provider               = google-beta
  for_each               = local.workstation_iam_bindings_additive
  project                = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].project
  location               = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].location
  workstation_cluster_id = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_cluster_id
  workstation_config_id  = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_config_id
  workstation_id         = google_workstations_workstation.workstations["${each.value.workstation_config_id}-${each.value.workstation_id}"].workstation_id
  role                   = each.value.role
  member                 = each.value.member
}

