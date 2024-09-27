/**
 * Copyright 2024 Google LLC
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
  repository_iam = merge([for k1, v1 in var.repositories : { for k2, v2 in v1.iam :
    "${k1}.${k2}" => {
      repository = k1
      role       = k2
      members    = v2
  } }]...)
  repository_iam_bindings = merge([for k1, v1 in var.repositories : { for k2, v2 in v1.iam_bindings :
    "${k1}.${k2}" => merge(v2, {
      repository = k1
  }) }]...)
  repository_iam_bindings_additive = merge([for k1, v1 in var.repositories : { for k2, v2 in v1.iam_bindings_additive :
    "${k1}.${k2}" => merge(v2, {
      repository = k1
  }) }]...)

  iam_instance_values = {
    project     = var.instance_create ? google_secure_source_manager_instance.instance[0].project : var.project_id
    location    = var.instance_create ? google_secure_source_manager_instance.instance[0].location : var.location
    instance_id = var.instance_create ? google_secure_source_manager_instance.instance[0].instance_id : var.instance_id
  }
}

resource "google_secure_source_manager_instance_iam_binding" "authoritative" {
  for_each    = var.iam
  project     = local.iam_instance_values["project"]
  location    = local.iam_instance_values["location"]
  instance_id = local.iam_instance_values["instance_id"]
  role        = each.key
  members     = each.value
}

resource "google_secure_source_manager_instance_iam_binding" "bindings" {
  for_each    = var.iam_bindings
  project     = local.iam_instance_values["project"]
  location    = local.iam_instance_values["location"]
  instance_id = local.iam_instance_values["instance_id"]
  role        = each.value.role
  members     = each.value.members
}

resource "google_secure_source_manager_instance_iam_member" "bindings" {
  for_each    = var.iam_bindings_additive
  project     = local.iam_instance_values["project"]
  location    = local.iam_instance_values["location"]
  instance_id = local.iam_instance_values["instance_id"]
  role        = each.value.role
  member      = each.value.member
}

resource "google_secure_source_manager_repository_iam_binding" "authoritative" {
  for_each      = local.repository_iam
  project       = google_secure_source_manager_repository.repositories[each.value.repository].project
  location      = google_secure_source_manager_repository.repositories[each.value.repository].location
  repository_id = google_secure_source_manager_repository.repositories[each.value.repository].repository_id
  role          = each.value.role
  members       = each.value.members
}

resource "google_secure_source_manager_repository_iam_binding" "bindings" {
  for_each      = local.repository_iam_bindings
  project       = google_secure_source_manager_repository.repositories[each.value.repository].project
  location      = google_secure_source_manager_repository.repositories[each.value.repository].location
  repository_id = google_secure_source_manager_repository.repositories[each.value.repository].repository_id
  role          = each.value.role
  members       = each.value.members
}

resource "google_secure_source_manager_repository_iam_member" "bindings" {
  for_each      = local.repository_iam_bindings_additive
  project       = google_secure_source_manager_repository.repositories[each.value.repository].project
  location      = google_secure_source_manager_repository.repositories[each.value.repository].location
  repository_id = google_secure_source_manager_repository.repositories[each.value.repository].repository_id
  role          = each.value.role
  member        = each.value.member
}
