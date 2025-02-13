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

resource "google_secure_source_manager_instance" "instance" {
  count       = var.instance_create ? 1 : 0
  instance_id = var.instance_id
  project     = var.project_id
  location    = var.location
  labels      = var.labels
  kms_key     = var.kms_key
  dynamic "private_config" {
    for_each = var.ca_pool == null ? [] : [""]
    content {
      is_private = true
      ca_pool    = var.ca_pool
    }
  }
}

resource "google_secure_source_manager_repository" "repositories" {
  for_each      = var.repositories
  repository_id = each.key
  instance      = try(google_secure_source_manager_instance.instance[0].name, "projects/${var.project_id}/locations/${var.location}/instances/${var.instance_id}")
  project       = var.project_id
  location      = var.location
  description   = each.value.description
  dynamic "initial_config" {
    for_each = each.value.initial_config == null ? [] : [""]
    content {
      default_branch = each.value.initial_config.default_branch
      gitignores     = each.value.initial_config.gitignores
      license        = each.value.initial_config.license
      readme         = each.value.initial_config.readme
    }
  }
}